import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'temporal_timeline_state.dart';

/// Message mapper for temporal timeline operations
@injectable
class TemporalTimelineMessageMapper
    implements IStateMessageMapper<TemporalTimelineState> {
  @override
  MessageKey? map(TemporalTimelineState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        TemporalTimelineOperation.toggleHidden =>
          MessageKey.info('timeline.hidden_toggled'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
