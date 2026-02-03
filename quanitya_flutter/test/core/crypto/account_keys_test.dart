import 'package:flutter_test/flutter_test.dart';
import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:quanitya_flutter/infrastructure/crypto/models/account_keys.dart';

void main() {
  group('AccountKeys', () {
    late IKeyDuo mockUltimateKeys;
    late IKeyDuo mockDeviceKeys;
    
    setUp(() async {
      // Generate real key duos for testing using new ECDH-based GenerationService
      mockUltimateKeys = await GenerationService.generateKeyDuo();
      mockDeviceKeys = await GenerationService.generateKeyDuo();
    });

    test('creates AccountKeys with required fields', () {
      // Arrange
      const symmetricDataKey = 'test-symmetric-key';
      const recoveryBlob = 'test-recovery-blob';
      const deviceBlob = 'test-device-blob';

      // Act
      final accountKeys = AccountKeys(
        ultimateKeys: mockUltimateKeys,
        deviceKeys: mockDeviceKeys,
        symmetricDataKey: symmetricDataKey,
        recoveryBlob: recoveryBlob,
        deviceBlob: deviceBlob,
      );

      // Assert
      expect(accountKeys.ultimateKeys, equals(mockUltimateKeys));
      expect(accountKeys.deviceKeys, equals(mockDeviceKeys));
      expect(accountKeys.symmetricDataKey, equals(symmetricDataKey));
      expect(accountKeys.recoveryBlob, equals(recoveryBlob));
      expect(accountKeys.deviceBlob, equals(deviceBlob));
    });

    test('provides access to key duo properties', () {
      // Arrange
      final accountKeys = AccountKeys(
        ultimateKeys: mockUltimateKeys,
        deviceKeys: mockDeviceKeys,
        symmetricDataKey: 'test-key',
        recoveryBlob: 'test-recovery',
        deviceBlob: 'test-device',
      );

      // Act & Assert
      expect(accountKeys.ultimateKeys.signing, isNotNull);
      expect(accountKeys.ultimateKeys.encryption, isNotNull);
      expect(accountKeys.deviceKeys.signing, isNotNull);
      expect(accountKeys.deviceKeys.encryption, isNotNull);
    });

    test('key duos have private keys available', () {
      // Arrange
      final accountKeys = AccountKeys(
        ultimateKeys: mockUltimateKeys,
        deviceKeys: mockDeviceKeys,
        symmetricDataKey: 'test-key',
        recoveryBlob: 'test-recovery',
        deviceBlob: 'test-device',
      );

      // Act & Assert
      expect(accountKeys.ultimateKeys.signing.hasPrivateKey, isTrue);
      expect(accountKeys.ultimateKeys.encryption.hasPrivateKey, isTrue);
      expect(accountKeys.deviceKeys.signing.hasPrivateKey, isTrue);
      expect(accountKeys.deviceKeys.encryption.hasPrivateKey, isTrue);
    });
  });
}