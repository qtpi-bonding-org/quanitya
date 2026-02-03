/// Exception thrown when data ingestion fails for reasons other than validation.
///
/// Wraps underlying errors with context about the ingestion operation.
/// Integrates with cubit_ui_flow for automatic error handling in UI.
///
/// Example:
/// ```dart
/// try {
///   await repository.bulkInsert(entries);
/// } catch (e) {
///   throw IngestionException('Failed to persist entries', e);
/// }
/// ```
class IngestionException implements Exception {
  /// Human-readable description of what went wrong.
  final String message;

  /// The underlying error that caused this exception, if any.
  final Object? cause;

  IngestionException(this.message, [this.cause]);

  @override
  String toString() {
    if (cause != null) {
      return 'IngestionException: $message\nCaused by: $cause';
    }
    return 'IngestionException: $message';
  }
}
