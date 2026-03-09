/// Contract tests for Serverpod generated models.
///
/// These tests verify that the API model shapes match what Flutter code expects.
/// They catch breaking changes when server models evolve but Flutter doesn't adapt.
///
/// Key principle: Test contract shape, not implementation.
/// - ✅ Model fields exist and are accessible
/// - ✅ Constructors accept expected parameters
/// - ❌ Business logic (unit tests)
/// - ❌ Server behavior (integration tests)
@Tags(['contract'])
library;

import 'package:flutter_test/flutter_test.dart';
import 'package:anonaccount_client/anonaccount_client.dart';

void main() {
  group('Model Contracts - Shape Verification', () {
    group('AnonAccount', () {
      test('has required fields for account creation', () {
        // This test fails at COMPILE TIME if fields are removed/renamed
        final account = AnonAccount(
          id: 1,
          ultimateSigningPublicKeyHex: 'device_public_key_hex_128_chars',
          encryptedDataKey: 'encrypted_recovery_blob_base64',
          ultimatePublicKey: 'ultimate_public_key_hex_128_chars',
        );

        // Field accessors must exist
        expect(account.id, equals(1));
        expect(account.ultimateSigningPublicKeyHex, isNotEmpty);
        expect(account.encryptedDataKey, isNotEmpty);
        expect(account.ultimatePublicKey, isNotEmpty);
      });

      test('id is nullable (server assigns)', () {
        final account = AnonAccount(
          ultimateSigningPublicKeyHex: 'key',
          encryptedDataKey: 'blob',
          ultimatePublicKey: 'ultimate',
        );

        // id can be null before server assigns it
        expect(account.id, isNull);
      });
    });

    group('AccountDevice', () {
      test('has required fields for device registration', () {
        final device = AccountDevice(
          id: 1,
          accountId: 42,
          deviceSigningPublicKeyHex: 'ecdsa_p256_public_key_hex_128_chars',
          encryptedDataKey: 'encrypted_sdk_blob_base64',
          label: 'iPhone 15 Pro',
        );

        expect(device.id, equals(1));
        expect(device.accountId, equals(42));
        expect(device.deviceSigningPublicKeyHex, isNotEmpty);
        expect(device.encryptedDataKey, isNotEmpty);
        expect(device.label, equals('iPhone 15 Pro'));
      });

      test('has optional fields for device management', () {
        final device = AccountDevice(
          id: 1,
          accountId: 1,
          deviceSigningPublicKeyHex: 'key',
          encryptedDataKey: 'blob',
          label: 'Test Device',
          isRevoked: true,
          lastActive: DateTime(2025, 1, 15),
        );

        // Optional fields used by DeviceListSection
        expect(device.isRevoked, isTrue);
        expect(device.lastActive, isNotNull);
      });

      test('isRevoked defaults correctly', () {
        final device = AccountDevice(
          id: 1,
          accountId: 1,
          deviceSigningPublicKeyHex: 'key',
          encryptedDataKey: 'blob',
          label: 'Device',
        );

        // Default should be false (not revoked)
        expect(device.isRevoked, isFalse);
      });
    });

    group('AuthenticationResult', () {
      test('has required fields for auth response', () {
        final result = AuthenticationResult(
          success: true,
          accountId: 42,
          deviceId: 7,
        );

        expect(result.success, isTrue);
        expect(result.accountId, equals(42));
        expect(result.deviceId, equals(7));
      });

      test('has optional errorMessage for failures', () {
        final result = AuthenticationResult(
          success: false,
          errorMessage: 'Invalid signature',
        );

        expect(result.success, isFalse);
        expect(result.errorMessage, equals('Invalid signature'));
      });
    });
  });

  group('Model Contracts - JSON Serialization', () {
    test('AnonAccount roundtrips through JSON', () {
      final original = AnonAccount(
        id: 1,
        ultimateSigningPublicKeyHex: 'key',
        encryptedDataKey: 'blob',
        ultimatePublicKey: 'ultimate',
      );

      final json = original.toJson();
      final restored = AnonAccount.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.ultimateSigningPublicKeyHex, equals(original.ultimateSigningPublicKeyHex));
    });

    test('AccountDevice roundtrips through JSON', () {
      final original = AccountDevice(
        id: 1,
        accountId: 42,
        deviceSigningPublicKeyHex: 'key',
        encryptedDataKey: 'blob',
        label: 'Device',
        isRevoked: false,
      );

      final json = original.toJson();
      final restored = AccountDevice.fromJson(json);

      expect(restored.id, equals(original.id));
      expect(restored.label, equals(original.label));
      expect(restored.isRevoked, equals(original.isRevoked));
    });

    test('AuthenticationResult roundtrips through JSON', () {
      final original = AuthenticationResult(
        success: true,
        accountId: 1,
        deviceId: 2,
      );

      final json = original.toJson();
      final restored = AuthenticationResult.fromJson(json);

      expect(restored.success, equals(original.success));
      expect(restored.accountId, equals(original.accountId));
    });
  });
}
