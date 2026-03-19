import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/dao/fts_search_dao.dart';

void main() {
  late AppDatabase database;
  late FtsSearchDao ftsDao;

  setUp(() async {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    ftsDao = FtsSearchDao(database);
    await ftsDao.ensureTable();
  });

  tearDown(() async {
    await database.close();
  });

  /// Helper: insert a template and return its ID
  Future<String> insertTemplate({
    String id = 'template-1',
    List<Map<String, dynamic>>? fields,
  }) async {
    final defaultFields = [
      {'id': 'field-notes', 'label': 'Notes', 'type': 'text'},
      {'id': 'field-mood', 'label': 'Mood Score', 'type': 'integer'},
    ];
    await database.into(database.trackerTemplates).insert(
      TrackerTemplatesCompanion.insert(
        id: id,
        name: 'Test Template',
        fieldsJson: jsonEncode(fields ?? defaultFields),
        updatedAt: DateTime.now(),
        isArchived: const Value(false),
        isHidden: const Value(false),
      ),
    );
    return id;
  }

  /// Helper: insert a log entry and return its ID
  Future<String> insertEntry({
    String id = 'entry-1',
    String templateId = 'template-1',
    required Map<String, dynamic> data,
  }) async {
    await database.into(database.logEntries).insert(
      LogEntriesCompanion.insert(
        id: id,
        templateId: templateId,
        dataJson: jsonEncode(data),
        updatedAt: DateTime.now(),
        occurredAt: Value(DateTime.now()),
      ),
    );
    return id;
  }

  group('FTS triggers', () {
    test('INSERT trigger indexes entry text', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'Had coffee with Sarah at the park'},
      );

      final results = await ftsDao.search('coffee');
      expect(results, ['entry-1']);
    });

    test('search finds partial words with prefix query', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'Beautiful morning walk'},
      );

      final results = await ftsDao.search('beauti*');
      expect(results, ['entry-1']);
    });

    test('search is case-insensitive', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'COFFEE with Sarah'},
      );

      final results = await ftsDao.search('coffee');
      expect(results, ['entry-1']);
    });

    test('search returns empty for no match', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'Had tea with Bob'},
      );

      final results = await ftsDao.search('coffee');
      expect(results, isEmpty);
    });

    test('search returns empty for empty query', () async {
      final results = await ftsDao.search('');
      expect(results, isEmpty);
    });

    test('search returns empty for whitespace query', () async {
      final results = await ftsDao.search('   ');
      expect(results, isEmpty);
    });

    test('UPDATE trigger re-indexes on data change', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'Had coffee'},
      );

      // Verify initial index
      expect(await ftsDao.search('coffee'), ['entry-1']);

      // Update the entry's data
      await (database.update(database.logEntries)
            ..where((t) => t.id.equals('entry-1')))
          .write(LogEntriesCompanion(
        dataJson: Value(jsonEncode({'field-notes': 'Had tea instead'})),
      ));

      // Old text gone, new text found
      expect(await ftsDao.search('coffee'), isEmpty);
      expect(await ftsDao.search('tea'), ['entry-1']);
    });

    test('DELETE trigger removes from index', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'Had coffee'},
      );

      expect(await ftsDao.search('coffee'), ['entry-1']);

      // Delete the entry
      await (database.delete(database.logEntries)
            ..where((t) => t.id.equals('entry-1')))
          .go();

      expect(await ftsDao.search('coffee'), isEmpty);
    });

    test('multiple entries ranked by relevance', () async {
      await insertTemplate();
      await insertEntry(
        id: 'entry-1',
        data: {'field-notes': 'coffee'},
      );
      await insertEntry(
        id: 'entry-2',
        data: {'field-notes': 'coffee coffee coffee is great'},
      );
      await insertEntry(
        id: 'entry-3',
        data: {'field-notes': 'no match here'},
      );

      final results = await ftsDao.search('coffee');
      expect(results, hasLength(2));
      expect(results, containsAll(['entry-1', 'entry-2']));
      // entry-2 should rank higher (more occurrences)
      expect(results.first, 'entry-2');
    });

    test('empty data_json is not indexed', () async {
      await insertTemplate();
      await database.into(database.logEntries).insert(
        LogEntriesCompanion.insert(
          id: 'entry-empty',
          templateId: 'template-1',
          dataJson: '{}',
          updatedAt: DateTime.now(),
          occurredAt: Value(DateTime.now()),
        ),
      );

      // FTS table should have no rows for this entry
      final count = await database.customSelect(
        'SELECT COUNT(*) AS cnt FROM log_entry_fts WHERE entry_id = ?',
        variables: [Variable.withString('entry-empty')],
      ).getSingle();
      expect(count.read<int>('cnt'), 0);
    });
  });

  group('rebuildIfEmpty', () {
    test('rebuilds when FTS empty but entries exist', () async {
      await insertTemplate();
      await insertEntry(
        data: {'field-notes': 'Had coffee'},
      );

      // Clear FTS manually (simulate new device where triggers
      // weren't set up when entries arrived)
      await database.customStatement('DELETE FROM log_entry_fts');
      expect(await ftsDao.search('coffee'), isEmpty);

      // Rebuild should restore the index
      await ftsDao.rebuildIfEmpty();
      expect(await ftsDao.search('coffee'), ['entry-1']);
    });

    test('skips rebuild when FTS already has data', () async {
      await insertTemplate();
      await insertEntry(
        id: 'entry-1',
        data: {'field-notes': 'Had coffee'},
      );

      // FTS has data from trigger — rebuildIfEmpty should be a no-op
      // (We verify by checking it doesn't throw or change results)
      await ftsDao.rebuildIfEmpty();
      expect(await ftsDao.search('coffee'), ['entry-1']);
    });

    test('skips rebuild when no entries exist', () async {
      // No entries, no FTS data — should be a no-op
      await ftsDao.rebuildIfEmpty();
      // Just verify it doesn't throw
    });
  });

  group('rebuildAll', () {
    test('reindexes everything from scratch', () async {
      await insertTemplate();
      await insertEntry(
        id: 'entry-1',
        data: {'field-notes': 'Had coffee'},
      );
      await insertEntry(
        id: 'entry-2',
        data: {'field-notes': 'Went for a walk'},
      );

      // Corrupt the FTS index
      await database.customStatement('DELETE FROM log_entry_fts');

      await ftsDao.rebuildAll();

      expect(await ftsDao.search('coffee'), ['entry-1']);
      expect(await ftsDao.search('walk'), ['entry-2']);
    });
  });
}
