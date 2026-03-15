import 'purchase_models.dart' show PurchaseStatus;

/// Exception for purchase-related errors.
class PurchaseException implements Exception {
  const PurchaseException(this.message, [this.cause, this.status]);
  final String message;
  final Object? cause;
  final PurchaseStatus? status;

  @override
  String toString() => 'PurchaseException: $message';
}
