import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../models/analysis_output.dart';
import '../models/analysis_enums.dart';
import '../models/matrix_vector_scalar/mvs_union.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../enums/time_resolution.dart';
import '../enums/analysis_output_mode.dart';

part 'analysis_builder_state.freezed.dart';

enum PipelineBuilderOperation {
  addStep,
  removeStep,
  updateStep,
  savePipeline,
  loadPreview,
  applyAiSuggestion,
}

/// UI presentation layer for pipeline slots
enum SlotPosition { leftBranch, rightBranch, combiner }

@freezed
class PipelineSlot with _$PipelineSlot {
  const factory PipelineSlot({
    required SlotPosition position,
    required int slotIndex, // 0, 1, 2 (which slot in that position)
    required int stepIndex, // Which step from the steps list
    required String stepId, // Unique identifier for the step
  }) = _PipelineSlot;
}

/// Represents a branch in the parallel pipeline
@freezed
class PipelineBranch with _$PipelineBranch {
  const factory PipelineBranch({
    required SlotPosition position,
    required List<PipelineSlot> slots,
    required String outputKey, // Final output key for this branch
    required AnalysisDataType outputType, // Final output type for this branch
  }) = _PipelineBranch;
}

@freezed
class AnalysisBuilderState
    with _$AnalysisBuilderState
    implements IUiFlowState {
  const factory AnalysisBuilderState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    PipelineBuilderOperation? lastOperation,

    // Pipeline data (execution model - JavaScript-based)
    String? fieldId,
    String? templateId,
    TimeResolution? timeResolution,

    // Presentation layer (UI layout) - Legacy visual pipeline (unused)
    @Default([]) List<PipelineSlot> slots,
    @Default([])
    List<PipelineBranch> branches, // Track branch outputs for combining
    @Default(0) int nextStepId, // For generating unique step IDs
    
    // Script-based data (WASM runtime - actively used)
    @Default('') String snippet,
    @Default('') String reasoning,
    @Default(AnalysisOutputMode.scalar) AnalysisOutputMode outputMode,
    @Default(AnalysisSnippetLanguage.js) AnalysisSnippetLanguage snippetLanguage,

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
  }) = _AnalysisBuilderState;

  const AnalysisBuilderState._();

  // IUiFlowState implementation
  @override
  bool get isIdle => status == UiFlowStatus.idle;
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  @override
  bool get isSuccess => status == UiFlowStatus.success;
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  @override
  bool get hasError => error != null;
}
