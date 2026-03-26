import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/ocr/services/template_extraction_schema_builder.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';

void main() {
  group('TemplateExtractionSchemaBuilder', () {
    group('buildExtractionFields', () {
      test('maps supported types and skips unsupported', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Name', type: FieldEnum.text),
          TemplateField(id: 'f2', label: 'Price', type: FieldEnum.float),
          TemplateField(id: 'f3', label: 'Count', type: FieldEnum.integer),
          TemplateField(id: 'f4', label: 'Active', type: FieldEnum.boolean),
          TemplateField(id: 'f5', label: 'Cat', type: FieldEnum.enumerated, options: ['a', 'b']),
          TemplateField(id: 'f6', label: 'Loc', type: FieldEnum.location),
          TemplateField(id: 'f7', label: 'Ref', type: FieldEnum.reference),
          TemplateField(id: 'f8', label: 'Group', type: FieldEnum.group),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(5));
        expect(result[0].fieldId, 'f1');
        expect(result[0].type, GbnfFieldType.string);
        expect(result[1].type, GbnfFieldType.number);
        expect(result[4].type, GbnfFieldType.enumerated);
        expect(result[4].enumValues, ['a', 'b']);
      });

      test('skips deleted fields', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Name', type: FieldEnum.text),
          TemplateField(id: 'f2', label: 'Old', type: FieldEnum.text, isDeleted: true),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(1));
      });
    });

    group('buildPrompt', () {
      test('uses NuExtract format with indent-4 template before text', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'Coffee 4.50\nBagel 3.25',
          fields: [
            ExtractionField(fieldId: 'f1', label: 'Item Name', type: GbnfFieldType.string),
            ExtractionField(fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
          ],
        );
        expect(prompt, contains('<|input|>'));
        expect(prompt, contains('### Template:'));
        expect(prompt, contains('### Text:'));
        expect(prompt, contains('<|output|>'));
        expect(prompt, contains('    "Item Name": ""'));
        expect(prompt, contains('Coffee 4.50'));
        expect(prompt.indexOf('### Template:'), lessThan(prompt.indexOf('### Text:')));
      });

      test('includes few-shot examples between template and text', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'test',
          fields: [
            ExtractionField(fieldId: 'f1', label: 'Name', type: GbnfFieldType.string),
          ],
          examples: [{'Name': 'Coffee'}],
        );
        expect(prompt, contains('### Example:'));
        expect(prompt, contains('Coffee'));
        final templateIdx = prompt.indexOf('### Template:');
        final exampleIdx = prompt.indexOf('### Example:');
        final textIdx = prompt.indexOf('### Text:');
        expect(templateIdx, lessThan(exampleIdx));
        expect(exampleIdx, lessThan(textIdx));
      });
    });

    group('buildExampleFromEntry', () {
      test('converts entry data to label-keyed strings with empty for missing', () {
        final fields = [
          ExtractionField(fieldId: 'u1', label: 'Item', type: GbnfFieldType.string),
          ExtractionField(fieldId: 'u2', label: 'Price', type: GbnfFieldType.number),
        ];
        final example = TemplateExtractionSchemaBuilder.buildExampleFromEntry(
          {'u1': 'Coffee', 'u2': 4.66}, fields,
        );
        expect(example, isNotNull);
        expect(example!['Item'], 'Coffee');
        expect(example['Price'], '4.66');

        // Null/empty values become empty strings
        final partial = TemplateExtractionSchemaBuilder.buildExampleFromEntry(
          {'u1': 'Coffee'}, fields,
        );
        expect(partial!['Price'], '');
      });

      test('returns null when no extractable values', () {
        final fields = [
          ExtractionField(fieldId: 'u1', label: 'Name', type: GbnfFieldType.string),
        ];
        expect(
          TemplateExtractionSchemaBuilder.buildExampleFromEntry({}, fields),
          isNull,
        );
      });
    });

    group('remapLabelsToIds', () {
      test('remaps labels to field IDs with type coercion', () {
        final items = [
          {'Item Name': 'Coffee', 'Price': '4.50'},
          {'Item Name': 'Bagel', 'Price': '3.25'},
        ];
        final fields = [
          ExtractionField(fieldId: 'uuid-1', label: 'Item Name', type: GbnfFieldType.string),
          ExtractionField(fieldId: 'uuid-2', label: 'Price', type: GbnfFieldType.number),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(items, fields);
        expect(result, hasLength(2));
        expect(result[0]['uuid-1'], 'Coffee');
        expect(result[0]['uuid-2'], 4.5);
      });

      test('ignores unknown keys and returns empty for empty input', () {
        final fields = [
          ExtractionField(fieldId: 'u1', label: 'Name', type: GbnfFieldType.string),
        ];
        final withExtra = TemplateExtractionSchemaBuilder.remapLabelsToIds(
          [{'Name': 'Coffee', 'extra': 'junk'}], fields,
        );
        expect(withExtra[0].containsKey('extra'), isFalse);
        expect(TemplateExtractionSchemaBuilder.remapLabelsToIds([], fields), isEmpty);
      });
    });
  });
}
