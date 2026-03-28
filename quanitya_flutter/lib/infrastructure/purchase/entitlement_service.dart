import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show AccountFeatureEntitlement, Client;
import '../config/debug_log.dart';

import '../auth/auth_account_orchestrator.dart';
import '../core/try_operation.dart';
import 'entitlement_repository.dart';
import 'entitlement_exception.dart';
import 'i_entitlement_service.dart';

const _tag = 'infrastructure/purchase/entitlement_service';

@LazySingleton(as: IEntitlementService)
class EntitlementService implements IEntitlementService {
  final Client _client;
  final AuthAccountOrchestrator _authOrchestrator;
  final EntitlementRepository _cache;

  EntitlementService(this._client, this._authOrchestrator, this._cache);

  @override
  Future<List<AccountFeatureEntitlement>> getEntitlements() {
    return tryMethod(
      () async {
        await _authOrchestrator.ensureAuthenticated();
        final entitlements =
            await _client.featureEntitlement.getMyEntitlements();
        Log.d(_tag, 'EntitlementService: server returned ${entitlements.length} entitlements');
        for (final e in entitlements) {
          Log.d(_tag, '  tag=${e.tag} feature=${e.feature.name} balance=${e.balance} type=${e.type.name}');
        }
        final cached = entitlements.map((e) => CachedEntitlement(
          tag: e.tag,
          balance: e.balance,
          feature: e.feature.name,
          type: e.type.name,
          name: e.tag,
        )).toList();
        Log.d(_tag, 'EntitlementService: cached ${cached.length} entitlements');
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
  Future<bool> hasAiAccess() {
    return tryMethod(
      () async => await _cache.hasAiAccess(),
      EntitlementException.new,
      'hasAiAccess',
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
