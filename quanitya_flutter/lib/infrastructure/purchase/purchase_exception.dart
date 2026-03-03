/// Exception for purchase-related errors.
class PurchaseException implements Exception {
  const PurchaseException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() => 'PurchaseException: $message';
}
