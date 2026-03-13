/// Describes why template parsing failed.
enum ParsingFailure {
  missingField,
  invalidValue,
  invalidCombination,
  colorPalette,
  colorMapping,
  generic,
}

/// Exception thrown when AI template JSON parsing fails.
///
/// This exception provides detailed information about parsing failures
/// to help with debugging and error reporting.
class TemplateParsingException implements Exception {
  /// The error message describing what went wrong
  final String message;

  /// The original exception that caused the parsing failure (if any)
  final Object? originalException;

  /// The stack trace from the original exception (if any)
  final StackTrace? stackTrace;

  /// The JSON path where the error occurred (if applicable)
  final String? jsonPath;

  /// The category of parsing failure
  final ParsingFailure kind;

  const TemplateParsingException(
    this.message, {
    this.originalException,
    this.stackTrace,
    this.jsonPath,
    this.kind = ParsingFailure.generic,
  });

  /// Creates a parsing exception for missing required fields
  factory TemplateParsingException.missingField(String fieldName, {String? jsonPath}) {
    return TemplateParsingException(
      'Missing required field: $fieldName',
      jsonPath: jsonPath,
      kind: ParsingFailure.missingField,
    );
  }

  /// Creates a parsing exception for invalid field values
  factory TemplateParsingException.invalidField(String fieldName, dynamic value, {String? jsonPath}) {
    return TemplateParsingException(
      'Invalid value for field $fieldName: $value',
      jsonPath: jsonPath,
      kind: ParsingFailure.invalidValue,
    );
  }

  /// Creates a parsing exception for invalid field combinations
  factory TemplateParsingException.invalidCombination(String fieldType, String uiElement) {
    return TemplateParsingException(
      'Invalid field-widget combination: $fieldType with $uiElement',
      kind: ParsingFailure.invalidCombination,
    );
  }

  /// Creates a parsing exception for color palette issues
  factory TemplateParsingException.colorPalette(String reason) {
    return TemplateParsingException(
      'Color palette error: $reason',
      kind: ParsingFailure.colorPalette,
    );
  }

  /// Creates a parsing exception for color mapping issues
  factory TemplateParsingException.colorMapping(String uiElement, String reason) {
    return TemplateParsingException(
      'Color mapping error for $uiElement: $reason',
      kind: ParsingFailure.colorMapping,
    );
  }

  @override
  String toString() {
    final buffer = StringBuffer('TemplateParsingException: $message');

    if (jsonPath != null) {
      buffer.write(' (at $jsonPath)');
    }

    if (originalException != null) {
      buffer.write('\nCaused by: $originalException');
    }

    return buffer.toString();
  }
}
