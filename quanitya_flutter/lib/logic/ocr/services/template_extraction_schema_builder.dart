import 'dart:convert';
import '../../llm/models/gbnf_field.dart';
import '../../llm/services/gbnf_grammar_generator.dart';
import '../../templates/enums/field_enum.dart';
import '../../templates/models/shared/template_field.dart';
import '../models/extraction_field.dart';

/// Bridges template fields to GBNF grammar and NuExtract prompts.
///
/// This is the only component that knows both template structure
/// and LLM prompt format. Pure static utility — no state.
class TemplateExtractionSchemaBuilder {
  TemplateExtractionSchemaBuilder._();

  static const _supportedTypes = {
    FieldEnum.text: GbnfFieldType.string,
    FieldEnum.integer: GbnfFieldType.integer,
    FieldEnum.float: GbnfFieldType.number,
    FieldEnum.boolean: GbnfFieldType.boolean,
    FieldEnum.enumerated: GbnfFieldType.enumerated,
  };

  /// Filters template fields to extractable types and converts
  /// to [ExtractionField] objects.
  ///
  /// Skips deleted fields and unsupported types (group, reference,
  /// location, datetime, dimension, multiEnum).
  static List<ExtractionField> buildExtractionFields(
    List<TemplateField> fields,
  ) {
    final result = <ExtractionField>[];
    for (final field in fields) {
      if (field.isDeleted) continue;
      final gbnfType = _supportedTypes[field.type];
      if (gbnfType == null) continue;
      result.add(ExtractionField(
        fieldId: field.id,
        label: field.label,
        type: gbnfType,
        enumValues: field.type == FieldEnum.enumerated ? field.options : null,
      ));
    }
    return result;
  }

  /// Generates a GBNF grammar for the given extraction fields.
  ///
  /// All values are strings in the grammar (NuExtract outputs strings).
  /// Type coercion happens in [remapLabelsToIds].
  static String buildGrammar(List<ExtractionField> fields) {
    return GbnfGrammarGenerator.generate(
      fields: fields.map((f) => f.toGbnfField()).toList(),
      asList: true,
    );
  }

  /// Builds a NuExtract-format prompt for structured extraction.
  ///
  /// Uses the official NuExtract prompt format:
  /// - `### Template:` with indent-4 JSON (all string values)
  /// - Optional `### Example:` sections with filled-in examples
  /// - `### Text:` with the OCR text
  ///
  /// [examples] is an optional list of filled-in template objects
  /// for few-shot extraction. Even one example improves quality.
  static String buildPrompt({
    required String ocrText,
    required List<ExtractionField> fields,
    List<Map<String, String>>? examples,
  }) {
    final buf = StringBuffer();

    // Template: array of objects with empty string values
    final templateObj = <String, String>{};
    for (final field in fields) {
      templateObj[field.label] = '';
    }
    final templateJson = const JsonEncoder.withIndent('    ')
        .convert([templateObj]);

    buf.writeln('<|input|>');
    buf.writeln('### Template:');
    buf.writeln(templateJson);

    // Few-shot examples (output-only, per NuExtract format)
    if (examples != null) {
      for (final example in examples) {
        final exampleJson = const JsonEncoder.withIndent('    ')
            .convert([example]);
        buf.writeln('### Example:');
        buf.writeln(exampleJson);
      }
    }

    buf.writeln('### Text:');
    buf.writeln(ocrText);
    buf.writeln();
    buf.write('<|output|>');

    return buf.toString();
  }

  /// Remaps LLM output from label-keyed to fieldId-keyed maps,
  /// coercing string values to their target types.
  ///
  /// NuExtract outputs everything as strings. This method converts:
  /// - integer fields: `"42"` → `42`
  /// - float/number fields: `"4.66"` → `4.66`
  /// - boolean fields: `"true"` → `true`
  /// - string/enumerated fields: kept as-is
  ///
  /// Values that fail to parse are kept as strings.
  /// Unknown keys in the LLM output are silently dropped.
  static List<Map<String, dynamic>> remapLabelsToIds(
    List<Map<String, dynamic>> llmItems,
    List<ExtractionField> fields,
  ) {
    if (llmItems.isEmpty) return [];

    final labelToField = {for (final f in fields) f.label: f};

    return llmItems.map((item) {
      final remapped = <String, dynamic>{};
      for (final entry in item.entries) {
        final field = labelToField[entry.key];
        if (field == null) continue;
        remapped[field.fieldId] = _coerceValue(entry.value, field.type);
      }
      return remapped;
    }).toList();
  }

  /// Coerces a string value to the target type.
  /// Returns the original value if coercion fails.
  static dynamic _coerceValue(dynamic value, GbnfFieldType targetType) {
    if (value is! String) return value;
    final trimmed = value.trim();
    if (trimmed.isEmpty) return value;

    // Strip common prefixes like $, €, £ for numeric fields
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

  /// Strips leading currency symbols for numeric parsing.
  static String _stripCurrencyPrefix(String s) {
    if (s.isEmpty) return s;
    const currencyPrefixes = ['\$', '€', '£', '¥', '₹'];
    for (final prefix in currencyPrefixes) {
      if (s.startsWith(prefix)) return s.substring(prefix.length).trim();
    }
    return s;
  }
}
