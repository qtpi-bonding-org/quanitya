import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import '../../../infrastructure/config/debug_log.dart';

import '../../../data/interfaces/analysis_script_interface.dart';
import '../../../data/repositories/data_retrieval_service.dart';
import '../../../logic/analysis/services/analysis_engine.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'visualization_state.dart';
export 'visualization_state.dart';

const _tag = 'features/visualization/cubits/visualization_cubit';

/// Cubit for loading visualization data with statistics.
@injectable
class VisualizationCubit extends QuanityaCubit<VisualizationState> {
  final DataRetrievalService _dataRepo;
  final IAnalysisScriptRepository _scriptRepo;
  final AnalysisEngine _analysisEngine;

  VisualizationCubit(
    this._dataRepo,
    this._scriptRepo,
    this._analysisEngine,
  ) : super(const VisualizationState());

  /// Load visualization data for a template.
  Future<void> loadForTemplate(String templateId, {int days = 30}) async {
    await tryOperation(() async {
      final data = await _dataRepo.getAggregatedData(templateId, days: days);

      if (data == null) {
        throw StateError('Template not found: $templateId');
      }

      // Calculate consistency rate
      final totalDays = data.endDate.difference(data.startDate).inDays + 1;
      final loggedDays = data.loggedDates.length;
      final consistencyRate = totalDays > 0 ? loggedDays / totalDays : 0.0;

      // Load and execute analysis scripts for this template
      final relevantScripts = await _scriptRepo.getScriptsForTemplate(templateId);

      final analysisResults = <String, ScriptResult>{};
      final failedScriptNames = <String>[];
      for (final script in relevantScripts) {
        try {
          final result = await _analysisEngine.execute(script);
          analysisResults[script.id] = ScriptResult(
            script: script,
            result: result,
          );
        } catch (e) {
          failedScriptNames.add(script.name);
          Log.d(_tag, 'Failed to execute script ${script.name}: $e');
        }
      }

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: VisualizationOperation.load,
        data: data,
        consistencyRate: consistencyRate.clamp(0.0, 1.0),
        analysisResults: analysisResults,
        failedScriptNames: failedScriptNames,
      );
    }, emitLoading: true);
  }
}
