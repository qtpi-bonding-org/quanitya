import 'dart:math';
import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';

/// Result of [DatabaseKeyService.getOrCreateEncryptedAtRestKey].
///
/// [key] is the hex-encoded 32-byte SQLCipher encryption key.
/// [wasCreated] is true if the key was freshly generated (not previously stored).
/// PowerSyncRepository uses [wasCreated] to detect a Keychain wipe and delete any
/// stale unreadable database file before opening a fresh one.
typedef EncryptedAtRestKeyResult = ({String key, bool wasCreated});

/// Provisions the SQLCipher database encryption key (encryptedAtRestKey).
///
/// - Key is stored in flutter_secure_storage with device-only Keychain
///   accessibility (iOS: first_unlock_this_device, Android: Keystore default).
/// - This service uses FlutterSecureStorage directly (not ISecureStorage) because
///   ISecureStorage does not support the first_unlock_this_device accessibility
///   flag required for device-only (non-iCloud-synced) storage.
/// - This key is completely separate from the E2EE iCloud key.
@lazySingleton
class DatabaseKeyService {
  static const _keyName = 'encryptedAtRestKey';

  // iOS: first_unlock_this_device excludes this item from iCloud Keychain backup
  // and device transfers. It remains accessible after first device unlock.
  static const _iosOptions = IOSOptions(
    accessibility: KeychainAccessibility.first_unlock_this_device,
  );

  final FlutterSecureStorage _storage;

  /// Default constructor used by the DI container.
  DatabaseKeyService() : _storage = const FlutterSecureStorage();

  /// Test constructor — injects a mock FlutterSecureStorage.
  @visibleForTesting
  DatabaseKeyService.withStorage(this._storage);

  /// Returns the stored encryptedAtRestKey, or generates and stores a new one.
  ///
  /// [wasCreated] is true if the key did not exist and was freshly generated.
  /// Use this flag in PowerSyncRepository to delete a stale DB file (Keychain wipe
  /// recovery — key absent but old encrypted DB still on disk).
  Future<EncryptedAtRestKeyResult> getOrCreateEncryptedAtRestKey() async {
    final existing = await _storage.read(
      key: _keyName,
      iOptions: _iosOptions,
    );
    if (existing != null) {
      return (key: existing, wasCreated: false);
    }

    final newKey = _generateHexKey();
    await _storage.write(
      key: _keyName,
      value: newKey,
      iOptions: _iosOptions,
    );
    return (key: newKey, wasCreated: true);
  }

  /// Deletes the encryptedAtRestKey from secure storage.
  ///
  /// Called by PowerSyncRepository when a SQLCipher open failure indicates the
  /// stored key does not match the database (wrong-key recovery path).
  Future<void> deleteEncryptedAtRestKey() async {
    await _storage.delete(
      key: _keyName,
      iOptions: _iosOptions,
    );
  }

  /// Generates a 32-byte cryptographically-random key as a lowercase hex string.
  String _generateHexKey() {
    final rng = Random.secure();
    final bytes = List<int>.generate(32, (_) => rng.nextInt(256));
    return bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }
}
