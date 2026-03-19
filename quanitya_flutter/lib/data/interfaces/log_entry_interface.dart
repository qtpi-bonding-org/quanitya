import '../../logic/log_entries/models/log_entry.dart';
import '../dao/log_entry_query_dao.dart'; // For LogEntryWithContext

/// Repository interface for LogEntryModel operations with encryption handling.
///
/// This interface defines the contract for managing log entries with
/// both local plaintext storage (for performance) and encrypted shadow storage
/// (for PowerSync synchronization). All write operations automatically handle
/// encryption and maintain consistency between storage layers.
abstract class ILogEntryRepository {
  /// Watches all log entries for a specific tracker template.
  ///
  /// Returns a stream that emits the current list of entries whenever
  /// the underlying data changes. Entries are ordered by timestamp descending
  /// (most recent first).
  ///
  /// Performance: Reads from local LogEntries table for speed.
  ///
  /// [templateId] The UUID of the TrackerTemplateModel to get entries for
  Stream<List<LogEntryModel>> watchEntriesForTemplate(String templateId);

  /// Watches all log entries across all templates.
  ///
  /// Returns a stream of all entries ordered by timestamp descending.
  /// Useful for dashboard views and cross-template analytics.
  Stream<List<LogEntryModel>> watchAllEntries();

  /// Watches log entries within a specific date range for a template.
  ///
  /// [templateId] The UUID of the TrackerTemplateModel
  /// [startDate] Inclusive start date for the range
  /// [endDate] Inclusive end date for the range
  Stream<List<LogEntryModel>> watchEntriesInDateRange(
    String templateId,
    DateTime startDate,
    DateTime endDate,
  );

  /// Watches logged/completed entries (past) - most recent first.
  /// 
  /// [templateId] Optional - filter to specific template
  Stream<List<LogEntryModel>> watchPastEntries({String? templateId});

  /// Watches upcoming/todo entries (future) - nearest first.
  /// 
  /// [templateId] Optional - filter to specific template
  Stream<List<LogEntryModel>> watchUpcomingEntries({String? templateId});

  /// Watches missed/overdue entries - most recently missed first.
  /// 
  /// [templateId] Optional - filter to specific template
  Stream<List<LogEntryModel>> watchMissedEntries({String? templateId});

  /// Watches logged/completed entries with full context (template + aesthetics).
  Stream<List<LogEntryWithContext>> watchPastEntriesWithContext({
    String? templateId,
    bool sortAscending = false,
  });

  /// Watches upcoming/todo entries with full context (template + aesthetics).
  Stream<List<LogEntryWithContext>> watchUpcomingEntriesWithContext({
    String? templateId,
    bool sortAscending = true,
  });

  /// Gets logged/completed entries (past) - most recent first.
  /// 
  /// [templateId] Optional - filter to specific template
  Future<List<LogEntryModel>> getPastEntries({String? templateId});

  /// Gets upcoming/todo entries (future) - nearest first.
  /// 
  /// [templateId] Optional - filter to specific template
  Future<List<LogEntryModel>> getUpcomingEntries({String? templateId});

  /// Gets missed/overdue entries - most recently missed first.
  /// 
  /// [templateId] Optional - filter to specific template
  Future<List<LogEntryModel>> getMissedEntries({String? templateId});

  /// Retrieves a specific log entry by ID from local storage.
  ///
  /// Returns null if no entry with the given ID exists.
  /// Performance: Single query against local LogEntries table.
  ///
  /// [id] The UUID of the entry to retrieve
  Future<LogEntryModel?> getEntry(String id);

  /// Retrieves the most recent N entries for a template.
  ///
  /// Useful for displaying recent activity or pagination scenarios.
  ///
  /// [templateId] The UUID of the TrackerTemplateModel
  /// [limit] Maximum number of entries to return
  Future<List<LogEntryModel>> getRecentEntries(String templateId, int limit);

  /// Saves a new log entry with automatic encryption handling.
  ///
  /// This operation:
  /// 1. Validates the entry data against the template schema
  /// 2. Writes to local LogEntries table (plaintext for performance)
  /// 3. Encrypts and writes to EncryptedEntries shadow table (for sync)
  /// 4. Ensures both operations succeed or rolls back on failure
  ///
  /// [entry] The log entry to save (must have valid UUID)
  /// Throws: ValidationException if entry data doesn't match template schema
  /// Throws: NotFoundException if referenced template doesn't exist
  /// Throws: DatabaseException if write operations fail
  Future<void> saveLogEntry(LogEntryModel entry);

