import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:quanitya_flutter/infrastructure/auth/auth_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/crypto/data_encryption_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/exceptions/crypto_exceptions.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

@GenerateMocks([ICryptoKeyRepository, IDataEncryption])
import 'auth_service_test.mocks.dart';

/// Fake Client that allows constructing AuthService without deep Serverpod mocking.
/// Methods that hit the server (authenticateDevice, etc.) are tested via integration tests.
class _FakeClient extends Fake implements Client {}

void main() {
  group('AuthService', () {
    late AuthService authService;
    late MockICryptoKeyRepository mockKeyRepo;
    late MockIDataEncryption mockEncryption;

    setUp(() {
      mockKeyRepo = MockICryptoKeyRepository();
      mockEncryption = MockIDataEncryption();
      authService = AuthService(mockKeyRepo, mockEncryption, _FakeClient());
    });

    group('isAuthenticated', () {
      test('returns true when key status is ready', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.ready);

        final result = await authService.isAuthenticated();

        expect(result, isTrue);
        verify(mockKeyRepo.getKeyStatus()).called(1);
      });

      test('returns false when key status is notInitialized', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.notInitialized);

        final result = await authService.isAuthenticated();

        expect(result, isFalse);
      });

      test('returns false when key status is needsRecovery', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.needsRecovery);

        final result = await authService.isAuthenticated();

        expect(result, isFalse);
      });

      test('returns false when key status is crossDeviceRecoveryAvailable', () async {
        when(mockKeyRepo.getKeyStatus())
            .thenAnswer((_) async => CryptoKeyStatus.crossDeviceRecoveryAvailable);

        final result = await authService.isAuthenticated();

        expect(result, isFalse);
      });
    });

    group('initialize', () {
      test('completes without error', () async {
        await expectLater(authService.initialize(), completes);
      });

      test('is idempotent', () async {
        await authService.initialize();
        await authService.initialize();
        // No error on second call
      });
    });
  });

  group('AuthException types', () {
    test('AccountRecoveryException includes message and cause', () {
      final cause = Exception('Root cause');
      final exception = AccountRecoveryException('Test error', cause: cause);

      expect(exception.message, equals('Test error'));
      expect(exception.cause, equals(cause));
      expect(exception.toString(), contains('Test error'));
      expect(exception.toString(), contains('caused by'));
    });

    test('AccountCreationException includes message', () {
      const exception = AccountCreationException('Creation failed');

      expect(exception.message, equals('Creation failed'));
    });

    test('DeviceAuthenticationException includes message', () {
      const exception = DeviceAuthenticationException('Auth failed');

      expect(exception.message, equals('Auth failed'));
    });

    test('AuthFailure enum has expected values', () {
      expect(AuthFailure.values, contains(AuthFailure.networkError));
      expect(AuthFailure.values, contains(AuthFailure.general));
    });
  });
}
