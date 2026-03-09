import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'analytics_inbox_state.dart';

@injectable
class AnalyticsInboxMessageMapper implements IStateMessageMapper<AnalyticsInboxState> {
  @override
  MessageKey? map(AnalyticsInboxState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsInboxOperation.sendAll =>
          MessageKey.success(L10nKeys.analyticsInboxSendAllSuccess),
        AnalyticsInboxOperation.clearSent =>
          MessageKey.success(L10nKeys.analyticsInboxClearSentSuccess),
        AnalyticsInboxOperation.clearAll =>
          MessageKey.success(L10nKeys.analyticsInboxClearAllSuccess),
        AnalyticsInboxOperation.toggleAutoSend =>
          MessageKey.success(L10nKeys.analyticsInboxToggleAutoSendSuccess),
      };
    }

    if (state.status.isFailure && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsInboxOperation.sendAll =>
          MessageKey.error(L10nKeys.analyticsInboxSendAllError),
        _ => MessageKey.error(L10nKeys.analyticsInboxOperationError),
      };
    }

    return null;
  }
}
