import 'package:drift/drift.dart' hide isNotNull;
import 'package:flutter_test/flutter_test.dart';
import 'package:powersync_sqlcipher/powersync.dart' hide Table;

import '../helpers/powersync_test_helper.dart';

/// Native PowerSync integration tests.
///
/// These tests verify that the PowerSync extension loads correctly
/// and that Drift + PowerSync work together with the real schema.
///
/// Requires: libpowersync.dylib in project root.
/// Run `scripts/setup_powersync_tests.sh` to set up.
void main() {
  late PowerSyncDatabase db;

  setUp(() async {
    db = await createTestPowerSyncDatabase();
  });

  tearDown(() async {
    await db.close();
  });

  group('PowerSync native extension', () {
    test('database initializes with schema', () async {
      // The fact that setUp succeeded means the extension loaded
      expect(db.connected, isFalse); // No connector, just local
    });

    test('can write and read from encrypted_templates table', () async {
      await db.execute(
        'INSERT INTO encrypted_templates (id, encrypted_data, updated_at) VALUES (?, ?, ?)',
        ['tmpl-1', 'encrypted-blob-data', '2026-03-12T00:00:00Z'],
      );

      final rows = await db.getAll('SELECT * FROM encrypted_templates');
      expect(rows.length, equals(1));
      expect(rows.first['id'], equals('tmpl-1'));
      expect(rows.first['encrypted_data'], equals('encrypted-blob-data'));
    });

    test('can write and read from encrypted_template_aesthetics table', () async {
      await db.execute(
        'INSERT INTO encrypted_template_aesthetics '
        '(id, encrypted_data, updated_at) '
        'VALUES (?, ?, ?)',
        [
          'aes-1',
          'encrypted-aesthetics-blob',
          '2026-03-12T00:00:00Z',
        ],
      );

      final rows = await db.getAll('SELECT * FROM encrypted_template_aesthetics');
      expect(rows.length, equals(1));
      expect(rows.first['encrypted_data'], equals('encrypted-aesthetics-blob'));
    });

    test('can write and read from notifications table', () async {
      await db.execute(
        'INSERT INTO notifications '
        '(id, title, message, type, created_at, expires_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'notif-1',
          'Welcome',
          'Hello!',
          'inform',
          '2026-03-12T00:00:00Z',
          '2026-03-19T00:00:00Z',
          '2026-03-12T00:00:00Z',
        ],
      );

      final rows = await db.getAll('SELECT * FROM notifications');
      expect(rows.length, equals(1));
      expect(rows.first['title'], equals('Welcome'));
    });

    test('ps_crud table exists (PowerSync internal)', () async {
      // PowerSync creates internal tables for CRUD tracking
      final tables = await db.getAll(
        "SELECT name FROM sqlite_master WHERE type='table' AND name LIKE 'ps_%'",
      );
      final tableNames = tables.map((r) => r['name'] as String).toList();
      expect(tableNames, contains('ps_crud'));
    });
  });

  group('PowerSync + Drift integration', () {
    test('Drift AppDatabase connects to PowerSync database', () async {
      final dbs = await createTestPowerSyncWithDrift();
      addTearDown(() async {
        await dbs.drift.close();
        await dbs.powerSync.close();
      });

      // Write via PowerSync raw SQL
      await dbs.powerSync.execute(
        'INSERT INTO notifications '
        '(id, title, message, type, created_at, expires_at, updated_at) '
        'VALUES (?, ?, ?, ?, ?, ?, ?)',
        [
          'notif-drift',
          'Drift Test',
          'Read via Drift',
          'inform',
          '2026-03-12T00:00:00Z',
          '2026-03-19T00:00:00Z',
          '2026-03-12T00:00:00Z',
        ],
      );

      // Read via Drift ORM
      final rows = await dbs.drift.customSelect(
        'SELECT * FROM notifications WHERE id = ?',
        variables: [Variable.withString('notif-drift')],
      ).get();

      expect(rows.length, equals(1));
      expect(rows.first.data['title'], equals('Drift Test'));
    });
  });
}
