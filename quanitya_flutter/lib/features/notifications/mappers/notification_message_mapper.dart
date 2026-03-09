import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import '../cubits/notification_inbox_cubit.dart';

@injectable
class NotificationMessageMapper implements IStateMessageMapper<NotificationInboxState> {
  @override
  MessageKey? map(NotificationInboxState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        NotificationOperation.markAsReceived =>
          MessageKey.success(L10nKeys.notificationMarkedAsReceived),
        NotificationOperation.dismiss =>
          MessageKey.success(L10nKeys.notificationDismissed),
        NotificationOperation.markAllAsReceived =>
          MessageKey.success(L10nKeys.notificationAllMarkedAsReceived),
      };
    }
    return null;
  }
}
