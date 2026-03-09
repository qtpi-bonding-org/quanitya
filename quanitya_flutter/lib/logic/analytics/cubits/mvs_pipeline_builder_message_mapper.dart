import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';
import 'mvs_pipeline_builder_state.dart';

@injectable
class MvsPipelineBuilderMessageMapper implements IStateMessageMapper<MvsPipelineBuilderState> {
  @override
  MessageKey? map(MvsPipelineBuilderState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        PipelineBuilderOperation.addStep => MessageKey.success(L10nKeys.pipelineStepAdded),
        PipelineBuilderOperation.removeStep => MessageKey.success(L10nKeys.pipelineStepRemoved),
        PipelineBuilderOperation.updateStep => MessageKey.success(L10nKeys.pipelineStepUpdated),
        PipelineBuilderOperation.savePipeline => MessageKey.success(L10nKeys.pipelineSaved),
        PipelineBuilderOperation.loadPreview => null, // No message for preview loads
        PipelineBuilderOperation.applyAiSuggestion => MessageKey.success(L10nKeys.aiSuggestionsApplied),
      };
    }
    return null; // Use global exception mapping for errors
  }
}