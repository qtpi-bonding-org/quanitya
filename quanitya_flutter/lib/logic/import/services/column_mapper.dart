import '../../ocr/models/extraction_field.dart';
import 'value_coercer.dart';

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
        mapped[fieldId] = type != null ? ValueCoercer.coerce(entry.value, type) : entry.value;
      }
      return mapped;
    }).toList();
  }
}
