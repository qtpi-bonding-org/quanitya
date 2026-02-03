import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:uuid/uuid.dart';

part 'log_entry.freezed.dart';
part 'log_entry.g.dart';

/// Temporal state of a log entry
enum EntryState {
  /// Scheduled for future, not yet done
  todo,
  /// Was scheduled for past, not done (overdue)
  missed,
  /// Has occurred (either ad-hoc or completed todo)
  logged,
}

/// Represents a data record created from a TrackerTemplateModel.
/// 
/// Supports three temporal states via two nullable timestamps:
/// - **TODO**: scheduledFor is future, occurredAt is null
/// - **MISSED**: scheduledFor is past, occurredAt is null  
/// - **LOGGED**: occurredAt is not null (ad-hoc or completed todo)
///
/// ## Validation Rules
/// - At least one of scheduledFor/occurredAt must be non-null
/// - occurredAt cannot be in the future
@freezed
class LogEntryModel with _$LogEntryModel {
  const LogEntryModel._();
  
  const factory LogEntryModel({
    /// Unique identifier for this entry (UUID format)
    required String id,
    
    /// Foreign key reference to the TrackerTemplateModel this entry belongs to
    required String templateId,
    
    /// When this entry is/was scheduled for (due date for todos)
    /// Null for ad-hoc logging without prior scheduling
    DateTime? scheduledFor,
    
    /// When this entry actually occurred/was completed
    /// Null for todos that haven't been done yet
    DateTime? occurredAt,
    
    /// Dynamic data payload containing the actual recorded values
    required Map<String, dynamic> data,
    
    /// Timestamp of last modification (for E2EE sync conflict resolution)
    required DateTime updatedAt,
  }) = _LogEntryModel;
  
  /// Creates a LogEntryModel from JSON map
  factory LogEntryModel.fromJson(Map<String, dynamic> json) => 
      _$LogEntryModelFromJson(json);
  
  // ─────────────────────────────────────────────────────────────────────────
  // Factory Constructors
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Create an ad-hoc log entry (logging something now, no prior scheduling)
  factory LogEntryModel.logNow({
    required String templateId,
    required Map<String, dynamic> data,
    DateTime? occurredAt,
  }) {
    final now = occurredAt ?? DateTime.now();
    _validateOccurredAt(now);
    return LogEntryModel(
      id: const Uuid().v4(),
      templateId: templateId,
      scheduledFor: null,
      occurredAt: now,
      data: data,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create a todo entry (scheduled for future)
  factory LogEntryModel.createTodo({
    required String templateId,
    required DateTime scheduledFor,
    Map<String, dynamic> data = const {},
  }) {
    return LogEntryModel(
      id: const Uuid().v4(),
      templateId: templateId,
      scheduledFor: scheduledFor,
      occurredAt: null,
      data: data,
      updatedAt: DateTime.now(),
    );
  }
  
  /// Create an empty log entry (for form initialization)
  factory LogEntryModel.empty({
    required String templateId,
  }) {
    final now = DateTime.now();
    return LogEntryModel(
      id: const Uuid().v4(),
      templateId: templateId,
      scheduledFor: null,
      occurredAt: now,
      data: {},
      updatedAt: now,
    );
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // State Derivation
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Get the current temporal state of this entry
  EntryState get state {
    // If occurred, it's logged (regardless of schedule)
    if (occurredAt != null) return EntryState.logged;
    
    // Not occurred yet - check schedule
    // scheduledFor must be non-null here since validate() ensures at least one is set
    final scheduled = scheduledFor;
    if (scheduled == null) {
      // Defensive: should never happen due to validation
      return EntryState.logged;
    }
    final now = DateTime.now();
    if (scheduled.isBefore(now)) return EntryState.missed;
    return EntryState.todo;
  }
  
  /// Whether this entry is completed/logged
  bool get isCompleted => occurredAt != null;
  
  /// Whether this entry is a pending todo
  bool get isTodo => state == EntryState.todo;
  
  /// Whether this entry is overdue/missed
  bool get isMissed => state == EntryState.missed;
  
  /// Whether this was completed on time (only meaningful if both dates set)
  bool? get wasOnTime {
    final occurred = occurredAt;
    final scheduled = scheduledFor;
    if (occurred == null || scheduled == null) return null;
    return !occurred.isAfter(scheduled);
  }
  
  /// How early/late this was completed (positive = late, negative = early)
  Duration? get completionDelta {
    final occurred = occurredAt;
    final scheduled = scheduledFor;
    if (occurred == null || scheduled == null) return null;
    return occurred.difference(scheduled);
  }
  
  /// The primary display timestamp (occurredAt if logged, scheduledFor if todo)
  /// Throws if both are null (should never happen due to validation)
  DateTime get displayTimestamp {
    final occurred = occurredAt;
    if (occurred != null) return occurred;
    final scheduled = scheduledFor;
    if (scheduled != null) return scheduled;
    // Defensive: validation ensures at least one is set
    throw StateError('LogEntry must have scheduledFor or occurredAt');
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Actions
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Mark this entry as completed now
  LogEntryModel markCompleted({DateTime? at}) {
    final completedAt = at ?? DateTime.now();
    _validateOccurredAt(completedAt);
    return copyWith(occurredAt: completedAt, updatedAt: DateTime.now());
  }
  
  /// Undo completion (back to todo/missed state)
  LogEntryModel undoCompletion() {
    if (scheduledFor == null) {
      throw StateError('Cannot undo completion of ad-hoc entry (no scheduledFor)');
    }
    return copyWith(occurredAt: null, updatedAt: DateTime.now());
  }
  
  /// Reschedule to a new date
  LogEntryModel reschedule(DateTime newDate) {
    return copyWith(scheduledFor: newDate, updatedAt: DateTime.now());
  }
  
  // ─────────────────────────────────────────────────────────────────────────
  // Validation
  // ─────────────────────────────────────────────────────────────────────────
  
  /// Validate the entry state
  static void validate(DateTime? scheduledFor, DateTime? occurredAt) {
    if (scheduledFor == null && occurredAt == null) {
      throw ArgumentError('Entry must have scheduledFor or occurredAt');
    }
    if (occurredAt != null) {
      _validateOccurredAt(occurredAt);
    }
  }
  
  static void _validateOccurredAt(DateTime occurredAt) {
    // Allow small buffer for clock skew (1 minute)
    final maxAllowed = DateTime.now().add(const Duration(minutes: 1));
    if (occurredAt.isAfter(maxAllowed)) {
      throw ArgumentError('occurredAt cannot be in the future');
    }
  }
}
