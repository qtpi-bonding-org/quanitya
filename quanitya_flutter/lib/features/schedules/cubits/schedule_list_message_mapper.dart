import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

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
        ScheduleListOperation.pause => MessageKey.success('schedule.paused'),
        ScheduleListOperation.resume => MessageKey.success('schedule.resumed'),
        ScheduleListOperation.delete => MessageKey.success('schedule.deleted'),
        ScheduleListOperation.update => MessageKey.success('schedule.updated'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
