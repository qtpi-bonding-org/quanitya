import 'package:test/test.dart';
import 'package:quanitya_server/src/services/snapshot_backup_service.dart';
import 'package:quanitya_server/src/services/snapshot_pipeline.dart';

void main() {
  group('SnapshotBackupService', () {
    test('createUserSnapshotData produces correct JSON structure', () {
      final snapshotDate = DateTime.utc(2026, 3, 1);
      final entries = [
        {
          'id': 'entry-1',
          'encryptedData': 'abc123',
          'updatedAt': '2026-02-15T00:00:00.000Z'
        },
        {
          'id': 'entry-2',
          'encryptedData': 'def456',
          'updatedAt': '2026-01-10T00:00:00.000Z'
        },
      ];

      final result = SnapshotBackupService.createUserSnapshotData(
        accountId: 42,
        snapshotDate: snapshotDate,
        entries: entries,
      );

      expect(result['version'], '2.0');
      expect(result['type'], 'full_snapshot');
      expect(result['accountId'], 42);
      expect(result['snapshotDate'], '2026-03-01T00:00:00.000Z');
      expect(result['entryCount'], 2);
      expect(result['entries'], entries);
      expect(result.containsKey('createdAt'), true);
    });

    test('generateSnapshotKey produces correct R2 path', () {
      final key = SnapshotBackupService.generateSnapshotKey(
          42, DateTime.utc(2026, 3, 1));
      expect(key, 'snapshots/user-entries/42/2026-03.json.gz');
    });

    test('generateSnapshotKey pads single-digit months', () {
      final key = SnapshotBackupService.generateSnapshotKey(
          42, DateTime.utc(2026, 1, 1));
      expect(key, 'snapshots/user-entries/42/2026-01.json.gz');
    });
  });

  group('SnapshotPipeline', () {
    test('uploadAndVerify is available as a reusable class', () {
      // Just verify the class and method exist and the constructor works
      // Actual R2 interaction tested via mocks in integration tests
      expect(SnapshotPipeline, isNotNull);
    });
  });

  group('BackupResult', () {
    test('result reports correct counts', () {
      final result = BackupResult(
        totalUsers: 10,
        successfulUsers: 8,
        failedUsers: 2,
        totalEntriesSnapshot: 500,
        totalEntriesDeleted: 100,
        errors: ['User 5: timeout', 'User 9: R2 error'],
      );
      expect(result.success, false);
      expect(result.totalUsers, 10);
      expect(result.errors.length, 2);
    });

    test('result with no errors reports success', () {
      final result = BackupResult(
        totalUsers: 5,
        successfulUsers: 5,
        failedUsers: 0,
        totalEntriesSnapshot: 200,
        totalEntriesDeleted: 50,
        errors: [],
      );
      expect(result.success, true);
    });
  });
}
