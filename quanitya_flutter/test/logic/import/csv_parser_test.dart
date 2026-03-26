import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/import/services/csv_parser.dart';

void main() {
  group('CsvParser', () {
    test('parses simple CSV with headers', () {
      const csv = 'Name,Price\nCoffee,4.50\nBagel,3.25';
      final result = CsvParser.parse(csv);
      expect(result, hasLength(2));
      expect(result[0]['Name'], 'Coffee');
      expect(result[0]['Price'], '4.50');
      expect(result[1]['Name'], 'Bagel');
      expect(result[1]['Price'], '3.25');
    });

    test('handles quoted fields with commas', () {
      const csv = 'Name,Description\n"Smith, John","A person"';
      final result = CsvParser.parse(csv);
      expect(result, hasLength(1));
      expect(result[0]['Name'], 'Smith, John');
    });

    test('handles empty fields', () {
      const csv = 'Name,Price\nCoffee,\n,3.25';
      final result = CsvParser.parse(csv);
      expect(result, hasLength(2));
      expect(result[0]['Price'], '');
      expect(result[1]['Name'], '');
    });

    test('handles messy input — trims headers and skips empty rows', () {
      const csv = ' Name , Price \nCoffee,4.50\n\nBagel,3.25\n';
      final result = CsvParser.parse(csv);
      expect(result, hasLength(2));
      expect(result[0]['Name'], 'Coffee');
      expect(result[1]['Name'], 'Bagel');
    });

    test('returns empty list for empty input', () {
      expect(CsvParser.parse(''), isEmpty);
    });

    test('handles CRLF line endings', () {
      const csv = 'Name,Price\r\nCoffee,4.50\r\nBagel,3.25';
      final result = CsvParser.parse(csv);
      expect(result, hasLength(2));
    });

    test('extracts headers', () {
      const csv = 'Item Name,Price,Date\nCoffee,4.50,2026-03-15';
      expect(CsvParser.extractHeaders(csv), ['Item Name', 'Price', 'Date']);
    });
  });
}
