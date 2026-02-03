/// Exception thrown when JSON schema validation fails for data ingestion.
///
/// Contains a map of item identifiers to their validation errors,
/// allowing batch validation with detailed error reporting.
///
/// Example:
/// ```dart
/// throw ValidationException({
///   'item-1': ['Missing required field: value'],
///   'item-2': ['Invalid type for field: timestamp'],
/// });
/// ```
class ValidationException implements Exception {
  /// Map of item identifiers to their validation error messages.
  ///
  /// Keys are typically item IDs or indices from the source data.
  /// Values are lists of error strings for that item.
  final Map<String, List<String>> errors;

  ValidationException(this.errors);

  /// Creates a ValidationException from a flat list of errors.
  ///
  /// Useful when validating a single item or when item IDs aren't relevant.
  factory ValidationException.fromList(List<String> errorList) {
    return ValidationException({'_': errorList});
  }

  /// Total number of validation errors across all items.
  int get errorCount => errors.values.fold(0, (sum, list) => sum + list.length);

  /// Whether there are any validation errors.
  bool get hasErrors => errors.isNotEmpty;

  /// Flattened list of all error messages.
  List<String> get allErrors => errors.values.expand((e) => e).toList();

  @override
  String toString() {
    if (errors.isEmpty) return 'ValidationException: No errors';
    
    final buffer = StringBuffer('ValidationException: $errorCount error(s)\n');
    for (final entry in errors.entries) {
      for (final error in entry.value) {
        buffer.writeln('  [${entry.key}] $error');
      }
    }
    return buffer.toString().trimRight();
  }
}
