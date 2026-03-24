import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show RailCatalogEntry;

import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import 'i_digital_purchase_repository.dart';
import 'purchase_models.dart';

/// Orchestrator interface for the purchase system.
///
/// Coordinates between providers, handles validation, and refreshes entitlements.
/// Future providers (Monero, X402) register here without changing existing code.
abstract class IPurchaseService {
  /// Fires when an entitlement is granted outside the normal purchase flow
  /// (e.g. orphaned purchase recovery, subscription reconciliation).
  Stream<void> get onEntitlementGranted;

  /// Register a purchase provider for its rail type.
  void registerProvider(IDigitalPurchaseRepository provider);

  /// Get available products, optionally filtered by rail.
  Future<List<PurchaseProduct>> getProducts({PurchaseRail? rail});

  /// Get the default provider for the current platform.
  Future<IDigitalPurchaseRepository?> getDefaultProvider();

  /// Execute a full purchase flow: initiate → validate → fulfill.
  Future<PurchaseValidationResult> purchase(PurchaseRequest request, {required AppSyncingMode mode});

  /// Recover and validate any pending purchases across all providers.
  Future<void> recoverPendingPurchases();

  /// Reconcile subscription entitlements with the server.
  ///
  /// Delegates to each provider's reconcileSubscriptionEntitlements().
  Future<void> reconcileSubscriptionEntitlements();

  /// Get rail catalog from server for the current platform.
  ///
  /// Returns server-authoritative rail statuses and product IDs.
  /// Works on all platforms including web (uses PoW, not IAP providers).
  Future<List<RailCatalogEntry>> getRailCatalog();

  /// Clean up all providers.
  Future<void> dispose();
}
