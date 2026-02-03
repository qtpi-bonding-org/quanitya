import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'mvs_pipeline_builder_state.dart';

@injectable
class MvsPipelineBuilderMessageMapper implements IStateMessageMapper<MvsPipelineBuilderState> {
  @override
  MessageKey? map(MvsPipelineBuilderState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        PipelineBuilderOperation.addStep => MessageKey.success('pipeline.step.added'),
        PipelineBuilderOperation.removeStep => MessageKey.success('pipeline.step.removed'),
        PipelineBuilderOperation.updateStep => MessageKey.success('pipeline.step.updated'),
        PipelineBuilderOperation.savePipeline => MessageKey.success('pipeline.saved'),
        PipelineBuilderOperation.loadPreview => null, // No message for preview loads
        PipelineBuilderOperation.applyAiSuggestion => MessageKey.success('ai.suggestions.applied'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}