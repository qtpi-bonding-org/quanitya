import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'analytics_inbox_state.dart';

@injectable
class AnalyticsInboxMessageMapper implements IStateMessageMapper<AnalyticsInboxState> {
  @override
  MessageKey? map(AnalyticsInboxState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsInboxOperation.sendAll =>
          MessageKey.success('analytics_inbox.send_all.success'),
        AnalyticsInboxOperation.clearSent =>
          MessageKey.success('analytics_inbox.clear_sent.success'),
        AnalyticsInboxOperation.clearAll =>
          MessageKey.success('analytics_inbox.clear_all.success'),
        AnalyticsInboxOperation.toggleAutoSend =>
          MessageKey.success('analytics_inbox.toggle_auto_send.success'),
      };
    }

    if (state.status.isFailure && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AnalyticsInboxOperation.sendAll =>
          MessageKey.error('analytics_inbox.send_all.error'),
        _ => MessageKey.error('analytics_inbox.operation.error'),
      };
    }

    return null;
  }
}
