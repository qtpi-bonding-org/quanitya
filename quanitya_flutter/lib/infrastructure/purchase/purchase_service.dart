import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import '../core/try_operation.dart';
import 'i_entitlement_service.dart';
import 'i_purchase_provider.dart';
import 'i_purchase_service.dart';
import 'purchase_exception.dart';
import 'purchase_models.dart';

@LazySingleton(as: IPurchaseService)
class PurchaseService implements IPurchaseService {
  final IEntitlementService _entitlementService;
  final Map<PurchaseRail, IPurchaseProvider> _providers = {};

  PurchaseService(this._entitlementService);

  @override
  void registerProvider(IPurchaseProvider provider) {
    _providers[provider.rail] = provider;
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
  Future<IPurchaseProvider?> getDefaultProvider() {
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
  Future<PurchaseValidationResult> purchase(PurchaseRequest request) {
    return tryMethod(
      () async {
        final provider = _providers[request.rail];
        if (provider == null) {
          throw PurchaseException('No provider for ${request.rail}');
        }

        final result = await provider.initiatePurchase(request);
        if (result.status != PurchaseStatus.success) {
          return PurchaseValidationResult(
            success: false,
            errorMessage: result.errorMessage ?? 'Purchase ${result.status.name}',
          );
        }

        final validation = await provider.validateWithServer(result);
        if (validation.success) {
          // Refresh entitlements after successful purchase
          try {
            await _entitlementService.getEntitlements();
          } catch (e) {
            debugPrint('PurchaseService: Failed to refresh entitlements: $e');
          }
        }
        return validation;
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
          final pending = await provider.recoverPendingPurchases();
          for (final purchase in pending) {
            if (purchase.status == PurchaseStatus.success) {
              await provider.validateWithServer(purchase);
            }
          }
        }
      },
      PurchaseException.new,
      'recoverPendingPurchases',
    );
  }

  @override
  Future<void> dispose() async {
    for (final provider in _providers.values) {
      await provider.dispose();
    }
    _providers.clear();
  }
}
