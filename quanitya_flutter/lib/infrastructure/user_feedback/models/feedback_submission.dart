import 'package:freezed_annotation/freezed_annotation.dart';

part 'feedback_submission.freezed.dart';
part 'feedback_submission.g.dart';

/// Feedback submission result.
@freezed
abstract class FeedbackSubmission with _$FeedbackSubmission {
  const FeedbackSubmission._();
  const factory FeedbackSubmission({
    required int feedbackId,
    required DateTime timestamp,
    required String feedbackText,
    required String feedbackType,
  }) = _FeedbackSubmission;
  
  factory FeedbackSubmission.fromJson(Map<String, dynamic> json) =>
      _$FeedbackSubmissionFromJson(json);
}
