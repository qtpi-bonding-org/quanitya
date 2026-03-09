import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

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
          MessageKey.info(L10nKeys.timelineLoaded),
        TimelineDataOperation.filter =>
          MessageKey.info(L10nKeys.timelineFiltered),
        TimelineDataOperation.sort =>
          MessageKey.info(L10nKeys.timelineSorted),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
