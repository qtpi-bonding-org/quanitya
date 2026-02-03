/// Custom exceptions for log entry operations.
library;

/// Base class for all log entry-related exceptions.
abstract class LogEntryException implements Exception {
  const LogEntryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'LogEntryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when saving a log entry fails.
class LogEntrySaveException extends LogEntryException {
  const LogEntrySaveException(super.message, [super.cause]);

  @override
  String toString() =>
      'LogEntrySaveException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when updating a log entry fails.
class LogEntryUpdateException extends LogEntryException {
  const LogEntryUpdateException(super.message, [super.cause]);

  @override
  String toString() =>
      'LogEntryUpdateException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when deleting a log entry fails.
class LogEntryDeleteException extends LogEntryException {
  const LogEntryDeleteException(super.message, [super.cause]);

  @override
  String toString() =>
      'LogEntryDeleteException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}
