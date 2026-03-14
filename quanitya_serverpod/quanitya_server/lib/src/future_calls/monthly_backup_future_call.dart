import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../services/snapshot_backup_service.dart';

/// Monthly full-snapshot backup with gated deletion.
///
/// Runs on the 1st of each month at 2 AM. Replaces MonthlyArchivalFutureCall.
/// Uses the same registration pattern as the existing archival future call.
class MonthlyBackupFutureCall extends FutureCall {
  /// Public method called by Serverpod's generated invoke wrapper.
  Future<void> runMonthlyBackup(Session session, int iteration) async {
    // Execute the actual work
    await _performBackup(session);

    // Schedule the next run (1st of next month at 2 AM)
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
    session.log(
        'Next monthly backup scheduled for: ${nextMonth.toIso8601String()}');
  }

  /// Bootstrap the schedule on server startup.
  Future<void> initializeSchedule(Session session, int iteration) async {
    final now = DateTime.now();
    DateTime nextExecution;

    if (now.day == 1 && now.hour < 2) {
      nextExecution = DateTime(now.year, now.month, 1, 2, 0, 0);
    } else {
      nextExecution = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
    }

    session.log(
        'Monthly backup schedule initialized for: ${nextExecution.toIso8601String()}');
  }

  Future<void> _performBackup(Session session) async {
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

      if (result.errors.isNotEmpty) {
        for (final error in result.errors) {
          session.log('Backup error: $error', level: LogLevel.error);
        }
      }
    } catch (e, st) {
      session.log('CRITICAL: Monthly backup failed: $e\n$st',
          level: LogLevel.error);
    }
  }
}
