import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:mockito/annotations.dart';

import 'package:quanitya_flutter/infrastructure/user_feedback/feedback_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/user_feedback/exceptions/feedback_exceptions.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/public_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/public_submission/models/submission_response.dart';
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
      )).thenAnswer((_) async {
        return const SubmissionResponse(
          success: true,
          message: 'Feedback received',
          data: {
            'feedbackId': 123,
            'timestamp': '2024-01-15T10:30:00.000Z',
          },
        );
      });
      
      // Act
      final result = await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
      );
      
      // Assert
      expect(result.feedbackId, 123);
      expect(result.feedbackText, feedbackText);
      expect(result.feedbackType, feedbackType);
      expect(result.timestamp, isA<DateTime>());
      
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
    
    test('validates feedback type (feature_request)', () async {
      // Arrange
      const feedbackText = 'This is a feature request with enough characters';
      const feedbackType = 'feature_request';
      
      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {
        return const SubmissionResponse(
          success: true,
          message: 'Feedback received',
          data: {
            'feedbackId': 124,
            'timestamp': '2024-01-15T10:30:00.000Z',
          },
        );
      });
      
      // Act
      final result = await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
      );
      
      // Assert
      expect(result.feedbackType, 'feature_request');
      
      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'feedback',
        payload: 'feature_request:$feedbackText',
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });
    
    test('validates feedback type (bug)', () async {
      // Arrange
      const feedbackText = 'This is a bug report with enough characters';
      const feedbackType = 'bug';
      
      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {
        return const SubmissionResponse(
          success: true,
          message: 'Feedback received',
          data: {
            'feedbackId': 125,
            'timestamp': '2024-01-15T10:30:00.000Z',
          },
        );
      });
      
      // Act
      final result = await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
      );
      
      // Assert
      expect(result.feedbackType, 'bug');
      
      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'feedback',
        payload: 'bug:$feedbackText',
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });
    
    test('validates feedback type (general)', () async {
      // Arrange
      const feedbackText = 'This is general feedback with enough characters';
      const feedbackType = 'general';
      
      when(mockSubmissionService.submitWithVerification(
        endpoint: anyNamed('endpoint'),
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).thenAnswer((_) async {
        return const SubmissionResponse(
          success: true,
          message: 'Feedback received',
          data: {
            'feedbackId': 126,
            'timestamp': '2024-01-15T10:30:00.000Z',
          },
        );
      });
      
      // Act
      final result = await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
      );
      
      // Assert
      expect(result.feedbackType, 'general');
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
      )).thenAnswer((_) async {
        return const SubmissionResponse(
          success: false,
          message: 'Server error occurred',
          data: null,
        );
      });
      
      // Act & Assert
      expect(
        () => service.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        ),
        throwsA(isA<FeedbackException>().having(
          (e) => e.message,
          'message',
          contains('Failed to submit feedback'),
        )),
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
      )).thenAnswer((_) async {
        return const SubmissionResponse(
          success: true,
          message: 'Feedback received',
          data: {
            'feedbackId': 127,
            'timestamp': '2024-01-15T10:30:00.000Z',
          },
        );
      });
      
      // Act
      final result = await service.submitFeedback(
        feedbackText: feedbackText,
        feedbackType: feedbackType,
        metadata: metadata,
      );
      
      // Assert
      expect(result.feedbackId, 127);
      
      verify(mockSubmissionService.submitWithVerification(
        endpoint: 'feedback',
        payload: anyNamed('payload'),
        submitCallback: anyNamed('submitCallback'),
      )).called(1);
    });
  });
}
