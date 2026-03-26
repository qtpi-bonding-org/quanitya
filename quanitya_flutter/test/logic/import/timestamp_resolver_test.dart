import 'package:flutter_test/flutter_test.dart';
import 'package:quanitya_flutter/logic/import/services/timestamp_resolver.dart';

void main() {
  group('TimestampResolver', () {
    test('uses DateTime.now() as fallback', () {
      final items = [{'name': 'Coffee', 'price': 4.5}];
      final before = DateTime.now();
      final result = TimestampResolver.resolve(items: items);
      final after = DateTime.now();
      expect(result, hasLength(1));
      expect(result[0].data, {'name': 'Coffee', 'price': 4.5});
      expect(result[0].occurredAt.isAfter(before.subtract(const Duration(seconds: 1))), isTrue);
      expect(result[0].occurredAt.isBefore(after.add(const Duration(seconds: 1))), isTrue);
    });

    test('batch timestamp overrides DateTime.now()', () {
      final batch = DateTime(2026, 3, 15);
      final result = TimestampResolver.resolve(
        items: [{'name': 'Coffee'}],
        batchTimestamp: batch,
      );
      expect(result[0].occurredAt, batch);
    });

    test('designated date field overrides batch timestamp', () {
      final items = [
        {'name': 'Coffee', 'date': '2026-03-10'},
        {'name': 'Bagel', 'date': '2026-03-11'},
      ];
      final result = TimestampResolver.resolve(
        items: items,
        dateFieldId: 'date',
        batchTimestamp: DateTime(2026, 3, 15),
      );
      expect(result[0].occurredAt, DateTime(2026, 3, 10));
      expect(result[1].occurredAt, DateTime(2026, 3, 11));
    });

    test('date field is stripped from data', () {
      final items = [{'name': 'Coffee', 'date': '2026-03-10'}];
      final result = TimestampResolver.resolve(items: items, dateFieldId: 'date');
      expect(result[0].data.containsKey('date'), isFalse);
      expect(result[0].data['name'], 'Coffee');
    });

    test('user per-item override beats everything', () {
      final userOverride = DateTime(2026, 6, 1);
      final items = [
        {'name': 'Coffee', 'date': '2026-03-10'},
        {'name': 'Bagel', 'date': '2026-03-11'},
      ];
      final result = TimestampResolver.resolve(
        items: items,
        dateFieldId: 'date',
        batchTimestamp: DateTime(2026, 3, 15),
        perItemTimestamps: {0: userOverride},
      );
      expect(result[0].occurredAt, userOverride);
      expect(result[1].occurredAt, DateTime(2026, 3, 11));
    });

    test('falls through to batch when date field parse fails', () {
      final batch = DateTime(2026, 3, 15);
      final items = [{'name': 'Coffee', 'date': 'not-a-date'}];
      final result = TimestampResolver.resolve(
        items: items, dateFieldId: 'date', batchTimestamp: batch,
      );
      expect(result[0].occurredAt, batch);
      expect(result[0].data.containsKey('date'), isFalse);
    });

    test('parses MM/dd/yyyy date format', () {
      final items = [{'name': 'Coffee', 'date': '03/15/2026'}];
      final result = TimestampResolver.resolve(items: items, dateFieldId: 'date');
      expect(result[0].occurredAt, DateTime(2026, 3, 15));
    });

    test('parses yyyy-MM-dd date format', () {
      final items = [{'name': 'Coffee', 'date': '2026-03-15'}];
      final result = TimestampResolver.resolve(items: items, dateFieldId: 'date');
      expect(result[0].occurredAt, DateTime(2026, 3, 15));
    });

    test('parses ISO 8601 datetime', () {
      final items = [{'name': 'Coffee', 'date': '2026-03-15T10:30:00'}];
      final result = TimestampResolver.resolve(items: items, dateFieldId: 'date');
      expect(result[0].occurredAt, DateTime(2026, 3, 15, 10, 30));
    });

    test('handles no date field designation', () {
      final batch = DateTime(2026, 3, 15);
      final items = [{'name': 'Coffee', 'date': '2026-03-10'}];
      final result = TimestampResolver.resolve(items: items, batchTimestamp: batch);
      expect(result[0].occurredAt, batch);
      expect(result[0].data.containsKey('date'), isTrue);
    });

    test('handles empty items list', () {
      expect(TimestampResolver.resolve(items: []), isEmpty);
    });
  });
}
