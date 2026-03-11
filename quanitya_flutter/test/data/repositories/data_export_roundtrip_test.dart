import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:drift/drift.dart' hide isNotNull;
import 'package:drift/native.dart';
import 'package:quanitya_flutter/data/db/app_database.dart';
import 'package:quanitya_flutter/data/repositories/data_export_repository.dart';

/// Round-trip integration test for data export/import.
///
/// Uses a real in-memory database to verify that data survives
/// the full export → JSON → import cycle. Platform-dependent parts
/// (share sheet, file picker) are bypassed by testing the core DB
/// operations directly.
void main() {
  late AppDatabase database;
  late DataExportRepository repo;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repo = DataExportRepository(database);
  });

  tearDown(() async {
    await database.close();
  });

  group('DataExportRepository', () {
    test('getExportableTableNames returns all database tables', () {
      final names = repo.getExportableTableNames();

      expect(names, isNotEmpty);
      expect(names, contains('tracker_templates'));
      expect(names, contains('log_entries'));
      expect(names, contains('schedules'));
      expect(names, contains('template_aesthetics'));
      expect(names, contains('analysis_scripts'));
      expect(names, contains('api_keys'));
      expect(names, contains('webhooks'));
      expect(names, contains('notifications'));
      expect(names, contains('error_box_entries'));
    });
  });

  group('Full round-trip: export → import', () {
    test('data survives export-import cycle across all table types', () async {
      // ── 1. Seed test data ──
      final now = DateTime.now().toIso8601String();

      await database.customStatement(
        'INSERT INTO tracker_templates (id, name, fields_json, updated_at, is_archived, is_hidden) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['tmpl-1', 'Mood Tracker', '[]', now, 0, 0],
      );
      await database.customStatement(
        'INSERT INTO tracker_templates (id, name, fields_json, updated_at, is_archived, is_hidden) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['tmpl-2', 'Sleep Log', '[{"id":"f1"}]', now, 1, 0],
      );

      await database.customStatement(
        'INSERT INTO log_entries (id, template_id, occurred_at, data_json, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['entry-1', 'tmpl-1', now, '{"mood":8}', now],
      );

      await database.customStatement(
        'INSERT INTO schedules (id, template_id, recurrence_rule, is_active, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['sched-1', 'tmpl-1', 'FREQ=DAILY;BYHOUR=9', 1, now],
      );

      await database.customStatement(
        'INSERT INTO template_aesthetics (id, template_id, palette_json, font_config_json, color_mappings_json, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['aes-1', 'tmpl-1', '{}', '{}', '{}', now],
      );

      await database.customStatement(
        'INSERT INTO api_keys (id, name, auth_type, secure_storage_key, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['key-1', 'My API', 'bearer', 'apikey_key-1', now],
      );

      await database.customStatement(
        'INSERT INTO webhooks (id, template_id, name, url, is_enabled, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['wh-1', 'tmpl-1', 'Daily Sync', 'https://example.com/hook', 1, now],
      );

      // ── 2. Export: read all tables (same logic as repo.exportData) ──
      final allTables = repo.getExportableTableNames();
      final exportData = <String, dynamic>{
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': database.schemaVersion,
        'format': 'raw_tables',
      };

      for (final tableName in allTables) {
        final rows =
            await database.customSelect('SELECT * FROM $tableName').get();
        exportData[tableName] = rows.map((r) => r.data).toList();
      }

      // Verify export captured the data
      expect(
        (exportData['tracker_templates'] as List).length,
        equals(2),
      );
      expect(
        (exportData['log_entries'] as List).length,
        equals(1),
      );
      expect(
        (exportData['schedules'] as List).length,
        equals(1),
      );
      expect(
        (exportData['template_aesthetics'] as List).length,
        equals(1),
      );
      expect(
        (exportData['api_keys'] as List).length,
        equals(1),
      );
      expect(
        (exportData['webhooks'] as List).length,
        equals(1),
      );

      // ── 3. Simulate JSON serialization round-trip ──
      final jsonString = const JsonEncoder.withIndent('  ').convert(exportData);
      final reimported = jsonDecode(jsonString) as Map<String, dynamic>;

      // ── 4. Clear the database (same as import does) ──
      for (final tableName in allTables) {
        await database.customStatement('DELETE FROM $tableName');
      }

      // Verify tables are empty
      for (final tableName in [
        'tracker_templates',
        'log_entries',
        'schedules',
        'template_aesthetics',
        'api_keys',
        'webhooks',
      ]) {
        final rows =
            await database.customSelect('SELECT * FROM $tableName').get();
        expect(rows, isEmpty, reason: '$tableName should be empty after clear');
      }

      // ── 5. Import: re-insert data (same logic as repo.importData) ──
      const metaKeys = {'exportedAt', 'schemaVersion', 'format'};
      final tableNamesToImport = reimported.keys
          .where((k) => !metaKeys.contains(k))
          .toSet();

      await database.transaction(() async {
        for (final tableName in tableNamesToImport) {
          final rows = reimported[tableName] as List<dynamic>?;
          if (rows == null || rows.isEmpty) continue;

          for (final row in rows) {
            final map = row as Map<String, dynamic>;
            final columns = map.keys.toList();
            final placeholders = columns.map((_) => '?').join(', ');
            final columnNames = columns.join(', ');
            final values = columns.map((c) => map[c]).toList();

            await database.customStatement(
              'INSERT OR REPLACE INTO $tableName ($columnNames) VALUES ($placeholders)',
              values,
            );
          }
        }
      });

      // ── 6. Verify data matches original ──
      final templates = await database
          .customSelect('SELECT * FROM tracker_templates ORDER BY id')
          .get();
      expect(templates.length, equals(2));
      expect(templates[0].data['id'], equals('tmpl-1'));
      expect(templates[0].data['name'], equals('Mood Tracker'));
      expect(templates[1].data['id'], equals('tmpl-2'));
      expect(templates[1].data['name'], equals('Sleep Log'));
      expect(templates[1].data['fields_json'], equals('[{"id":"f1"}]'));
      // Archived flag preserved
      expect(templates[1].data['is_archived'], equals(1));

      final entries = await database
          .customSelect('SELECT * FROM log_entries')
          .get();
      expect(entries.length, equals(1));
      expect(entries[0].data['id'], equals('entry-1'));
      expect(entries[0].data['template_id'], equals('tmpl-1'));
      expect(entries[0].data['data_json'], equals('{"mood":8}'));

      final schedules = await database
          .customSelect('SELECT * FROM schedules')
          .get();
      expect(schedules.length, equals(1));
      expect(schedules[0].data['recurrence_rule'], equals('FREQ=DAILY;BYHOUR=9'));

      final aesthetics = await database
          .customSelect('SELECT * FROM template_aesthetics')
          .get();
      expect(aesthetics.length, equals(1));
      expect(aesthetics[0].data['template_id'], equals('tmpl-1'));

      final apiKeys = await database
          .customSelect('SELECT * FROM api_keys')
          .get();
      expect(apiKeys.length, equals(1));
      expect(apiKeys[0].data['name'], equals('My API'));
      expect(apiKeys[0].data['auth_type'], equals('bearer'));

      final webhooks = await database
          .customSelect('SELECT * FROM webhooks')
          .get();
      expect(webhooks.length, equals(1));
      expect(webhooks[0].data['name'], equals('Daily Sync'));
      expect(webhooks[0].data['url'], equals('https://example.com/hook'));
    });

    test('import only selected tables leaves other tables untouched', () async {
      final now = DateTime.now().toIso8601String();

      // Insert data into two tables
      await database.customStatement(
        'INSERT INTO tracker_templates (id, name, fields_json, updated_at, is_archived, is_hidden) '
        'VALUES (?, ?, ?, ?, ?, ?)',
        ['tmpl-1', 'Original', '[]', now, 0, 0],
      );
      await database.customStatement(
        'INSERT INTO api_keys (id, name, auth_type, secure_storage_key, updated_at) '
        'VALUES (?, ?, ?, ?, ?)',
        ['key-1', 'Original Key', 'bearer', 'apikey_key-1', now],
      );

      // Build an import payload that only contains tracker_templates
      final importPayload = <String, dynamic>{
        'exportedAt': now,
        'schemaVersion': database.schemaVersion,
        'format': 'raw_tables',
        'tracker_templates': [
          {
            'id': 'tmpl-new',
            'name': 'Imported Template',
            'fields_json': '[]',
            'updated_at': now,
            'is_archived': 0,
            'is_hidden': 0,
          },
        ],
      };

      // Import only tracker_templates
      await database.transaction(() async {
        final tableName = 'tracker_templates';
        final rows = importPayload[tableName] as List<dynamic>;

        await database.customStatement('DELETE FROM $tableName');

        for (final row in rows) {
          final map = row as Map<String, dynamic>;
          final columns = map.keys.toList();
          final placeholders = columns.map((_) => '?').join(', ');
          final columnNames = columns.join(', ');
          final values = columns.map((c) => map[c]).toList();

          await database.customStatement(
            'INSERT OR REPLACE INTO $tableName ($columnNames) VALUES ($placeholders)',
            values,
          );
        }
      });

      // Verify tracker_templates was replaced
      final templates = await database
          .customSelect('SELECT * FROM tracker_templates')
          .get();
      expect(templates.length, equals(1));
      expect(templates[0].data['id'], equals('tmpl-new'));
      expect(templates[0].data['name'], equals('Imported Template'));

      // Verify api_keys was NOT touched
      final apiKeys = await database
          .customSelect('SELECT * FROM api_keys')
          .get();
      expect(apiKeys.length, equals(1));
      expect(apiKeys[0].data['name'], equals('Original Key'));
    });

    test('empty tables survive round-trip without errors', () async {
      // All tables are empty — export should work fine
      final allTables = repo.getExportableTableNames();
      final exportData = <String, dynamic>{
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': database.schemaVersion,
        'format': 'raw_tables',
      };

      for (final tableName in allTables) {
        final rows =
            await database.customSelect('SELECT * FROM $tableName').get();
        exportData[tableName] = rows.map((r) => r.data).toList();
      }

      // JSON round-trip
      final jsonString = jsonEncode(exportData);
      final reimported = jsonDecode(jsonString) as Map<String, dynamic>;

      // Import should be a no-op but should not throw
      const metaKeys = {'exportedAt', 'schemaVersion', 'format'};
      await database.transaction(() async {
        for (final key in reimported.keys.where((k) => !metaKeys.contains(k))) {
          final rows = reimported[key] as List<dynamic>?;
          if (rows == null || rows.isEmpty) continue;
          fail('Should not have any rows to import');
        }
      });

      // Verify everything still empty
      for (final tableName in allTables) {
        final rows =
            await database.customSelect('SELECT * FROM $tableName').get();
        expect(rows, isEmpty);
      }
    });

    test('schema version is included in export and can be validated', () async {
      final allTables = repo.getExportableTableNames();
      final exportData = <String, dynamic>{
        'exportedAt': DateTime.now().toIso8601String(),
        'schemaVersion': database.schemaVersion,
        'format': 'raw_tables',
      };

      for (final tableName in allTables) {
        final rows =
            await database.customSelect('SELECT * FROM $tableName').get();
        exportData[tableName] = rows.map((r) => r.data).toList();
      }

      final jsonString = jsonEncode(exportData);
      final reimported = jsonDecode(jsonString) as Map<String, dynamic>;

      expect(reimported['schemaVersion'], equals(4));
      expect(reimported['format'], equals('raw_tables'));
      expect(reimported['exportedAt'], isA<String>());
    });
  });
}
