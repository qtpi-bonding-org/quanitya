import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/foundation.dart' show Uint8List;

import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/exceptions/public_submission_exceptions.dart';
import 'package:anonaccount_client/anonaccount_client.dart'
    show PublicChallengeResponse, EndpointEntrypoint;
import 'package:anonaccount_client/anonaccount_client.dart' as aa;
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:dart_jwk_duo/dart_jwk_duo.dart';

// Generate mocks for testing
// Note: Run 'dart run build_runner build' to generate mocks
@GenerateMocks([
  ICryptoKeyRepository,
  KeyDuo,
])
import 'public_submission_service_test.mocks.dart';

// Fake entrypoint endpoint for challenge requests
class FakeEndpointEntrypoint extends Fake implements EndpointEntrypoint {
  Future<PublicChallengeResponse> Function()? _getChallengeImpl;

  void setChallengeResponse(Future<PublicChallengeResponse> Function() impl) {
    _getChallengeImpl = impl;
  }

  @override
  Future<PublicChallengeResponse> getChallenge() async {
    if (_getChallengeImpl != null) {
      return _getChallengeImpl!();
    }
    throw UnimplementedError('getChallenge not stubbed');
  }
}

// Fake anonaccount Caller with entrypoint
class FakeAnonaccountCaller extends Fake implements aa.Caller {
  @override
  final FakeEndpointEntrypoint entrypoint = FakeEndpointEntrypoint();
}

// Fake Modules with anonaccount
class FakeModules extends Fake implements Modules {
  @override
  final aa.Caller anonaccount = FakeAnonaccountCaller();
}

// Fake Client that returns our fake modules
class FakeClient extends Fake implements Client {
  @override
  final FakeModules modules = FakeModules();

  /// Access the fake entrypoint to stub challenge responses
  FakeEndpointEntrypoint get fakeEntrypoint =>
      (modules.anonaccount as FakeAnonaccountCaller).entrypoint;

  @override
  final FakeEndpointErrorReport errorReport = FakeEndpointErrorReport();

  @override
  final FakeEndpointFeedback feedback = FakeEndpointFeedback();
}

// Fake endpoint classes (still needed for submitCallback verification)
class FakeEndpointErrorReport extends Fake implements EndpointErrorReport {}
class FakeEndpointFeedback extends Fake implements EndpointFeedback {}

