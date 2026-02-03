import 'package:injectable/injectable.dart';
import '../../../data/interfaces/analysis_pipeline_interface.dart';
import '../../../infrastructure/core/try_operation.dart';
import '../exceptions/analysis_exceptions.dart';
import '../models/analysis_pipeline.dart';
import '../models/analysis_enums.dart';
import '../models/analysis_output.dart';
import '../enums/analysis_output_mode.dart';
import '../services/analysis_engine.dart';
import '../services/streaming_analytics_service.dart';

/// Central orchestrator for all analysis pipeline execution.
///
/// Provides a unified, high-level API by coordinating specialized services:
/// - [AnalysisEngine] - Core execution and MVS type conversions
/// - [StreamingAnalyticsService] - Real-time result streaming
///
/// This orchestrator simplifies the API surface for consumers (Cubits, UI)
/// by providing clear, purpose-driven methods instead of requiring direct
/// service interaction.
@injectable
class AnalysisOrchestrator {
  final AnalysisEngine _engine;
  final StreamingAnalyticsService _streamingService;
  final IAnalysisPipelineRepository _pipelineRepo;

  const AnalysisOrchestrator(
    this._engine,
    this._streamingService,
    this._pipelineRepo,
  );

  /// Execute a saved pipeline by ID.
  ///
  /// Loads pipeline definition from database and executes it.
  /// Throws [AnalysisException] if pipeline not found or execution fails.
  Future<AnalysisOutput> executeById(String pipelineId) {
    return tryMethod(
      () async {
        final pipeline = await _pipelineRepo.getPipeline(pipelineId);
        if (pipeline == null) {
          throw AnalysisException('Pipeline not found: $pipelineId');
        }
        return await _engine.execute(pipeline);
      },
      AnalysisException.new,
      'executeById',
    );
  }

  /// Execute a pipeline model directly.
  ///
  /// Used for both saved pipelines and temporary live preview pipelines.
  Future<AnalysisOutput> execute(AnalysisPipelineModel pipeline) {
    return tryMethod(
      () => _engine.execute(pipeline),
      AnalysisException.new,
      'execute',
    );
  }

  /// Stream scalar results for a saved pipeline.
  ///
  /// Delegates to [StreamingAnalyticsService] for real-time updates.
  /// Watches for changes in pipeline definition and template data.
  Stream<Map<String, double>> streamScalarResults(String pipelineId) {
    return _streamingService.streamScalarResults(pipelineId);
  }

  /// Stream full results for live preview in pipeline builder.
  ///
  /// Delegates to [StreamingAnalyticsService] for real-time preview.
  /// Creates a temporary pipeline from current builder state.
  Stream<AnalysisOutput> streamLivePreview({
    required String snippet,
    required String fieldId,
    required AnalysisOutputMode outputMode,
    required AnalysisSnippetLanguage snippetLanguage,
    String? templateId,
  }) {
    return _streamingService.streamResultsForLivePreview(
      snippet: snippet,
      fieldId: fieldId,
      outputMode: outputMode,
      snippetLanguage: snippetLanguage,
      templateId: templateId,
    );
  }
}
