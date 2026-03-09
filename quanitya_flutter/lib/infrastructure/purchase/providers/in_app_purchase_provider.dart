import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_2_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../../core/try_operation.dart';
import '../../crypto/crypto_key_repository.dart';
import '../../crypto/data_encryption_service.dart';
import '../../crypto/utils/hashcash.dart';
import '../i_purchase_provider.dart';
import '../purchase_exception.dart';
import '../purchase_models.dart';

@LazySingleton(as: IPurchaseProvider)
class InAppPurchaseProvider implements IPurchaseProvider {
  final Client _client;
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryptionService _encryption;

  InAppPurchaseProvider(this._client, this._keyRepository, this._encryption);

  final iap.InAppPurchase _iapInstance = iap.InAppPurchase.instance;
  StreamSubscription<List<iap.PurchaseDetails>>? _purchaseSubscription;

  /// Cached product IDs fetched from server. Null until first fetch.
  Set<String>? _cachedProductIds;

  /// Pending purchase completers keyed by product ID.
  final Map<String, Completer<PurchaseResult>> _pendingCompleters = {};

  /// Store the raw PurchaseDetails for completePurchase calls.
  final Map<String, iap.PurchaseDetails> _rawPurchaseDetails = {};

  @override
  PurchaseRail get rail {
    if (Platform.isIOS || Platform.isMacOS) return PurchaseRail.appleIap;
    if (Platform.isAndroid) return PurchaseRail.googleIap;
    return PurchaseRail.appleIap;
  }

  @override
  PurchaseUiMode get uiMode => PurchaseUiMode.storeManaged;

  @override
  Future<bool> isAvailable() {
    return tryMethod(
      () async => await _iapInstance.isAvailable(),
      PurchaseException.new,
      'isAvailable',
    );
  }

  @override
  Future<void> initialize() {
    return tryMethod(
      () async {
        _purchaseSubscription?.cancel();
        _purchaseSubscription = _iapInstance.purchaseStream.listen(
          _handlePurchaseUpdates,
          onError: (error) {
            debugPrint('InAppPurchaseProvider: Purchase stream error: $error');
          },
        );
      },
      PurchaseException.new,
      'initialize',
    );
  }

  /// Fetch active product IDs from the server, or return cached values.
  ///
  /// Uses the HashCash-protected productCatalog endpoint (no IP tracking).
  /// Maps the client-side [rail] to the server's PaymentRail name
  /// and queries the rail_product table for active entries.
  Future<Set<String>> _getProductIds() async {
    if (_cachedProductIds != null) return _cachedProductIds!;

    final railName = switch (rail) {
      PurchaseRail.appleIap => 'apple_iap',
      PurchaseRail.googleIap => 'google_iap',
      _ => 'apple_iap',
    };

    // 1. Get challenge from server
    final challengeResponse = await _client.productCatalog.getChallenge();
    final challenge = challengeResponse['challenge'] as String;
    final difficulty = challengeResponse['difficulty'] as int;

    // 2. Mine proof-of-work
    final proofOfWork = await Hashcash.mint(challenge, difficulty: difficulty);

    // 3. Sign payload with device key
    final publicKeyHex =
        await _keyRepository.getDeviceSigningPublicKeyHex();
    if (publicKeyHex == null) {
      throw const PurchaseException('Device key not found');
    }
    final payload = '$challenge:$railName';
    final signature = await _encryption.signWithDeviceKey(payload);

    // 4. Call protected endpoint
    final ids = await _client.productCatalog.getActiveStoreProductIds(
      challenge,
      proofOfWork,
      publicKeyHex,
      signature,
      railName,
    );
    _cachedProductIds = ids.toSet();
    return _cachedProductIds!;
  }

  @override
  Future<List<PurchaseProduct>> getAvailableProducts() {
    return tryMethod(
      () async {
        final productIds = await _getProductIds();
        final response = await _iapInstance.queryProductDetails(productIds);

        if (response.notFoundIDs.isNotEmpty) {
          debugPrint(
            'InAppPurchaseProvider: Products not found: ${response.notFoundIDs}',
          );
        }

        return response.productDetails.map((detail) {
          return PurchaseProduct(
            productId: detail.id,
            title: detail.title,
            description: detail.description,
            priceUsd: detail.rawPrice,
            rail: rail,
            productType: _detectProductType(detail),
            localizedPrice: detail.price,
            currencyCode: detail.currencyCode,
          );
        }).toList();
      },
      PurchaseException.new,
      'getAvailableProducts',
    );
  }

  @override
  Future<PurchaseResult> initiatePurchase(PurchaseRequest request) {
    return tryMethod(
      () async {
        final response =
            await _iapInstance.queryProductDetails({request.productId});
        if (response.productDetails.isEmpty) {
          throw PurchaseException('Product not found: ${request.productId}');
        }

        final productDetails = response.productDetails.first;
        final completer = Completer<PurchaseResult>();
        _pendingCompleters[request.productId] = completer;

        final purchaseParam = iap.PurchaseParam(
          productDetails: productDetails,
        );

        final isSubscription =
            _detectProductType(productDetails) == StoreProductType.subscription;

        final bool started;
        if (isSubscription) {
          started = await _iapInstance.buyNonConsumable(
            purchaseParam: purchaseParam,
          );
        } else {
          started = await _iapInstance.buyConsumable(
            purchaseParam: purchaseParam,
          );
        }

        if (!started) {
          _pendingCompleters.remove(request.productId);
          return PurchaseResult(
            status: PurchaseStatus.failed,
            rail: rail,
            productId: request.productId,
            errorMessage: 'Failed to start purchase',
          );
        }

        return await completer.future;
      },
      PurchaseException.new,
      'initiatePurchase',
    );
  }

