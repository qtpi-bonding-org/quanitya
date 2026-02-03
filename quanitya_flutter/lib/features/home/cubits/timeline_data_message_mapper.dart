import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'timeline_data_state.dart';

/// Message mapper for timeline data operations
@injectable
class TimelineDataMessageMapper
    implements IStateMessageMapper<TimelineDataState> {
  @override
  MessageKey? map(TimelineDataState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TimelineDataOperation.load =>
          MessageKey.info('timeline.loaded'),
        TimelineDataOperation.filter =>
          MessageKey.info('timeline.filtered'),
        TimelineDataOperation.sort =>
          MessageKey.info('timeline.sorted'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
