import 'package:injectable/injectable.dart';

import '../../../data/interfaces/analysis_script_interface.dart';
import '../../../data/interfaces/log_entry_interface.dart';
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
@injectable
class StreamingAnalyticsService {
  final IAnalysisScriptRepository _scriptRepo;
  final AnalysisEngine _analysisEngine;
  final ILogEntryRepository _logEntryRepo;

  const StreamingAnalyticsService(
    this._scriptRepo,
    this._analysisEngine,
    this._logEntryRepo,
  );

  /// Stream scalar results for a saved script.
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

          return _streamTemplateData(script.templateId)
              .asyncMap((_) => _executeAndExtractScalars(script))
              .handleError((error) {
                throw AnalysisException('streamScalarResults failed: $error');
              });
        });
  }

  /// Stream full results for current script being built (live preview).
  Stream<AnalysisOutput> streamResultsForLivePreview({
    required String snippet,
    required String fieldId,
    required AnalysisOutputMode outputMode,
    required AnalysisSnippetLanguage snippetLanguage,
    String? templateId,
  }) {
    if (snippet.isEmpty) {
      return Stream.value(const AnalysisOutput.scalar([]));
    }

    if (templateId == null || templateId.isEmpty) {
      return Stream.value(const AnalysisOutput.scalar([]));
    }

    return _streamTemplateData(templateId)
        .asyncMap((_) async {
          try {
            final script = AnalysisScriptModel(
              id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
              name: 'Live Preview',
              templateId: templateId,
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

  Future<Map<String, double>> _executeAndExtractScalars(
    AnalysisScriptModel script,
  ) async {
    try {
      final result = await _analysisEngine.execute(script);
      return result.when(
        scalar: (scalars) => {for (final s in scalars) s.label: s.value},
        vector: (vectors) => {},
        matrix: (matrices) => {},
      );
    } catch (error) {
      throw AnalysisException('Script execution failed: $error');
    }
  }

  Stream<void> _streamTemplateData(String templateId) {
    return _logEntryRepo
        .watchPastEntries(templateId: templateId)
        .map((_) {});
  }
}
