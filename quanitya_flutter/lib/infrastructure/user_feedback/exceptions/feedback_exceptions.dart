/// Describes why a feedback operation failed.
enum FeedbackFailure {
  tooShort,
  tooLong,
  invalidType,
  submissionFailed,
}

/// Base exception for feedback operations.
class FeedbackException implements Exception {
  final String message;
  final FeedbackFailure kind;

  const FeedbackException(this.message, {this.kind = FeedbackFailure.submissionFailed});

  @override
  String toString() => 'FeedbackException: $message';
}
