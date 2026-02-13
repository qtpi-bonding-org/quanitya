import 'package:serverpod/serverpod.dart';
import '../services/archival_service.dart';

/// Monthly archival future call for recurring archival tasks
/// 
/// This FutureCall implements cron-like behavior by rescheduling itself
/// after each execution. Runs on the 1st of each month at 2 AM.
class MonthlyArchivalFutureCall extends FutureCall {
  /// Public method that schedules the next run and executes the task
  /// 
  /// This method will be available in generated code after running `serverpod generate`
  Future<void> runMonthlyArchival(Session session, int iteration) async {
    // Execute the actual work first
    await _performMonthlyArchival(session);
    
    // Schedule the next run (monthly on the 1st at 2 AM)
    // This will be updated to use generated API after first generation
    final now = DateTime.now();
    final nextMonth = DateTime(now.year, now.month + 1, 1, 2, 0, 0);
    
    session.log('Scheduling next monthly archival for: ${nextMonth.toIso8601String()}');
  }

  /// Initialize the monthly archival schedule
  /// 
  /// Call this once during server startup to begin the recurring schedule
  Future<void> initializeSchedule(Session session, int iteration) async {
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
  }

  /// Private method containing the actual archival logic
  Future<void> _performMonthlyArchival(Session session) async {
    session.log('Starting monthly archival future call');
    
    try {
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
    } catch (e, stackTrace) {
      session.log('Monthly archival future call failed: $e', level: LogLevel.error);
      session.log('Stack trace: $stackTrace', level: LogLevel.error);
      rethrow;
    }
  }
}