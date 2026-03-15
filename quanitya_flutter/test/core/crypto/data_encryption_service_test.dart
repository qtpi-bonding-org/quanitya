import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:webcrypto/webcrypto.dart';
import 'package:quanitya_flutter/infrastructure/crypto/data_encryption_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/crypto/exceptions/crypto_exceptions.dart';
import 'package:faker/faker.dart';

// Generate mocks
@GenerateMocks([ICryptoKeyRepository])
import 'data_encryption_service_test.mocks.dart';

/// Whether webcrypto native symbols are available in this test environment.
bool _webcryptoAvailable = true;

/// Returns true if webcrypto is NOT available (test should return early).
bool _skipIfNoWebcrypto() {
  if (!_webcryptoAvailable) {
    markTestSkipped('webcrypto native library not available');
    return true;
  }
  return false;
}

void main() {
  const int testIterations = 5;

  group('DataEncryptionService', () {
    late DataEncryptionService dataEncryptionService;
    late MockICryptoKeyRepository mockKeyRepository;
    late Faker faker;
    AesGcmSecretKey? testSymmetricKey;

    setUpAll(() async {
      try {
        await AesGcmSecretKey.generateKey(256);
      } on UnsupportedError {
        _webcryptoAvailable = false;
      }
    });

    setUp(() async {
      mockKeyRepository = MockICryptoKeyRepository();
      dataEncryptionService = DataEncryptionService(mockKeyRepository);
      faker = Faker();

      if (_webcryptoAvailable) {
        testSymmetricKey = await AesGcmSecretKey.generateKey(256);
      }
    });

    group('isKeyProvisioned', () {
      test('returns true when symmetric key exists', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => testSymmetricKey);

        final result = await dataEncryptionService.isKeyProvisioned();

        expect(result, isTrue);
        verify(mockKeyRepository.getSymmetricDataKey()).called(1);
      });

      test('returns false when symmetric key is null', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => null);

        final result = await dataEncryptionService.isKeyProvisioned();

        expect(result, isFalse);
      });
    });

    group('Symmetric Encryption (AES-GCM)', () {
      test('encryptData throws CryptoOperationException when no key', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => null);

        expect(
          () => dataEncryptionService.encryptData('test'),
          throwsA(isA<CryptoOperationException>()),
        );
      });

      test('decryptData throws CryptoOperationException when no key', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => null);

        expect(
          () => dataEncryptionService.decryptData(Uint8List(20)),
          throwsA(isA<CryptoOperationException>()),
        );
      });

      test('decryptData throws CryptoOperationException for ciphertext too short', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => testSymmetricKey);

        expect(
          () => dataEncryptionService.decryptData(Uint8List(5)),
          throwsA(isA<CryptoOperationException>()),
        );
      });

      test('encrypt then decrypt returns original plaintext', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => testSymmetricKey);

        const plaintext = 'Hello, World!';
        final encrypted = await dataEncryptionService.encryptData(plaintext);
        final decrypted = await dataEncryptionService.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('encrypted data is different from plaintext', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => testSymmetricKey);

        const plaintext = 'Test message';
        final encrypted = await dataEncryptionService.encryptData(plaintext);

        expect(encrypted, isNot(equals(utf8.encode(plaintext))));
        expect(encrypted.length, greaterThan(12)); // IV + ciphertext + auth tag
      });

      test('empty string encrypts and decrypts correctly', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => testSymmetricKey);

        const plaintext = '';
        final encrypted = await dataEncryptionService.encryptData(plaintext);
        final decrypted = await dataEncryptionService.decryptData(encrypted);

        expect(decrypted, equals(plaintext));
      });

      test('Property: AES-GCM round trip preserves data', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getSymmetricDataKey())
            .thenAnswer((_) async => testSymmetricKey);

        for (int i = 0; i < testIterations; i++) {
          String plaintext;

          switch (i % 5) {
            case 0:
              plaintext = faker.lorem.sentence();
              break;
            case 1:
              plaintext = '🚀 Unicode: 中文 العربية';
              break;
            case 2:
              plaintext = jsonEncode({'id': faker.guid.guid(), 'name': faker.person.name()});
              break;
            case 3:
              plaintext = 'a' * 1000; // Long string
              break;
            case 4:
              plaintext = 'Special: !@#\$%^&*()';
              break;
            default:
              plaintext = 'test';
          }

          final encrypted = await dataEncryptionService.encryptData(plaintext);
          final decrypted = await dataEncryptionService.decryptData(encrypted);

          expect(decrypted, equals(plaintext),
            reason: 'Round trip should preserve data (iteration $i)');
        }
      });
    });

    group('Device Key Operations', () {
      test('signWithDeviceKey throws CryptoOperationException when no key', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getDeviceKey())
            .thenAnswer((_) async => null);

        expect(
          () => dataEncryptionService.signWithDeviceKey('challenge'),
          throwsA(isA<CryptoOperationException>()),
        );
      });

      test('encryptWithDeviceKey throws CryptoOperationException when no key', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getDeviceKey())
            .thenAnswer((_) async => null);

        expect(
          () => dataEncryptionService.encryptWithDeviceKey(Uint8List(10)),
          throwsA(isA<CryptoOperationException>()),
        );
      });

      test('decryptWithDeviceKey throws CryptoOperationException when no key', () async {
        if (_skipIfNoWebcrypto()) return;
        when(mockKeyRepository.getDeviceKey())
            .thenAnswer((_) async => null);

        expect(
          () => dataEncryptionService.decryptWithDeviceKey(Uint8List(10)),
          throwsA(isA<CryptoOperationException>()),
        );
      });
    });
  });
}
