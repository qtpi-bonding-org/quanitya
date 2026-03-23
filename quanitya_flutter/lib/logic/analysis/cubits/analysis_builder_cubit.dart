import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:uuid/uuid.dart';
import 'dart:async';

import '../../../data/interfaces/analysis_script_interface.dart';
import '../../../data/repositories/template_with_aesthetics_repository.dart';
import '../../../infrastructure/llm/models/llm_types.dart';
import '../../../logic/templates/enums/field_enum.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../enums/time_resolution.dart';
import '../enums/analysis_output_mode.dart';
import '../enums/calculation.dart';
import '../models/analysis_enums.dart';
import '../models/matrix_vector_scalar/analysis_data_type.dart';
import '../models/analysis_script.dart';
import '../services/field_context_service.dart';
import '../services/ai/ai_analysis_orchestrator.dart';
import '../services/streaming_analytics_service.dart';
import '../services/wasm_analysis_service.dart';
import '../models/analysis_output.dart';
import 'analysis_builder_state.dart';

/// Default hint snippet shown in the code editor when no script is loaded.
/// Documents the JS ↔ Flutter API so users know what's available.
const analysisHintSnippet = '''
// ── data in ──────────────────────────────────
// data.values      → your field values (any type):
//   number:  [7.5, 8, 6, ...]
//   string:  ["good", "bad", ...]
//   bool:    [true, false, ...]
//   group:   [{sleep: 7, mood: "ok"}, ...]
// data.timestamps  → [1705000000000, ...]  (ms epoch)
// data.getDates()  → [Date, Date, ...]
// data.col()       → [{value, timestamp, date}, ...]
//
// ── libraries ────────────────────────────────
// ss / simpleStatistics  (simple-statistics)
// jstat                  (jStat)
//
// ── return (depends on output mode) ──────────
// scalar: return 42;
//         return {label: "Mean", value: 7.5, unit: "kg"};
//         return [{label: "A", value: 1}, ...];
//
// vector: return {label: "Dist", values: [1, 2, 3]};
//         return [{label: "A", values: [...]}, ...];
//
// matrix: return {label: "Series", values: [...],
//                 timestamps: [ms, ...]};
// ─────────────────────────────────────────────

return ss.mean(data.values);
''';

@injectable
class AnalysisBuilderCubit extends QuanityaCubit<AnalysisBuilderState> {
  final IAnalysisScriptRepository _repository;
  final TemplateWithAestheticsRepository _templateRepository;
  final AiAnalysisOrchestrator _aiOrchestrator;
  final FieldContextService _fieldContextService;
  final StreamingAnalyticsService _streamingService;
  final IWasmAnalysisService _wasmService;

  AnalysisBuilderCubit(
    this._repository,
    this._templateRepository,
    this._aiOrchestrator,
    this._fieldContextService,
    this._streamingService,
    this._wasmService,
  ) : super(const AnalysisBuilderState());

  StreamSubscription<AnalysisOutput>? _liveResultsSubscription;

  /// Initialize the script builder for a specific field and template
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

      // Load existing scripts for this field using composite fieldId
      final compositeFieldId = templateId != null
          ? '$templateId:$fieldId'
          : fieldId;
      var existing = await _repository.getScriptsForField(compositeFieldId);
      if (existing.isEmpty && templateId != null) {
        // Fallback: show all scripts for this template
        final all = await _repository.getAllScripts();
        existing = all.where((p) => p.fieldId.startsWith('$templateId:')).toList();
      }
      final script = existing.isNotEmpty ? existing.first : null;

      // Get entry count for hint text
      final entryCount = templateId != null
          ? await _repository.countEntriesForTemplate(templateId)
          : 0;

