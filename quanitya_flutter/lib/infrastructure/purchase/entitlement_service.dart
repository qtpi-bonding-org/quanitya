import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../auth/auth_service.dart';
import '../core/try_operation.dart';
import 'entitlement_cache.dart';
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
  final EntitlementCache _cache;

  EntitlementService(this._client, this._authService, this._cache);

  @override
  Future<List<AccountEntitlement>> getEntitlements() {
    return tryMethod(
      () async {
        await _authService.ensureAuthenticated();
        final entitlements =
            await _client.modules.anonaccred.commerce.getEntitlements();
        debugPrint('📦 EntitlementService: server returned ${entitlements.length} entitlements');
        for (final e in entitlements) {
          debugPrint('📦   tag=${e.entitlement?.tag} balance=${e.balance} type=${e.entitlement?.type.name}');
        }
        final cached = entitlements
            .where((e) => e.entitlement?.tag != null)
            .map(
              (e) => CachedEntitlement(
                tag: e.entitlement!.tag,
                balance: e.balance,
                type: e.entitlement!.type.name,
                name: e.entitlement?.name,
              ),
            )
            .toList();
        debugPrint('📦 EntitlementService: cached ${cached.length} entitlements');
        await _cache.store(cached);
        return entitlements;
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
  Future<bool> hasSyncAccess() => _cache.hasSyncAccess();

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
