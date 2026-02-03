/// Exception thrown when notification operations fail.
class NotificationException implements Exception {
  const NotificationException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'NotificationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
