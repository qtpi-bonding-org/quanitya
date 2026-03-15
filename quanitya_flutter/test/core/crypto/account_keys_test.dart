import 'package:flutter_test/flutter_test.dart';
import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:quanitya_flutter/infrastructure/crypto/models/account_keys.dart';

/// Whether webcrypto native symbols are available in this test environment.
/// Set once in setUpAll; checked by each test.
bool _webcryptoAvailable = true;

void main() {
  group('AccountKeys', () {
    IKeyDuo? ultimateKeys;
    IKeyDuo? deviceKeys;

    setUpAll(() async {
      try {
        await GenerationService.generateKeyDuo();
      } on UnsupportedError {
        _webcryptoAvailable = false;
      }
    });

    setUp(() async {
      if (!_webcryptoAvailable) return;
      ultimateKeys = await GenerationService.generateKeyDuo();
      deviceKeys = await GenerationService.generateKeyDuo();
    });

    test('creates AccountKeys with required fields', () {
      if (!_webcryptoAvailable) {
        markTestSkipped('webcrypto native library not available');
        return;
      }
      const symmetricDataKey = 'test-symmetric-key';
      const recoveryBlob = 'test-recovery-blob';
      const deviceBlob = 'test-device-blob';

      final accountKeys = AccountKeys(
        ultimateKeys: ultimateKeys!,
        deviceKeys: deviceKeys!,
        symmetricDataKey: symmetricDataKey,
        recoveryBlob: recoveryBlob,
        deviceBlob: deviceBlob,
      );

      expect(accountKeys.ultimateKeys, equals(ultimateKeys));
      expect(accountKeys.deviceKeys, equals(deviceKeys));
      expect(accountKeys.symmetricDataKey, equals(symmetricDataKey));
      expect(accountKeys.recoveryBlob, equals(recoveryBlob));
      expect(accountKeys.deviceBlob, equals(deviceBlob));
    });

    test('provides access to key duo properties', () {
      if (!_webcryptoAvailable) {
        markTestSkipped('webcrypto native library not available');
        return;
      }
      final accountKeys = AccountKeys(
        ultimateKeys: ultimateKeys!,
        deviceKeys: deviceKeys!,
        symmetricDataKey: 'test-key',
        recoveryBlob: 'test-recovery',
        deviceBlob: 'test-device',
      );

      expect(accountKeys.ultimateKeys.signing, isNotNull);
      expect(accountKeys.ultimateKeys.encryption, isNotNull);
      expect(accountKeys.deviceKeys.signing, isNotNull);
      expect(accountKeys.deviceKeys.encryption, isNotNull);
    });

    test('key duos have private keys available', () {
      if (!_webcryptoAvailable) {
        markTestSkipped('webcrypto native library not available');
        return;
      }
      final accountKeys = AccountKeys(
        ultimateKeys: ultimateKeys!,
        deviceKeys: deviceKeys!,
        symmetricDataKey: 'test-key',
        recoveryBlob: 'test-recovery',
        deviceBlob: 'test-device',
      );

      expect(accountKeys.ultimateKeys.signing.hasPrivateKey, isTrue);
      expect(accountKeys.ultimateKeys.encryption.hasPrivateKey, isTrue);
      expect(accountKeys.deviceKeys.signing.hasPrivateKey, isTrue);
      expect(accountKeys.deviceKeys.encryption.hasPrivateKey, isTrue);
    });
  });
}
