import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/import_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';

void main() {
  late TrackerTemplateModel template;
  late List<ExtractionField> extractionFields;
  late ImportDataSourceAdapter adapter;

  setUp(() {
    template = TrackerTemplateModel(
      id: 'template-1',
      name: 'Grocery Receipt',
      fields: [
        TemplateField(id: 'field-name', label: 'Item Name', type: FieldEnum.text),
        TemplateField(id: 'field-price', label: 'Price', type: FieldEnum.float),
      ],
      updatedAt: DateTime(2026, 3, 25),
    );
    extractionFields = [
      ExtractionField(fieldId: 'field-name', label: 'Item Name', type: GbnfFieldType.string),
      ExtractionField(fieldId: 'field-price', label: 'Price', type: GbnfFieldType.number),
    ];
    adapter = ImportDataSourceAdapter(template, extractionFields);
  });

  group('ImportDataSourceAdapter', () {
    test('adapterId is import.bulk', () {
      expect(adapter.adapterId, 'import.bulk');
    });

    group('validate', () {
      test('returns empty for valid data', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        expect(adapter.validate(data), isEmpty);
      });

      test('returns error for missing field', () {
        final data = {'field-name': 'Coffee'};
        expect(adapter.validate(data), isNotEmpty);
      });
    });

    group('mapToEntry', () {
      test('uses _occurredAt from data for timestamp', () {
        final ts = DateTime(2026, 3, 15, 10, 30);
        final data = {
          'field-name': 'Coffee', 'field-price': 4.5,
          '_occurredAt': ts.toIso8601String(),
        };
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.occurredAt, ts);
      });

      test('strips _occurredAt from entry data', () {
        final data = {
          'field-name': 'Coffee', 'field-price': 4.5,
          '_occurredAt': '2026-03-15T10:30:00.000',
        };
        final entry = adapter.mapToEntry(data, 'template-1');
        expect(entry.data.containsKey('_occurredAt'), isFalse);
        expect(entry.data['field-name'], 'Coffee');
      });

      test('includes _sourceAdapter and _dedupKey metadata', () {
        final entry = adapter.mapToEntry(
          {'field-name': 'Coffee', 'field-price': 4.5}, 'template-1',
        );
        expect(entry.data['_sourceAdapter'], 'import.bulk');
        expect(entry.data['_dedupKey'], isNotNull);
      });
    });

    group('extractDedupKey', () {
      test('produces consistent keys and different keys for different data', () {
        final d1 = {'field-name': 'Coffee', 'field-price': 4.5};
        final d2 = {'field-name': 'Bagel', 'field-price': 3.25};
        expect(adapter.extractDedupKey(d1), adapter.extractDedupKey(d1));
        expect(adapter.extractDedupKey(d1), isNot(adapter.extractDedupKey(d2)));
      });

      test('ignores metadata keys', () {
        final data = {'field-name': 'Coffee', 'field-price': 4.5};
        final dataWithMeta = {
          ...data, '_sourceAdapter': 'x', '_dedupKey': 'y', '_occurredAt': 'z',
        };
        expect(adapter.extractDedupKey(data), adapter.extractDedupKey(dataWithMeta));
      });
    });
  });
}
