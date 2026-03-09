import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'log_entry_history_state.dart';

/// Message mapper for log entry history operations
@injectable
class LogEntryHistoryMessageMapper
    implements IStateMessageMapper<LogEntryHistoryState> {
  @override
  MessageKey? map(LogEntryHistoryState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        LogEntryHistoryOperation.load => null,
      };
    }
    return null; // Use global exception mapping for errors
  }
}
