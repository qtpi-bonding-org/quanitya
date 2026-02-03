import 'package:injectable/injectable.dart';

import '../../../data/interfaces/log_entry_interface.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../../../infrastructure/webhooks/webhook_service.dart';
import '../exceptions/log_entry_exceptions.dart';
import '../models/log_entry.dart';

/// Service layer for log entry operations.
/// 
/// Wraps ILogEntryRepository and adds cross-cutting concerns like webhook triggering.
/// Use this instead of calling the repository directly when saving log entries.
@lazySingleton
class LogEntryService {
  final ILogEntryRepository _repository;
  final WebhookService _webhookService;

  LogEntryService(this._repository, this._webhookService);

  /// Save a log entry and trigger associated webhooks if it's an actual log.
  /// 
  /// Webhooks are only fired for entries with occurredAt set (actual logs),
  /// not for todos (scheduledFor only). Fire-and-forget after save succeeds.
  Future<void> saveLogEntry(LogEntryModel entry) {
    return tryMethod(
      () async {
        await _repository.saveLogEntry(entry);
        
        // Only trigger webhooks for actual logs (not todos)
        if (entry.occurredAt != null) {
          _webhookService.triggerForTemplate(entry.templateId);
        }
      },
      LogEntrySaveException.new,
      'saveLogEntry',
    );
  }

  /// Update a log entry (no webhook trigger - only new entries trigger webhooks).
  Future<void> updateLogEntry(LogEntryModel entry) {
    return tryMethod(
      () async {
        await _repository.updateLogEntry(entry);
      },
      LogEntryUpdateException.new,
      'updateLogEntry',
    );
  }

  /// Delete a log entry.
  Future<void> deleteLogEntry(String id) {
    return tryMethod(
      () async {
        await _repository.deleteLogEntry(id);
      },
      LogEntryDeleteException.new,
      'deleteLogEntry',
    );
  }
}
