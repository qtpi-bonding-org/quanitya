/// Exception for webhook-related errors
class WebhookException implements Exception {
  final String message;
  final Object? cause;

  const WebhookException(this.message, [this.cause]);

  @override
  String toString() => 'WebhookException: $message${cause != null ? ' ($cause)' : ''}';
}

/// Exception for API key-related errors
class ApiKeyException implements Exception {
  final String message;
  final Object? cause;

  const ApiKeyException(this.message, [this.cause]);

  @override
  String toString() => 'ApiKeyException: $message${cause != null ? ' ($cause)' : ''}';
}