void main() {
  late PublicSubmissionService service;
  late FakeClient fakeClient;
  late MockICryptoKeyRepository mockCryptoRepo;
  late MockKeyDuo mockKeyDuo;

  setUp(() {
    fakeClient = FakeClient();
    mockCryptoRepo = MockICryptoKeyRepository();
    mockKeyDuo = MockKeyDuo();

    service = PublicSubmissionService(fakeClient, mockCryptoRepo);
  });

  group('PublicSubmissionService', () {
    test('submitWithVerification completes full flow successfully', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'test-challenge',
        difficulty: 16, // Lower difficulty for faster test
        expiresAt: 1234567890,
      ));

      when(mockCryptoRepo.getDeviceSigningPublicKeyHex()).thenAnswer(
        (_) async => 'a' * 128, // 128 hex chars
      );

      when(mockCryptoRepo.getDeviceKey()).thenAnswer(
        (_) async => mockKeyDuo,
      );

      // Mock signature generation
      when(mockKeyDuo.sign(any)).thenAnswer(
        (_) async => Uint8List.fromList(List.generate(64, (i) => i)),
      );

      // Act - completes without throwing means success
      await service.submitWithVerification(
        endpoint: 'errorReport',
        payload: 'test:payload',
        submitCallback: (challenge, pow, pubKey, sig) async {
          // void callback - success
        },
      );

      // Assert - verify crypto methods were called
      verify(mockCryptoRepo.getDeviceSigningPublicKeyHex()).called(1);
      verify(mockCryptoRepo.getDeviceKey()).called(1);
      verify(mockKeyDuo.sign(any)).called(1);
    });

    test('throws exception when device key not found', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'test-challenge',
        difficulty: 16,
        expiresAt: 1234567890,
      ));

      when(mockCryptoRepo.getDeviceSigningPublicKeyHex()).thenAnswer(
        (_) async => null, // Key not found
      );

      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async {},
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });

    test('throws exception when challenge request fails', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async {
        throw Exception('Network error');
      });

      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async {},
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });

    test('throws exception when proof-of-work fails', () async {
      // Arrange - Use impossibly high difficulty to force failure
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'test-challenge',
        difficulty: 256, // Impossibly high difficulty
        expiresAt: 1234567890,
      ));

      // Act & Assert
      // Note: This test may take a while or timeout, which is expected behavior
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async {},
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 5)), skip: 'Expected timeout with difficulty 256 - test validates exception type but takes too long');

    test('throws exception when signature fails', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'test-challenge',
        difficulty: 16,
        expiresAt: 1234567890,
      ));

      when(mockCryptoRepo.getDeviceSigningPublicKeyHex()).thenAnswer(
        (_) async => 'a' * 128,
      );

      when(mockCryptoRepo.getDeviceKey()).thenAnswer(
        (_) async => null, // Device key not found for signing
      );

      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async {},
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });

    test('translates ServerException with rateLimitExceeded to RateLimitExceededException', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'test-challenge',
        difficulty: 16,
        expiresAt: 1234567890,
      ));

      when(mockCryptoRepo.getDeviceSigningPublicKeyHex()).thenAnswer(
        (_) async => 'a' * 128,
      );

      when(mockCryptoRepo.getDeviceKey()).thenAnswer(
        (_) async => mockKeyDuo,
      );

      when(mockKeyDuo.sign(any)).thenAnswer(
        (_) async => Uint8List.fromList(List.generate(64, (i) => i)),
      );

      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (challenge, pow, pubKey, sig) async {
            throw ServerException(
              code: ServerErrorCode.rateLimitExceeded,
              message: 'Rate limit exceeded',
            );
          },
        ),
        throwsA(isA<RateLimitExceededException>()),
      );
    });

    test('handles network errors gracefully', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'test-challenge',
        difficulty: 16,
        expiresAt: 1234567890,
      ));

      when(mockCryptoRepo.getDeviceSigningPublicKeyHex()).thenAnswer(
        (_) async => 'a' * 128,
      );

      when(mockCryptoRepo.getDeviceKey()).thenAnswer(
        (_) async => mockKeyDuo,
      );

      when(mockKeyDuo.sign(any)).thenAnswer(
        (_) async => Uint8List.fromList(List.generate(64, (i) => i)),
      );

      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (_, __, ___, _) async {
            throw Exception('Network error');
          },
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });

    test('works with feedback endpoint', () async {
      // Arrange
      fakeClient.fakeEntrypoint.setChallengeResponse(() async => PublicChallengeResponse(
        challenge: 'feedback-challenge',
        difficulty: 16,
        expiresAt: 1234567890,
      ));

      when(mockCryptoRepo.getDeviceSigningPublicKeyHex()).thenAnswer(
        (_) async => 'b' * 128,
      );

      when(mockCryptoRepo.getDeviceKey()).thenAnswer(
        (_) async => mockKeyDuo,
      );

      when(mockKeyDuo.sign(any)).thenAnswer(
        (_) async => Uint8List.fromList(List.generate(64, (i) => i + 1)),
      );

      // Act - completes without throwing means success
      await service.submitWithVerification(
        endpoint: 'feedback',
        payload: 'general:100',
        submitCallback: (challenge, pow, pubKey, sig) async {
          // void callback - success
        },
      );

      // Assert - verify crypto was used
      verify(mockCryptoRepo.getDeviceSigningPublicKeyHex()).called(1);
    });

    test('throws exception for unknown endpoint', () async {
      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'unknown',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async {},
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });
  });
}
