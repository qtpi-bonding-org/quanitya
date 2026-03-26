import '../../llm/models/gbnf_field.dart';
import '../../ocr/models/extraction_field.dart';

/// Maps source columns to template field IDs and coerces string values.
/// Source-agnostic: works with any column mapping. Pure static utility.
class ColumnMapper {
  ColumnMapper._();

  /// Applies column mapping and type coercion to raw items.
  ///
  /// [items] — raw label-keyed data from any source.
  /// [columnMapping] — maps source column names to template field IDs.
  /// [extractionFields] — field definitions for type coercion.
  ///
  /// Returns fieldId-keyed items with coerced values. Unmapped columns dropped.
  static List<Map<String, dynamic>> mapAndCoerce({
    required List<Map<String, dynamic>> items,
    required Map<String, String> columnMapping,
    required List<ExtractionField> extractionFields,
  }) {
    if (items.isEmpty) return [];
    final fieldTypes = {for (final f in extractionFields) f.fieldId: f.type};

    return items.map((item) {
      final mapped = <String, dynamic>{};
      for (final entry in item.entries) {
        final fieldId = columnMapping[entry.key];
        if (fieldId == null) continue;
        final type = fieldTypes[fieldId];
        mapped[fieldId] = type != null ? _coerceValue(entry.value, type) : entry.value;
      }
      return mapped;
    }).toList();
  }

  static dynamic _coerceValue(dynamic value, GbnfFieldType targetType) {
    if (value is! String) return value;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return trimmed;
    final numericStr = _stripCurrencyPrefix(trimmed);

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

  static String _stripCurrencyPrefix(String s) {
    if (s.isEmpty) return s;
    const prefixes = ['\$', '€', '£', '¥', '₹'];
    for (final prefix in prefixes) {
      if (s.startsWith(prefix)) return s.substring(prefix.length).trim();
    }
    return s;
  }
}
