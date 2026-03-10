import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../public_submission/public_submission_service.dart';
import '../core/try_operation.dart';
import 'models/feedback_submission.dart';
import 'exceptions/feedback_exceptions.dart';

/// Service for submitting user feedback to the server.
@lazySingleton
class FeedbackSubmissionService {
  final Client _client;
  final PublicSubmissionService _submissionService;
  
  FeedbackSubmissionService(
    this._client,
    this._submissionService,
  );
  
  /// Submit feedback to server.
  ///
  /// Parameters:
  /// - [feedbackText]: User's feedback (10-5000 characters)
  /// - [feedbackType]: Type of feedback ('feature_request', 'bug', 'general')
  /// - [metadata]: Optional JSON metadata
  ///
  /// Returns: FeedbackSubmission with server response
  ///
  /// Throws: FeedbackException on failure
  Future<FeedbackSubmission> submitFeedback({
    required String feedbackText,
    required String feedbackType,
    String? metadata,
  }) {
    return tryMethod(
      () async {
        // Validate input
        _validateFeedback(feedbackText, feedbackType);
        
        // Build payload for signing
        // Format: "challenge:feedbackType:feedbackText"
        final payloadSuffix = '$feedbackType:$feedbackText';
        
        // Submit via PublicSubmissionService
        final response = await _submissionService.submitWithVerification(
          endpoint: 'feedback',
          payload: payloadSuffix,
          submitCallback: (challenge, proofOfWork, publicKeyHex, signature) async {
            return await _client.feedback.submitFeedback(
              challenge: challenge,
              proofOfWork: proofOfWork,
              publicKeyHex: publicKeyHex,
              signature: signature,
              feedbackText: feedbackText,
              feedbackType: feedbackType,
              metadata: metadata,
            );
          },
        );
        
        if (!response.success) {
          throw FeedbackException('Failed to submit feedback: ${response.message}');
        }
        
        return FeedbackSubmission(
          feedbackId: response.data?['feedbackId'] as int,
          timestamp: DateTime.parse(response.data?['timestamp'] as String),
          feedbackText: feedbackText,
          feedbackType: feedbackType,
        );
      },
      (message, [cause]) => FeedbackException(message),
      'submitFeedback',
    );
  }
  
  /// Validate feedback input.
  void _validateFeedback(String text, String type) {
    // Validate text length
    if (text.length < 10) {
      throw FeedbackException('Feedback must be at least 10 characters');
    }
    if (text.length > 5000) {
      throw FeedbackException('Feedback must be less than 5000 characters');
    }
    
    // Validate type
    const validTypes = ['feature_request', 'bug', 'general'];
    if (!validTypes.contains(type)) {
      throw FeedbackException('Invalid feedback type: $type');
    }
  }
}