  @override
  Future<PurchaseValidationResult> validateWithServer(
    PurchaseResult purchase,
  ) {
    return tryMethod(
      () async {
        final publicKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        if (publicKeyHex == null) {
          throw const PurchaseException('Device key not found');
        }

        final challenge = await _client.modules.anonaccount.device
            .generateAuthChallenge(publicKeyHex);
        final signature = await _encryption.signWithDeviceKey(challenge);
        final authResult = await _client.modules.anonaccount.device
            .authenticateDevice(challenge, signature);

        if (!authResult.success || authResult.accountId == null) {
          throw const PurchaseException('Authentication failed');
        }

        final accountId = authResult.accountId!;
        Map<String, dynamic> result;

        if (purchase.rail == PurchaseRail.appleIap) {
          result =
              await _client.modules.anonaccred.iAP.validateAppleTransaction(
            publicKeyHex,
            signature,
            purchase.transactionId ?? '',
            purchase.productId,
            accountId,
            internalTransactionId: purchase.transactionId,
          );
        } else {
          result =
              await _client.modules.anonaccred.iAP.validateGooglePurchase(
            publicKeyHex,
            signature,
            purchase.packageName ?? '',
            purchase.productId,
            purchase.purchaseToken ?? '',
            accountId,
            internalTransactionId: purchase.transactionId,
          );
        }

        final success = result['success'] as bool? ?? false;
        if (success) {
          final rawDetails = _rawPurchaseDetails.remove(purchase.productId);
          if (rawDetails != null) {
            await _iapInstance.completePurchase(rawDetails);
          }
        }

        return PurchaseValidationResult(
          success: success,
          internalTransactionId:
              result['internal_transaction_id'] as String?,
          tag: result['tag'] as String?,
          amount: (result['amount'] as num?)?.toDouble(),
          errorMessage: result['error'] as String?,
        );
      },
      PurchaseException.new,
      'validateWithServer',
    );
  }

  @override
  Future<List<PurchaseResult>> recoverPendingPurchases() {
    return tryMethod(
      () async {
        await _iapInstance.restorePurchases();
        return <PurchaseResult>[];
      },
      PurchaseException.new,
      'recoverPendingPurchases',
    );
  }

  @override
  Future<void> dispose() async {
    await _purchaseSubscription?.cancel();
    _purchaseSubscription = null;
    _pendingCompleters.clear();
    _rawPurchaseDetails.clear();
    _cachedProductIds = null;
  }

  /// Detect product type from platform-specific store metadata.
  ///
  /// Cross-platform `ProductDetails` does not expose product type,
  /// so we cast to iOS/Android subclasses.
  /// iOS has two subclasses: `AppStoreProduct2Details` (StoreKit 2, has type)
  /// and `AppStoreProductDetails` (StoreKit 1, no type field).
  StoreProductType _detectProductType(iap.ProductDetails detail) {
    try {
      if (Platform.isIOS || Platform.isMacOS) {
        if (detail is AppStoreProduct2Details) {
          return switch (detail.sk2Product.type) {
            SK2ProductType.autoRenewable ||
            SK2ProductType.nonRenewable =>
              StoreProductType.subscription,
            SK2ProductType.consumable ||
            SK2ProductType.nonConsumable =>
              StoreProductType.consumable,
          };
        }
        // SK1 (AppStoreProductDetails) doesn't expose product type
        return StoreProductType.unknown;
      } else if (Platform.isAndroid) {
        if (detail is GooglePlayProductDetails) {
          return switch (detail.productDetails.productType) {
            ProductType.subs => StoreProductType.subscription,
            ProductType.inapp => StoreProductType.consumable,
          };
        }
      }
    } catch (e) {
      debugPrint('InAppPurchaseProvider: Failed to detect product type: $e');
    }
    return StoreProductType.unknown;
  }

  void _handlePurchaseUpdates(List<iap.PurchaseDetails> purchaseDetailsList) {
    for (final details in purchaseDetailsList) {
      final result = _mapPurchaseDetails(details);
      final completer = _pendingCompleters.remove(details.productID);

      if (details.status == iap.PurchaseStatus.purchased ||
          details.status == iap.PurchaseStatus.restored) {
        _rawPurchaseDetails[details.productID] = details;
      }

      if (completer != null && !completer.isCompleted) {
        completer.complete(result);
      }
    }
  }

  PurchaseResult _mapPurchaseDetails(iap.PurchaseDetails details) {
    final PurchaseStatus status;
    switch (details.status) {
      case iap.PurchaseStatus.purchased:
      case iap.PurchaseStatus.restored:
        status = PurchaseStatus.success;
      case iap.PurchaseStatus.pending:
        status = PurchaseStatus.pending;
      case iap.PurchaseStatus.canceled:
        status = PurchaseStatus.cancelled;
      case iap.PurchaseStatus.error:
        status = PurchaseStatus.failed;
    }

    return PurchaseResult(
      status: status,
      rail: rail,
      productId: details.productID,
      transactionId: details.purchaseID,
      purchaseToken: details.verificationData.serverVerificationData,
      errorMessage: details.error?.message,
    );
  }
}
