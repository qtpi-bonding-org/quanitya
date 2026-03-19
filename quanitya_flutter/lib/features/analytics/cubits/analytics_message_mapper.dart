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
        AnalyticsOperation.sendAll =>
          MessageKey.success(L10nKeys.analyticsInboxSendAllSuccess),
        AnalyticsOperation.clearSent =>
          MessageKey.success(L10nKeys.analyticsInboxClearSentSuccess),
        AnalyticsOperation.clearAll =>
          MessageKey.success(L10nKeys.analyticsInboxClearAllSuccess),
        AnalyticsOperation.toggleAutoSend =>
          MessageKey.success(L10nKeys.analyticsInboxToggleAutoSendSuccess),
      };
    }

    if (state.status.isFailure && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsOperation.sendAll =>
          MessageKey.error(L10nKeys.analyticsInboxSendAllError),
        _ => MessageKey.error(L10nKeys.analyticsInboxOperationError),
      };
    }

    return null;
  }
}
