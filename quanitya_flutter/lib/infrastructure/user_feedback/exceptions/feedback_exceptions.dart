/// Base exception for feedback operations.
class FeedbackException implements Exception {
  final String message;
  
  const FeedbackException(this.message);
  
  @override
  String toString() => 'FeedbackException: $message';
}
