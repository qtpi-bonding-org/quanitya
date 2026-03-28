import '../../logic/analysis/models/analysis_script.dart';

/// Time-series data extracted from log entries for a specific field.
/// Values can be any type: double, String, bool, List, Map (for group fields).
typedef FieldTimeSeries = ({List<dynamic> values, List<DateTime> timestamps});

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
  /// [fieldId] The field UUID to filter by
  Stream<List<AnalysisScriptModel>> watchScriptsForField(String fieldId);

  /// Retrieves a specific analysis script by ID from local storage.
  ///
  /// Returns null if no script with the given ID exists.
  Future<AnalysisScriptModel?> getScript(String id);

  /// Gets all analysis scripts.
  Future<List<AnalysisScriptModel>> getAllScripts();

  /// Gets analysis scripts for a specific field.
  ///
  /// [fieldId] The field UUID to filter by
  Future<List<AnalysisScriptModel>> getScriptsForField(String fieldId);

  /// Gets all analysis scripts for a template.
  ///
  /// [templateId] The template UUID to filter by
  Future<List<AnalysisScriptModel>> getScriptsForTemplate(String templateId);

  /// Saves a new analysis script with automatic encryption handling.
  Future<void> saveScript(AnalysisScriptModel script);

  /// Updates an existing analysis script with encryption handling.
  Future<void> updateScript(AnalysisScriptModel script);

  /// Deletes an analysis script from both storage layers.
  Future<void> deleteScript(String id);

  /// Bulk inserts multiple analysis scripts efficiently.
  Future<void> bulkInsert(List<AnalysisScriptModel> scripts);

  /// Gets the count of all analysis scripts.
  Future<int> countScripts();

  /// Gets the entry count for a template by ID.
  Future<int> countEntriesForTemplate(String templateId);

  /// Fetches numeric time-series data for a field.
  ///
  /// [templateId] The template UUID
  /// [fieldId] The field UUID
  /// [entryRangeStart] and [entryRangeEnd] slice the result set (0-based,
  /// ordered by date descending). Both null = all entries.
  Future<FieldTimeSeries> fetchFieldTimeSeries(
    String templateId,
    String fieldId, {
    int? entryRangeStart,
    int? entryRangeEnd,
  });
}
