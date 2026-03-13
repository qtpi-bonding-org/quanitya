import 'purchase_models.dart';

/// Interface for purchase providers (Apple IAP, Google IAP, Monero, X402, etc.)
///
/// Each provider handles a specific payment rail. The orchestrator
/// (IPurchaseService) delegates to the appropriate provider based on the rail.
abstract class IPurchaseProvider {
  /// Which payment rail this provider handles.
  PurchaseRail get rail;

  /// Whether the store manages the purchase UI (IAP) or the app does (Monero/X402).
  PurchaseUiMode get uiMode;

  /// Check if this provider is available on the current platform.
  Future<bool> isAvailable();

  /// Initialize the provider (e.g., subscribe to purchase streams).
  Future<void> initialize();

  /// Get products available for purchase via this provider.
  Future<List<PurchaseProduct>> getAvailableProducts();

  /// Initiate a purchase through the store/payment system.
  Future<PurchaseResult> initiatePurchase(PurchaseRequest request);

  /// Validate a completed purchase with the server and fulfill entitlements.
  Future<PurchaseValidationResult> validateWithServer(PurchaseResult purchase);

  /// Recover any pending/unfinished purchases.
  ///
  /// For stream-based providers (Apple/Google IAP), this triggers re-delivery
  /// of pending transactions via the purchase stream. Orphaned transactions
  /// are validated and completed automatically by the stream handler.
  Future<void> recoverPendingPurchases();

  /// Clean up resources (e.g., cancel stream subscriptions).
  Future<void> dispose();
}
