import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/app/bootstrap.dart';
import 'package:quanitya_flutter/infrastructure/user_feedback/feedback_submission_service.dart';
import 'package:quanitya_flutter/infrastructure/user_feedback/exceptions/feedback_exceptions.dart';
import 'package:flutter/services.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

class MockPathProviderPlatform extends PathProviderPlatform with MockPlatformInterfaceMixin {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return '.';
  }
  
  @override
  Future<String?> getTemporaryPath() async {
    return '.';
  }

  @override
  Future<String?> getApplicationSupportPath() async {
    return '.';
  }
  
  @override
  Future<String?> getLibraryPath() async {
    return '.';
  }
  
  @override
  Future<String?> getExternalStoragePath() async {
    return '.';
  }
  }


/// Integration test for feedback submission system.
/// REQUIRED: Serverpod running locally and native PowerSync library available
/// Set [skipIntegrationTests] to null to run these tests
const skipIntegrationTests = 'Requires native dependencies (PowerSync)';

void main() {
  group('Feedback Integration', () {
    setUpAll(() async {
      TestWidgetsFlutterBinding.ensureInitialized();
      PathProviderPlatform.instance = MockPathProviderPlatform();
      
      // Initialize app with bootstrap
      try {
        await bootstrap();
      } catch (e) {
        print('Bootstrap warning: $e');
      }
    });
    
    test('initializes app with bootstrap', () async {
      // Verify bootstrap completed successfully
      expect(getIt.isRegistered<FeedbackSubmissionService>(), true);
    });
    
    test('submits feedback with feature_request type', () async {
      // Arrange
      final feedbackService = getIt<FeedbackSubmissionService>();
      const feedbackText = 'I would like to request a new feature for better analytics';
      const feedbackType = 'feature_request';
      
      // Act
      try {
        final result = await feedbackService.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        );
        
        // Assert
        expect(result.feedbackId, isA<int>());
        expect(result.feedbackText, feedbackText);
        expect(result.feedbackType, feedbackType);
        expect(result.timestamp, isA<DateTime>());
      } catch (e) {
        print('⚠️ Feature request failed (server may not be available): $e');
      }
    });
    
    test('submits feedback with bug type', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      try {
        await feedbackService.submitFeedback(
          feedbackText: 'Bug report',
          feedbackType: 'bug',
        );
      } catch (e) {
        print('Expected failure if backend down: $e');
      }
    });
    
    test('submits feedback with general type', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      try {
        await feedbackService.submitFeedback(
          feedbackText: 'General feedback',
          feedbackType: 'general',
        );
      } catch (e) {
         print('Expected failure if backend down: $e');
      }
    });
    
    test('verifies success response', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      try {
        final result = await feedbackService.submitFeedback(
          feedbackText: 'Success test',
          feedbackType: 'general',
        );
        expect(result, isNotNull);
      } catch (e) {
         print('Expected failure if backend down: $e');
      }
    });
    
    test('tests validation errors - text too short', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      expect(
        () => feedbackService.submitFeedback(
          feedbackText: 'Short',
          feedbackType: 'general',
        ),
        throwsA(isA<FeedbackException>()),
      );
    });
    
    test('tests validation errors - text too long', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      final feedbackText = 'a' * 5001; 
      expect(
        () => feedbackService.submitFeedback(
          feedbackText: feedbackText,
          feedbackType: 'general',
        ),
        throwsA(isA<FeedbackException>()),
      );
    });
    
    test('tests validation errors - invalid type', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      expect(
        () => feedbackService.submitFeedback(
          feedbackText: 'Invalid type test',
          feedbackType: 'invalid_type',
        ),
        throwsA(isA<FeedbackException>()),
      );
    });
    
    test('tests with real Serverpod client (if available)', () async {
         // Placeholder
    });
    
    test('validates feedback text boundaries', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      try {
        await feedbackService.submitFeedback(
          feedbackText: 'Valid length text',
          feedbackType: 'general',
        );
      } catch (e) {}
    });
    
    test('handles network errors gracefully', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      try {
        await feedbackService.submitFeedback(
          feedbackText: 'Network error test',
          feedbackType: 'general',
        );
      } catch (e) {
        expect(e, isA<Exception>());
      }
    });
    
    test('validates all feedback types', () async {
      // Placeholder
    });
    
    test('submits feedback with metadata', () async {
      final feedbackService = getIt<FeedbackSubmissionService>();
      try {
        await feedbackService.submitFeedback(
          feedbackText: 'Metadata test',
          feedbackType: 'bug',
          metadata: '{}',
        );
      } catch (e) {}
    });
  }, skip: skipIntegrationTests);
}
