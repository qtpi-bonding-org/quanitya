import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../core/try_operation.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import '../crypto/exceptions/crypto_exceptions.dart';
import 'platform_capability_service.dart';

/// Platform-aware secure storage that gracefully handles web limitations.
/// 
/// Uses flutter_secure_storage on all platforms (including web via WebCrypto API)
/// Provides warnings about web storage limitations for user awareness
@LazySingleton(as: ISecureStorage)
class PlatformSecureStorage implements ISecureStorage {
  final PlatformCapabilityService _capabilities;
  final FlutterSecureStorage _secureStorage;
  
  static const String _deviceKeyId = 'device_key';
  static const String _symmetricDataKeyId = 'symmetric_data_key';

  PlatformSecureStorage(this._capabilities) 
    : _secureStorage = const FlutterSecureStorage();

  @override
  Future<void> storeDeviceKey(String jwk) {
    return tryMethod(
      () async {
        if (jwk.isEmpty) {
          throw ArgumentError('Device key JWK cannot be empty');
        }
        
        if (_capabilities.isWeb) {
          debugPrint('🌐 Web: Using WebCrypto API for secure storage');
        }
        
        await _secureStorage.write(key: _deviceKeyId, value: jwk);
      },
      KeyStorageException.new,
      'storeDeviceKey',
    );
  }

  @override
  Future<void> storeSymmetricDataKey(String jwk) {
    return tryMethod(
      () async {
        if (jwk.isEmpty) {
          throw ArgumentError('Symmetric data key JWK cannot be empty');
        }
        
        await _secureStorage.write(key: _symmetricDataKeyId, value: jwk);
      },
      KeyStorageException.new,
      'storeSymmetricDataKey',
    );
  }

  @override
  Future<String?> getDeviceKey() {
    return tryMethod(
      () async {
        return await _secureStorage.read(key: _deviceKeyId);
      },
      KeyRetrievalException.new,
      'getDeviceKey',
    );
  }

  @override
  Future<String?> getSymmetricDataKey() {
    return tryMethod(
      () async {
        return await _secureStorage.read(key: _symmetricDataKeyId);
      },
      KeyRetrievalException.new,
      'getSymmetricDataKey',
    );
  }

  @override
  Future<void> clearAllKeys() {
    return tryMethod(
      () async {
        await _secureStorage.delete(key: _deviceKeyId);
        await _secureStorage.delete(key: _symmetricDataKeyId);
      },
      KeyStorageException.new,
      'clearAllKeys',
    );
  }

  @override
  Future<void> storeSecureData(String key, String value) {
    return tryMethod(
      () async {
        if (key.isEmpty) {
          throw ArgumentError('Secure data key cannot be empty');
        }
        if (value.isEmpty) {
          throw ArgumentError('Secure data value cannot be empty');
        }
        
        await _secureStorage.write(key: key, value: value);
      },
      KeyStorageException.new,
      'storeSecureData',
    );
  }

  @override
  Future<String?> getSecureData(String key) {
    return tryMethod(
      () async {
        if (key.isEmpty) {
          throw ArgumentError('Secure data key cannot be empty');
        }
        
        return await _secureStorage.read(key: key);
      },
      KeyRetrievalException.new,
      'getSecureData',
    );
  }

  @override
  Future<void> deleteSecureData(String key) {
    return tryMethod(
      () async {
        if (key.isEmpty) {
          throw ArgumentError('Secure data key cannot be empty');
        }
        
        await _secureStorage.delete(key: key);
      },
      KeyStorageException.new,
      'deleteSecureData',
    );
  }

