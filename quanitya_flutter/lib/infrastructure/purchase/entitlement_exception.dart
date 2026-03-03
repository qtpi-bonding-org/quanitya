/// Exception for entitlement-related errors.
class EntitlementException implements Exception {
  const EntitlementException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'EntitlementException: $message';
}
