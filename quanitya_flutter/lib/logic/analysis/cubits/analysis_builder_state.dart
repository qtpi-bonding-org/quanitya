import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../models/analysis_output.dart';
import '../models/analysis_enums.dart';
import '../models/analysis_script.dart';
import '../models/matrix_vector_scalar/mvs_union.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../enums/time_resolution.dart';
import '../enums/analysis_output_mode.dart';

part 'analysis_builder_state.freezed.dart';

enum ScriptBuilderOperation {
  addStep,
  removeStep,
  updateStep,
  saveScript,
  loadPreview,
  applyAiSuggestion,
}

/// UI presentation layer for script slots
enum SlotPosition { leftBranch, rightBranch, combiner }

@freezed
abstract class ScriptSlot with _$ScriptSlot {
  const factory ScriptSlot({
    required SlotPosition position,
    required int slotIndex, // 0, 1, 2 (which slot in that position)
    required int stepIndex, // Which step from the steps list
    required String stepId, // Unique identifier for the step
  }) = _ScriptSlot;
}

/// Represents a branch in the parallel analysis
@freezed
abstract class ScriptBranch with _$ScriptBranch {
  const factory ScriptBranch({
    required SlotPosition position,
    required List<ScriptSlot> slots,
    required String outputKey, // Final output key for this branch
    required AnalysisDataType outputType, // Final output type for this branch
  }) = _ScriptBranch;
}

@freezed
abstract class AnalysisBuilderState
    with _$AnalysisBuilderState, UiFlowStateMixin
    implements IUiFlowState {
  const factory AnalysisBuilderState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    ScriptBuilderOperation? lastOperation,

    // Script data (execution model - JavaScript-based)
    String? fieldId,
    String? templateId,
    TimeResolution? timeResolution,

    // Presentation layer (UI layout) - Legacy visual (unused)
    @Default([]) List<ScriptSlot> slots,
    @Default([])
    List<ScriptBranch> branches, // Track branch outputs for combining
    @Default(0) int nextStepId, // For generating unique step IDs

    // Script-based data (WASM runtime - actively used)
    @Default('') String snippet,
    @Default('') String reasoning,
    @Default(AnalysisOutputMode.scalar) AnalysisOutputMode outputMode,
    @Default(AnalysisSnippetLanguage.js) AnalysisSnippetLanguage snippetLanguage,
    int? entryRangeStart,
    int? entryRangeEnd,
    @Default(0) int entryCount,

    // Progressive disclosure state
    @Default(false)
    bool branchesFinished, // Hide "Add Step" buttons, show clean combiner
    // Live preview state
    @Default(false) bool livePreviewEnabled,
    AnalysisOutput? liveResults,
    AnalysisOutput? previewResult,

    // Template context for field selection
    @Default([]) List<String> availableFieldNames,

    // Available context keys from previous steps (for input selection)
    @Default({}) Set<String> availableContextKeys,

    // Preview data for each step
    @Default({}) Map<int, MvsUnion> previewResults,

    // Validation state
    @Default([]) List<bool> stepValidations,

    // AI field selection
    String? selectedFieldForAi,

    // Available scripts for this field
    @Default([]) List<AnalysisScriptModel> availableScripts,
    String? selectedScriptId,
  }) = _AnalysisBuilderState;

  const AnalysisBuilderState._();
}
