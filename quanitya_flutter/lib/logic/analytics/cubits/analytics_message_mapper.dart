import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'analytics_state.dart';

@injectable
class AnalyticsMessageMapper implements IStateMessageMapper<AnalyticsState> {
  @override
  MessageKey? map(AnalyticsState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsOperation.loadPipelines => null, // No message for loading
        AnalyticsOperation.executePipeline => MessageKey.success('analytics.pipeline.executed'),
        AnalyticsOperation.savePipeline => MessageKey.success('analytics.pipeline.saved'),
        AnalyticsOperation.updatePipeline => MessageKey.success('analytics.pipeline.updated'),
        AnalyticsOperation.deletePipeline => MessageKey.success('analytics.pipeline.deleted'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}