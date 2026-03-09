import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';
import 'analysis_builder_state.dart';

@injectable
class AnalysisBuilderMessageMapper implements IStateMessageMapper<AnalysisBuilderState> {
  @override
  MessageKey? map(AnalysisBuilderState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        PipelineBuilderOperation.addStep => MessageKey.success(L10nKeys.analysisStepAdded),
        PipelineBuilderOperation.removeStep => MessageKey.success(L10nKeys.analysisStepRemoved),
        PipelineBuilderOperation.updateStep => MessageKey.success(L10nKeys.analysisStepUpdated),
        PipelineBuilderOperation.savePipeline => MessageKey.success(L10nKeys.analysisSaved),
        PipelineBuilderOperation.loadPreview => null, // No message for preview loads
        PipelineBuilderOperation.applyAiSuggestion => MessageKey.success(L10nKeys.aiSuggestionsApplied),
      };
    }
    return null; // Use global exception mapping for errors
  }
}