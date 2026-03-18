import '../../logic/analytics/models/analysis_script.dart';

/// Time-series numeric data extracted from log entries for a specific field.
typedef FieldTimeSeries = ({List<double> values, List<DateTime> timestamps});

/// Repository interface for AnalysisScriptModel operations with encryption handling.
///
/// This interface defines the contract for managing analysis scripts with
/// both local plaintext storage (for performance) and encrypted shadow storage
/// (for PowerSync synchronization). All write operations automatically handle
/// encryption and maintain consistency between storage layers.
abstract class IAnalysisScriptRepository {
  /// Watches all analysis scripts.
  ///
  /// Returns a stream that emits the current list of scripts whenever
  /// the underlying data changes. Scripts are ordered by name.
  Stream<List<AnalysisScriptModel>> watchAllScripts();

  /// Watches analysis scripts for a specific field.
  ///
  /// Returns a stream of scripts that analyze the specified field.
  ///
  /// [fieldId] The field identifier to filter by
  Stream<List<AnalysisScriptModel>> watchScriptsForField(String fieldId);

  /// Retrieves a specific analysis script by ID from local storage.
  ///
  /// Returns null if no script with the given ID exists.
  ///
  /// [id] The UUID of the script to retrieve
  Future<AnalysisScriptModel?> getScript(String id);

  /// Gets all analysis scripts.
  Future<List<AnalysisScriptModel>> getAllScripts();

  /// Gets analysis scripts for a specific field.
  ///
  /// [fieldId] The field identifier to filter by
  Future<List<AnalysisScriptModel>> getScriptsForField(String fieldId);

  /// Saves a new analysis script with automatic encryption handling.
  ///
  /// This operation:
  /// 1. Validates the script configuration
  /// 2. Writes to local AnalysisScripts table (plaintext for performance)
  /// 3. Encrypts and writes to EncryptedAnalysisScripts shadow table (for sync)
  /// 4. Ensures both operations succeed or rolls back on failure
  ///
  /// [script] The analysis script to save (must have valid UUID)
  Future<void> saveScript(AnalysisScriptModel script);

  /// Updates an existing analysis script with encryption handling.
  ///
  /// This operation:
  /// 1. Validates the updated script configuration
  /// 2. Updates local AnalysisScripts table
  /// 3. Re-encrypts and updates EncryptedAnalysisScripts shadow table
  /// 4. Maintains data integrity and audit trail
  ///
  /// [script] The updated script (ID must match existing record)
  Future<void> updateScript(AnalysisScriptModel script);

  /// Deletes an analysis script from both storage layers.
  ///
  /// This is a hard delete operation that removes the script from both
  /// local and encrypted storage.
  ///
  /// [id] The UUID of the script to delete
  Future<void> deleteScript(String id);

  /// Bulk inserts multiple analysis scripts efficiently.
  ///
  /// This operation uses DualDao.bulkUpsert for efficient batch writes
  /// to both local and encrypted tables atomically.
  ///
  /// [scripts] List of analysis scripts to insert
  Future<void> bulkInsert(List<AnalysisScriptModel> scripts);

  /// Gets the count of all analysis scripts.
  Future<int> countScripts();

  /// Fetches numeric time-series data for a field.
  ///
  /// Resolves the fieldId format ("templateId:fieldName") to the actual
  /// field UUID used in entry data, then extracts numeric values.
  /// [entryRangeStart] and [entryRangeEnd] slice the result set (0-based,
  /// ordered by date descending). Both null = all entries.
  Future<FieldTimeSeries> fetchFieldTimeSeries(
    String fieldId, {
    int? entryRangeStart,
    int? entryRangeEnd,
  });
}
