import 'dart:convert';
import '../../llm/models/gbnf_field.dart';
import '../../llm/services/gbnf_grammar_generator.dart';
import '../../templates/enums/field_enum.dart';
import '../../templates/models/shared/template_field.dart';
import '../models/extraction_field.dart';

/// Bridges template fields to GBNF grammar and LLM prompts.
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

  static String buildGrammar(List<ExtractionField> fields) {
    return GbnfGrammarGenerator.generate(
      fields: fields.map((f) => f.toGbnfField()).toList(),
      asList: true,
    );
  }

  static String buildPrompt({
    required String ocrText,
    required List<ExtractionField> fields,
  }) {
    final templateObj = <String, String>{};
    for (final field in fields) {
      templateObj[field.label] = '';
    }
    // jsonEncode preserves insertion order (Dart maps are LinkedHashMap),
    // keeping the user's original field order in the prompt template.
    return '<|input|>\n$ocrText\n<|output|>\n[${jsonEncode(templateObj)}]\n';
  }

  static List<Map<String, dynamic>> remapLabelsToIds(
    List<Map<String, dynamic>> llmItems,
    List<ExtractionField> fields,
  ) {
    if (llmItems.isEmpty) return [];
    final labelToId = {for (final f in fields) f.label: f.fieldId};
    return llmItems.map((item) {
      final remapped = <String, dynamic>{};
      for (final entry in item.entries) {
        final fieldId = labelToId[entry.key];
        if (fieldId != null) {
          remapped[fieldId] = entry.value;
        }
      }
      return remapped;
    }).toList();
  }
}
