import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:in_app_purchase/in_app_purchase.dart' as iap;
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../../core/try_operation.dart';
import '../../crypto/crypto_key_repository.dart';
import '../../crypto/data_encryption_service.dart';
import '../i_purchase_provider.dart';
import '../purchase_exception.dart';
import '../purchase_models.dart';

/// Product IDs matching App Store Connect / Google Play Console configuration
/// and server's APPLE_PRODUCT_MAPPINGS / GOOGLE_PRODUCT_MAPPINGS env vars.
const Set<String> _productIds = {
  'sync_days_30',
  'sync_days_90',
  'sync_days_365',
};

@LazySingleton(as: IPurchaseProvider)
class InAppPurchaseProvider implements IPurchaseProvider {
  final Client _client;
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryptionService _encryption;

  InAppPurchaseProvider(this._client, this._keyRepository, this._encryption);

  final iap.InAppPurchase _iapInstance = iap.InAppPurchase.instance;
  StreamSubscription<List<iap.PurchaseDetails>>? _purchaseSubscription;

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

  @override
  Future<List<PurchaseProduct>> getAvailableProducts() {
    return tryMethod(
      () async {
        final response = await _iapInstance.queryProductDetails(_productIds);

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

        final started = await _iapInstance.buyConsumable(
          purchaseParam: purchaseParam,
        );

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

        final challenge = await _client.modules.anonaccred.device
            .generateAuthChallenge(publicKeyHex);
        final signature = await _encryption.signWithDeviceKey(challenge);
        final authResult = await _client.modules.anonaccred.device
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
