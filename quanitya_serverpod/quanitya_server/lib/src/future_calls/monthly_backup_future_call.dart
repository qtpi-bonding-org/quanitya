import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../services/snapshot_backup_service.dart';

/// Abstract monthly full-snapshot backup future call.
///
/// Defines the shared backup logic. Concrete subclasses are created in each
/// server project (community standalone and cloud) so that `serverpod generate`
/// produces the typed dispatch for that server's `type`.
///
/// This is the Serverpod-recommended pattern for modules that expose future
/// calls: the module defines an `abstract` FutureCall and consuming servers
/// provide concrete implementations.
abstract class MonthlyBackupFutureCall extends FutureCall {
  /// The name used to register this future call for scheduling.
  static const String callName = 'MonthlyBackupFutureCall';

  /// Perform the backup. Called by [runMonthlyBackup] after scheduling.
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
  /// Self-scheduling is the responsibility of the concrete subclass or the
  /// server's registration code, since it depends on the generated dispatch
  /// (for `type: server`) or legacy API (for `type: module` standalone).
  Future<void> runMonthlyBackup(Session session, int iteration) async {
    await performBackup(session);
    session.log('Monthly backup iteration $iteration completed');
  }
}
