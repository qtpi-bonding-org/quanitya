import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/ocr/services/template_extraction_schema_builder.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';

void main() {
  group('TemplateExtractionSchemaBuilder', () {
    group('buildExtractionFields', () {
      test('maps text field to string', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Item Name', type: FieldEnum.text),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(1));
        expect(result[0].fieldId, 'f1');
        expect(result[0].label, 'Item Name');
        expect(result[0].type, GbnfFieldType.string);
      });

      test('maps integer field to integer', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Count', type: FieldEnum.integer),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.integer);
      });

      test('maps float field to number', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Price', type: FieldEnum.float),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.number);
      });

      test('maps boolean field to boolean', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Organic', type: FieldEnum.boolean),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.boolean);
      });

      test('maps enumerated field with options', () {
        final fields = [
          TemplateField(
            id: 'f1',
            label: 'Category',
            type: FieldEnum.enumerated,
            options: ['food', 'drink'],
          ),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.enumerated);
        expect(result[0].enumValues, ['food', 'drink']);
      });

      test('skips unsupported field types', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Name', type: FieldEnum.text),
          TemplateField(id: 'f2', label: 'Location', type: FieldEnum.location),
          TemplateField(id: 'f3', label: 'Ref', type: FieldEnum.reference),
          TemplateField(id: 'f4', label: 'Time', type: FieldEnum.datetime),
          TemplateField(id: 'f5', label: 'Weight', type: FieldEnum.dimension),
          TemplateField(id: 'f6', label: 'Details', type: FieldEnum.group),
          TemplateField(id: 'f7', label: 'Tags', type: FieldEnum.multiEnum),
          TemplateField(id: 'f8', label: 'Price', type: FieldEnum.float),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(2));
        expect(result[0].fieldId, 'f1');
        expect(result[1].fieldId, 'f8');
      });

      test('skips deleted fields', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Name', type: FieldEnum.text),
          TemplateField(id: 'f2', label: 'Old', type: FieldEnum.text, isDeleted: true),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(1));
        expect(result[0].fieldId, 'f1');
      });

      test('returns empty list when no extractable fields', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Location', type: FieldEnum.location),
        ];
        final result = TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, isEmpty);
      });
    });

    group('buildGrammar', () {
      test('produces non-empty grammar string', () {
        final fields = [
          ExtractionField(fieldId: 'f1', label: 'Name', type: GbnfFieldType.string),
        ];
        final grammar = TemplateExtractionSchemaBuilder.buildGrammar(fields);
        expect(grammar, isNotEmpty);
        expect(grammar, contains('"Name"'));
        expect(grammar, contains('root'));
      });

      test('throws on empty fields', () {
        expect(
          () => TemplateExtractionSchemaBuilder.buildGrammar([]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('buildPrompt', () {
      test('includes OCR text in input section', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'Coffee 4.50\nBagel 3.25',
          fields: [
            ExtractionField(fieldId: 'f1', label: 'Item', type: GbnfFieldType.string),
            ExtractionField(fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
          ],
        );
        expect(prompt, contains('Coffee 4.50'));
        expect(prompt, contains('Bagel 3.25'));
      });

      test('includes NuExtract template with field labels and empty values', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'some text',
          fields: [
            ExtractionField(fieldId: 'f1', label: 'Item Name', type: GbnfFieldType.string),
            ExtractionField(fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
          ],
        );
        expect(prompt, contains('<|input|>'));
        expect(prompt, contains('<|output|>'));
        expect(prompt, contains('Item Name'));
        expect(prompt, contains('Price'));
      });
    });

    group('remapLabelsToIds', () {
      test('remaps label keys to field IDs', () {
        final items = [
          {'Item Name': 'Coffee', 'Price': 4.5},
          {'Item Name': 'Bagel', 'Price': 3.25},
        ];
        final fields = [
          ExtractionField(fieldId: 'uuid-1', label: 'Item Name', type: GbnfFieldType.string),
          ExtractionField(fieldId: 'uuid-2', label: 'Price', type: GbnfFieldType.number),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(items, fields);
        expect(result, hasLength(2));
        expect(result[0]['uuid-1'], 'Coffee');
        expect(result[0]['uuid-2'], 4.5);
        expect(result[1]['uuid-1'], 'Bagel');
        expect(result[1]['uuid-2'], 3.25);
      });

      test('ignores keys not in extraction fields', () {
        final items = [
          {'Name': 'Coffee', 'extra_key': 'junk'},
        ];
        final fields = [
          ExtractionField(fieldId: 'uuid-1', label: 'Name', type: GbnfFieldType.string),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(items, fields);
        expect(result[0].containsKey('uuid-1'), isTrue);
        expect(result[0].containsKey('extra_key'), isFalse);
      });

      test('returns empty list for empty input', () {
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds([], []);
        expect(result, isEmpty);
      });
    });
  });
}
