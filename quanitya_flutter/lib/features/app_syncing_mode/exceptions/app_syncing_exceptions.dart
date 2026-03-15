/// Exception for app syncing mode issues
class AppSyncingException implements Exception {
  final String message;
  final Object? cause;

  const AppSyncingException(this.message, [this.cause]);

  @override
  String toString() => 'AppSyncingException: $message';
}

/// Typedef for backward compatibility
typedef AppOperatingException = AppSyncingException;

/// Exception for network issues
class NetworkException implements Exception {
  final String message;
  final Object? cause;

  const NetworkException(this.message, [this.cause]);

  @override
  String toString() => 'NetworkException: $message';
}
