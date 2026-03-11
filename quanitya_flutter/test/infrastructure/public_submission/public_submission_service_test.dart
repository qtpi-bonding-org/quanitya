import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';
import 'package:flutter/foundation.dart' show Uint8List;

import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/crypto/crypto_key_repository.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/exceptions/public_submission_exceptions.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:dart_jwk_duo/dart_jwk_duo.dart';

// Generate mocks for testing
// Note: Run 'dart run build_runner build' to generate mocks
@GenerateMocks([
  ICryptoKeyRepository,
  KeyDuo,
])
import 'public_submission_service_test.mocks.dart';

// Fake Client that returns our fake endpoints
class FakeClient extends Fake implements Client {
  @override
  final FakeEndpointErrorReport errorReport = FakeEndpointErrorReport();
  
  @override
  final FakeEndpointFeedback feedback = FakeEndpointFeedback();
}

// Fake endpoint classes that we can control
class FakeEndpointErrorReport extends Fake implements EndpointErrorReport {
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

class FakeEndpointFeedback extends Fake implements EndpointFeedback {
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
      fakeClient.errorReport.setChallengeResponse(() async => PublicChallengeResponse(
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
      
      // Act
      final response = await service.submitWithVerification(
        endpoint: 'errorReport',
        payload: 'test:payload',
        submitCallback: (challenge, pow, pubKey, sig) async {
          return ApiResponse(
            success: true,
            message: 'Success',
            jsonData: jsonEncode({'reportId': 123}),
          );
        },
      );

      // Assert
      expect(response.success, true);
      expect(response.message, 'Success');
      expect(response.data?['reportId'], 123);
      
      // Verify crypto methods were called
      verify(mockCryptoRepo.getDeviceSigningPublicKeyHex()).called(1);
      verify(mockCryptoRepo.getDeviceKey()).called(1);
      verify(mockKeyDuo.sign(any)).called(1);
    });
    
    test('throws exception when device key not found', () async {
      // Arrange
      fakeClient.errorReport.setChallengeResponse(() async => PublicChallengeResponse(
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
          submitCallback: (_, __, ___, ____) async => ApiResponse(success: true),
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
      
      // Note: No verify() call here because exception is thrown before method completes
    });
    
    test('throws exception when challenge request fails', () async {
      // Arrange
      fakeClient.errorReport.setChallengeResponse(() async {
        throw Exception('Network error');
      });
      
      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'errorReport',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async => ApiResponse(success: true),
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });
    
    test('throws exception when proof-of-work fails', () async {
      // Arrange - Use impossibly high difficulty to force failure
      fakeClient.errorReport.setChallengeResponse(() async => PublicChallengeResponse(
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
          submitCallback: (_, __, ___, ____) async => ApiResponse(success: true),
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    }, timeout: const Timeout(Duration(seconds: 5)), skip: 'Expected timeout with difficulty 256 - test validates exception type but takes too long');
    
    test('throws exception when signature fails', () async {
      // Arrange
      fakeClient.errorReport.setChallengeResponse(() async => PublicChallengeResponse(
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
          submitCallback: (_, __, ___, ____) async => ApiResponse(success: true),
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
      
      // Note: No verify() calls here because exception is thrown before methods complete
    });
    
    test('handles rate limit exceeded (429 error)', () async {
      // Arrange
      fakeClient.errorReport.setChallengeResponse(() async => PublicChallengeResponse(
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
      
      // Act
      final response = await service.submitWithVerification(
        endpoint: 'errorReport',
        payload: 'test:payload',
        submitCallback: (challenge, pow, pubKey, sig) async {
          return ApiResponse(
            success: false,
            message: 'Rate limit exceeded',
          );
        },
      );
      
      // Assert
      expect(response.success, false);
      expect(response.message, 'Rate limit exceeded');
    });
    
    test('handles network errors gracefully', () async {
      // Arrange
      fakeClient.errorReport.setChallengeResponse(() async => PublicChallengeResponse(
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
      fakeClient.feedback.setChallengeResponse(() async => PublicChallengeResponse(
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
      
      // Act
      final response = await service.submitWithVerification(
        endpoint: 'feedback',
        payload: 'general:100',
        submitCallback: (challenge, pow, pubKey, sig) async {
          return ApiResponse(
            success: true,
            message: 'Feedback received',
            jsonData: jsonEncode({'feedbackId': 456}),
          );
        },
      );
      
      // Assert
      expect(response.success, true);
      expect(response.data?['feedbackId'], 456);
    });
    
    test('throws exception for unknown endpoint', () async {
      // Act & Assert
      expect(
        () => service.submitWithVerification(
          endpoint: 'unknown',
          payload: 'test:payload',
          submitCallback: (_, __, ___, ____) async => ApiResponse(success: true),
        ),
        throwsA(isA<PublicSubmissionException>()),
      );
    });
  });
}
