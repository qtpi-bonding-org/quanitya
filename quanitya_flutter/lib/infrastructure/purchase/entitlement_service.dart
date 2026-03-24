import 'package:anonaccred_client/anonaccred_client.dart'
    show AccountEntitlement;
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../auth/auth_account_orchestrator.dart';
import '../core/try_operation.dart';
import 'entitlement_repository.dart';
import 'entitlement_exception.dart';
import 'i_entitlement_service.dart';

/// Whether an entitlement tag grants sync access.
///
/// Convention: all sync-tier tags start with `sync_`. New tiers
/// (e.g. `sync_5gb_days`) are recognised automatically.
bool isSyncEntitlementTag(String tag) => tag.startsWith('sync_');

@LazySingleton(as: IEntitlementService)
class EntitlementService implements IEntitlementService {
  final Client _client;
  final AuthAccountOrchestrator _authOrchestrator;
  final EntitlementRepository _cache;

  EntitlementService(this._client, this._authOrchestrator, this._cache);

  @override
  Future<List<AccountEntitlement>> getEntitlements() {
    return tryMethod(
      () async {
        await _authOrchestrator.ensureAuthenticated();
        final entitlements =
            await _client.modules.anonaccred.commerce.getEntitlements();
        debugPrint('📦 EntitlementService: server returned ${entitlements.length} entitlements');
        for (final e in entitlements) {
          debugPrint('📦   tag=${e.entitlement?.tag} balance=${e.balance} type=${e.entitlement?.type.name}');
        }
        final cached = <CachedEntitlement>[];
        for (final e in entitlements) {
          final ent = e.entitlement;
          if (ent == null || ent.tag.isEmpty) continue;
          cached.add(CachedEntitlement(
            tag: ent.tag,
            balance: e.balance,
            type: ent.type.name,
            name: ent.name,
          ));
        }
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
        await _authOrchestrator.ensureAuthenticated();
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
      () async => await _cache.hasSyncAccess(),
      EntitlementException.new,
      'hasSyncAccess',
    );
  }

  @override
  Future<void> consumeEntitlement(String tag, double quantity) {
    return tryMethod(
      () async {
        await _authOrchestrator.ensureAuthenticated();
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
