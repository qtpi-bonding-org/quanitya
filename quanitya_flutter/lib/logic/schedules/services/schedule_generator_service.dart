import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import '../../../infrastructure/config/debug_log.dart';
import 'package:injectable/injectable.dart';

import '../../../data/repositories/schedule_repository.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../data/interfaces/log_entry_interface.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../../../infrastructure/notifications/notification_service.dart';
import '../../../logic/log_entries/models/log_entry.dart';
import '../exceptions/schedule_exceptions.dart';
import '../models/schedule.dart';
import 'recurrence_service.dart';

const _tag = 'logic/schedules/services/schedule_generator_service';

/// Result of a todo generation run.
class GenerationResult {
  /// Number of todo entries created.
  final int todosCreated;
  
  /// Number of schedules processed.
  final int schedulesProcessed;
  
  /// Number of occurrences skipped (duplicates).
  final int skippedDuplicates;
  
  /// Schedules that failed to process (invalid RRULE, etc).
  final List<String> failedScheduleIds;

  const GenerationResult({
    required this.todosCreated,
    required this.schedulesProcessed,
    required this.skippedDuplicates,
    this.failedScheduleIds = const [],
  });

  @override
  String toString() => 'GenerationResult('
      'created: $todosCreated, '
      'processed: $schedulesProcessed, '
      'skipped: $skippedDuplicates, '
      'failed: ${failedScheduleIds.length})';
}

/// Service for generating todo entries from schedules.
/// 
/// Orchestrates between:
/// - [ScheduleRepository] - reads active schedules
/// - [LogEntryRepository] - creates todo entries, checks duplicates
/// - [RecurrenceService] - calculates occurrence dates from RRULE
/// - [NotificationService] - schedules reminders for todos
/// - [TemplateWithAestheticsRepository] - gets template names for notifications
/// 
/// Key behaviors:
/// - Idempotent: won't create duplicate todos for same scheduledFor time
/// - Backfills: generates todos from lastGeneratedAt, not just "now"
/// - Configurable horizon: default 56 days ahead
/// - Schedules notifications for todos with reminders
@lazySingleton
class ScheduleGeneratorService {
  final ScheduleRepository _scheduleRepo;
  final ILogEntryRepository _logEntryRepo;
  final RecurrenceService _recurrenceService;
  final NotificationService _notificationService;
  final TemplateWithAestheticsRepository _templateRepo;

  /// Default generation horizon (56 days = 8 weeks).
  static const defaultHorizon = Duration(days: 56);

  ScheduleGeneratorService(
    this._scheduleRepo,
    this._logEntryRepo,
    this._recurrenceService,
    this._notificationService,
    this._templateRepo,
  );

  /// Generate todos for all active schedules.
  /// 
  /// [horizon] - How far ahead to generate (default: 56 days)
  /// 
  /// This method:
  /// 1. Fetches all active schedules
  /// 2. For each, calculates occurrences from lastGeneratedAt to now+horizon
  /// 3. Creates LogEntry todos for each occurrence (skipping duplicates)
  /// 4. Updates schedule.lastGeneratedAt
  Future<GenerationResult> generatePendingTodos({
    Duration horizon = defaultHorizon,
  }) {
    return tryMethod(
      () async {
        Log.d(_tag, 'ScheduleGeneratorService: Starting generation (horizon: ${horizon.inDays} days)');
        
        // Get all active schedules needing generation
        final cutoff = DateTime.now().subtract(horizon);
        Log.d(_tag, 'ScheduleGeneratorService: Looking for schedules needing generation since $cutoff');
        final activeSchedules = await _scheduleRepo.getSchedulesNeedingGeneration(cutoff);

        if (activeSchedules.isEmpty) {
          Log.d(_tag, 'ScheduleGeneratorService: No active schedules found');
          return const GenerationResult(
            todosCreated: 0,
            schedulesProcessed: 0,
            skippedDuplicates: 0,
          );
        }

        int totalCreated = 0;
        int totalSkipped = 0;
        final failedIds = <String>[];

        Log.d(_tag, 'ScheduleGeneratorService: Found ${activeSchedules.length} active schedule(s)');
        for (final schedule in activeSchedules) {
          Log.d(_tag, 'ScheduleGeneratorService: Processing schedule ${schedule.id} '
              'for template ${schedule.templateId}, '
              'rule=${schedule.recurrenceRule}, '
              'hasReminder=${schedule.hasReminder}, '
              'reminderOffset=${schedule.reminderOffsetMinutes}, '
              'lastGenerated=${schedule.lastGeneratedAt}');
          try {
            final result = await _generateForSchedule(schedule, horizon);
            totalCreated += result.created;
            totalSkipped += result.skipped;
          } catch (e, stack) {
            Log.d(_tag, 'ScheduleGeneratorService: Failed for ${schedule.id}: $e');
            await ErrorPrivserver.captureError(e, stack, source: 'ScheduleGeneratorService');
            failedIds.add(schedule.id);
          }
        }

        Log.d(_tag, 'ScheduleGeneratorService: Done - created $totalCreated, skipped $totalSkipped');
        if (failedIds.isNotEmpty) {
          Log.d(_tag, 'ScheduleGeneratorService: WARNING - ${failedIds.length} '
              'schedule(s) failed: ${failedIds.join(', ')}');
        }

        return GenerationResult(
          todosCreated: totalCreated,
          schedulesProcessed: activeSchedules.length,
          skippedDuplicates: totalSkipped,
          failedScheduleIds: failedIds,
        );
      },
      ScheduleGenerationException.new,
      'generatePendingTodos',
    );
  }

