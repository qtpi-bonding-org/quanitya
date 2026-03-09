import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'analytics_state.dart';

@injectable
class AnalyticsMessageMapper implements IStateMessageMapper<AnalyticsState> {
  @override
  MessageKey? map(AnalyticsState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsOperation.loadPipelines => null, // No message for loading
        AnalyticsOperation.executePipeline => MessageKey.success(L10nKeys.analyticsPipelineExecuted),
        AnalyticsOperation.savePipeline => MessageKey.success(L10nKeys.analyticsPipelineSaved),
        AnalyticsOperation.updatePipeline => MessageKey.success(L10nKeys.analyticsPipelineUpdated),
        AnalyticsOperation.deletePipeline => MessageKey.success(L10nKeys.analyticsPipelineDeleted),
      };
    }
    return null; // Use global exception mapping for errors
  }
}