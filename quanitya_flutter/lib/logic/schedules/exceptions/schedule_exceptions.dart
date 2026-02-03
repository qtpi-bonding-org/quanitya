/// Custom exceptions for schedule operations.
library;

/// Base class for all schedule-related exceptions.
abstract class ScheduleException implements Exception {
  const ScheduleException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'ScheduleException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when generating schedule entries fails.
class ScheduleGenerationException extends ScheduleException {
  const ScheduleGenerationException(super.message, [super.cause]);

  @override
  String toString() =>
      'ScheduleGenerationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
