import '../../llm/models/gbnf_field.dart';

/// Coerces string values to target types for import pipelines.
///
/// Shared utility used by both ColumnMapper (CSV/general) and
/// TemplateExtractionSchemaBuilder (OCR/LLM). Pure static.
class ValueCoercer {
  ValueCoercer._();

  /// Coerces a string value to the target type.
  /// Returns the original value if coercion fails.
  /// Normalizes whitespace-only strings to empty string.
  static dynamic coerce(dynamic value, GbnfFieldType targetType) {
    if (value is! String) return value;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;

    final numericStr = stripCurrencyPrefix(trimmed);

    return switch (targetType) {
      GbnfFieldType.integer => int.tryParse(numericStr) ?? value,
      GbnfFieldType.number => double.tryParse(numericStr) ?? value,
      GbnfFieldType.boolean => switch (trimmed.toLowerCase()) {
          'true' => true,
          'false' => false,
          _ => value,
        },
      GbnfFieldType.string || GbnfFieldType.enumerated => value,
    };
  }

  /// Strips leading currency symbols for numeric parsing.
  static String stripCurrencyPrefix(String s) {
    if (s.isEmpty) return s;
    const prefixes = ['\$', '€', '£', '¥', '₹'];
    for (final prefix in prefixes) {
      if (s.startsWith(prefix)) return s.substring(prefix.length).trim();
    }
    return s;
  }
}
