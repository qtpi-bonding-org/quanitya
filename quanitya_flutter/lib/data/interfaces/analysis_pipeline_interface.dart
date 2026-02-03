import '../../logic/analytics/models/analysis_pipeline.dart';

/// Repository interface for AnalysisPipelineModel operations with encryption handling.
///
/// This interface defines the contract for managing analysis pipelines with
/// both local plaintext storage (for performance) and encrypted shadow storage
/// (for PowerSync synchronization). All write operations automatically handle
/// encryption and maintain consistency between storage layers.
abstract class IAnalysisPipelineRepository {
  /// Watches all analysis pipelines.
  ///
  /// Returns a stream that emits the current list of pipelines whenever
  /// the underlying data changes. Pipelines are ordered by name.
  Stream<List<AnalysisPipelineModel>> watchAllPipelines();

  /// Watches analysis pipelines for a specific field.
  ///
  /// Returns a stream of pipelines that analyze the specified field.
  ///
  /// [fieldId] The field identifier to filter by
  Stream<List<AnalysisPipelineModel>> watchPipelinesForField(String fieldId);

  /// Retrieves a specific analysis pipeline by ID from local storage.
  ///
  /// Returns null if no pipeline with the given ID exists.
  ///
  /// [id] The UUID of the pipeline to retrieve
  Future<AnalysisPipelineModel?> getPipeline(String id);

  /// Gets all analysis pipelines.
  Future<List<AnalysisPipelineModel>> getAllPipelines();

  /// Gets analysis pipelines for a specific field.
  ///
  /// [fieldId] The field identifier to filter by
  Future<List<AnalysisPipelineModel>> getPipelinesForField(String fieldId);

  /// Saves a new analysis pipeline with automatic encryption handling.
  ///
  /// This operation:
  /// 1. Validates the pipeline configuration
  /// 2. Writes to local AnalysisPipelines table (plaintext for performance)
  /// 3. Encrypts and writes to EncryptedAnalysisPipelines shadow table (for sync)
  /// 4. Ensures both operations succeed or rolls back on failure
  ///
  /// [pipeline] The analysis pipeline to save (must have valid UUID)
  Future<void> savePipeline(AnalysisPipelineModel pipeline);

  /// Updates an existing analysis pipeline with encryption handling.
  ///
  /// This operation:
  /// 1. Validates the updated pipeline configuration
  /// 2. Updates local AnalysisPipelines table
  /// 3. Re-encrypts and updates EncryptedAnalysisPipelines shadow table
  /// 4. Maintains data integrity and audit trail
  ///
  /// [pipeline] The updated pipeline (ID must match existing record)
  Future<void> updatePipeline(AnalysisPipelineModel pipeline);

  /// Deletes an analysis pipeline from both storage layers.
  ///
  /// This is a hard delete operation that removes the pipeline from both
  /// local and encrypted storage.
  ///
  /// [id] The UUID of the pipeline to delete
  Future<void> deletePipeline(String id);

  /// Bulk inserts multiple analysis pipelines efficiently.
  ///
  /// This operation uses DualDao.bulkUpsert for efficient batch writes
  /// to both local and encrypted tables atomically.
  ///
  /// [pipelines] List of analysis pipelines to insert
  Future<void> bulkInsert(List<AnalysisPipelineModel> pipelines);

  /// Gets the count of all analysis pipelines.
  Future<int> countPipelines();
}