import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/infrastructure/auth/auth_repository.dart';
import 'package:quanitya_flutter/infrastructure/auth/registration_payload.dart';
import 'package:quanitya_flutter/infrastructure/crypto/interfaces/i_secure_storage.dart';
import 'package:quanitya_flutter/infrastructure/platform/secure_preferences.dart';

// ─────────────────────────────────────────────────────────────────────────────
// In-memory fake implementations — no platform dependencies
// ─────────────────────────────────────────────────────────────────────────────

class _FakeSecureStorage implements ISecureStorage {
  final _store = <String, String>{};

  @override
  Future<void> storeSecureData(String key, String value) async =>
      _store[key] = value;

  @override
  Future<String?> getSecureData(String key) async => _store[key];

  @override
  Future<void> deleteSecureData(String key) async => _store.remove(key);

  // ── Key-typed helpers (unused by AuthRepository, satisfy the interface) ──

  @override
  Future<void> storeDeviceKey(String jwk) async => _store['device_key'] = jwk;

  @override
  Future<String?> getDeviceKey() async => _store['device_key'];

  @override
  Future<void> storeSymmetricDataKey(String jwk) async =>
      _store['symmetric_key'] = jwk;

  @override
  Future<String?> getSymmetricDataKey() async => _store['symmetric_key'];

  @override
  Future<void> clearAllKeys() async => _store.clear();

  @override
  Future<void> storeWithPlatformOptions({
    required String key,
    required String value,
    bool synchronizable = false,
  }) async =>
      _store[key] = value;

  @override
  Future<String?> getWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  }) async =>
      _store[key];

  @override
  Future<void> deleteWithPlatformOptions({
    required String key,
    bool synchronizable = false,
  }) async =>
      _store.remove(key);

  @override
  Future<void> storeICloudDeviceKey(String jwk) async =>
      _store['icloud_device_key'] = jwk;

  @override
  Future<String?> getICloudDeviceKey() async => _store['icloud_device_key'];

  @override
  Future<void> deleteICloudDeviceKey() async =>
      _store.remove('icloud_device_key');
}

// ─────────────────────────────────────────────────────────────────────────────
// Helpers
// ─────────────────────────────────────────────────────────────────────────────

RegistrationPayload _makePayload() => RegistrationPayload(
      devicePublicKeyHex: 'aabbcc' * 21 + 'aabb', // 128-char hex
      ultimatePublicKeyHex: 'ddeeff' * 21 + 'ddee',
      recoveryBlob: 'recovery-blob-data',
      deviceBlob: 'device-blob-data',
      signature: 'base64signature==',
      deviceKeyAttestation: 'attestation-hex',
      createdAt: DateTime(2026, 3, 23),
    );

// ─────────────────────────────────────────────────────────────────────────────
// Tests
// ─────────────────────────────────────────────────────────────────────────────

void main() {
  late _FakeSecureStorage fakeStorage;
  late SecurePreferences fakePrefs;
  late AuthRepository repository;

  setUp(() {
    fakeStorage = _FakeSecureStorage();
    // SecurePreferences wraps ISecureStorage — wire the same fake instance so
    // both share the same in-memory map (they use different key namespaces).
    fakePrefs = SecurePreferences(fakeStorage);
    repository = AuthRepository(fakePrefs, fakeStorage);
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Registration flag
  // ───────────────────────────────────────────────────────────────────────────

  group('registration flag', () {
    test('isRegisteredWithServer returns false when flag not set', () async {
      expect(await repository.isRegisteredWithServer, isFalse);
    });

    test('setRegistered makes isRegisteredWithServer return true', () async {
      await repository.setRegistered();

      expect(await repository.isRegisteredWithServer, isTrue);
    });

    test('clearRegistrationFlag resets flag to false', () async {
      await repository.setRegistered();
      await repository.clearRegistrationFlag();

      expect(await repository.isRegisteredWithServer, isFalse);
    });

    test('clearRegistrationFlag is a no-op when flag was never set', () async {
      await repository.clearRegistrationFlag(); // Should not throw
      expect(await repository.isRegisteredWithServer, isFalse);
    });
  });

  // ───────────────────────────────────────────────────────────────────────────
  // Registration payload
  // ───────────────────────────────────────────────────────────────────────────

  group('registration payload', () {
    test('getRegistrationPayload returns null when nothing stored', () async {
      expect(await repository.getRegistrationPayload(), isNull);
    });

    test('storeRegistrationPayload persists payload', () async {
      final payload = _makePayload();
      await repository.storeRegistrationPayload(payload);

      final retrieved = await repository.getRegistrationPayload();

      expect(retrieved, isNotNull);
      expect(retrieved!.devicePublicKeyHex, payload.devicePublicKeyHex);
      expect(retrieved.ultimatePublicKeyHex, payload.ultimatePublicKeyHex);
      expect(retrieved.recoveryBlob, payload.recoveryBlob);
      expect(retrieved.deviceBlob, payload.deviceBlob);
      expect(retrieved.signature, payload.signature);
      expect(retrieved.deviceKeyAttestation, payload.deviceKeyAttestation);
      expect(retrieved.createdAt, payload.createdAt);
    });

    test('deleteRegistrationPayload removes stored payload', () async {
      await repository.storeRegistrationPayload(_makePayload());
      await repository.deleteRegistrationPayload();

      expect(await repository.getRegistrationPayload(), isNull);
    });

    test('deleteRegistrationPayload is a no-op when nothing stored', () async {
      await repository.deleteRegistrationPayload(); // Should not throw
      expect(await repository.getRegistrationPayload(), isNull);
    });

    test('crossDeviceKeyAttestation roundtrips correctly when null', () async {
      final payload = _makePayload();
      expect(payload.crossDeviceKeyAttestation, isNull);

      await repository.storeRegistrationPayload(payload);
      final retrieved = await repository.getRegistrationPayload();

      expect(retrieved!.crossDeviceKeyAttestation, isNull);
    });

    test('crossDeviceKeyAttestation roundtrips correctly when set', () async {
      final payload = _makePayload().copyWith(
        crossDeviceKeyAttestation: 'cross-device-attest-hex',
      );

      await repository.storeRegistrationPayload(payload);
      final retrieved = await repository.getRegistrationPayload();

      expect(
        retrieved!.crossDeviceKeyAttestation,
        'cross-device-attest-hex',
      );
    });
  });
}
