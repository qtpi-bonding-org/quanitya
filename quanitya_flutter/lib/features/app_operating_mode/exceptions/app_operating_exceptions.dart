/// Exception for app operating mode issues
class AppOperatingException implements Exception {
  final String message;
  final Object? cause;
  
  const AppOperatingException(this.message, [this.cause]);
  
  @override
  String toString() => 'AppOperatingException: $message';
}

/// Exception for network issues  
class NetworkException implements Exception {
  final String message;
  final Object? cause;
  
  const NetworkException(this.message, [this.cause]);
  
  @override
  String toString() => 'NetworkException: $message';
}