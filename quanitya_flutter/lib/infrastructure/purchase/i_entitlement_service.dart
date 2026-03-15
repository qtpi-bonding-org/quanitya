import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;

import '../../features/app_syncing_mode/models/app_syncing_mode.dart';

/// Interface for querying entitlement balances and feature access.
abstract class IEntitlementService {
  /// Get all entitlements for the current account.
  Future<List<AccountEntitlement>> getEntitlements(AppSyncingMode mode);

  /// Get the balance for a specific entitlement tag.
  Future<double> getEntitlementBalance(String tag, AppSyncingMode mode);

  /// Check if the account has sync access (sync-day credits > 0).
  Future<bool> hasSyncAccess(AppSyncingMode mode);

  /// Consume entitlement credits for a specific tag.
  Future<void> consumeEntitlement(String tag, double quantity, AppSyncingMode mode);
}
