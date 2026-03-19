import 'package:injectable/injectable.dart';

import '../../../data/interfaces/analysis_script_interface.dart';
import '../exceptions/analysis_exceptions.dart';
import '../models/analysis_script.dart';
import '../models/analysis_enums.dart';
import '../models/analysis_output.dart';
import '../enums/analysis_output_mode.dart';
import '../services/analysis_engine.dart';

/// Service for real-time streaming analytics calculations.
///
/// Streams script definitions and log entries from database,
/// calculates results in real-time, and emits results.
///
/// Follows data flow consistency pattern:
/// - Database as single source of truth
/// - No stored calculation results
/// - Always fresh calculations from source data
@injectable
class StreamingAnalyticsService {
  final IAnalysisScriptRepository _scriptRepo;
  final AnalysisEngine _analysisEngine;

  const StreamingAnalyticsService(this._scriptRepo, this._analysisEngine);

  /// Stream scalar results for a saved script.
  ///
  /// Combines script definition stream with template data stream,
  /// executes script in real-time when either changes,
  /// and emits only scalar results.
  Stream<Map<String, double>> streamScalarResults(String scriptId) {
    return _scriptRepo
        .watchAllScripts()
        .map(
          (scripts) => scripts.where((s) => s.id == scriptId).firstOrNull,
        )
        .distinct()
        .asyncExpand((script) {
          if (script == null) {
            return Stream.value(<String, double>{});
          }

          // Extract templateId from fieldId (format: "templateId:fieldName")
          final templateId = _extractTemplateId(script.fieldId);

          return _streamTemplateData(templateId)
              .asyncMap((_) => _executeAndExtractScalars(script))
              .handleError((error) {
                throw AnalysisException('streamScalarResults failed: $error');
              });
        });
  }

  /// Stream full results for current script being built.
  ///
  /// Used by script builder for live preview functionality.
  /// Takes current steps and field info, streams template data,
  /// and calculates results in real-time.
  Stream<AnalysisOutput> streamResultsForLivePreview({
    required String snippet,
    required String fieldId,
    required AnalysisOutputMode outputMode,
    required AnalysisSnippetLanguage snippetLanguage,
    String? templateId,
  }) {
    if (snippet.isEmpty) {
      // Return a dummy empty result
      return Stream.value(const AnalysisOutput.scalar([]));
    }

    // Extract templateId from fieldId if not provided
    final actualTemplateId = templateId ?? _extractTemplateId(fieldId);

    return _streamTemplateData(actualTemplateId)
        .asyncMap((_) async {
          try {
            // Create a temporary script model for execution
            final script = AnalysisScriptModel(
              id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
              name: 'Live Preview',
              fieldId: fieldId,
              outputMode: outputMode,
              snippetLanguage: snippetLanguage,
              snippet: snippet,
              updatedAt: DateTime.now(),
            );

            return await _analysisEngine.execute(script);
          } catch (error) {
            throw AnalysisException(
              'streamResultsForLivePreview failed: $error',
            );
          }
        })
        .handleError((error) {
          throw AnalysisException('Live preview failed: $error');
        });
  }

  /// Execute script and extract scalar results.
  Future<Map<String, double>> _executeAndExtractScalars(
    AnalysisScriptModel script,
  ) async {
    try {
      // Execute script using AnalysisEngine
      final result = await _analysisEngine.execute(script);

      // Extract results into a labeled map for UI consumption
      return result.when(
        scalar: (scalars) => {for (final s in scalars) s.label: s.value},
        vector: (vectors) => {}, // Vectors are charts, not scalar summaries
        matrix: (matrices) => {}, // Matrices are complex
      );
    } catch (error) {
      throw AnalysisException('Script execution failed: $error');
    }
  }

  /// Stream template data changes.
  ///
  /// This is a placeholder that streams template data changes.
  /// In a real implementation, this would watch for log entry changes
  /// for the specific template.
  Stream<void> _streamTemplateData(String templateId) {
    // For now, emit periodically to trigger recalculation
    // In the future, this could watch actual log entry changes
    return Stream.periodic(const Duration(seconds: 5));
  }

  /// Extract templateId from fieldId format "templateId:fieldName"
  String _extractTemplateId(String fieldId) {
    final parts = fieldId.split(':');
    if (parts.length != 2) {
      throw AnalysisException(
        'Invalid fieldId format: $fieldId. Expected "templateId:fieldName"',
      );
    }
    return parts[0];
  }
}
