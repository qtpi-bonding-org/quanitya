import 'package:faker/faker.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'package:quanitya_flutter/data/dao/log_entry_dual_dao.dart';
import 'package:quanitya_flutter/data/dao/log_entry_query_dao.dart';
import 'package:quanitya_flutter/data/dao/template_query_dao.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/repositories/log_entry_repository.dart';
import 'package:quanitya_flutter/logic/log_entries/models/log_entry.dart';

@GenerateMocks([
  LogEntryDualDao,
  LogEntryQueryDao,
  TemplateQueryDao,
  AppDatabase,
])
import 'repository_extensions_test.mocks.dart';

const int kPropertyTestIterations = 5;

void main() {
  final faker = Faker();

  group('LogEntryRepository Ingestion Extensions', () {
    late MockLogEntryDualDao mockWriteDao;
    late MockLogEntryQueryDao mockQueryDao;
    late MockTemplateQueryDao mockTemplateQueryDao;
    late MockAppDatabase mockDb;
    late LogEntryRepository repository;

    setUp(() {
      mockWriteDao = MockLogEntryDualDao();
      mockQueryDao = MockLogEntryQueryDao();
      mockTemplateQueryDao = MockTemplateQueryDao();
      mockDb = MockAppDatabase();
      repository = LogEntryRepository(
        mockWriteDao,
        mockQueryDao,
        mockTemplateQueryDao,
        mockDb,
      );
    });

    group('getDedupKeysForTemplate', () {
      test('returns empty set when no entries exist', () async {
        const templateId = 'template-123';
        when(mockQueryDao.findByTemplateId(templateId))
            .thenAnswer((_) async => []);

        final result = await repository.getDedupKeysForTemplate(templateId);

        expect(result, isEmpty);
        verify(mockQueryDao.findByTemplateId(templateId)).called(1);
      });

      test('extracts _dedupKey from entry data', () async {
        const templateId = 'template-123';
        final entries = [
          LogEntryModel.logNow(
            templateId: templateId,
            data: {'_dedupKey': 'key-1', 'value': 100},
          ),
          LogEntryModel.logNow(
            templateId: templateId,
            data: {'_dedupKey': 'key-2', 'value': 200},
          ),
          LogEntryModel.logNow(
            templateId: templateId,
            data: {'value': 300}, // No dedup key
          ),
        ];
        when(mockQueryDao.findByTemplateId(templateId))
            .thenAnswer((_) async => entries);

        final result = await repository.getDedupKeysForTemplate(templateId);

        expect(result, equals({'key-1', 'key-2'}));
      });

      test('ignores empty and null dedup keys', () async {
        const templateId = 'template-123';
        final entries = [
          LogEntryModel.logNow(
            templateId: templateId,
            data: {'_dedupKey': 'valid-key', 'value': 100},
          ),
          LogEntryModel.logNow(
            templateId: templateId,
            data: {'_dedupKey': '', 'value': 200}, // Empty string
          ),
          LogEntryModel.logNow(
            templateId: templateId,
            data: {'_dedupKey': null, 'value': 300}, // Null
          ),
        ];
        when(mockQueryDao.findByTemplateId(templateId))
            .thenAnswer((_) async => entries);

        final result = await repository.getDedupKeysForTemplate(templateId);

        expect(result, equals({'valid-key'}));
      });
    });

    group('Property 8: Repository bulkInsert persists entries', () {
      test(
        '**Feature: data-ingestion-pipeline, Property 8: Repository bulkInsert persists entries** - '
        '**Validates: Requirements 9.2**',
        () async {
          for (int i = 0; i < kPropertyTestIterations; i++) {
            // Generate random entries
            final templateId = faker.guid.guid();
            final entryCount = faker.randomGenerator.integer(5, min: 1);
            final entries = List.generate(
              entryCount,
              (j) => LogEntryModel.logNow(
                templateId: templateId,
                data: {
                  'value': faker.randomGenerator.integer(1000),
                  '_sourceAdapter': 'test.adapter',
                  '_dedupKey': faker.guid.guid(),
                },
              ),
            );

            // Mock the conversion and bulkUpsert
            for (final entry in entries) {
              final entity = LogEntry(
                id: entry.id,
                templateId: entry.templateId,
                scheduledFor: entry.scheduledFor,
                occurredAt: entry.occurredAt,
                dataJson: '{}',
                updatedAt: entry.updatedAt,
              );
              when(mockWriteDao.modelToEntity(entry)).thenReturn(entity);
            }
            when(mockWriteDao.bulkUpsert(any)).thenAnswer((_) async => []);

            // Execute bulkInsert
            await repository.bulkInsert(entries);

            // Property: bulkUpsert should be called with all entities
            verify(mockWriteDao.bulkUpsert(any)).called(1);
          }
        },
      );

      test('bulkInsert handles empty list gracefully', () async {
        await repository.bulkInsert([]);

        // Should not call bulkUpsert for empty list
        verifyNever(mockWriteDao.bulkUpsert(any));
      });
    });
  });
}
