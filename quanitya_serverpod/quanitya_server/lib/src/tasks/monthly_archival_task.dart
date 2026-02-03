import 'dart:io';
import 'package:serverpod/serverpod.dart';
import '../services/archival_service.dart';

/// Monthly archival background task
/// 
/// Scheduled to run monthly to archive old data to R2.
/// Archives data that's 8+ months old while keeping 6 months for PowerSync.
Future<void> runMonthlyArchival(Session session) async {
  try {
    session.log('Starting monthly archival background task');
    
    // Check if R2 is configured
    final r2AccountId = Platform.environment['R2_ACCOUNT_ID'];
    if (r2AccountId == null) {
      session.log('R2 not configured, skipping archival', level: LogLevel.warning);
      return;
    }
    
    // Run archival process
    final archivalService = ArchivalService.fromEnvironment(session);
    final result = await archivalService.runMonthlyArchival();
    
    if (result.success) {
      session.log('Monthly archival completed successfully. '
                 'Users: ${result.successfulUsers}/${result.totalUsers}, '
                 'Entries archived: ${result.totalEntriesArchived}');
    } else {
      session.log('Monthly archival failed. Errors: ${result.errors.join(', ')}', 
                 level: LogLevel.error);
    }
    
  } catch (e, stackTrace) {
    session.log('Monthly archival task crashed: $e', level: LogLevel.error);
    session.log('Stack trace: $stackTrace', level: LogLevel.error);
    rethrow; // Let Serverpod handle task failure
  }
}