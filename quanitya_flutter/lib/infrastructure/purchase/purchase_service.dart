import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show Client, RailCatalogEntry;

import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import '../../features/settings/repositories/llm_provider_config_repository.dart';
import '../core/try_operation.dart';
import '../platform/platform_capability_service.dart';
import '../public_submission/public_submission_service.dart';
import 'entitlement_repository.dart';
import 'i_digital_purchase_repository.dart';
import 'i_purchase_service.dart';
import 'purchase_exception.dart';
import 'purchase_models.dart';

@LazySingleton(as: IPurchaseService)
class PurchaseService implements IPurchaseService {
  final PublicSubmissionService _submissionService;
  final Client _client;
  final PlatformCapabilityService _platformCaps;
  final EntitlementRepository _entitlementRepo;
  final LlmProviderConfigRepository _llmConfigRepo;
  final Map<PurchaseRail, IDigitalPurchaseRepository> _providers = {};
  final List<StreamSubscription<void>> _entitlementSubscriptions = [];

  final StreamController<void> _entitlementGrantedController =
      StreamController<void>.broadcast();

  @override
  Stream<void> get onEntitlementGranted => _entitlementGrantedController.stream;

  PurchaseService(
    this._submissionService,
    this._client,
    this._platformCaps,
    this._entitlementRepo,
    this._llmConfigRepo,
  );

  @override
  void registerProvider(IDigitalPurchaseRepository provider) {
    _providers[provider.rail] = provider;
    _entitlementSubscriptions.add(
      provider.onEntitlementGranted.listen((_) {
        _entitlementGrantedController.add(null);
      }),
    );
    debugPrint('PurchaseService: Registered provider for ${provider.rail}');
  }

  @override
  Future<List<PurchaseProduct>> getProducts({PurchaseRail? rail}) {
    return tryMethod(
      () async {
        if (rail != null) {
          final provider = _providers[rail];
          if (provider == null) return <PurchaseProduct>[];
          return await provider.getAvailableProducts();
        }

        final allProducts = <PurchaseProduct>[];
        for (final provider in _providers.values) {
          final products = await provider.getAvailableProducts();
          allProducts.addAll(products);
        }
        return allProducts;
      },
      PurchaseException.new,
      'getProducts',
    );
  }

  @override
  Future<IDigitalPurchaseRepository?> getDefaultProvider() {
    return tryMethod(
      () async {
        for (final provider in _providers.values) {
          if (await provider.isAvailable()) return provider;
        }
        return null;
      },
      PurchaseException.new,
      'getDefaultProvider',
    );
  }

  @override
  Future<PurchaseValidationResult> purchase(PurchaseRequest request, {required AppSyncingMode mode}) {
    return tryMethod(
      () async {
        final provider = _providers[request.rail];
        if (provider == null) {
          throw PurchaseException('No provider for ${request.rail}');
        }

        final result = await provider.initiatePurchase(request);
        if (result.status != PurchaseStatus.success) {
          throw PurchaseException(
            result.errorMessage ?? 'Purchase ${result.status.name}',
            null,
            result.status,
          );
        }

        final validationResult = await provider.validateWithServer(result);

        if (validationResult.tag != null && validationResult.amount != null) {
          try {
            await _entitlementRepo.updateBalance(
              validationResult.tag!,
              validationResult.amount!,
            );
            await _entitlementRepo.markPurchased();
            if (validationResult.tag == 'llm_calls') {
              await _llmConfigRepo.saveQuanityaSelection();
            }
          } catch (e) {
            // Best-effort: server already granted the entitlement, so the
            // next getEntitlements() call will refresh the cache. Don't
            // fail the purchase over a local cache write error.
            debugPrint('PurchaseService.purchase: cache update failed (non-fatal): $e');
          }
        } else {
          debugPrint('PurchaseService.purchase: server returned incomplete entitlement '
              '(tag=${validationResult.tag}, amount=${validationResult.amount})');
        }

        return validationResult;
      },
      PurchaseException.new,
      'purchase',
    );
  }

  @override
  Future<void> recoverPendingPurchases() {
    return tryMethod(
      () async {
        for (final provider in _providers.values) {
          await provider.recoverPendingPurchases();
        }
      },
      PurchaseException.new,
      'recoverPendingPurchases',
    );
  }

  @override
  Future<void> reconcileSubscriptionEntitlements() {
    return tryMethod(
      () async {
        for (final provider in _providers.values) {
          await provider.reconcileSubscriptionEntitlements();
        }
      },
      PurchaseException.new,
      'reconcileSubscriptionEntitlements',
    );
  }

  @override
  Future<List<RailCatalogEntry>> getRailCatalog() {
    return tryMethod(
      () async {
        final platformId = _platformCaps.platformId;
        final catalog = await _submissionService
            .queryWithVerification<List<RailCatalogEntry>>(
          endpoint: 'productCatalog',
          payload: platformId,
          queryCallback: (challenge, proofOfWork, publicKeyHex, signature) async {
            final response = await _client.productCatalog.getCatalog(
              challenge,
              proofOfWork,
              publicKeyHex,
              signature,
              platformId,
            );
            return response.rails;
          },
        );
        return catalog;
      },
      PurchaseException.new,
      'getRailCatalog',
    );
  }

  @override
  Future<void> dispose() async {
    for (final sub in _entitlementSubscriptions) {
      await sub.cancel();
    }
    _entitlementSubscriptions.clear();
    await _entitlementGrantedController.close();
    for (final provider in _providers.values) {
      await provider.dispose();
    }
    _providers.clear();
  }
}
