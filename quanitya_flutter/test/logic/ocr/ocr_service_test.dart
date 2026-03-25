import 'dart:ui';
import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/ocr/services/ocr_service.dart';

void main() {
  group('OcrService.reconstructRows', () {
    test('groups lines on same Y-position into one row', () {
      final lines = [
        OcrLine(text: 'Coffee', bounds: const Rect.fromLTWH(10, 100, 80, 20)),
        OcrLine(text: '\$4.50', bounds: const Rect.fromLTWH(200, 102, 50, 20)),
      ];
      final result = OcrService.reconstructRows(lines);
      expect(result, contains('Coffee'));
      expect(result, contains('\$4.50'));
      final rowLines = result.split('\n').where((l) => l.isNotEmpty).toList();
      expect(rowLines, hasLength(1));
    });

    test('separates lines at different Y-positions into different rows', () {
      final lines = [
        OcrLine(text: 'Coffee', bounds: const Rect.fromLTWH(10, 100, 80, 20)),
        OcrLine(text: 'Bagel', bounds: const Rect.fromLTWH(10, 150, 80, 20)),
      ];
      final result = OcrService.reconstructRows(lines);
      final rowLines = result.split('\n').where((l) => l.isNotEmpty).toList();
      expect(rowLines, hasLength(2));
      expect(rowLines[0], contains('Coffee'));
      expect(rowLines[1], contains('Bagel'));
    });

    test('sorts columns left-to-right within a row', () {
      final lines = [
        OcrLine(text: '\$4.50', bounds: const Rect.fromLTWH(200, 100, 50, 20)),
        OcrLine(text: 'Coffee', bounds: const Rect.fromLTWH(10, 102, 80, 20)),
      ];
      final result = OcrService.reconstructRows(lines);
      final rowLines = result.split('\n').where((l) => l.isNotEmpty).toList();
      expect(rowLines, hasLength(1));
      expect(rowLines[0].indexOf('Coffee'), lessThan(rowLines[0].indexOf('\$4.50')));
    });

    test('handles empty input', () {
      final result = OcrService.reconstructRows([]);
      expect(result, isEmpty);
    });

    test('handles single line', () {
      final lines = [
        OcrLine(text: 'Hello', bounds: const Rect.fromLTWH(10, 100, 80, 20)),
      ];
      final result = OcrService.reconstructRows(lines);
      expect(result.trim(), 'Hello');
    });

    test('handles three-column receipt layout', () {
      final lines = [
        OcrLine(text: '1x', bounds: const Rect.fromLTWH(10, 100, 30, 20)),
        OcrLine(text: 'Coffee', bounds: const Rect.fromLTWH(60, 102, 80, 20)),
        OcrLine(text: '\$4.50', bounds: const Rect.fromLTWH(250, 101, 50, 20)),
        OcrLine(text: '2x', bounds: const Rect.fromLTWH(10, 150, 30, 20)),
        OcrLine(text: 'Bagel', bounds: const Rect.fromLTWH(60, 152, 80, 20)),
        OcrLine(text: '\$6.50', bounds: const Rect.fromLTWH(250, 151, 50, 20)),
      ];
      final result = OcrService.reconstructRows(lines);
      final rowLines = result.split('\n').where((l) => l.isNotEmpty).toList();
      expect(rowLines, hasLength(2));
      expect(rowLines[0], contains('1x'));
      expect(rowLines[0], contains('Coffee'));
      expect(rowLines[0], contains('\$4.50'));
      expect(rowLines[1], contains('2x'));
      expect(rowLines[1], contains('Bagel'));
      expect(rowLines[1], contains('\$6.50'));
    });
  });
}
