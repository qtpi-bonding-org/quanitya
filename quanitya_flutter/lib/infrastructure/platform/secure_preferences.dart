import 'package:injectable/injectable.dart';

import '../crypto/interfaces/i_secure_storage.dart';

/// Simple preferences API backed by secure storage.
///
/// For non-secret app preferences that need persistence across sessions.
/// Wraps [ISecureStorage] with a friendlier API (getBool, setBool, remove).
@lazySingleton
class SecurePreferences {
  final ISecureStorage _storage;

  SecurePreferences(this._storage);

  Future<bool?> getBool(String key) async {
    final value = await _storage.getSecureData(key);
    if (value == null) return null;
    return value == 'true';
  }

  Future<void> setBool(String key, bool value) =>
      _storage.storeSecureData(key, value.toString());

  Future<String?> getString(String key) => _storage.getSecureData(key);

  Future<void> setString(String key, String value) =>
      _storage.storeSecureData(key, value);

  Future<void> remove(String key) => _storage.deleteSecureData(key);
}
