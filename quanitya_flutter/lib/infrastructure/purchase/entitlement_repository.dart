import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../platform/secure_preferences.dart';
import 'entitlement_cache.dart' show CachedEntitlement;
import 'entitlement_service.dart' show syncEntitlementTags;

@lazySingleton
class EntitlementRepository {
  final SecurePreferences _prefs;

  static const String _cacheKey = 'cached_entitlements';
  static const String _purchasedKey = 'has_ever_purchased';

  EntitlementRepository(this._prefs);

  // ---------------------------------------------------------------------------
  // Cache methods (absorbed from EntitlementCache)
  // ---------------------------------------------------------------------------

  Future<List<CachedEntitlement>> load() async {
    final json = await _prefs.getString(_cacheKey);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => CachedEntitlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> store(List<CachedEntitlement> entitlements) async {
    final json = jsonEncode(entitlements.map((e) => e.toJson()).toList());
    await _prefs.setString(_cacheKey, json);
  }

  Future<bool> hasSyncAccess() async {
    final entitlements = await load();
    return entitlements
        .any((e) => syncEntitlementTags.contains(e.tag) && e.balance > 0);
  }

  Future<void> clear() async {
    await _prefs.remove(_cacheKey);
  }

  // ---------------------------------------------------------------------------
  // Purchase flag methods (absorbed from PaidAccountCubit)
  // ---------------------------------------------------------------------------

  /// Whether the user has ever made a purchase.
  Future<bool> hasEverPurchased() async {
    final value = await _prefs.getBool(_purchasedKey);
    return value == true;
  }

  /// Mark that the user has made a purchase. Idempotent — safe to call multiple
  /// times; only writes on the first call.
  Future<void> markPurchased() async {
    final already = await hasEverPurchased();
    if (already) return;
    await _prefs.setBool(_purchasedKey, true);
  }

  // ---------------------------------------------------------------------------
  // Balance update helper
  // ---------------------------------------------------------------------------

  /// Load the cached entitlement list, update the balance for [tag] (adding a
  /// new entry if none exists), then persist the result.
  Future<void> updateBalance(String tag, double amount) async {
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
  }
}
