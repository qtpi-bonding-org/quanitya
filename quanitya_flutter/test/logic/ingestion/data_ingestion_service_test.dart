import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:quanitya_flutter/data/interfaces/log_entry_interface.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/adapter_registry.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/flutter_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/ingestion/adapters/json_data_source_adapter.dart';
import 'package:quanitya_flutter/logic/ingestion/exceptions/validation_exception.dart';
import 'package:quanitya_flutter/logic/ingestion/services/data_ingestion_service.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/tracker_template.dart';
import 'package:quanitya_flutter/logic/templates/models/shared/template_field.dart';
import 'package:quanitya_flutter/logic/templates/enums/field_enum.dart';

@GenerateMocks([ILogEntryRepository])
import 'data_ingestion_service_test.mocks.dart';

const int kPropertyTestIterations = 5;

// ─────────────────────────────────────────────────────────────────────────────
// Test Adapters
// ─────────────────────────────────────────────────────────────────────────────

/// Test data class for Flutter adapter testing
class TestSourceData {
  final String id;
  final int value;
  final DateTime timestamp;

  TestSourceData({
    required this.id,
    required this.value,
    required this.timestamp,
  });
}

/// Test Flutter adapter implementation
class TestFlutterAdapter extends FlutterDataSourceAdapter<TestSourceData> {
  TestFlutterAdapter({
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
        TemplateField.create(label: 'Value', type: FieldEnum.integer),
      ],
    );
  }

  @override
  LogEntryModel mapToEntry(TestSourceData sourceData, String templateId) {
    return LogEntryModel.logNow(
      templateId: templateId,
      data: {
        'value': sourceData.value,
        '_sourceAdapter': adapterId,
        '_dedupKey': extractDedupKey(sourceData),
      },
    );
  }

  @override
  String extractDedupKey(TestSourceData sourceData) => sourceData.id;

  @override
  DateTime extractTimestamp(TestSourceData sourceData) => sourceData.timestamp;
}

/// Test JSON adapter implementation
class TestJsonAdapter extends JsonDataSourceAdapter {
  TestJsonAdapter({
    required this.adapterId,
    required this.displayName,
  });

  @override
  final String adapterId;

  @override
  final String displayName;

  @override
  Map<String, dynamic> get inputSchema => {
        'type': 'object',
        'required': ['id', 'value'],
        'properties': {
          'id': {'type': 'string'},
          'value': {'type': 'integer'},
        },
      };

  @override
  List<String> validate(Map<String, dynamic> json) {
    final errors = <String>[];
    if (json['id'] == null) errors.add('Missing required field: id');
    if (json['value'] == null) errors.add('Missing required field: value');
    if (json['value'] != null && json['value'] is! int) {
      errors.add('Invalid type for field: value (expected int)');
    }
    return errors;
  }

