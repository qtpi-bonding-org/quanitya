import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../services/snapshot_backup_service.dart';

/// Abstract monthly full-snapshot backup future call.
///
/// Defines the shared backup logic. Concrete subclasses are created in each
/// server project (cloud) so that `serverpod generate` produces the typed
/// dispatch for that server.
abstract class MonthlyBackupFutureCall extends FutureCall {
  /// Perform the backup. Called by [runMonthlyBackup].
  ///
  /// Subclasses can override to use a different backup service.
  Future<void> performBackup(Session session) async {
    final r2AccountId = Platform.environment['R2_ACCOUNT_ID'];
    if (r2AccountId == null || r2AccountId.isEmpty) {
      session.log('R2 not configured — skipping monthly backup',
          level: LogLevel.warning);
      return;
    }

    try {
      final service = SnapshotBackupService.fromEnvironment(session);
      final result = await service.runMonthlyBackup();

      session.log(result.summary);

      for (final error in result.errors) {
        session.log('Backup error: $error', level: LogLevel.error);
      }
    } catch (e, st) {
      session.log('CRITICAL: Monthly backup failed: $e\n$st',
          level: LogLevel.error);
    }
  }

  /// Run the backup and log completion.
  ///
  /// Self-scheduling is the responsibility of the concrete subclass.
  Future<void> runMonthlyBackup(Session session) async {
    await performBackup(session);
    session.log('Monthly backup completed');
  }
}
