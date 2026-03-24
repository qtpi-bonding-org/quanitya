import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

/// Interface for querying entitlement balances and feature access.
abstract class IEntitlementService {
  /// Get all entitlements for the current account.
  Future<List<AccountEntitlement>> getEntitlements();

  /// Get the balance for a specific entitlement tag.
  Future<double> getEntitlementBalance(String tag);

  /// Check if the account has sync access (sync-day credits > 0).
  Future<bool> hasSyncAccess();

  /// Check if the account has LLM access (llm_calls credits > 0).
  Future<bool> hasLlmAccess();

  /// Consume entitlement credits for a specific tag.
  Future<void> consumeEntitlement(String tag, double quantity);
}
