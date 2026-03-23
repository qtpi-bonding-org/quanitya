import 'purchase_models.dart';

/// Repository interface for digital purchases (Apple IAP, Google IAP, Monero, X402, etc.)
///
/// Each repository handles a specific payment rail. The orchestrator
/// (IPurchaseService) delegates to the appropriate repository based on the rail.
abstract class IDigitalPurchaseRepository {
  /// Which payment rail this repository handles.
  PurchaseRail get rail;

  /// Whether the store manages the purchase UI (IAP) or the app does (Monero/X402).
  PurchaseUiMode get uiMode;

  /// Check if this repository is available on the current platform.
  Future<bool> isAvailable();

  /// Initialize the repository (e.g., subscribe to purchase streams).
  Future<void> initialize();

  /// Get products available for purchase via this repository.
  Future<List<PurchaseProduct>> getAvailableProducts();

  /// Initiate a purchase through the store/payment system.
  Future<PurchaseResult> initiatePurchase(PurchaseRequest request);

  /// Validate a completed purchase with the server and fulfill entitlements.
  Future<PurchaseValidationResult> validateWithServer(PurchaseResult purchase);

  /// Recover any pending/unfinished purchases.
  ///
  /// For stream-based repositories (Apple/Google IAP), this triggers re-delivery
  /// of pending transactions via the purchase stream. Orphaned transactions
  /// are validated and completed automatically by the stream handler.
  Future<void> recoverPendingPurchases();

  /// Reconcile subscription entitlements with the server.
  ///
  /// On iOS/macOS, queries StoreKit 2 for current transactions and submits
  /// any unprocessed subscription renewals to the server. Server-side
  /// idempotency (receipt hash) prevents double-granting.
  /// No-op on Android, web, and other platforms.
  Future<void> reconcileSubscriptionEntitlements();

  /// Clean up resources (e.g., cancel stream subscriptions).
  Future<void> dispose();
}
