import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_secure_storage.dart';

/// In-memory fake for [ISecureStorage] for use in tests.
class FakeSecureStorage implements ISecureStorage {
  final Map<String, String> _store = {};

  @override
  Future<void> storeSecureData(String key, String value) async {
    _store[key] = value;
  }

  @override
  Future<String?> getSecureData(String key) async {
    return _store[key];
  }

  @override
  Future<void> deleteSecureData(String key) async {
    _store.remove(key);
  }

  @override
  Future<void> storeDeviceKey(String jwk) async {
    _store['device_key'] = jwk;
  }

  @override
  Future<void> storeSymmetricDataKey(String jwk) async {
    _store['symmetric_data_key'] = jwk;
  }

  @override
  Future<String?> getDeviceKey() async {
    return _store['device_key'];
  }

  @override
  Future<String?> getSymmetricDataKey() async {
    return _store['symmetric_data_key'];
  }

  @override
  Future<void> clearAllKeys() async {
    _store.clear();
  }

  @override
  Future<void> storeWithPlatformOptions({
    required String key,
    required String value,
    bool synchronizable = false,
  }) async {
    _store['platform_$key'] = value;
  }

  @override
  Future<String?> getWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  }) async {
    return _store['platform_$key'];
  }

  @override
  Future<void> deleteWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  }) async {
    _store.remove('platform_$key');
  }

  @override
  Future<void> storeICloudDeviceKey(String jwk) async {
    _store['device_key_icloud'] = jwk;
  }

  @override
  Future<String?> getICloudDeviceKey() async {
    return _store['device_key_icloud'];
  }

  @override
  Future<void> deleteICloudDeviceKey() async {
    _store.remove('device_key_icloud');
  }
}