      return state.copyWith(
        fieldId: fieldId,
        templateId: templateId,
        entryCount: entryCount,
        availableFieldNames: availableFields,
        availableScripts: existing,
        selectedScriptId: script?.id,
        snippet: script?.snippet ?? analysisHintSnippet,
        reasoning: script?.reasoning ?? '',
        outputMode: script?.outputMode ?? AnalysisOutputMode.scalar,
        snippetLanguage: script?.snippetLanguage ?? AnalysisSnippetLanguage.js,
        entryRangeStart: script?.entryRangeStart,
        entryRangeEnd: script?.entryRangeEnd,
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

  /// Select a different script to edit
  void selectScript(String scriptId) {
    final script = state.availableScripts
        .where((p) => p.id == scriptId)
        .firstOrNull;
    if (script == null) return;

    emit(state.copyWith(
      selectedScriptId: scriptId,
      snippet: script.snippet,
      reasoning: script.reasoning ?? '',
      outputMode: script.outputMode,
      snippetLanguage: script.snippetLanguage,
      entryRangeStart: script.entryRangeStart,
      entryRangeEnd: script.entryRangeEnd,
    ));

    if (state.livePreviewEnabled) {
      startLivePreview();
    }
  }

  /// Clear editor and start a new script from scratch.
  void newScript() {
    emit(state.copyWith(
      selectedScriptId: null,
      snippet: analysisHintSnippet,
      reasoning: '',
      outputMode: AnalysisOutputMode.scalar,
      snippetLanguage: AnalysisSnippetLanguage.js,
      entryRangeStart: null,
      entryRangeEnd: null,
      previewResult: null,
    ));
  }

  /// Execute the current snippet and store results.
  Future<void> runScript() async {
    if (state.snippet.isEmpty) return;

    await tryOperation(() async {
      // Use selected script's fieldId (already in templateId:fieldName format),
      // or construct it from state if editing a new script.
      final selectedScript = state.selectedScriptId != null
          ? state.availableScripts
              .where((p) => p.id == state.selectedScriptId)
              .firstOrNull
          : null;
      final effectiveFieldId = selectedScript?.fieldId ??
          (state.templateId != null && state.fieldId != null
              ? '${state.templateId}:${state.fieldId}'
              : state.fieldId ?? '');

      final script = AnalysisScriptModel(
        id: state.selectedScriptId ?? 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: 'Preview',
        fieldId: effectiveFieldId,
        outputMode: state.outputMode,
        snippetLanguage: state.snippetLanguage,
        snippet: state.snippet,
        entryRangeStart: state.entryRangeStart,
        entryRangeEnd: state.entryRangeEnd,
        updatedAt: DateTime.now(),
      );

      final result = await _wasmService.execute(script);
      analytics?.trackAnalysisRun();

      return state.copyWith(
        previewResult: result,
        status: UiFlowStatus.success,
        lastOperation: ScriptBuilderOperation.loadPreview,
      );
    }, emitLoading: true);
  }

  /// Update the output mode
  void setOutputMode(AnalysisOutputMode mode) {
    emit(state.copyWith(outputMode: mode));
  }

  /// Update the entry range slice (both null = all entries).
  ///
  /// Freezed's copyWith treats null as "keep current value" for nullable
  /// fields, so clearing requires reconstructing the state explicitly.
  void setEntryRange({int? start, int? end}) {
    if (start == null && end == null) {
      // Reconstruct state without entry range fields to force them to null
      emit(AnalysisBuilderState(
        status: state.status,
        error: state.error,
        lastOperation: state.lastOperation,
        fieldId: state.fieldId,
        templateId: state.templateId,
        timeResolution: state.timeResolution,
        slots: state.slots,
        branches: state.branches,
        nextStepId: state.nextStepId,
        snippet: state.snippet,
        reasoning: state.reasoning,
        outputMode: state.outputMode,
        snippetLanguage: state.snippetLanguage,
        // entryRangeStart: null,  (default)
        // entryRangeEnd: null,    (default)
        entryCount: state.entryCount,
        branchesFinished: state.branchesFinished,
        livePreviewEnabled: state.livePreviewEnabled,
        liveResults: state.liveResults,
        previewResult: state.previewResult,
        availableFieldNames: state.availableFieldNames,
        availableContextKeys: state.availableContextKeys,
        previewResults: state.previewResults,
        stepValidations: state.stepValidations,
        selectedFieldForAi: state.selectedFieldForAi,
        availableScripts: state.availableScripts,
        selectedScriptId: state.selectedScriptId,
      ));
    } else {
      emit(state.copyWith(entryRangeStart: start, entryRangeEnd: end));
    }
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
        lastOperation: ScriptBuilderOperation.applyAiSuggestion,
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

  /// Save script
  Future<void> saveScript(String name) async {
    await tryOperation(() async {
      // Build the composite fieldId (templateId:fieldName) if possible
      final effectiveFieldId = state.templateId != null && state.fieldId != null
          ? '${state.templateId}:${state.fieldId}'
          : state.fieldId ?? '';

      final scriptId = state.selectedScriptId ?? const Uuid().v4();

      final script = AnalysisScriptModel(
        id: scriptId,
        name: name,
        fieldId: effectiveFieldId,
        outputMode: state.outputMode,
        snippetLanguage: state.snippetLanguage,
        snippet: state.snippet,
        reasoning: state.reasoning,
        entryRangeStart: state.entryRangeStart,
        entryRangeEnd: state.entryRangeEnd,
        updatedAt: DateTime.now(),
      );

      await _repository.saveScript(script);

      // Reload scripts list so the new/updated one appears in the selector
      var scripts = await _repository.getScriptsForField(effectiveFieldId);
      if (scripts.isEmpty) {
        scripts = await _repository.getAllScripts();
      }

      return state.copyWith(
        availableScripts: scripts,
        selectedScriptId: scriptId,
        status: UiFlowStatus.success,
        lastOperation: ScriptBuilderOperation.saveScript,
      );
    }, emitLoading: true);
  }

  /// Generate AI script recommendation
  Future<void> generateAndApplyAiScript({
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

  AnalysisDataType getCurrentTailType() => AnalysisDataType.timeSeriesMatrix;

  void finishBranches() => emit(state.copyWith(branchesFinished: true));
  void editBranches() => emit(state.copyWith(branchesFinished: false));

  void setSelectedFieldForAi(String? fieldId) {
    emit(state.copyWith(selectedFieldForAi: fieldId));
  }

  @override
  Future<void> close() {
    _liveResultsSubscription?.cancel();
    return super.close();
  }
}
