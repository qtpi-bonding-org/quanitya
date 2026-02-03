import 'package:flutter_test/flutter_test.dart';
import 'package:health/health.dart';

import 'package:quanitya_flutter/integrations/flutter/health/health_adapter_factory.dart';

const int kPropertyTestIterations = 5;

void main() {
  group('HealthAdapterFactory Property Tests', () {
    late HealthAdapterFactory factory;

    setUp(() {
      factory = HealthAdapterFactory();
    });

    group('Property 7: HealthAdapterFactory generates valid adapters', () {
      test(
        '**Feature: data-ingestion-pipeline, Property 7: HealthAdapterFactory generates valid adapters** - '
        '**Validates: Requirements 8.1, 8.2, 8.3**',
        () {
          // Test all HealthDataType values
          for (final type in HealthDataType.values) {
            final adapter = factory.create(type);

            // Property: adapterId matches "health.{typename}"
            final expectedId = 'health.${type.name.toLowerCase()}';
            expect(
              adapter.adapterId,
              equals(expectedId),
              reason: 'Adapter for $type should have ID "$expectedId"',
            );

            // Property: displayName is non-empty
            expect(
              adapter.displayName,
              isNotEmpty,
              reason: 'Adapter for $type should have non-empty displayName',
            );

            // Property: displayName is human-readable (no underscores)
            expect(
              adapter.displayName.contains('_'),
              isFalse,
              reason: 'displayName for $type should not contain underscores',
            );

            // Property: deriveTemplate returns valid template
            final template = adapter.deriveTemplate();
            expect(
              template.name,
              isNotEmpty,
              reason: 'Template for $type should have non-empty name',
            );
            expect(
              template.fields,
              isNotEmpty,
              reason: 'Template for $type should have at least one field',
            );
          }
        },
      );

      test('adapterId format is consistent across all types', () {
        for (final type in HealthDataType.values) {
          final adapter = factory.create(type);

          // Should start with "health."
          expect(
            adapter.adapterId.startsWith('health.'),
            isTrue,
            reason: 'Adapter ID for $type should start with "health."',
          );

          // Should be lowercase
          expect(
            adapter.adapterId,
            equals(adapter.adapterId.toLowerCase()),
            reason: 'Adapter ID for $type should be lowercase',
          );
        }
      });

      test('displayName humanization is correct', () {
        // Test specific known conversions
        final testCases = {
          HealthDataType.HEART_RATE: 'Heart Rate',
          HealthDataType.BLOOD_OXYGEN: 'Blood Oxygen',
          HealthDataType.STEPS: 'Steps',
          HealthDataType.BODY_MASS_INDEX: 'Body Mass Index',
          HealthDataType.SLEEP_ASLEEP: 'Sleep Asleep',
        };

        for (final entry in testCases.entries) {
          final adapter = factory.create(entry.key);
          expect(
            adapter.displayName,
            equals(entry.value),
            reason: '${entry.key} should humanize to "${entry.value}"',
          );
        }
      });
    });

    group('mapToEntry includes required metadata', () {
      test('entry data contains _sourceAdapter and _dedupKey', () {
        final adapter = factory.create(HealthDataType.STEPS);
        final templateId = 'test-template-id';

        final healthPoint = HealthDataPoint(
          uuid: 'health-uuid-123',
          type: HealthDataType.STEPS,
          value: NumericHealthValue(numericValue: 5432),
          unit: HealthDataUnit.COUNT,
          dateFrom: DateTime(2025, 12, 28, 10, 0),
          dateTo: DateTime(2025, 12, 28, 11, 0),
          sourceName: 'iPhone',
          sourceId: 'com.apple.Health',
          sourcePlatform: HealthPlatformType.appleHealth,
          sourceDeviceId: 'device-123',
        );

        final entry = adapter.mapToEntry(healthPoint, templateId);

        // Check required metadata
        expect(entry.data['_sourceAdapter'], equals('health.steps'));
        expect(entry.data['_dedupKey'], equals('health-uuid-123'));
        expect(entry.data['value'], equals(5432));

        // Check additional health metadata
        expect(entry.data['_healthUuid'], equals('health-uuid-123'));
        expect(entry.data['_healthSource'], equals('com.apple.Health'));
        expect(entry.data['_healthSourceName'], equals('iPhone'));
      });
    });

    group('extractDedupKey uses health UUID', () {
      test('returns the health platform UUID', () {
        final adapter = factory.create(HealthDataType.HEART_RATE);

        final healthPoint = HealthDataPoint(
          uuid: 'unique-health-uuid-456',
          type: HealthDataType.HEART_RATE,
          value: NumericHealthValue(numericValue: 72),
          unit: HealthDataUnit.BEATS_PER_MINUTE,
          dateFrom: DateTime.now(),
          dateTo: DateTime.now(),
          sourceName: 'Apple Watch',
          sourceId: 'com.apple.Health',
          sourcePlatform: HealthPlatformType.appleHealth,
          sourceDeviceId: 'watch-456',
        );

        expect(
          adapter.extractDedupKey(healthPoint),
          equals('unique-health-uuid-456'),
        );
      });
    });

    group('createAll generates multiple adapters', () {
      test('returns adapters for all requested types', () {
        final types = [
          HealthDataType.STEPS,
          HealthDataType.HEART_RATE,
          HealthDataType.BLOOD_OXYGEN,
        ];

        final adapters = factory.createAll(types);

        expect(adapters.length, equals(3));
        expect(adapters[0].adapterId, equals('health.steps'));
        expect(adapters[1].adapterId, equals('health.heart_rate'));
        expect(adapters[2].adapterId, equals('health.blood_oxygen'));
      });
    });
  });
}
