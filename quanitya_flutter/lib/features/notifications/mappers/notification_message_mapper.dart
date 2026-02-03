import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../cubits/notification_inbox_cubit.dart';

@injectable
class NotificationMessageMapper implements IStateMessageMapper<NotificationInboxState> {
  @override
  MessageKey? map(NotificationInboxState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        NotificationOperation.markAsReceived => 
          MessageKey.success('notification.markedAsReceived'),
        NotificationOperation.dismiss => 
          MessageKey.success('notification.dismissed'),
        NotificationOperation.markAllAsReceived => 
          MessageKey.success('notification.allMarkedAsReceived'),
      };
    }
    return null;
  }
}