  @override
  Future<void> storeWithPlatformOptions({
    required String key,
    required String value,
    bool synchronizable = false,
  }) {
    return tryMethod(
      () async {
        if (key.isEmpty) {
          throw ArgumentError('Platform storage key cannot be empty');
        }
        if (value.isEmpty) {
          throw ArgumentError('Platform storage value cannot be empty');
        }
        
        if (_capabilities.supportsICloudKeychain && synchronizable) {
          // iOS-specific options with iCloud sync
          const iOSOptions = IOSOptions(
            synchronizable: true,
            accessibility: KeychainAccessibility.first_unlock,
          );
          await _secureStorage.write(key: key, value: value, iOptions: iOSOptions);
        } else if (_capabilities.supportsICloudKeychain) {
          // iOS-specific options without sync (local only)
          const iOSOptions = IOSOptions(
            synchronizable: false,
            accessibility: KeychainAccessibility.first_unlock,
          );
          await _secureStorage.write(key: key, value: value, iOptions: iOSOptions);
        } else {
          // Other platforms - regular secure storage
          await _secureStorage.write(key: key, value: value);
        }
      },
      KeyStorageException.new,
      'storeWithPlatformOptions',
    );
  }

  @override
  Future<String?> getWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  }) {
    return tryMethod(
      () async {
        if (key.isEmpty) {
          throw ArgumentError('Platform storage key cannot be empty');
        }
        
        if (_capabilities.supportsICloudKeychain && synchronizable) {
          // iOS-specific options with iCloud sync
          const iOSOptions = IOSOptions(
            synchronizable: true,
            accessibility: KeychainAccessibility.first_unlock,
          );
          return await _secureStorage.read(key: key, iOptions: iOSOptions);
        } else if (_capabilities.supportsICloudKeychain) {
          // iOS-specific options without sync (local only)
          const iOSOptions = IOSOptions(
            synchronizable: false,
            accessibility: KeychainAccessibility.first_unlock,
          );
          return await _secureStorage.read(key: key, iOptions: iOSOptions);
        } else {
          // Other platforms - regular secure storage
          return await _secureStorage.read(key: key);
        }
      },
      KeyRetrievalException.new,
      'getWithPlatformOptions',
    );
  }

  @override
  Future<void> deleteWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  }) {
    return tryMethod(
      () async {
        if (key.isEmpty) {
          throw ArgumentError('Platform storage key cannot be empty');
        }
        
        if (_capabilities.supportsICloudKeychain && synchronizable) {
          // iOS-specific options with iCloud sync
          const iOSOptions = IOSOptions(
            synchronizable: true,
            accessibility: KeychainAccessibility.first_unlock,
          );
          await _secureStorage.delete(key: key, iOptions: iOSOptions);
        } else if (_capabilities.supportsICloudKeychain) {
          // iOS-specific options without sync (local only)
          const iOSOptions = IOSOptions(
            synchronizable: false,
            accessibility: KeychainAccessibility.first_unlock,
          );
          await _secureStorage.delete(key: key, iOptions: iOSOptions);
        } else {
          // Other platforms - regular secure storage
          await _secureStorage.delete(key: key);
        }
      },
      KeyStorageException.new,
      'deleteWithPlatformOptions',
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────────
  // iCloud Device Key (convenience methods)
  // ─────────────────────────────────────────────────────────────────────────────

  static const String _iCloudDeviceKeyId = 'device_key_icloud';

  @override
  Future<void> storeICloudDeviceKey(String jwk) {
    return storeWithPlatformOptions(
      key: _iCloudDeviceKeyId,
      value: jwk,
      synchronizable: true,
    );
  }

  @override
  Future<String?> getICloudDeviceKey() {
    return getWithPlatformOptions(
      key: _iCloudDeviceKeyId,
      synchronizable: true,
    );
  }

  @override
  Future<void> deleteICloudDeviceKey() {
    return deleteWithPlatformOptions(
      key: _iCloudDeviceKeyId,
      synchronizable: true,
    );
  }

  /// Whether keys are stored in native secure storage or web fallback.
  bool get isNativelySecure => !_capabilities.isWeb;
  
  /// Warning message for web users about WebCrypto storage.
  String? get storageWarning {
    if (_capabilities.isWeb) {
      return 'Keys are stored using WebCrypto API with localStorage. While persistent, '
             'this is experimental and less secure than native keychain storage. '
             'Consider using the mobile app for maximum security.';
    }
    return null;
  }
}