import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:quanitya_flutter/infrastructure/user_feedback/feedback_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/user_feedback/exceptions/feedback_exceptions.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

@GenerateMocks([Client, PublicSubmissionService])
import 'feedback_submission_service_test.mocks.dart';

void main() {
  late FeedbackSubmissionService service;
  late MockClient mockClient;
  late MockPublicSubmissionService mockSubmissionService;

  setUp(() {
    mockClient = MockClient();
    mockSubmissionService = MockPublicSubmissionService();

    service = FeedbackSubmissionService(mockClient, mockSubmissionService);
  });

  group('FeedbackSubmissionService', () {
    test('submitFeedback succeeds with valid input', () async {
      // Arrange
      const feedbackText = 'This is a valid feedback message with enough characters';
      const feedbackType = 'general';

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {});

      // Act - completes without throwing means success
      await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
      );

      // Assert
      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'feedback',
        payload: 'general:$feedbackText',
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });

    test('validates text length (min 10 chars)', () async {
      // Arrange
      const feedbackText = 'Too short'; // 9 characters
      const feedbackType = 'general';

      // Act & Assert
      expect(
        () => service.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        ),
        throwsA(isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          contains('at least 10 characters'),
        )),
      );

      verifyNever(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      ));
    });

    test('validates text length (max 5000 chars)', () async {
      // Arrange
      final feedbackText = 'a' * 5001; // 5001 characters
      const feedbackType = 'general';

      // Act & Assert
      expect(
        () => service.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        ),
        throwsA(isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          contains('less than 5000 characters'),
        )),
      );

      verifyNever(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      ));
    });

    test('accepts all valid feedback types', () async {
      for (final feedbackType in ['feature_request', 'bug', 'general']) {
        reset(mockSubmissionService);
        const feedbackText = 'This is valid feedback with enough characters';

        when(mockSubmissionService.submitWithVerification(
          endpoint: anyNamed('endpoint'),
          payload: anyNamed('payload'),
          submitCallback: anyNamed('submitCallback'),
        )).thenAnswer((_) async {});

        await service.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        );

        verify(mockSubmissionService.submitWithVerification(
          endpoint: 'feedback',
          payload: '$feedbackType:$feedbackText',
          submitCallback: anyNamed('submitCallback'),
        )).called(1);
      }
    });

    test('throws exception for invalid type', () async {
      // Arrange
      const feedbackText = 'This is feedback with invalid type';
      const feedbackType = 'invalid_type';

      // Act & Assert
      expect(
        () => service.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        ),
        throwsA(isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          contains('Invalid feedback type'),
        )),
      );

      verifyNever(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      ));
    });

    test('handles server errors gracefully', () async {
      // Arrange
      const feedbackText = 'This is a valid feedback message';
      const feedbackType = 'general';

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenThrow(Exception('Server error occurred'));

      // Act & Assert
      expect(
        () => service.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        ),
        throwsA(isA<FeedbackException>()),
      );

      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'feedback',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });

    test('includes metadata when provided', () async {
      // Arrange
      const feedbackText = 'This is feedback with metadata';
      const feedbackType = 'bug';
      const metadata = '{"version": "1.0.0", "platform": "iOS"}';

      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {});

      // Act
      await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
        metadata: metadata,
      );

      // Assert
      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'feedback',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });
  });
}
