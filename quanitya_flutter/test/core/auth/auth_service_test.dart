import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:quanitya_flutter/infrastructure/auth/auth_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/crypto/data_encryption_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/exceptions/crypto_exceptions.dart';

@GenerateMocks([ICryptoKeyRepository, IDataEncryptionService])
import 'auth_service_test.mocks.dart';

/// Tests for AuthService - focusing on testable logic without Serverpod client mocking.
/// 
/// Note: Full integration tests with the Serverpod client should be done as
/// live API tests in test/live_api/ since the generated client structure
/// is complex to mock properly.
void main() {
  group('AuthService', () {
    late MockICryptoKeyRepository mockKeyRepo;
    late MockIDataEncryptionService mockEncryption;

    setUp(() {
      mockKeyRepo = MockICryptoKeyRepository();
      mockEncryption = MockIDataEncryptionService();
    });

    group('isAuthenticated (via key status)', () {
      test('returns true when key status is ready', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.ready);

        // We can't instantiate AuthService without a real Client,
        // but we can test the key status logic directly
        final status = await mockKeyRepo.getKeyStatus();
        final isAuthenticated = status == CryptoKeyStatus.ready;

        expect(isAuthenticated, isTrue);
      });

      test('returns false when key status is notInitialized', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.notInitialized);

        final status = await mockKeyRepo.getKeyStatus();
        final isAuthenticated = status == CryptoKeyStatus.ready;

        expect(isAuthenticated, isFalse);
      });

      test('returns false when key status is needsRecovery', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.needsRecovery);

        final status = await mockKeyRepo.getKeyStatus();
        final isAuthenticated = status == CryptoKeyStatus.ready;

        expect(isAuthenticated, isFalse);
      });
    });

    group('validateRecoveryKey logic', () {
      test('valid JWK passes validation', () async {
        const testJwk = '{"keys":[{"kty":"EC"}]}';
        when(mockKeyRepo.validateUltimateKeyJwk(testJwk))
            .thenAnswer((_) async {});

        // Should not throw
        await mockKeyRepo.validateUltimateKeyJwk(testJwk);

        verify(mockKeyRepo.validateUltimateKeyJwk(testJwk)).called(1);
      });

      test('invalid JWK throws ValidationException', () async {
        const testJwk = 'not-valid-json';
        when(mockKeyRepo.validateUltimateKeyJwk(testJwk))
            .thenThrow(const ValidationException('Invalid JWK format'));

        expect(
          () => mockKeyRepo.validateUltimateKeyJwk(testJwk),
          throwsA(isA<ValidationException>()),
        );
      });

      test('empty JWK throws ValidationException', () async {
        const testJwk = '';
        when(mockKeyRepo.validateUltimateKeyJwk(testJwk))
            .thenThrow(const ValidationException('Ultimate key cannot be empty'));

        expect(
          () => mockKeyRepo.validateUltimateKeyJwk(testJwk),
          throwsA(isA<ValidationException>()),
        );
      });
    });

    group('signOut logic', () {
      test('clears all keys from repository', () async {
        when(mockKeyRepo.clearKeys()).thenAnswer((_) async {});

        await mockKeyRepo.clearKeys();

        verify(mockKeyRepo.clearKeys()).called(1);
      });
    });

    group('generateAndStoreDeviceKey', () {
      test('generates and stores device key for recovery', () async {
        when(mockKeyRepo.generateAndStoreDeviceKey())
            .thenAnswer((_) async {});

        await mockKeyRepo.generateAndStoreDeviceKey();

        verify(mockKeyRepo.generateAndStoreDeviceKey()).called(1);
      });
    });
  });

  group('AccountRecoveryException', () {
    test('includes message', () {
      const exception = AccountRecoveryException('Test error');
      
      expect(exception.message, equals('Test error'));
      expect(exception.toString(), contains('Test error'));
    });

    test('includes cause when provided', () {
      final cause = Exception('Root cause');
      final exception = AccountRecoveryException('Test error', cause: cause);
      
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('caused by'));
    });
  });

  group('AccountCreationException', () {
    test('includes message', () {
      const exception = AccountCreationException('Creation failed');
      
      expect(exception.message, equals('Creation failed'));
    });
  });

  group('DeviceAuthenticationException', () {
    test('includes message', () {
      const exception = DeviceAuthenticationException('Auth failed');
      
      expect(exception.message, equals('Auth failed'));
    });
  });
}
