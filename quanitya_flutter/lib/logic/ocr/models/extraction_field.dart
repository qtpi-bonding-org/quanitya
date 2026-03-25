import '../../llm/models/gbnf_field.dart';

/// Pairs a template field with its extraction metadata.
class ExtractionField {
  final String fieldId;
  final String label;
  final GbnfFieldType type;
  final List<String>? enumValues;

  const ExtractionField({
    required this.fieldId,
    required this.label,
    required this.type,
    this.enumValues,
  });

  GbnfField toGbnfField() => GbnfField(
        key: label,
        type: type,
        enumValues: enumValues,
      );
}