  /// Generate todos for a specific schedule.
  /// 
  /// Useful after creating/updating a schedule.
  Future<int> generateForSchedule(String scheduleId, {Duration? horizon}) {
    return tryMethod(
      () async {
        final schedule = await _scheduleRepo.getSchedule(scheduleId);
        if (schedule == null) {
          Log.d(_tag, 'ScheduleGeneratorService: Schedule $scheduleId not found');
          return 0;
        }

        if (!schedule.isActive) {
          Log.d(_tag, 'ScheduleGeneratorService: Schedule $scheduleId is not active');
          return 0;
        }

        final result = await _generateForSchedule(schedule, horizon ?? defaultHorizon);
        return result.created;
      },
      ScheduleGenerationException.new,
      'generateForSchedule',
    );
  }

  /// Internal: generate todos for a single schedule.
  Future<_SingleScheduleResult> _generateForSchedule(
    ScheduleModel schedule,
    Duration horizon,
  ) async {
    // Determine the generation window
    // Start from lastGeneratedAt (or schedule creation) to backfill missed
    final startFrom = schedule.lastGeneratedAt ?? schedule.updatedAt;
    final endAt = DateTime.now().add(horizon);

    Log.d(_tag, 'ScheduleGeneratorService: Generation window: $startFrom → $endAt');

    // Get occurrences from RRULE
    final occurrences = _recurrenceService.getOccurrences(
      rruleString: schedule.recurrenceRule,
      start: schedule.updatedAt, // DTSTART = when schedule was created
      after: startFrom,
      before: endAt,
    );

    Log.d(_tag, 'ScheduleGeneratorService: RRULE produced ${occurrences.length} occurrence(s)');

    if (occurrences.isEmpty) {
      // Still update lastGeneratedAt to avoid re-processing
      await _scheduleRepo.markGenerated(schedule.id, DateTime.now());
      Log.d(_tag, 'ScheduleGeneratorService: No occurrences, marking as generated');
      return const _SingleScheduleResult(created: 0, skipped: 0);
    }

    // Get existing entries for this template to check duplicates
    final existingEntries = await _logEntryRepo.getUpcomingEntries(
      templateId: schedule.templateId,
    );
    final existingScheduledTimes = existingEntries
        .where((e) => e.scheduledFor != null)
        .map((e) => e.scheduledFor) // Safe: filtered for non-null above
        .whereType<DateTime>()
        .toSet();

    // Get template name for notifications (if schedule has reminders)
    String? templateName;
    if (schedule.hasReminder) {
      final templateData = await _templateRepo.findById(schedule.templateId);
      templateName = templateData?.template.name ?? 'Reminder';
    }

    int created = 0;
    int skipped = 0;

    for (final occurrence in occurrences) {
      // Check for duplicate (same template + same scheduledFor time)
      final isDuplicate = existingScheduledTimes.any(
        (existing) => _isSameMinute(existing, occurrence),
      );

      if (isDuplicate) {
        skipped++;
        continue;
      }

      // Create todo entry
      final todo = LogEntryModel.createTodo(
        templateId: schedule.templateId,
        scheduledFor: occurrence,
      );

      await _logEntryRepo.saveLogEntry(todo);
      created++;
      Log.d(_tag, 'ScheduleGeneratorService: Created todo ${todo.id} for $occurrence');

      // Schedule notification if reminder is configured
      if (schedule.hasReminder && templateName != null) {
        await _scheduleNotification(
          todo: todo,
          schedule: schedule,
          templateName: templateName,
        );
      } else {
        Log.d(_tag, 'ScheduleGeneratorService: No notification - '
            'hasReminder=${schedule.hasReminder}, templateName=$templateName');
      }
      
      // Add to set to prevent duplicates within same batch
      existingScheduledTimes.add(occurrence);
    }

    // Update lastGeneratedAt
    await _scheduleRepo.markGenerated(schedule.id, DateTime.now());

    Log.d(_tag, 'ScheduleGeneratorService: Schedule ${schedule.id} - '
        'created $created, skipped $skipped');

    return _SingleScheduleResult(created: created, skipped: skipped);
  }

