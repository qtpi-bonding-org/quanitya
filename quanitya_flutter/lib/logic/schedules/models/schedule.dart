import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'schedule.freezed.dart';
part 'schedule.g.dart';

/// Represents a recurring schedule - "WHEN" to remind user to log.
/// 
/// Links to a TrackerTemplate (the "WHAT") and generates LogEntry todos
/// based on the recurrence rule. One template can have multiple schedules.
/// 
/// Example use cases:
/// - "Log my mood daily at 9am"
/// - "Weekly workout summary every Sunday at 6pm"
/// - "Medication reminder every 8 hours"
@freezed
abstract class ScheduleModel with _$ScheduleModel {
  const ScheduleModel._();
  
  const factory ScheduleModel({
    /// Unique identifier for this schedule (UUID format)
    required String id,
    
    /// FK to TrackerTemplate - defines what to log
    required String templateId,
    
    /// RRULE string defining the recurrence pattern
    /// See: https://icalendar.org/iCalendar-RFC-5545/3-8-5-3-recurrence-rule.html
    /// Examples:
    /// - "FREQ=DAILY;BYHOUR=9" (daily at 9am)
    /// - "FREQ=WEEKLY;BYDAY=MO,WE,FR" (Mon/Wed/Fri)
    /// - "FREQ=MONTHLY;BYMONTHDAY=1" (1st of each month)
    required String recurrenceRule,
    
    /// Minutes before due time to send notification (null = no reminder)
    /// Examples: 0 = at due time, 15 = 15 min before, 60 = 1 hour before
    int? reminderOffsetMinutes,
    
    /// Whether this schedule is active (can pause without deleting)
    @Default(true) bool isActive,
    
    /// Last time entries were generated from this schedule
    /// Used for incremental generation to avoid duplicates
    DateTime? lastGeneratedAt,
    
    /// Timestamp of last modification
    required DateTime updatedAt,
  }) = _ScheduleModel;
  
  /// Creates a ScheduleModel from JSON map
  factory ScheduleModel.fromJson(Map<String, dynamic> json) => 
      _$ScheduleModelFromJson(json);
  
  // ─────────────────────────────────────────────────────────────────────────
  // Factory Constructors
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Create a new schedule with generated UUID
  factory ScheduleModel.create({
    required String templateId,
    required String recurrenceRule,
    int? reminderOffsetMinutes,
    bool isActive = true,
  }) {
    return ScheduleModel(
      id: const Uuid().v4(),
      templateId: templateId,
      recurrenceRule: recurrenceRule,
      reminderOffsetMinutes: reminderOffsetMinutes,
      isActive: isActive,
      lastGeneratedAt: null,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a simple daily schedule
  factory ScheduleModel.daily({
    required String templateId,
    required int hour,
    int minute = 0,
    int? reminderOffsetMinutes,
  }) {
    final rule = 'FREQ=DAILY;BYHOUR=$hour;BYMINUTE=$minute';
    return ScheduleModel.create(
      templateId: templateId,
      recurrenceRule: rule,
      reminderOffsetMinutes: reminderOffsetMinutes,
    );
  }
  
  /// Create a weekly schedule on specific days
  factory ScheduleModel.weekly({
    required String templateId,
    required List<String> days, // MO, TU, WE, TH, FR, SA, SU
    required int hour,
    int minute = 0,
    int? reminderOffsetMinutes,
  }) {
    final daysStr = days.join(',');
    final rule = 'FREQ=WEEKLY;BYDAY=$daysStr;BYHOUR=$hour;BYMINUTE=$minute';
    return ScheduleModel.create(
      templateId: templateId,
      recurrenceRule: rule,
      reminderOffsetMinutes: reminderOffsetMinutes,
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Computed Properties
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Whether this schedule has a reminder configured
  bool get hasReminder => reminderOffsetMinutes != null;
  
  /// Human-readable description of reminder timing
  String? get reminderDescription {
    final offset = reminderOffsetMinutes;
    if (offset == null) return null;
    if (offset == 0) return 'At due time';
    if (offset < 60) return '$offset min before';
    final hours = offset ~/ 60;
    final mins = offset % 60;
    if (mins == 0) return '$hours hour${hours > 1 ? 's' : ''} before';
    return '$hours hour${hours > 1 ? 's' : ''} $mins min before';
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Pause this schedule
  ScheduleModel pause() => copyWith(isActive: false, updatedAt: DateTime.now());
  
  /// Resume this schedule
  ScheduleModel resume() => copyWith(isActive: true, updatedAt: DateTime.now());
  
  /// Mark that entries have been generated up to this point
  ScheduleModel markGenerated(DateTime generatedAt) => 
      copyWith(lastGeneratedAt: generatedAt, updatedAt: DateTime.now());
  
  /// Update the recurrence rule
  ScheduleModel updateRule(String newRule) => 
      copyWith(recurrenceRule: newRule, updatedAt: DateTime.now());
  
  /// Update reminder offset
  ScheduleModel updateReminder(int? offsetMinutes) => 
      copyWith(reminderOffsetMinutes: offsetMinutes, updatedAt: DateTime.now());
}
