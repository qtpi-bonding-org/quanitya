import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../generated/protocol.dart';
import 'snapshot_pipeline.dart';

/// Full snapshot backup service for user data.
///
/// Creates monthly full snapshots of all user entries to R2,
/// then deletes entries older than the retention threshold
/// only after verifying the backup exists.
class SnapshotBackupService {
  final Session _session;
  final SnapshotPipeline _pipeline;
  final int _bufferMonths;
  final int _concurrency;

  SnapshotBackupService(
    this._session,
    this._pipeline, {
    int? bufferMonths,
    int? concurrency,
  })  : _bufferMonths = bufferMonths ??
            int.tryParse(
                    Platform.environment['ARCHIVE_BUFFER_MONTHS'] ?? '') ??
                6,
        _concurrency = concurrency ??
            int.tryParse(
                    Platform.environment['BACKUP_CONCURRENCY'] ?? '') ??
                20;

  /// Create the JSON data structure for a user snapshot.
  static Map<String, dynamic> createUserSnapshotData({
    required String accountUuid,
    required DateTime snapshotDate,
    required List<Map<String, dynamic>> entries,
  }) {
    return {
      'version': '2.0',
      'type': 'full_snapshot',
      'accountUuid': accountUuid,
      'snapshotDate': snapshotDate.toIso8601String(),
      'entryCount': entries.length,
      'entries': entries,
      'createdAt': DateTime.now().toUtc().toIso8601String(),
    };
  }

  /// Generate R2 key for a user snapshot.
  static String generateSnapshotKey(String accountUuid, DateTime snapshotDate) {
    final year = snapshotDate.year;
    final month = snapshotDate.month.toString().padLeft(2, '0');
    return 'snapshots/user-entries/$accountUuid/$year-$month.json.gz';
  }

  /// Backup a single user's entries and delete old ones.
  ///
  /// Returns the number of entries in the snapshot, or -1 if backup failed.
  Future<int> backupUser(String accountUuid, DateTime snapshotDate) async {
    try {
      // 1. Query all entries for this user
      final entries = await _getAllUserEntries(accountUuid);
      if (entries.isEmpty) {
        _session.log('No entries for user $accountUuid, skipping snapshot');
        return 0;
      }

      // 2. Create snapshot data
      final snapshotData = createUserSnapshotData(
        accountUuid: accountUuid,
        snapshotDate: snapshotDate,
        entries: entries,
      );
      final key = generateSnapshotKey(accountUuid, snapshotDate);

      // 3. Compress, upload, and verify via pipeline
      final verified = await _pipeline.uploadAndVerify(key, snapshotData);
      if (!verified) {
        _session.log(
          'Snapshot verification failed for user $accountUuid — skipping deletion',
          level: LogLevel.error,
        );
        return -1;
      }

      // 5. Delete old entries (gated on verified backup)
      final deleted = await _deleteOldEntries(accountUuid, snapshotDate);
      _session.log(
          'User $accountUuid: snapshot=${entries.length} entries, deleted=$deleted old entries');

      return entries.length;
    } catch (e) {
      _session.log('Backup failed for user $accountUuid: $e',
          level: LogLevel.error);
      return -1;
    }
  }

  /// Run monthly backup for all users with parallel processing.
  Future<BackupResult> runMonthlyBackup() async {
    final snapshotDate = DateTime.now().toUtc();
    _session.log('Starting monthly snapshot backup...');

    // Get all unique user IDs
    final userIds = await _getAllUserIds();
    _session.log('Found ${userIds.length} users to backup');

    if (userIds.isEmpty) {
      return BackupResult(
        totalUsers: 0,
        successfulUsers: 0,
        failedUsers: 0,
        totalEntriesSnapshot: 0,
        totalEntriesDeleted: 0,
        errors: [],
      );
    }

    int successfulUsers = 0;
    int failedUsers = 0;
    int totalEntries = 0;
    final errors = <String>[];

    // Process in parallel batches
    for (var i = 0; i < userIds.length; i += _concurrency) {
      final batch = userIds.skip(i).take(_concurrency).toList();
      final results = await Future.wait(
        batch.map((id) => backupUser(id, snapshotDate)),
        eagerError: false,
      );

      for (var j = 0; j < results.length; j++) {
        if (results[j] >= 0) {
          successfulUsers++;
          totalEntries += results[j];
        } else {
          failedUsers++;
          errors.add('User ${batch[j]}: backup failed');
        }
      }
    }

    return BackupResult(
      totalUsers: userIds.length,
      successfulUsers: successfulUsers,
      failedUsers: failedUsers,
      totalEntriesSnapshot: totalEntries,
      totalEntriesDeleted: 0,
      errors: errors,
    );
  }

  /// Query all encrypted entries for a user.
  Future<List<Map<String, dynamic>>> _getAllUserEntries(String accountUuid) async {
    final entries = await EncryptedEntry.db.find(
      _session,
      where: (t) => t.accountUuid.equals(accountUuid),
    );
    return entries.map((e) => e.toJson()).toList();
  }

  /// Delete entries older than the retention threshold.
  Future<int> _deleteOldEntries(String accountUuid, DateTime snapshotDate) async {
    final cutoff = DateTime.utc(
      snapshotDate.year,
      snapshotDate.month - _bufferMonths,
      snapshotDate.day,
    );
    final deleted = await EncryptedEntry.db.deleteWhere(
      _session,
      where: (t) =>
          t.accountUuid.equals(accountUuid) & (t.updatedAt < cutoff),
    );
    return deleted.length;
  }

  /// Get all unique account IDs that have entries.
  Future<List<String>> _getAllUserIds() async {
    final result = await _session.db.unsafeQuery(
      'SELECT DISTINCT "accountUuid" FROM "encrypted_entries" ORDER BY "accountUuid"',
    );
    return result.map((row) => row[0] as String).toList();
  }

  /// Create snapshot backup service from environment.
  static SnapshotBackupService fromEnvironment(Session session) {
    return SnapshotBackupService(
        session, SnapshotPipeline.fromEnvironment(session));
  }
}

/// Result of the monthly backup process.
class BackupResult {
  final int totalUsers;
  final int successfulUsers;
  final int failedUsers;
  final int totalEntriesSnapshot;
  final int totalEntriesDeleted;
  final List<String> errors;

  BackupResult({
    required this.totalUsers,
    required this.successfulUsers,
    required this.failedUsers,
    required this.totalEntriesSnapshot,
    required this.totalEntriesDeleted,
    required this.errors,
  });

  bool get success => errors.isEmpty;

  String get summary =>
      'Backup complete: $successfulUsers/$totalUsers users, '
      '$totalEntriesSnapshot entries snapshot, '
      '$totalEntriesDeleted old entries deleted, '
      '${errors.length} errors';
}
