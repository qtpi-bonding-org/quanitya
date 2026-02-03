import 'package:serverpod/serverpod.dart';
import '../services/archival_service.dart';
import '../generated/protocol.dart';

/// Monthly archival future call for recurring archival tasks
/// 
/// This FutureCall implements cron-like behavior by rescheduling itself
/// after each execution. Runs on the 1st of each month at 2 AM.
class MonthlyArchivalFutureCall extends FutureCall<ArchivalScheduleData> {
  @override
  Future<void> invoke(Session session, ArchivalScheduleData? object) async {
    try {
      session.log('Starting monthly archival future call');
      
      // Run the archival process
      final archivalService = ArchivalService.fromEnvironment(session);
      final result = await archivalService.runMonthlyArchival();
      
      if (result.success) {
        session.log(
          'Monthly archival completed successfully. '
          'Users: ${result.successfulUsers}/${result.totalUsers}, '
          'Entries archived: ${result.totalEntriesArchived}'
        );
      } else {
        session.log(
          'Monthly archival failed. Errors: ${result.errors.join(', ')}',
          level: LogLevel.error,
        );
      }
      
      // Schedule next execution for the 1st of next month at 2 AM
      await _scheduleNextExecution(session);
      
    } catch (e) {
      session.log('Monthly archival future call failed: $e', level: LogLevel.error);
      
      // Still schedule next execution even if this one failed
      await _scheduleNextExecution(session);
      rethrow;
    }
  }

  /// Schedule the next monthly execution
  Future<void> _scheduleNextExecution(Session session) async {
    final now = DateTime.now();
    
    // Calculate next month's 1st day at 2 AM
    final nextMonth = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
    
    session.log('Scheduling next monthly archival for: ${nextMonth.toIso8601String()}');
    
    await session.serverpod.futureCallAtTime(
      'monthlyArchival',
      ArchivalScheduleData(
        scheduledAt: nextMonth,
        lastRun: DateTime.now(),
      ),
      nextMonth,
    );
  }

  /// Initialize the monthly archival schedule
  /// 
  /// Call this once during server startup to begin the recurring schedule
  static Future<void> initializeSchedule(Session session) async {
    final now = DateTime.now();
    
    // Calculate next execution time
    DateTime nextExecution;
    
    if (now.day == 1 && now.hour < 2) {
      // If it's the 1st and before 2 AM, schedule for today at 2 AM
      nextExecution = DateTime(now.year, now.month, 1, 2, 0, 0);
    } else {
      // Otherwise, schedule for next month's 1st at 2 AM
      nextExecution = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
    }
    
    session.log('Initializing monthly archival schedule for: ${nextExecution.toIso8601String()}');
    
    await session.serverpod.futureCallAtTime(
      'monthlyArchival',
      ArchivalScheduleData(
        scheduledAt: nextExecution,
        lastRun: null,
      ),
      nextExecution,
    );
  }
}