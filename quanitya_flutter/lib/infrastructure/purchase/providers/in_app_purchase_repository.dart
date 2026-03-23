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

import '../../auth/auth_service.dart';
import '../../core/try_operation.dart';
import '../../crypto/crypto_key_repository.dart';
import '../../crypto/data_encryption_service.dart';
import '../../crypto/utils/hashcash.dart';
import '../../device/device_info_service.dart';
import '../i_purchase_provider.dart';
import '../purchase_exception.dart';
import '../purchase_models.dart';

/// Repository for Apple/Google In-App Purchases.
///
/// Handles ONLY platform IAP operations: product listing, purchase initiation,
/// server validation, and purchase completion. No side effects (no cubits,
/// no cache updates, no LLM switching). Callers handle side effects.
@LazySingleton(as: IPurchaseProvider)
class InAppPurchaseRepository implements IPurchaseProvider {
  final Client _client;
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryptionService _encryption;
  final AuthService _authService;
  final DeviceInfoService _deviceInfoService;

  InAppPurchaseRepository(
    this._client,
    this._keyRepository,
    this._encryption,
    this._authService,
    this._deviceInfoService,
  );

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
    if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) return PurchaseRail.appleIap;
    if (!kIsWeb && Platform.isAndroid) return PurchaseRail.googleIap;
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
  /// Calls getCatalog with the platform name, then extracts product IDs
  /// for this provider's rail from the response.
  Future<Set<String>> _getProductIds() async {
    final cached = _cachedProductIds;
    if (cached != null) return cached;

    try {
      final platformName = _getPlatformName();

      // 1. Get challenge from server
      final challengeResponse = await _client.modules.anonaccount.entrypoint.getChallenge();
      final challenge = challengeResponse.challenge;
      final difficulty = challengeResponse.difficulty;

      // 2. Mine proof-of-work
      final proofOfWork = await Hashcash.mint(challenge, difficulty: difficulty);

      // 3. Sign payload with device key
      final publicKeyHex =
          await _keyRepository.getDeviceSigningPublicKeyHex();
      if (publicKeyHex == null) {
        throw const PurchaseException('Device key not found');
      }
      final payload = '$challenge:$platformName';
      final signature = await _encryption.signWithDeviceKey(payload);

      // 4. Call platform catalog endpoint
      final catalog = await _client.productCatalog.getCatalog(
        challenge,
        proofOfWork,
        publicKeyHex,
        signature,
        platformName,
      );

      // 5. Extract product IDs for this provider's rail
      final railName = switch (rail) {
        PurchaseRail.appleIap => 'apple_iap',
        PurchaseRail.googleIap => 'google_iap',
        PurchaseRail.monero => 'monero',
        PurchaseRail.x402Http => 'x402_http',
      };

      final matchingRail = catalog.rails
          .where((r) => r.rail == railName && r.status == RailStatus.active)
          .firstOrNull;

      final ids = matchingRail?.productIds.toSet() ?? <String>{};
      _cachedProductIds = ids;
      return ids;
    } on ServerException catch (e) {
      throw PurchaseException('Product catalog: ${e.message}');
    } on PurchaseException {
      rethrow;
    } catch (e) {
      throw PurchaseException('Failed to fetch product catalog: $e');
    }
  }

  /// Get platform name for the catalog endpoint.
  String _getPlatformName() {
    if (kIsWeb) return 'web';
    if (Platform.isIOS) return 'ios';
    if (Platform.isAndroid) return 'android';
    if (Platform.isMacOS) return 'macos';
    if (Platform.isWindows) return 'windows';
    if (Platform.isLinux) return 'linux';
    return 'unknown';
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
            subscriptionPeriod: _detectSubscriptionPeriod(detail) ??
                _periodFromProductId(detail.id),
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
        debugPrint('validateWithServer: starting for '
            'rail=${purchase.rail}, '
            'productId=${purchase.productId}, '
            'transactionId=${purchase.transactionId}, '
            'status=${purchase.status}');

        // Ensure server registration and JWT session before validating.
        final deviceLabel = await _deviceInfoService.getDeviceName();
        await _authService.ensureRegistered(deviceLabel: deviceLabel);
        await _authService.ensureAuthenticated();

        debugPrint('validateWithServer: authenticated, validating...');
        final result;

        if (purchase.rail == PurchaseRail.appleIap) {
          final txnId = purchase.transactionId ?? '';
          debugPrint('validateWithServer: calling validateAppleTransaction '
              'txnId=$txnId, '
              'productId=${purchase.productId}');
          result =
              await _client.modules.anonaccred.iAP.validateAppleTransaction(
            txnId,
            purchase.productId,
            internalTransactionId: purchase.transactionId,
          );
        } else {
          debugPrint('validateWithServer: calling validateGooglePurchase '
              'packageName=${purchase.packageName}, '
              'productId=${purchase.productId}, '
              'purchaseToken=${purchase.purchaseToken != null ? '${purchase.purchaseToken?.substring(0, 20)}...' : 'null'}');
          final packageName = purchase.packageName;
          final purchaseToken = purchase.purchaseToken;
          if (packageName == null || purchaseToken == null) {
            throw PurchaseException(
              'Missing required Google purchase data: '
              'packageName=${packageName != null ? "present" : "null"}, '
              'purchaseToken=${purchaseToken != null ? "present" : "null"}',
            );
          }
          result =
              await _client.modules.anonaccred.iAP.validateGooglePurchase(
            packageName,
            purchase.productId,
            purchaseToken,
            internalTransactionId: purchase.transactionId,
          );
        }

        debugPrint('validateWithServer: server response=$result');

        if (result.success) {
          // Complete the platform purchase (clears Apple/Google queue)
          final rawDetails = _rawPurchaseDetails.remove(purchase.productId);
          if (rawDetails != null) {
            await _iapInstance.completePurchase(rawDetails);
            debugPrint('validateWithServer: completePurchase called');
          }
        }

        return PurchaseValidationResult(
          success: result.success,
          productId: result.productId,
          tag: result.tag,
          amount: result.amount,
          errorMessage: result.error,
        );
      },
      PurchaseException.new,
      'validateWithServer',
    );
  }

  @override
  Future<void> recoverPendingPurchases() {
    return tryMethod(
      () async {
        await _iapInstance.restorePurchases();
        // Restored transactions arrive via the purchase stream.
        // _handlePurchaseUpdates routes them to _recoverOrphanedPurchase
        // which validates with server and calls completePurchase.
      },
      PurchaseException.new,
      'recoverPendingPurchases',
    );
  }

  @override
  Future<void> reconcileSubscriptionEntitlements() {
    return tryMethod(
      () async {
        // Only run on iOS/macOS — StoreKit 2 transactions API.
        if (kIsWeb || !(Platform.isIOS || Platform.isMacOS)) {
          debugPrint(
            'reconcileSubscriptionEntitlements: skipping (not iOS/macOS)',
          );
          return;
        }

        debugPrint('reconcileSubscriptionEntitlements: querying SK2 transactions...');
        final allTransactions = await SK2Transaction.transactions();
        // Only reconcile subscriptions — consumables are one-time and already
        // handled by the purchase stream. subscriptionGroupID is non-null for
        // auto-renewable and non-renewable subscriptions.
        final transactions = allTransactions.where(
          (tx) => tx.subscriptionGroupID != null,
        ).toList();
        debugPrint(
          'reconcileSubscriptionEntitlements: found ${transactions.length} subscription transactions (${allTransactions.length} total)',
        );

        for (final transaction in transactions) {
          try {
            final productId = transaction.productId;
            debugPrint(
              'reconcileSubscriptionEntitlements: submitting '
              'productId=$productId, '
              'transactionId=${transaction.id}',
            );

            final result = PurchaseResult(
              status: PurchaseStatus.success,
              rail: PurchaseRail.appleIap,
              productId: productId,
              transactionId: transaction.id,
            );

            final validation = await validateWithServer(result);
            debugPrint(
              'reconcileSubscriptionEntitlements: '
              'productId=$productId → '
              'success=${validation.success}',
            );
          } catch (e) {
            debugPrint(
              'reconcileSubscriptionEntitlements: failed for '
              '${transaction.productId}: $e',
            );
          }
        }
      },
      PurchaseException.new,
      'reconcileSubscriptionEntitlements',
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
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
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
      } else if (!kIsWeb && Platform.isAndroid) {
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

  /// Detect subscription billing period from platform-specific metadata.
  SubscriptionPeriod? _detectSubscriptionPeriod(iap.ProductDetails detail) {
    try {
      if (!kIsWeb && (Platform.isIOS || Platform.isMacOS)) {
        if (detail is AppStoreProduct2Details) {
          final period = detail.sk2Product.subscription?.subscriptionPeriod;
          if (period == null) return null;
          return switch (period.unit) {
            SK2SubscriptionPeriodUnit.month => SubscriptionPeriod.monthly,
            SK2SubscriptionPeriodUnit.year => SubscriptionPeriod.yearly,
            _ => null,
          };
        }
      } else if (!kIsWeb && Platform.isAndroid) {
        if (detail is GooglePlayProductDetails) {
          final offers = detail.productDetails.subscriptionOfferDetails;
          if (offers != null && offers.isNotEmpty) {
            final phases = offers.first.pricingPhases;
            if (phases.isNotEmpty) {
              final billingPeriod = phases.first.billingPeriod;
              if (billingPeriod.contains('Y')) return SubscriptionPeriod.yearly;
              if (billingPeriod.contains('M')) return SubscriptionPeriod.monthly;
              return null;
            }
          }
        }
      }
    } catch (e) {
      debugPrint('InAppPurchaseProvider: Failed to detect subscription period: $e');
    }
    return null;
  }

  /// Fallback: parse period from product ID naming convention.
  /// Schema: q_{date}_{category}_{tier}_{period}
  /// e.g. q_20260308_sync_500mb_month → monthly
  static SubscriptionPeriod? _periodFromProductId(String productId) {
    if (productId.endsWith('_month')) return SubscriptionPeriod.monthly;
    if (productId.endsWith('_year')) return SubscriptionPeriod.yearly;
    return null;
  }

  final Set<String> _recoveringTransactions = {};

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
      } else if (details.status == iap.PurchaseStatus.purchased ||
          details.status == iap.PurchaseStatus.restored) {
        // Orphaned transaction — no active purchase request waiting for this.
        // Skip if already being recovered (prevents re-entry loop).
        final txnId = result.transactionId ?? result.productId;
        if (!_recoveringTransactions.contains(txnId)) {
          _recoverOrphanedPurchase(result);
        }
      }
    }
  }

  Future<void> _recoverOrphanedPurchase(PurchaseResult result) async {
    final txnId = result.transactionId ?? result.productId;
    _recoveringTransactions.add(txnId);
    try {
      debugPrint('_recoverOrphanedPurchase: recovering '
          'productId=${result.productId}, '
          'transactionId=${result.transactionId}');
      await validateWithServer(result);
      debugPrint('_recoverOrphanedPurchase: recovered ${result.productId}');
    } catch (e) {
      debugPrint('_recoverOrphanedPurchase: failed for '
          '${result.productId}: $e');
      // Still try to complete the purchase to clear the queue
      final rawDetails = _rawPurchaseDetails.remove(result.productId);
      if (rawDetails != null) {
        try {
          await _iapInstance.completePurchase(rawDetails);
          debugPrint('_recoverOrphanedPurchase: '
              'completePurchase called for ${result.productId}');
        } catch (e2) {
          debugPrint('_recoverOrphanedPurchase: '
              'completePurchase also failed: $e2');
        }
      }
    } finally {
      _recoveringTransactions.remove(txnId);
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
