import 'dart:convert';

import 'package:injectable/injectable.dart';

import '../platform/secure_preferences.dart';
import 'entitlement_service.dart' show syncEntitlementTags;

@lazySingleton
class EntitlementCache {
  final SecurePreferences _prefs;
  static const String _key = 'cached_entitlements';

  EntitlementCache(this._prefs);

  Future<List<CachedEntitlement>> load() async {
    final json = await _prefs.getString(_key);
    if (json == null) return [];
    final list = jsonDecode(json) as List;
    return list
        .map((e) => CachedEntitlement.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> store(List<CachedEntitlement> entitlements) async {
    final json = jsonEncode(entitlements.map((e) => e.toJson()).toList());
    await _prefs.setString(_key, json);
  }

  Future<bool> hasSyncAccess() async {
    final entitlements = await load();
    return entitlements
        .any((e) => syncEntitlementTags.contains(e.tag) && e.balance > 0);
  }

  Future<void> clear() async {
    await _prefs.remove(_key);
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