  @override
  TrackerTemplateModel deriveTemplate() {
    return TrackerTemplateModel.create(
      name: displayName,
      fields: [
        TemplateField.create(label: 'Value', type: FieldEnum.integer),
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
  String extractDedupKey(Map<String, dynamic> sourceData) =>
      sourceData['id']?.toString() ?? '';

  @override
  DateTime extractTimestamp(Map<String, dynamic> sourceData) => DateTime.now();
}

void main() {
  final faker = Faker();

  group('DataIngestionService Property Tests', () {
    late MockILogEntryRepository mockRepo;
    late AdapterRegistry registry;
    late DataIngestionService service;
    late TestFlutterAdapter flutterAdapter;
    late TestJsonAdapter jsonAdapter;

    setUp(() {
      mockRepo = MockILogEntryRepository();
      registry = AdapterRegistry();
      service = DataIngestionService(registry, mockRepo);

      flutterAdapter = TestFlutterAdapter(
        adapterId: 'test.flutter',
        displayName: 'Test Flutter Adapter',
      );
      jsonAdapter = TestJsonAdapter(
        adapterId: 'test.json',
        displayName: 'Test JSON Adapter',
      );

      registry.register(flutterAdapter);
      registry.register(jsonAdapter);
    });

    group('Property 4: Sync deduplication', () {
      test(
        '**Feature: data-ingestion-script, Property 4: Sync deduplication** - '
        '**Validates: Requirements 5.2, 6.4**',
        () async {
          for (int i = 0; i < kPropertyTestIterations; i++) {
            final templateId = faker.guid.guid();

            // Generate source data with some duplicates
            final totalItems = faker.randomGenerator.integer(10, min: 3);
            final duplicateCount = faker.randomGenerator.integer(totalItems - 1, min: 1);

            // Create existing dedup keys (simulating already imported items)
            final existingKeys = <String>{};
            for (int j = 0; j < duplicateCount; j++) {
              existingKeys.add('existing-key-$j');
            }

            // Create source data - some with existing keys, some new
            final sourceData = <TestSourceData>[];
            for (int j = 0; j < duplicateCount; j++) {
              sourceData.add(TestSourceData(
                id: 'existing-key-$j', // Will be filtered as duplicate
                value: faker.randomGenerator.integer(1000),
                timestamp: DateTime.now(),
              ));
            }
            final newItemCount = totalItems - duplicateCount;
            for (int j = 0; j < newItemCount; j++) {
              sourceData.add(TestSourceData(
                id: 'new-key-$j', // Will be imported
                value: faker.randomGenerator.integer(1000),
                timestamp: DateTime.now(),
              ));
            }

            // Mock repository
            when(mockRepo.getDedupKeysForTemplate(templateId))
                .thenAnswer((_) async => existingKeys);
            when(mockRepo.bulkInsert(any)).thenAnswer((_) async {});

            // Execute sync
            final count = await service.syncFlutter(
              adapter: flutterAdapter,
              templateId: templateId,
              sourceData: sourceData,
            );

            // Property: Only new items should be inserted
            expect(
              count,
              equals(newItemCount),
              reason: 'Should only import non-duplicate items (iteration $i)',
            );

            // Verify bulkInsert was called with correct number of entries
            if (newItemCount > 0) {
              final captured = verify(mockRepo.bulkInsert(captureAny)).captured;
              final insertedEntries = captured.last as List<LogEntryModel>;
              expect(
                insertedEntries.length,
                equals(newItemCount),
                reason: 'bulkInsert should receive only new entries (iteration $i)',
              );

              // Verify none of the inserted entries have existing keys
              for (final entry in insertedEntries) {
                final dedupKey = entry.data['_dedupKey'] as String;
                expect(
                  existingKeys.contains(dedupKey),
                  isFalse,
                  reason: 'Inserted entry should not have existing dedup key (iteration $i)',
                );
              }
            }

            // Reset mocks for next iteration
            reset(mockRepo);
          }
        },
      );

      test('syncJson also deduplicates correctly', () async {
        for (int i = 0; i < kPropertyTestIterations; i++) {
          final templateId = faker.guid.guid();

          // Create existing keys
          final existingKeys = {'existing-1', 'existing-2'};

          // Create source data with mix of existing and new
          final sourceData = [
            {'id': 'existing-1', 'value': 100}, // Duplicate
            {'id': 'new-1', 'value': 200}, // New
            {'id': 'existing-2', 'value': 300}, // Duplicate
            {'id': 'new-2', 'value': 400}, // New
          ];

          when(mockRepo.getDedupKeysForTemplate(templateId))
              .thenAnswer((_) async => existingKeys);
          when(mockRepo.bulkInsert(any)).thenAnswer((_) async {});

          final count = await service.syncJson(
            adapter: jsonAdapter,
            templateId: templateId,
            sourceData: sourceData,
          );

          expect(count, equals(2), reason: 'Should import only 2 new items (iteration $i)');

          reset(mockRepo);
        }
      });
    });

    group('Property 5: Sync returns correct count', () {
      test(
        '**Feature: data-ingestion-script, Property 5: Sync returns correct count** - '
        '**Validates: Requirements 5.5, 6.7**',
        () async {
          for (int i = 0; i < kPropertyTestIterations; i++) {
            final templateId = faker.guid.guid();
            final itemCount = faker.randomGenerator.integer(10, min: 1);

            // Generate unique source data (no duplicates)
            final sourceData = List.generate(
              itemCount,
              (j) => TestSourceData(
                id: faker.guid.guid(),
                value: faker.randomGenerator.integer(1000),
                timestamp: DateTime.now(),
              ),
            );

            // Mock repository with no existing keys
            when(mockRepo.getDedupKeysForTemplate(templateId))
                .thenAnswer((_) async => <String>{});
            when(mockRepo.bulkInsert(any)).thenAnswer((_) async {});

            // Execute sync
            final count = await service.syncFlutter(
              adapter: flutterAdapter,
              templateId: templateId,
              sourceData: sourceData,
            );

            // Property: Returned count equals number of items inserted
            expect(
              count,
              equals(itemCount),
              reason: 'Returned count should equal source data length (iteration $i)',
            );

            reset(mockRepo);
          }
        },
      );

      test('returns 0 for empty source data', () async {
        final templateId = faker.guid.guid();

        final count = await service.syncFlutter(
          adapter: flutterAdapter,
          templateId: templateId,
          sourceData: [],
        );

        expect(count, equals(0));
        verifyNever(mockRepo.getDedupKeysForTemplate(any));
        verifyNever(mockRepo.bulkInsert(any));
      });

      test('returns 0 when all items are duplicates', () async {
        final templateId = faker.guid.guid();
        final existingKeys = {'key-1', 'key-2', 'key-3'};

        final sourceData = [
          TestSourceData(id: 'key-1', value: 100, timestamp: DateTime.now()),
          TestSourceData(id: 'key-2', value: 200, timestamp: DateTime.now()),
          TestSourceData(id: 'key-3', value: 300, timestamp: DateTime.now()),
        ];

        when(mockRepo.getDedupKeysForTemplate(templateId))
            .thenAnswer((_) async => existingKeys);

        final count = await service.syncFlutter(
          adapter: flutterAdapter,
          templateId: templateId,
          sourceData: sourceData,
        );

        expect(count, equals(0));
        verifyNever(mockRepo.bulkInsert(any));
      });
    });

    group('Property 6: Entry metadata includes adapter info', () {
      test(
        '**Feature: data-ingestion-script, Property 6: Entry metadata includes adapter info** - '
        '**Validates: Requirements 7.1, 7.2**',
        () async {
          for (int i = 0; i < kPropertyTestIterations; i++) {
            final templateId = faker.guid.guid();
            final itemCount = faker.randomGenerator.integer(5, min: 1);

            // Generate source data
            final sourceData = List.generate(
              itemCount,
              (j) => TestSourceData(
                id: 'item-$j-${faker.guid.guid()}',
                value: faker.randomGenerator.integer(1000),
                timestamp: DateTime.now(),
              ),
            );

            // Mock repository
            when(mockRepo.getDedupKeysForTemplate(templateId))
                .thenAnswer((_) async => <String>{});
            
            List<LogEntryModel>? capturedEntries;
            when(mockRepo.bulkInsert(any)).thenAnswer((invocation) async {
              capturedEntries = invocation.positionalArguments[0] as List<LogEntryModel>;
            });

            // Execute sync
            await service.syncFlutter(
              adapter: flutterAdapter,
              templateId: templateId,
              sourceData: sourceData,
            );

            // Property: All entries have adapter metadata
            expect(capturedEntries, isNotNull);
            for (int j = 0; j < capturedEntries!.length; j++) {
              final entry = capturedEntries![j];

              // Check _sourceAdapter
              expect(
                entry.data['_sourceAdapter'],
                equals(flutterAdapter.adapterId),
                reason: 'Entry $j should have _sourceAdapter = ${flutterAdapter.adapterId} (iteration $i)',
              );

              // Check _dedupKey is non-empty
              expect(
                entry.data['_dedupKey'],
                isNotNull,
                reason: 'Entry $j should have _dedupKey (iteration $i)',
              );
              expect(
                entry.data['_dedupKey'],
                isNotEmpty,
                reason: 'Entry $j _dedupKey should be non-empty (iteration $i)',
              );
            }

            reset(mockRepo);
          }
        },
      );

      test('JSON adapter also includes metadata', () async {
        final templateId = faker.guid.guid();
        final sourceData = [
          {'id': 'json-item-1', 'value': 100},
          {'id': 'json-item-2', 'value': 200},
        ];

        when(mockRepo.getDedupKeysForTemplate(templateId))
            .thenAnswer((_) async => <String>{});

        List<LogEntryModel>? capturedEntries;
        when(mockRepo.bulkInsert(any)).thenAnswer((invocation) async {
          capturedEntries = invocation.positionalArguments[0] as List<LogEntryModel>;
        });

        await service.syncJson(
          adapter: jsonAdapter,
          templateId: templateId,
          sourceData: sourceData,
        );

        expect(capturedEntries, isNotNull);
        for (final entry in capturedEntries!) {
          expect(entry.data['_sourceAdapter'], equals(jsonAdapter.adapterId));
          expect(entry.data['_dedupKey'], isNotNull);
          expect(entry.data['_dedupKey'], isNotEmpty);
        }
      });
    });

    group('syncJson validation', () {
      test('throws ValidationException when validation fails', () async {
        final templateId = faker.guid.guid();
        final invalidData = [
          {'id': 'item-1', 'value': 100}, // Valid
          {'id': 'item-2'}, // Missing value
          {'value': 300}, // Missing id
        ];

        expect(
          () => service.syncJson(
            adapter: jsonAdapter,
            templateId: templateId,
            sourceData: invalidData,
          ),
          throwsA(isA<ValidationException>()),
        );

        // Should not call repository methods when validation fails
        verifyNever(mockRepo.getDedupKeysForTemplate(any));
        verifyNever(mockRepo.bulkInsert(any));
      });

      test('ValidationException contains all errors', () async {
        final templateId = faker.guid.guid();
        final invalidData = [
          {'id': 'item-1'}, // Missing value
          {'value': 200}, // Missing id
        ];

        try {
          await service.syncJson(
            adapter: jsonAdapter,
            templateId: templateId,
            sourceData: invalidData,
          );
          fail('Should have thrown ValidationException');
        } on ValidationException catch (e) {
          // Each invalid item gets its own entry in the errors map
          // Total error count should be at least 2 (one per invalid item)
          expect(e.errorCount, greaterThanOrEqualTo(2));
          expect(e.hasErrors, isTrue);
        }
      });
    });
  });
}
