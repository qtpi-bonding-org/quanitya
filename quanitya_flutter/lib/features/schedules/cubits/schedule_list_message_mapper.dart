import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'schedule_list_state.dart';

/// Message mapper for schedule list operations
@injectable
class ScheduleListMessageMapper
    implements IStateMessageMapper<ScheduleListState> {
  @override
  MessageKey? map(ScheduleListState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        ScheduleListOperation.load => null, // Silent load
        ScheduleListOperation.pause => MessageKey.success(L10nKeys.schedulePaused),
        ScheduleListOperation.resume => MessageKey.success(L10nKeys.scheduleResumed),
        ScheduleListOperation.delete => MessageKey.success(L10nKeys.scheduleDeleted),
        ScheduleListOperation.update => MessageKey.success(L10nKeys.scheduleUpdated),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
