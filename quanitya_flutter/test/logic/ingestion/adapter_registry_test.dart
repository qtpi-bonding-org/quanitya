import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:quanitya_flutter/logic/ingestion/adapters/adapter_registry.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/i_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';

const int kPropertyTestIterations = 1;

/// Test adapter implementation for property testing
class TestAdapter implements IDataSourceAdapter<Map<String, dynamic>> {
  TestAdapter({
    required this.adapterId,
    required this.displayName,
  });

  @override
  final String adapterId;

  @override
  final String displayName;

  @override
  TrackerTemplateModel deriveTemplate() {
    return TrackerTemplateModel.create(
      name: displayName,
      fields: [
        TemplateField.create(
          label: 'Value',
          type: FieldEnum.integer,
        ),
      ],
    );
  }

  @override
  LogEntryModel mapToEntry(Map<String, dynamic> sourceData, String templateId) {
    return LogEntryModel.logNow(
      templateId: templateId,
      data: {
        'value': sourceData['value'],
        '_sourceAdapter': adapterId,
        '_dedupKey': extractDedupKey(sourceData),
      },
    );
  }

  @override
  String extractDedupKey(Map<String, dynamic> sourceData) {
    return sourceData['id']?.toString() ?? '';
  }

  @override
  DateTime extractTimestamp(Map<String, dynamic> sourceData) {
    return DateTime.now();
  }
}

void main() {
  final faker = Faker();

  group('AdapterRegistry Property Tests', () {
    late AdapterRegistry registry;

    setUp(() {
      registry = AdapterRegistry();
    });

    group('Property 2: Registry register-get round trip', () {
      test(
        '**Feature: data-ingestion-script, Property 2: Registry register-get round trip** - '
        '**Validates: Requirements 4.1, 4.2**',
        () {
          for (int i = 0; i < kPropertyTestIterations; i++) {
            // Generate random adapter
            final adapterId = '${faker.lorem.word()}.${faker.lorem.word()}';
            final displayName = faker.lorem.sentence();
            final adapter = TestAdapter(
              adapterId: adapterId,
              displayName: displayName,
            );

            // Register adapter
            registry.register(adapter);

            // Property: get(adapter.adapterId) returns the same adapter instance
            final retrieved = registry.get(adapterId);
            expect(
              retrieved,
              same(adapter),
              reason: 'Retrieved adapter should be the same instance (iteration $i)',
            );
            expect(
              retrieved?.adapterId,
              equals(adapterId),
              reason: 'Retrieved adapter ID should match (iteration $i)',
            );
            expect(
              retrieved?.displayName,
              equals(displayName),
              reason: 'Retrieved adapter displayName should match (iteration $i)',
            );
          }
        },
      );

      test('get returns null for unregistered adapter ID', () {
        for (int i = 0; i < kPropertyTestIterations; i++) {
          final nonExistentId = 'nonexistent.${faker.guid.guid()}';
          expect(
            registry.get(nonExistentId),
            isNull,
            reason: 'Should return null for unregistered ID (iteration $i)',
          );
        }
      });
    });

    group('Property 3: Registry getByCategory filters correctly', () {
      test(
        '**Feature: data-ingestion-script, Property 3: Registry getByCategory filters correctly** - '
        '**Validates: Requirements 4.4**',
        () {
          for (int i = 0; i < kPropertyTestIterations; i++) {
            // Create fresh registry for each iteration
            final testRegistry = AdapterRegistry();

            // Generate random category
            final category = faker.lorem.word();
            final otherCategory = '${faker.lorem.word()}_other';

            // Register adapters in target category
            final categoryAdapters = <TestAdapter>[];
            final categoryCount = faker.randomGenerator.integer(5, min: 1);
            for (int j = 0; j < categoryCount; j++) {
              final adapter = TestAdapter(
                adapterId: '$category.${faker.lorem.word()}_$j',
                displayName: faker.lorem.sentence(),
              );
              categoryAdapters.add(adapter);
              testRegistry.register(adapter);
            }

            // Register adapters in other category
            final otherCount = faker.randomGenerator.integer(3, min: 1);
            for (int j = 0; j < otherCount; j++) {
              final adapter = TestAdapter(
                adapterId: '$otherCategory.${faker.lorem.word()}_$j',
                displayName: faker.lorem.sentence(),
              );
              testRegistry.register(adapter);
            }

            // Property: getByCategory returns only adapters with matching prefix
            final filtered = testRegistry.getByCategory(category);

            expect(
              filtered.length,
              equals(categoryCount),
              reason: 'Should return exactly $categoryCount adapters (iteration $i)',
            );

            for (final adapter in filtered) {
              expect(
                adapter.adapterId.startsWith('$category.'),
                isTrue,
                reason: 'All returned adapters should have ID starting with "$category." (iteration $i)',
              );
            }

            // Verify none of the other category adapters are included
            for (final adapter in filtered) {
              expect(
                adapter.adapterId.startsWith('$otherCategory.'),
                isFalse,
                reason: 'No adapters from other category should be included (iteration $i)',
              );
            }
          }
        },
      );

      test('getByCategory returns empty list for non-existent category', () {
        for (int i = 0; i < kPropertyTestIterations; i++) {
          // Register some adapters
          registry.register(TestAdapter(
            adapterId: 'existing.adapter',
            displayName: 'Existing',
          ));

          final nonExistentCategory = 'nonexistent_${faker.guid.guid()}';
          final result = registry.getByCategory(nonExistentCategory);

          expect(
            result,
            isEmpty,
            reason: 'Should return empty list for non-existent category (iteration $i)',
          );
        }
      });
    });

    group('all getter', () {
      test('returns all registered adapters', () {
        for (int i = 0; i < kPropertyTestIterations; i++) {
          final testRegistry = AdapterRegistry();
          final adapterCount = faker.randomGenerator.integer(10, min: 1);
          final registeredAdapters = <TestAdapter>[];

          for (int j = 0; j < adapterCount; j++) {
            final adapter = TestAdapter(
              adapterId: '${faker.lorem.word()}.adapter_$j',
              displayName: faker.lorem.sentence(),
            );
            registeredAdapters.add(adapter);
            testRegistry.register(adapter);
          }

          final all = testRegistry.all;
          expect(
            all.length,
            equals(adapterCount),
            reason: 'Should return all $adapterCount adapters (iteration $i)',
          );

          for (final adapter in registeredAdapters) {
            expect(
              all.contains(adapter),
              isTrue,
              reason: 'All registered adapters should be in the list (iteration $i)',
            );
          }
        }
      });
    });
  });
}
