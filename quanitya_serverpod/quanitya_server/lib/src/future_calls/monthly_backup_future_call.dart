import 'dart:io';

import 'package:serverpod/serverpod.dart';

import '../generated/future_calls.dart';
import '../services/snapshot_backup_service.dart';

/// Monthly full-snapshot backup with gated deletion.
///
/// Runs on the 1st of each month at 2 AM. Replaces MonthlyArchivalFutureCall.
/// Self-reschedules using the generated FutureCalls pattern.
class MonthlyBackupFutureCall extends FutureCall {
  /// Public method called by Serverpod's generated invoke wrapper.
  Future<void> runMonthlyBackup(Session session, int iteration) async {
    // Schedule next run FIRST (crash-safe)
    try {
      final now = DateTime.now();
      final nextMonth = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
      final delay = nextMonth.difference(now);

      await session.serverpod.futureCalls
          .callWithDelay(delay)
          .monthlyBackup
          .runMonthlyBackup(iteration + 1);

      session.log(
          'Next monthly backup scheduled for: ${nextMonth.toIso8601String()}');
    } catch (e) {
      session.log('Failed to schedule next monthly backup: $e',
          level: LogLevel.warning);
    }

    // Execute the actual work
    await _performBackup(session);

    session.log('Monthly backup iteration $iteration completed');
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
