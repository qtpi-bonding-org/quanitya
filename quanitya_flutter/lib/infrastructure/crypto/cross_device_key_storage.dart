import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';

import 'interfaces/i_cross_device_key_storage.dart';
import 'interfaces/i_secure_storage.dart';

/// iCloud Keychain implementation of [ICrossDeviceKeyStorage].
///
/// Uses `synchronizable: true` to sync the device key across
/// all Apple devices signed into the same iCloud account.
class ICloudKeyStorage implements ICrossDeviceKeyStorage {
  final ISecureStorage _secureStorage;

  ICloudKeyStorage(this._secureStorage);

  @override
  bool get isAvailable => !kIsWeb && Platform.isIOS;

  @override
  String get deviceLabel => 'iCloud';

  @override
  Future<void> store(String jwk) => _secureStorage.storeICloudDeviceKey(jwk);

  @override
  Future<String?> retrieve() => _secureStorage.getICloudDeviceKey();

  @override
  Future<void> delete() => _secureStorage.deleteICloudDeviceKey();
}

/// No-op implementation for platforms without cross-device key storage.
///
/// [isAvailable] returns false. All operations are no-ops.
/// Used as fallback when no platform-specific storage is available.
class NoOpCrossDeviceKeyStorage implements ICrossDeviceKeyStorage {
  @override
  bool get isAvailable => false;

  @override
  String get deviceLabel => '';

  @override
  Future<void> store(String jwk) async {}

  @override
  Future<String?> retrieve() async => null;

  @override
  Future<void> delete() async {}
}

/// DI module that registers the correct [ICrossDeviceKeyStorage]
/// based on the current platform.
///
/// - iOS: [ICloudKeyStorage] (iCloud Keychain)
/// - Android: [NoOpCrossDeviceKeyStorage] (Block Store added later)
/// - Other: [NoOpCrossDeviceKeyStorage]
@module
abstract class CrossDeviceKeyModule {
  @lazySingleton
  ICrossDeviceKeyStorage crossDeviceStorage(ISecureStorage secureStorage) {
    if (!kIsWeb && Platform.isIOS) {
      return ICloudKeyStorage(secureStorage);
    }
    // TODO: Android Block Store — return BlockStoreKeyStorage(...)
    return NoOpCrossDeviceKeyStorage();
  }
}
