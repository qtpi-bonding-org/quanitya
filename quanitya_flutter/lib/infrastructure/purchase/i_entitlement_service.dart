import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show AccountFeatureEntitlement;

/// Interface for querying entitlement balances and feature access.
abstract class IEntitlementService {
  /// Get all entitlements for the current account.
  Future<List<AccountFeatureEntitlement>> getEntitlements();

  /// Get the balance for a specific entitlement tag.
  Future<double> getEntitlementBalance(String tag);

  /// Check if the account has sync access (sync-day credits > 0).
  Future<bool> hasSyncAccess();

  /// Check if the account has AI access (ai_credits > 0).
  Future<bool> hasAiAccess();

  /// Consume entitlement credits for a specific tag.
  Future<void> consumeEntitlement(String tag, double quantity);
}