  /// Updates an existing log entry with encryption handling.
  ///
  /// This operation:
  /// 1. Validates the updated entry data against template schema
  /// 2. Updates local LogEntries table
  /// 3. Re-encrypts and updates EncryptedEntries shadow table
  /// 4. Maintains data integrity and audit trail
  ///
  /// [entry] The updated entry (ID must match existing record)
  /// Throws: NotFoundException if entry doesn't exist
  /// Throws: ValidationException if updated data is invalid
  Future<void> updateLogEntry(LogEntryModel entry);

  /// Deletes a log entry from both storage layers.
  ///
  /// This is a hard delete operation that removes the entry from both
  /// local and encrypted storage. Consider if soft delete is more appropriate
  /// for your use case.
  ///
  /// [id] The UUID of the entry to delete
  /// Throws: NotFoundException if entry doesn't exist
  Future<void> deleteLogEntry(String id);

  /// Deletes all log entries for a specific template.
  ///
  /// WARNING: This is a destructive operation typically used when
  /// permanently deleting a template. All associated entries are
  /// removed from both local and encrypted storage.
  ///
  /// [templateId] The UUID of the template whose entries should be deleted
  /// Returns: The number of entries deleted
  Future<int> deleteAllEntriesForTemplate(String templateId);

  /// Synchronizes local storage with encrypted shadow tables.
  ///
  /// This method handles the synchronization contract between local
  /// plaintext storage and encrypted shadow storage. It's typically
  /// called by the E2EE puller service when encrypted data changes.
  ///
  /// [templateId] Optional - sync only entries for specific template
  /// Returns the number of entries synchronized
  Future<int> syncFromEncryptedStorage({String? templateId});

  /// Validates entry data against template schema.
  ///
  /// Checks that the entry's data structure matches the field definitions
  /// in the associated TrackerTemplateModel. This includes type validation,
  /// required field checks, and constraint validation.
  ///
  /// [entry] The entry to validate
  /// Returns: List of validation errors (empty if valid)
  Future<List<String>> validateEntryData(LogEntryModel entry);

  /// Gets statistics for entries of a specific template.
  ///
  /// Returns aggregate information like entry count, date range,
  /// and field-specific statistics for analytics purposes.
  ///
  /// [templateId] The UUID of the template to analyze
  Future<Map<String, dynamic>> getEntryStatistics(String templateId);

  /// Gets all entries for a specific template.
  ///
  /// [templateId] The UUID of the TrackerTemplateModel
  Future<List<LogEntryModel>> getEntriesForTemplate(String templateId);

  /// Gets all log entries across all templates.
  Future<List<LogEntryModel>> getAllEntries();

  /// Gets the count of entries for a specific template.
  Future<int> countEntriesForTemplate(String templateId);

  /// Gets the total count of all entries.
  Future<int> countAllEntries();

  /// Gets entry count and last logged date for all templates.
  Future<List<TemplateSummary>> getTemplateSummaries();

  /// Watches entry count and last logged date for all templates.
  Stream<List<TemplateSummary>> watchTemplateSummaries();

  // ─────────────────────────────────────────────────────────────────────────
  // Ingestion Support Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Gets all deduplication keys for entries of a specific template.
  ///
  /// Used by the ingestion pipeline to filter out duplicate imports.
  /// Reads the `_dedupKey` field from each entry's data map.
  ///
  /// [templateId] The UUID of the TrackerTemplateModel
  /// Returns: Set of existing dedup keys (empty if none found)
  Future<Set<String>> getDedupKeysForTemplate(String templateId);

  /// Bulk inserts multiple log entries efficiently.
  ///
  /// This operation:
  /// 1. Skips validation (imported data already validated by adapter)
  /// 2. Uses DualDao.bulkUpsert for efficient batch writes
  /// 3. Writes to both local and encrypted tables atomically
  ///
  /// [entries] List of log entries to insert
  /// Note: Entries should have adapter metadata (_sourceAdapter, _dedupKey)
  Future<void> bulkInsert(List<LogEntryModel> entries);

  // ─────────────────────────────────────────────────────────────────────────
  // Analytics Support Methods
  // ─────────────────────────────────────────────────────────────────────────

  /// Gets time series data for a specific field across all entries.
  ///
  /// Extracts values from the specified field in entry data and returns
  /// them as time series points for analytics processing.
  ///
  /// [fieldId] The field identifier to extract values from
  /// Returns: List of time series points ordered by date ascending
  Future<List<({DateTime date, num value})>> getTimeSeriesForField(String fieldId);
}
