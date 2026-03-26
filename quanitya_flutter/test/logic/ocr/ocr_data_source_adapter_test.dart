import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/ocr_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

void main() {
  late TrackerTemplateModel template;
  late List<ExtractionField> extractionFields;
  late OcrDataSourceAdapter adapter;

  setUp(() {
    template = TrackerTemplateModel(
      id: 'template-1',
      name: 'Grocery Receipt',
      fields: [
        TemplateField(
            id: 'field-name', label: 'Item Name', type: FieldEnum.text),
        TemplateField(id: 'field-price', label: 'Price', type: FieldEnum.float),
      ],
      updatedAt: DateTime(2026, 3, 25),
    );

    extractionFields = [
      ExtractionField(
          fieldId: 'field-name',
          label: 'Item Name',
          type: GbnfFieldType.string),
      ExtractionField(
          fieldId: 'field-price', label: 'Price', type: GbnfFieldType.number),
    ];

    adapter = OcrDataSourceAdapter(
      template,
      extractionFields,
      batchTimestamp: DateTime(2026, 3, 25, 10, 30),
    );
  });

  group('OcrDataSourceAdapter', () {
    test('adapterId is ocr.on_device', () {
      expect(adapter.adapterId, 'ocr.on_device');
    });

    test('displayName is set', () {
      expect(adapter.displayName, isNotEmpty);
    });

    group('validate (after coercion)', () {
      test('returns empty for valid coerced data', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        expect(adapter.validate(data), isEmpty);
      });

      test('returns empty for empty string values', () {
        final data = {'field-name': '', 'field-price': ''};
        expect(adapter.validate(data), isEmpty);
      });

      test('returns error for missing field', () {
        final data = {'field-name': 'Coffee'};
        final errors = adapter.validate(data);
        expect(errors, isNotEmpty);
        expect(errors.first, contains('field-price'));
      });

      test('returns error for wrong type after failed coercion', () {
        final data = {'field-name': 'Coffee', 'field-price': 'not a number'};
        final errors = adapter.validate(data);
        expect(errors, isNotEmpty);
      });

      test('accepts int for number field', () {
        final data = {'field-name': 'Coffee', 'field-price': 4};
        expect(adapter.validate(data), isEmpty);
      });
    });

    group('mapToEntry', () {
      test('creates LogEntry with correct templateId', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.templateId, 'template-1');
      });

      test('includes source data in entry data', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.data['field-name'], 'Coffee');
        expect(entry.data['field-price'], 4.5);
      });

      test('includes _sourceAdapter metadata', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.data['_sourceAdapter'], 'ocr.on_device');
      });

      test('includes _dedupKey metadata', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.data['_dedupKey'], isNotNull);
        expect(entry.data['_dedupKey'], isNotEmpty);
      });

      test('uses batch timestamp as occurredAt', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.occurredAt, DateTime(2026, 3, 25, 10, 30));
      });
    });

    group('extractDedupKey', () {
      test('produces consistent key for same data', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        expect(adapter.extractDedupKey(data), adapter.extractDedupKey(data));
      });

      test('produces different keys for different data', () {
        final data1 = {'field-name': 'Coffee', 'field-price': 4.5};
        final data2 = {'field-name': 'Bagel', 'field-price': 3.25};
        expect(adapter.extractDedupKey(data1),
            isNot(adapter.extractDedupKey(data2)));
      });

      test('ignores metadata keys in dedup calculation', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final dataWithMeta = {
          'field-name': 'Coffee',
          'field-price': 4.5,
          '_sourceAdapter': 'ocr.on_device',
          '_dedupKey': 'old-key',
        };
        expect(adapter.extractDedupKey(data),
            adapter.extractDedupKey(dataWithMeta));
      });
    });

    group('deriveTemplate', () {
      test('returns the template it was constructed with', () {
        expect(adapter.deriveTemplate(), template);
      });
    });
  });
}
