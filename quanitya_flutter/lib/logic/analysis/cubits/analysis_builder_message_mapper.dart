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
        ScriptBuilderOperation.addStep => MessageKey.success(L10nKeys.analysisStepAdded),
        ScriptBuilderOperation.removeStep => MessageKey.success(L10nKeys.analysisStepRemoved),
        ScriptBuilderOperation.updateStep => MessageKey.success(L10nKeys.analysisStepUpdated),
        ScriptBuilderOperation.saveScript => MessageKey.success(L10nKeys.analysisSaved),
        ScriptBuilderOperation.deleteScript => MessageKey.success(L10nKeys.analysisDeleted),
        ScriptBuilderOperation.loadPreview => null,
        ScriptBuilderOperation.applyAiSuggestion => MessageKey.success(L10nKeys.aiSuggestionsApplied),
      };
    }
    return null; // Use global exception mapping for errors
  }
}