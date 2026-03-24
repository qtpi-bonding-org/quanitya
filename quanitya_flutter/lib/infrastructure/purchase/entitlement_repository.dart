import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../core/try_operation.dart';
import '../platform/secure_preferences.dart';
import 'entitlement_exception.dart';
import 'entitlement_service.dart' show isSyncEntitlementTag;

@lazySingleton
class EntitlementRepository {
  final SecurePreferences _prefs;

  static const String _cacheKey = 'cached_entitlements';
  static const String _purchasedKey = 'has_ever_purchased';

  EntitlementRepository(this._prefs);

  // ---------------------------------------------------------------------------
  // Cache methods (absorbed from EntitlementCache)
  // ---------------------------------------------------------------------------

  Future<List<CachedEntitlement>> load() {
    return tryMethod(
      () async {
        final json = await _prefs.getString(_cacheKey);
        if (json == null) return <CachedEntitlement>[];
        final list = jsonDecode(json) as List;
        return list
            .map((e) => CachedEntitlement.fromJson(e as Map<String, dynamic>))
            .toList();
      },
      EntitlementException.new,
      'load',
    );
  }

  Future<void> store(List<CachedEntitlement> entitlements) {
    return tryMethod(
      () async {
        final json = jsonEncode(entitlements.map((e) => e.toJson()).toList());
        await _prefs.setString(_cacheKey, json);
      },
      EntitlementException.new,
      'store',
    );
  }

  Future<bool> hasSyncAccess() {
    return tryMethod(
      () async {
        final entitlements = await load();
        return entitlements
            .any((e) => isSyncEntitlementTag(e.tag) && e.balance > 0);
      },
      EntitlementException.new,
      'hasSyncAccess',
    );
  }

  Future<bool> hasLlmAccess() {
    return tryMethod(
      () async {
        final entitlements = await load();
        return entitlements
            .any((e) => e.tag == 'llm_calls' && e.balance > 0);
      },
      EntitlementException.new,
      'hasLlmAccess',
    );
  }

  Future<void> clear() {
    return tryMethod(
      () async {
        await _prefs.remove(_cacheKey);
      },
      EntitlementException.new,
      'clear',
    );
  }

  // ---------------------------------------------------------------------------
  // Purchase flag methods
  // ---------------------------------------------------------------------------

  Future<bool> hasEverPurchased() {
    return tryMethod(
      () async {
        final value = await _prefs.getBool(_purchasedKey);
        return value == true;
      },
      EntitlementException.new,
      'hasEverPurchased',
    );
  }

  Future<void> markPurchased() {
    return tryMethod(
      () async {
        final already = await hasEverPurchased();
        if (already) return;
        await _prefs.setBool(_purchasedKey, true);
      },
      EntitlementException.new,
      'markPurchased',
    );
  }

  // ---------------------------------------------------------------------------
  // Balance update helper
  // ---------------------------------------------------------------------------

  /// Set the cached balance for [tag] to [amount] (absolute value, not delta).
  Future<void> updateBalance(String tag, double amount) {
    return tryMethod(
      () async {
        final entitlements = await load();
        final index = entitlements.indexWhere((e) => e.tag == tag);
        final List<CachedEntitlement> updated;

        if (index >= 0) {
          updated = [
            for (var i = 0; i < entitlements.length; i++)
              if (i == index)
                CachedEntitlement(
                  tag: entitlements[i].tag,
                  balance: amount,
                  type: entitlements[i].type,
                  name: entitlements[i].name,
                )
              else
                entitlements[i],
          ];
        } else {
          updated = [
            ...entitlements,
            CachedEntitlement(tag: tag, balance: amount, type: 'unknown'),
          ];
        }

        await store(updated);
      },
      EntitlementException.new,
      'updateBalance',
    );
  }
}

class CachedEntitlement {
  final String tag;
  final double balance;
  final String type;
  final String? name;

  const CachedEntitlement({
    required this.tag,
    required this.balance,
    required this.type,
    this.name,
  });

  factory CachedEntitlement.fromJson(Map<String, dynamic> json) =>
      CachedEntitlement(
        tag: json['tag'] as String,
        balance: (json['balance'] as num).toDouble(),
        type: json['type'] as String,
        name: json['name'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'tag': tag,
        'balance': balance,
        'type': type,
        if (name != null) 'name': name,
      };
}
