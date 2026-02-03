/// Exception thrown when local device authentication operations fail.
class DeviceAuthException implements Exception {
  const DeviceAuthException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DeviceAuthException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
