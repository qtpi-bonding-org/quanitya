import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/repositories/data_retrieval_service.dart';
import '../../../logic/analysis/models/analysis_output.dart';
import '../../../logic/analysis/models/analysis_script.dart';

part 'visualization_state.freezed.dart';

enum VisualizationOperation { load }

/// Typed container for an executed analysis script and its output.
class ScriptResult {
  final AnalysisScriptModel script;
  final AnalysisOutput result;

  const ScriptResult({required this.script, required this.result});
}

@freezed
class VisualizationState
    with _$VisualizationState, UiFlowStateMixin
    implements IUiFlowState {
  const VisualizationState._();

  const factory VisualizationState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    VisualizationOperation? lastOperation,
    TemplateAggregatedData? data,
    /// Consistency rate (0.0 to 1.0) - percentage of days with entries
    @Default(0.0) double consistencyRate,
    /// Analysis results keyed by script ID
    @Default({}) Map<String, ScriptResult> analysisResults,
    /// Names of scripts that failed to execute (for user feedback)
    @Default([]) List<String> failedScriptNames,
  }) = _VisualizationState;
}
