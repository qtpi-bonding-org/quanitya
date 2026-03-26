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
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(1));
        expect(result[0].fieldId, 'f1');
        expect(result[0].label, 'Item Name');
        expect(result[0].type, GbnfFieldType.string);
      });

      test('maps integer field to integer', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Count', type: FieldEnum.integer),
        ];
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.integer);
      });

      test('maps float field to number', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Price', type: FieldEnum.float),
        ];
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.number);
      });

      test('maps boolean field to boolean', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Organic', type: FieldEnum.boolean),
        ];
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
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
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result[0].type, GbnfFieldType.enumerated);
        expect(result[0].enumValues, ['food', 'drink']);
      });

      test('skips unsupported field types', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Name', type: FieldEnum.text),
          TemplateField(id: 'f2', label: 'Location', type: FieldEnum.location),
          TemplateField(
              id: 'f3', label: 'Ref', type: FieldEnum.reference),
          TemplateField(id: 'f4', label: 'Time', type: FieldEnum.datetime),
          TemplateField(
              id: 'f5', label: 'Weight', type: FieldEnum.dimension),
          TemplateField(id: 'f6', label: 'Details', type: FieldEnum.group),
          TemplateField(id: 'f7', label: 'Tags', type: FieldEnum.multiEnum),
          TemplateField(id: 'f8', label: 'Price', type: FieldEnum.float),
        ];
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(2));
        expect(result[0].fieldId, 'f1');
        expect(result[1].fieldId, 'f8');
      });

      test('skips deleted fields', () {
        final fields = [
          TemplateField(id: 'f1', label: 'Name', type: FieldEnum.text),
          TemplateField(
              id: 'f2', label: 'Old', type: FieldEnum.text, isDeleted: true),
        ];
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, hasLength(1));
        expect(result[0].fieldId, 'f1');
      });

      test('returns empty list when no extractable fields', () {
        final fields = [
          TemplateField(
              id: 'f1', label: 'Location', type: FieldEnum.location),
        ];
        final result =
            TemplateExtractionSchemaBuilder.buildExtractionFields(fields);
        expect(result, isEmpty);
      });
    });

    group('buildGrammar', () {
      test('produces grammar with all string values', () {
        final fields = [
          ExtractionField(
              fieldId: 'f1', label: 'Name', type: GbnfFieldType.string),
          ExtractionField(
              fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
        ];
        final grammar =
            TemplateExtractionSchemaBuilder.buildGrammar(fields);
        expect(grammar, isNotEmpty);
        expect(grammar, contains(r'"\"Name\""'));
        expect(grammar, contains(r'"\"Price\""'));
        expect(grammar, contains('root'));
        // All values should be strings — no integer/number/boolean rules
        expect(grammar, isNot(contains('integer ::')));
        expect(grammar, isNot(contains('number ::')));
      });

      test('throws on empty fields', () {
        expect(
          () => TemplateExtractionSchemaBuilder.buildGrammar([]),
          throwsA(isA<ArgumentError>()),
        );
      });
    });

    group('buildPrompt', () {
      test('uses NuExtract format with Template and Text headers', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'Coffee 4.50',
          fields: [
            ExtractionField(
                fieldId: 'f1', label: 'Item', type: GbnfFieldType.string),
            ExtractionField(
                fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
          ],
        );
        expect(prompt, contains('<|input|>'));
        expect(prompt, contains('### Template:'));
        expect(prompt, contains('### Text:'));
        expect(prompt, contains('<|output|>'));
      });

      test('template uses indent-4 JSON with empty string values', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'test',
          fields: [
            ExtractionField(
                fieldId: 'f1',
                label: 'Item Name',
                type: GbnfFieldType.string),
            ExtractionField(
                fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
          ],
        );
        // Should have indented JSON
        expect(prompt, contains('    "Item Name"'));
        expect(prompt, contains('    "Price"'));
        // All values should be empty strings
        expect(prompt, contains('"Item Name": ""'));
        expect(prompt, contains('"Price": ""'));
      });

      test('template is before text', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'some text here',
          fields: [
            ExtractionField(
                fieldId: 'f1', label: 'Name', type: GbnfFieldType.string),
          ],
        );
        final templateIdx = prompt.indexOf('### Template:');
        final textIdx = prompt.indexOf('### Text:');
        expect(templateIdx, lessThan(textIdx));
      });

      test('includes OCR text in Text section', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'Coffee 4.50\nBagel 3.25',
          fields: [
            ExtractionField(
                fieldId: 'f1', label: 'Item', type: GbnfFieldType.string),
          ],
        );
        expect(prompt, contains('Coffee 4.50'));
        expect(prompt, contains('Bagel 3.25'));
      });

      test('includes few-shot examples when provided', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'test',
          fields: [
            ExtractionField(
                fieldId: 'f1', label: 'Name', type: GbnfFieldType.string),
            ExtractionField(
                fieldId: 'f2', label: 'Price', type: GbnfFieldType.number),
          ],
          examples: [
            {'Name': 'Coffee', 'Price': '4.50'},
          ],
        );
        expect(prompt, contains('### Example:'));
        expect(prompt, contains('Coffee'));
        expect(prompt, contains('4.50'));
      });

      test('example section is between template and text', () {
        final prompt = TemplateExtractionSchemaBuilder.buildPrompt(
          ocrText: 'test',
          fields: [
            ExtractionField(
                fieldId: 'f1', label: 'Name', type: GbnfFieldType.string),
          ],
          examples: [
            {'Name': 'Coffee'},
          ],
        );
        final templateIdx = prompt.indexOf('### Template:');
        final exampleIdx = prompt.indexOf('### Example:');
        final textIdx = prompt.indexOf('### Text:');
        expect(templateIdx, lessThan(exampleIdx));
        expect(exampleIdx, lessThan(textIdx));
      });
    });

    group('buildExampleFromEntry', () {
      test('converts entry data to label-keyed string map', () {
        final entryData = {'uuid-1': 'Coffee', 'uuid-2': 4.66};
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Item Name',
              type: GbnfFieldType.string),
          ExtractionField(
              fieldId: 'uuid-2',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final example = TemplateExtractionSchemaBuilder
            .buildExampleFromEntry(entryData, fields);
        expect(example, isNotNull);
        expect(example!['Item Name'], 'Coffee');
        expect(example['Price'], '4.66');
      });

      test('skips null values', () {
        final entryData = {'uuid-1': 'Coffee', 'uuid-2': null};
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Item Name',
              type: GbnfFieldType.string),
          ExtractionField(
              fieldId: 'uuid-2',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final example = TemplateExtractionSchemaBuilder
            .buildExampleFromEntry(entryData, fields);
        expect(example, isNotNull);
        expect(example!.containsKey('Item Name'), isTrue);
        expect(example.containsKey('Price'), isFalse);
      });

      test('skips empty string values', () {
        final entryData = {'uuid-1': '', 'uuid-2': 4.66};
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Item Name',
              type: GbnfFieldType.string),
          ExtractionField(
              fieldId: 'uuid-2',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final example = TemplateExtractionSchemaBuilder
            .buildExampleFromEntry(entryData, fields);
        expect(example, isNotNull);
        expect(example!.containsKey('Item Name'), isFalse);
        expect(example['Price'], '4.66');
      });

      test('returns null when no extractable values', () {
        final entryData = <String, dynamic>{'other-field': 'value'};
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Name',
              type: GbnfFieldType.string),
        ];
        final example = TemplateExtractionSchemaBuilder
            .buildExampleFromEntry(entryData, fields);
        expect(example, isNull);
      });

      test('converts all types to strings', () {
        final entryData = {
          'f1': 'text',
          'f2': 42,
          'f3': 3.14,
          'f4': true,
        };
        final fields = [
          ExtractionField(
              fieldId: 'f1', label: 'Text', type: GbnfFieldType.string),
          ExtractionField(
              fieldId: 'f2', label: 'Int', type: GbnfFieldType.integer),
          ExtractionField(
              fieldId: 'f3', label: 'Float', type: GbnfFieldType.number),
          ExtractionField(
              fieldId: 'f4', label: 'Bool', type: GbnfFieldType.boolean),
        ];
        final example = TemplateExtractionSchemaBuilder
            .buildExampleFromEntry(entryData, fields);
        expect(example!['Text'], 'text');
        expect(example['Int'], '42');
        expect(example['Float'], '3.14');
        expect(example['Bool'], 'true');
      });

      test('ignores metadata keys in entry data', () {
        final entryData = {
          'uuid-1': 'Coffee',
          '_sourceAdapter': 'ocr.on_device',
          '_dedupKey': 'abc123',
        };
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Name',
              type: GbnfFieldType.string),
        ];
        final example = TemplateExtractionSchemaBuilder
            .buildExampleFromEntry(entryData, fields);
        expect(example, isNotNull);
        expect(example!.length, 1);
        expect(example['Name'], 'Coffee');
      });
    });

    group('remapLabelsToIds', () {
      test('remaps label keys to field IDs', () {
        final items = [
          {'Item Name': 'Coffee', 'Price': '4.50'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Item Name',
              type: GbnfFieldType.string),
          ExtractionField(
              fieldId: 'uuid-2',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['uuid-1'], 'Coffee');
        // Number coercion: "4.50" → 4.5
        expect(result[0]['uuid-2'], 4.5);
      });

      test('coerces integer strings', () {
        final items = [
          {'Count': '42'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'f1',
              label: 'Count',
              type: GbnfFieldType.integer),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['f1'], 42);
        expect(result[0]['f1'], isA<int>());
      });

      test('coerces number strings', () {
        final items = [
          {'Price': '3.14'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'f1',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['f1'], 3.14);
        expect(result[0]['f1'], isA<double>());
      });

      test('coerces boolean strings', () {
        final items = [
          {'Active': 'true'},
          {'Active': 'false'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'f1',
              label: 'Active',
              type: GbnfFieldType.boolean),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['f1'], true);
        expect(result[1]['f1'], false);
      });

      test('strips currency prefix for numeric coercion', () {
        final items = [
          {'Price': '\$4.66'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'f1',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['f1'], 4.66);
      });

      test('keeps string values that fail numeric coercion', () {
        final items = [
          {'Price': 'not a number'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'f1',
              label: 'Price',
              type: GbnfFieldType.number),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['f1'], 'not a number');
      });

      test('keeps empty strings as-is', () {
        final items = [
          {'Name': ''},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'f1',
              label: 'Name',
              type: GbnfFieldType.string),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0]['f1'], '');
      });

      test('ignores keys not in extraction fields', () {
        final items = [
          {'Name': 'Coffee', 'extra_key': 'junk'},
        ];
        final fields = [
          ExtractionField(
              fieldId: 'uuid-1',
              label: 'Name',
              type: GbnfFieldType.string),
        ];
        final result = TemplateExtractionSchemaBuilder.remapLabelsToIds(
            items, fields);
        expect(result[0].containsKey('uuid-1'), isTrue);
        expect(result[0].containsKey('extra_key'), isFalse);
      });

      test('returns empty list for empty input', () {
        final result =
            TemplateExtractionSchemaBuilder.remapLabelsToIds([], []);
        expect(result, isEmpty);
      });
    });
  });
}
