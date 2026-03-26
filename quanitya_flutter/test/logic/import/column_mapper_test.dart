import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/import/services/column_mapper.dart';
import 'package:quanitya_flutter/logic/llm/models/gbnf_field.dart';
import 'package:quanitya_flutter/logic/ocr/models/extraction_field.dart';

void main() {
  final fields = [
    ExtractionField(fieldId: 'f-name', label: 'Item Name', type: GbnfFieldType.string),
    ExtractionField(fieldId: 'f-price', label: 'Price', type: GbnfFieldType.number),
    ExtractionField(fieldId: 'f-qty', label: 'Quantity', type: GbnfFieldType.integer),
    ExtractionField(fieldId: 'f-organic', label: 'Organic', type: GbnfFieldType.boolean),
  ];

  group('ColumnMapper', () {
    test('maps columns and coerces types', () {
      final items = [
        {'Item': 'Coffee', 'Cost': '4.50', 'Qty': '2', 'Bio': 'true'},
      ];
      final mapping = {'Item': 'f-name', 'Cost': 'f-price', 'Qty': 'f-qty', 'Bio': 'f-organic'};

      final result = ColumnMapper.mapAndCoerce(
        items: items, columnMapping: mapping, extractionFields: fields,
      );

      expect(result, hasLength(1));
      expect(result[0]['f-name'], 'Coffee');
      expect(result[0]['f-price'], 4.5);
      expect(result[0]['f-qty'], 2);
      expect(result[0]['f-organic'], true);
    });

    test('strips currency prefix for numbers', () {
      final items = [{'Price': '\$4.66'}];
      final mapping = {'Price': 'f-price'};
      final result = ColumnMapper.mapAndCoerce(
        items: items, columnMapping: mapping, extractionFields: fields,
      );
      expect(result[0]['f-price'], 4.66);
    });

    test('keeps values that fail coercion as strings', () {
      final items = [{'Price': 'not-a-number'}];
      final mapping = {'Price': 'f-price'};
      final result = ColumnMapper.mapAndCoerce(
        items: items, columnMapping: mapping, extractionFields: fields,
      );
      expect(result[0]['f-price'], 'not-a-number');
    });

    test('ignores unmapped columns', () {
      final items = [{'Item': 'Coffee', 'Extra': 'junk'}];
      final mapping = {'Item': 'f-name'};
      final result = ColumnMapper.mapAndCoerce(
        items: items, columnMapping: mapping, extractionFields: fields,
      );
      expect(result[0].containsKey('f-name'), isTrue);
      expect(result[0].containsKey('Extra'), isFalse);
    });

    test('handles empty items list', () {
      final result = ColumnMapper.mapAndCoerce(
        items: [], columnMapping: {}, extractionFields: fields,
      );
      expect(result, isEmpty);
    });

    test('normalizes whitespace-only to empty string', () {
      final items = [{'Price': '  '}];
      final mapping = {'Price': 'f-price'};
      final result = ColumnMapper.mapAndCoerce(
        items: items, columnMapping: mapping, extractionFields: fields,
      );
      expect(result[0]['f-price'], '');
    });

    test('works with identity mapping (OCR path)', () {
      final items = [{'Item Name': 'Coffee', 'Price': '4.50'}];
      final mapping = {for (final f in fields) f.label: f.fieldId};
      final result = ColumnMapper.mapAndCoerce(
        items: items, columnMapping: mapping, extractionFields: fields,
      );
      expect(result[0]['f-name'], 'Coffee');
      expect(result[0]['f-price'], 4.5);
    });
  });
}