  /// Schedule a notification for a todo entry.
  Future<void> _scheduleNotification({
    required LogEntryModel todo,
    required ScheduleModel schedule,
    required String templateName,
  }) async {
    final scheduledFor = todo.scheduledFor;
    final reminderOffset = schedule.reminderOffsetMinutes;
    if (scheduledFor == null || reminderOffset == null) {
      Log.d(_tag, 'ScheduleGeneratorService: Skipping notification - '
          'scheduledFor=$scheduledFor, reminderOffset=$reminderOffset');
      return;
    }

    // Calculate notification time (scheduledFor - offset)
    final notifyAt = scheduledFor.subtract(
      Duration(minutes: reminderOffset),
    );

    // Don't schedule notifications in the past
    if (notifyAt.isBefore(DateTime.now())) {
      Log.d(_tag, 'ScheduleGeneratorService: Skipping past notification - '
          'notifyAt=$notifyAt is before now=${DateTime.now()}');
      return;
    }

    // Use todo ID hash as notification ID (stable, unique per todo)
    final notificationId = todo.id.hashCode;

    Log.d(_tag, 'ScheduleGeneratorService: Scheduling notification $notificationId '
        'for "$templateName" at $notifyAt (todo=${todo.id})');

    await _notificationService.schedule(
      id: notificationId,
      title: templateName,
      body: 'Time to log your $templateName',
      scheduledAt: notifyAt,
      payload: todo.id,
      category: NotificationCategories.reminder,
    );
  }

  /// Cancel all pending notifications for a schedule's upcoming todos
  /// and optionally delete those todos.
  ///
  /// Call before deleting a schedule to clean up generated artefacts.
  Future<void> cancelForSchedule(String templateId, {bool deleteTodos = true}) async {
    final todos = await _logEntryRepo.getUpcomingEntries(templateId: templateId);
    for (final todo in todos) {
      await _notificationService.cancel(todo.id.hashCode);
    }
    if (deleteTodos) {
      for (final todo in todos) {
        await _logEntryRepo.deleteLogEntry(todo.id);
      }
    }
    Log.d(_tag, 'ScheduleGeneratorService: Cancelled ${todos.length} notification(s) '
        'for template $templateId (deletedTodos=$deleteTodos)');
  }

  /// Check if two DateTimes are the same minute (ignoring seconds/millis).
  bool _isSameMinute(DateTime a, DateTime b) {
    return a.year == b.year &&
        a.month == b.month &&
        a.day == b.day &&
        a.hour == b.hour &&
        a.minute == b.minute;
  }
}

/// Internal result for single schedule processing.
class _SingleScheduleResult {
  final int created;
  final int skipped;
  const _SingleScheduleResult({required this.created, required this.skipped});
}
