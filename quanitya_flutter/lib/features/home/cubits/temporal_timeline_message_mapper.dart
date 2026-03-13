import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'temporal_timeline_state.dart';

/// Message mapper for temporal timeline — navigation only, no user-facing messages.
@injectable
class TemporalTimelineMessageMapper
    implements IStateMessageMapper<TemporalTimelineState> {
  @override
  MessageKey? map(TemporalTimelineState state) {
    return null;
  }
}
