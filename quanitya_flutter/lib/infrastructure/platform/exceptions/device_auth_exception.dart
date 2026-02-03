/// Exception thrown when device authentication operations fail.
class DeviceAuthException implements Exception {
  final String message;
  final Object? cause;

  const DeviceAuthException(this.message, [this.cause]);

  @override
  String toString() {
    return 'DeviceAuthException: $message';
  }
}