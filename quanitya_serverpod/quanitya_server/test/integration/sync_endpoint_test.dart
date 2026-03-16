import 'package:serverpod/serverpod.dart';
import 'package:test/test.dart';
import 'package:uuid/uuid.dart';

import 'test_tools/serverpod_test_tools.dart';

void main() {
  withServerpod(
    'SyncEndpoint integration',
    rollbackDatabase: RollbackDatabase.afterEach,
    (sessionBuilder, endpoints) {
      const testAccountId = '42';
      late TestSessionBuilder authedSession;

      setUp(() {
        authedSession = sessionBuilder.copyWith(
          authentication: AuthenticationOverride.authenticationInfo(
            testAccountId,
            {},
          ),
        );
      });

      // ───────────────────────────────────────────────────────────────────
      // Encrypted Templates
      // ───────────────────────────────────────────────────────────────────

      group('Encrypted Templates', () {
        test('upsert inserts a new template and returns it', () async {
          final id = const Uuid().v4();
          final data = 'encrypted-template-blob-abc123';

          final result = await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            data,
          );

          expect(result.id.toString(), equals(id));
          expect(result.accountUuid, equals(testAccountId));
          expect(result.encryptedData, equals(data));
        });

        test('upsert updates an existing template', () async {
          final id = const Uuid().v4();

          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            'original-data',
          );

          final updated = await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            'updated-data',
          );

          expect(updated.encryptedData, equals('updated-data'));
        });

        test('delete removes an existing template', () async {
          final id = const Uuid().v4();
          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            'data-to-delete',
          );

          final result = await endpoints.sync.deleteEncryptedTemplate(
            authedSession,
            id,
          );

          expect(result, isTrue);
        });

        test('delete returns false for non-existent template', () async {
          final result = await endpoints.sync.deleteEncryptedTemplate(
            authedSession,
            const Uuid().v4(),
          );

          expect(result, isFalse);
        });
      });

      // ───────────────────────────────────────────────────────────────────
      // Encrypted Entries
      // ───────────────────────────────────────────────────────────────────

      group('Encrypted Entries', () {
        test('upsert inserts a new entry and returns it', () async {
          final id = const Uuid().v4();
          final data = 'encrypted-entry-blob-xyz789';

          final result = await endpoints.sync.upsertEncryptedEntry(
            authedSession,
            id,
            data,
          );

          expect(result.id.toString(), equals(id));
          expect(result.accountUuid, equals(testAccountId));
          expect(result.encryptedData, equals(data));
        });

        test('upsert updates an existing entry', () async {
          final id = const Uuid().v4();

          await endpoints.sync.upsertEncryptedEntry(
            authedSession,
            id,
            'original-entry',
          );

          final updated = await endpoints.sync.upsertEncryptedEntry(
            authedSession,
            id,
            'updated-entry',
          );

          expect(updated.encryptedData, equals('updated-entry'));
        });

        test('delete removes an existing entry', () async {
          final id = const Uuid().v4();
          await endpoints.sync.upsertEncryptedEntry(
            authedSession,
            id,
            'entry-to-delete',
          );

          final result = await endpoints.sync.deleteEncryptedEntry(
            authedSession,
            id,
          );

          expect(result, isTrue);
        });
      });

      // ───────────────────────────────────────────────────────────────────
      // Encrypted Schedules
      // ───────────────────────────────────────────────────────────────────

      group('Encrypted Schedules', () {
        test('upsert inserts a new schedule and returns it', () async {
          final id = const Uuid().v4();
          final data = 'encrypted-schedule-blob';

          final result = await endpoints.sync.upsertEncryptedSchedule(
            authedSession,
            id,
            data,
          );

          expect(result.id.toString(), equals(id));
          expect(result.accountUuid, equals(testAccountId));
          expect(result.encryptedData, equals(data));
        });

        test('upsert updates an existing schedule', () async {
          final id = const Uuid().v4();

          await endpoints.sync.upsertEncryptedSchedule(
            authedSession,
            id,
            'original-schedule',
          );

          final updated = await endpoints.sync.upsertEncryptedSchedule(
            authedSession,
            id,
            'updated-schedule',
          );

          expect(updated.encryptedData, equals('updated-schedule'));
        });

        test('delete removes an existing schedule', () async {
          final id = const Uuid().v4();
          await endpoints.sync.upsertEncryptedSchedule(
            authedSession,
            id,
            'schedule-to-delete',
          );

          final result = await endpoints.sync.deleteEncryptedSchedule(
            authedSession,
            id,
          );

          expect(result, isTrue);
        });
      });

      // ───────────────────────────────────────────────────────────────────
      // Encrypted Analysis Scripts
      // ───────────────────────────────────────────────────────────────────

      group('Encrypted Analysis Scripts', () {
        test('upsert inserts a new script and returns it', () async {
          final id = const Uuid().v4();
          final data = 'encrypted-script-blob';

          final result = await endpoints.sync.upsertEncryptedAnalysisScript(
            authedSession,
            id,
            data,
          );

          expect(result.id.toString(), equals(id));
          expect(result.accountUuid, equals(testAccountId));
          expect(result.encryptedData, equals(data));
        });

        test('upsert updates an existing script', () async {
          final id = const Uuid().v4();

          await endpoints.sync.upsertEncryptedAnalysisScript(
            authedSession,
            id,
            'original-script',
          );

          final updated = await endpoints.sync.upsertEncryptedAnalysisScript(
            authedSession,
            id,
            'updated-script',
          );

          expect(updated.encryptedData, equals('updated-script'));
        });

        test('delete removes an existing script', () async {
          final id = const Uuid().v4();
          await endpoints.sync.upsertEncryptedAnalysisScript(
            authedSession,
            id,
            'script-to-delete',
          );

          final result = await endpoints.sync.deleteEncryptedAnalysisScript(
            authedSession,
            id,
          );

          expect(result, isTrue);
        });
      });

      // ───────────────────────────────────────────────────────────────────
      // Encrypted Template Aesthetics
      // ───────────────────────────────────────────────────────────────────

      group('Encrypted Template Aesthetics', () {
        test('upsert inserts encrypted aesthetics and returns them', () async {
          final id = const Uuid().v4();
          const encryptedData = 'base64-encoded-encrypted-aesthetics-data';

          final result = await endpoints.sync.upsertEncryptedTemplateAesthetics(
            authedSession,
            id,
            encryptedData,
          );

          expect(result.id.toString(), equals(id));
          expect(result.encryptedData, equals(encryptedData));
        });

        test('upsert updates existing encrypted aesthetics', () async {
          final id = const Uuid().v4();
          const originalData = 'original-encrypted-data';
          const updatedData = 'updated-encrypted-data';

          await endpoints.sync.upsertEncryptedTemplateAesthetics(
            authedSession,
            id,
            originalData,
          );

          final updated = await endpoints.sync.upsertEncryptedTemplateAesthetics(
            authedSession,
            id,
            updatedData,
          );

          expect(updated.encryptedData, equals(updatedData));
        });

        test('delete removes existing encrypted aesthetics', () async {
          final id = const Uuid().v4();
          const encryptedData = 'encrypted-data-to-delete';

          await endpoints.sync.upsertEncryptedTemplateAesthetics(
            authedSession,
            id,
            encryptedData,
          );

          final result = await endpoints.sync.deleteEncryptedTemplateAesthetics(
            authedSession,
            id,
          );

          expect(result, isTrue);
        });
      });

      // ───────────────────────────────────────────────────────────────────
      // Storage Usage
      // ───────────────────────────────────────────────────────────────────

      group('Storage Usage', () {
        test('starts at zero for fresh account', () async {
          final usage = await endpoints.sync.getStorageUsage(authedSession);

          expect(usage.bytesUsed, equals(0));
          expect(usage.rowCount, equals(0));
        });

        test('tracks inserts across all encrypted types', () async {
          // Seed the usage record before any inserts to avoid double-counting
          // (_seedUsage scans DB rows, then incrementUsage adds on top).
          await endpoints.sync.getStorageUsage(authedSession);

          final templateData = 'template-data-100bytes-padding-here';
          final entryData = 'entry-data-200bytes-padding-here-extra';

          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            const Uuid().v4(),
            templateData,
          );
          await endpoints.sync.upsertEncryptedEntry(
            authedSession,
            const Uuid().v4(),
            entryData,
          );

          final usage = await endpoints.sync.getStorageUsage(authedSession);

          expect(usage.rowCount, equals(2));
          expect(
            usage.bytesUsed,
            equals(templateData.length + entryData.length),
          );
        });

        test('decrements after delete', () async {
          await endpoints.sync.getStorageUsage(authedSession);

          final id = const Uuid().v4();
          final data = 'some-encrypted-data';

          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            data,
          );

          final before = await endpoints.sync.getStorageUsage(authedSession);
          expect(before.rowCount, equals(1));

          await endpoints.sync.deleteEncryptedTemplate(authedSession, id);

          final after = await endpoints.sync.getStorageUsage(authedSession);
          expect(after.rowCount, equals(0));
          expect(after.bytesUsed, equals(0));
        });

        test('adjusts on update with different size data', () async {
          await endpoints.sync.getStorageUsage(authedSession);

          final id = const Uuid().v4();
          final shortData = 'short';
          final longData = 'this-is-much-longer-data-than-before';

          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            shortData,
          );

          final before = await endpoints.sync.getStorageUsage(authedSession);
          expect(before.bytesUsed, equals(shortData.length));

          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            longData,
          );

          final after = await endpoints.sync.getStorageUsage(authedSession);
          expect(after.bytesUsed, equals(longData.length));
          expect(after.rowCount, equals(1)); // still 1, was update not insert
        });
      });

      // ───────────────────────────────────────────────────────────────────
      // Account Isolation
      // ───────────────────────────────────────────────────────────────────

      group('Account Isolation', () {
        test('cannot delete another account\'s data', () async {
          final id = const Uuid().v4();

          // Account 42 creates a template
          await endpoints.sync.upsertEncryptedTemplate(
            authedSession,
            id,
            'account-42-data',
          );

          // Account 99 tries to delete it
          final otherSession = sessionBuilder.copyWith(
            authentication: AuthenticationOverride.authenticationInfo(
              '99',
              {},
            ),
          );

          final result = await endpoints.sync.deleteEncryptedTemplate(
            otherSession,
            id,
          );

          expect(result, isFalse);
        });
      });
    },
  );
}
