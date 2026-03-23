import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../auth/auth_service.dart';
import '../core/try_operation.dart';
import 'entitlement_exception.dart';
import 'i_entitlement_service.dart';

/// Entitlement tags for cloud sync access (one per storage tier).
const List<String> syncEntitlementTags = [
  'sync_500mb_days',
  'sync_1gb_days',
];

@LazySingleton(as: IEntitlementService)
class EntitlementService implements IEntitlementService {
  final Client _client;
  final AuthService _authService;

  EntitlementService(this._client, this._authService);

  @override
  Future<List<AccountEntitlement>> getEntitlements() {
    return tryMethod(
      () async {
        await _authService.ensureAuthenticated();
        return await _client.modules.anonaccred.commerce.getEntitlements();
      },
      EntitlementException.new,
      'getEntitlements',
    );
  }

  @override
  Future<double> getEntitlementBalance(String tag) {
    return tryMethod(
      () async {
        await _authService.ensureAuthenticated();
        return await _client.modules.anonaccred.commerce.getEntitlementBalance(
          tag,
        );
      },
      EntitlementException.new,
      'getEntitlementBalance',
    );
  }

  @override
  Future<bool> hasSyncAccess() {
    return tryMethod(
      () async {
        for (final tag in syncEntitlementTags) {
          final balance = await getEntitlementBalance(tag);
          if (balance > 0) return true;
        }
        return false;
      },
      EntitlementException.new,
      'hasSyncAccess',
    );
  }

  @override
  Future<void> consumeEntitlement(String tag, double quantity) {
    return tryMethod(
      () async {
        await _authService.ensureAuthenticated();
        await _client.modules.anonaccred.commerce.consumeEntitlement(
          tag,
          quantity,
        );
      },
      EntitlementException.new,
      'consumeEntitlement',
    );
  }
}
