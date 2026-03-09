import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../../data/interfaces/analysis_pipeline_interface.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../infrastructure/llm/models/llm_types.dart';
import '../../../logic/templates/enums/field_enum.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../enums/time_resolution.dart';
import '../enums/analysis_output_mode.dart';
import '../enums/calculation.dart';
import '../models/analysis_enums.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../models/analysis_pipeline.dart';
import '../services/field_context_service.dart';
import '../services/ai/ai_analysis_orchestrator.dart';
import '../services/streaming_analytics_service.dart';
import '../models/analysis_output.dart';
import 'analysis_builder_state.dart';

@injectable
class AnalysisBuilderCubit extends QuanityaCubit<AnalysisBuilderState> {
  final IAnalysisPipelineRepository _repository;
  final TemplateWithAestheticsRepository _templateRepository;
  final AiAnalysisOrchestrator _aiOrchestrator;
  final FieldContextService _fieldContextService;
  final StreamingAnalyticsService _streamingService;

  AnalysisBuilderCubit(
    this._repository,
    this._templateRepository,
    this._aiOrchestrator,
    this._fieldContextService,
    this._streamingService,
  ) : super(const AnalysisBuilderState());

  StreamSubscription<AnalysisOutput>? _liveResultsSubscription;

  /// Initialize the pipeline builder for a specific field and template
  Future<void> initializeForField(
    String fieldId,
    TimeResolution? timeResolution, {
    String? templateId,
  }) async {
    await tryOperation(() async {
      List<String> availableFields = [];

      if (templateId != null) {
        final templateWithAesthetics = await _templateRepository.findById(
          templateId,
        );
        if (templateWithAesthetics != null) {
          availableFields = templateWithAesthetics.template.fields
              .where((field) => _isNumericField(field.type))
              .map((field) => field.label)
              .toList();
        }
      }

      return state.copyWith(
        fieldId: fieldId,
        templateId: templateId,
        availableFieldNames: availableFields,
        snippet: '',
        reasoning: '',
        outputMode: AnalysisOutputMode.scalar,
        snippetLanguage: AnalysisSnippetLanguage.js,
        previewResult: null,
        liveResults: null,
        status: UiFlowStatus.success,
      );
    }, emitLoading: true);
  }

  bool _isNumericField(FieldEnum fieldType) {
    return switch (fieldType) {
      FieldEnum.integer => true,
      FieldEnum.float => true,
      FieldEnum.dimension => true,
      _ => false,
    };
  }

  /// Update the current snippet
  void updateSnippet(String snippet) {
    emit(state.copyWith(snippet: snippet));
    if (state.livePreviewEnabled) {
      startLivePreview();
    }
  }

  /// Apply an AI suggestion
  void applySuggestion({
    required String snippet,
    required String reasoning,
    required AnalysisOutputMode outputMode,
    required AnalysisSnippetLanguage snippetLanguage,
  }) {
    emit(
      state.copyWith(
        snippet: snippet,
        reasoning: reasoning,
        outputMode: outputMode,
        snippetLanguage: snippetLanguage,
        status: UiFlowStatus.success,
        lastOperation: PipelineBuilderOperation.applyAiSuggestion,
      ),
    );

    if (state.livePreviewEnabled) {
      startLivePreview();
    }
  }

  /// Start live preview
  void startLivePreview() {
    if (state.fieldId == null) return;

    _liveResultsSubscription?.cancel();
    _liveResultsSubscription = _streamingService
        .streamResultsForLivePreview(
          snippet: state.snippet,
          fieldId: state.fieldId!,
          outputMode: state.outputMode,
          snippetLanguage: state.snippetLanguage,
          templateId: state.templateId,
        )
        .listen(
          (results) {
            emit(state.copyWith(liveResults: results));
          },
          onError: (error) {
            emit(state.copyWith(liveResults: null, error: error));
          },
        );

    emit(state.copyWith(livePreviewEnabled: true));
  }

  /// Stop live preview
  void stopLivePreview() {
    _liveResultsSubscription?.cancel();
    _liveResultsSubscription = null;

    emit(state.copyWith(livePreviewEnabled: false, liveResults: null));
  }

  /// Toggle live preview
  void toggleLivePreview() {
    if (state.livePreviewEnabled) {
      stopLivePreview();
    } else {
      startLivePreview();
    }
  }

  /// Save pipeline
  Future<void> savePipeline(String name) async {
    await tryOperation(() async {
      if (state.fieldId == null) {
        throw Exception('Cannot save pipeline without field selection');
      }

      final pipeline = AnalysisPipelineModel(
        id: const Uuid().v4(),
        name: name,
        fieldId: state.fieldId!,
        outputMode: state.outputMode,
        snippetLanguage: state.snippetLanguage,
        snippet: state.snippet,
        reasoning: state.reasoning,
        updatedAt: DateTime.now(),
      );

      await _repository.savePipeline(pipeline);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: PipelineBuilderOperation.savePipeline,
      );
    }, emitLoading: true);
  }

  /// Generate AI pipeline recommendation
  Future<void> generateAndApplyAiPipeline({
    required String fieldId,
    required String userIntent,
    required LlmConfig llmConfig,
  }) async {
    await tryOperation(() async {
      if (state.templateId == null) {
        throw Exception('Template ID is required for AI suggestions');
      }

      final fieldContext = await _fieldContextService.getFieldContext(
        templateId: state.templateId!,
        fieldId: fieldId,
      );

      final suggestion = await _aiOrchestrator.generateSuggestion(
        intent: userIntent,
        fieldContext: fieldContext,
        llmConfig: llmConfig,
      );

      applySuggestion(
        snippet: suggestion.snippet,
        reasoning: suggestion.reasoning,
        outputMode: suggestion.outputMode,
        snippetLanguage: suggestion.snippetLanguage,
      );
      return state;
    }, emitLoading: true);
  }

  // --- Legacy Stubs for UI Compatibility ---

  AnalysisDataType getCurrentTailType() => AnalysisDataType.timeSeriesMatrix;

  void addCombinerStep(Calculation op, Map<String, dynamic> params) {}
  void addStepToBranch(
    SlotPosition pos,
    Calculation op,
    Map<String, dynamic> params,
  ) {}
  void finishBranches() => emit(state.copyWith(branchesFinished: true));
  void editBranches() => emit(state.copyWith(branchesFinished: false));
  void updateNodeParams(int index, Map<String, dynamic> params) {}
  void removeStepFromSlot(SlotPosition pos, int index) {}

  void setSelectedFieldForAi(String? fieldId) {
    emit(state.copyWith(selectedFieldForAi: fieldId));
  }

  @override
  Future<void> close() {
    _liveResultsSubscription?.cancel();
    return super.close();
  }
}
