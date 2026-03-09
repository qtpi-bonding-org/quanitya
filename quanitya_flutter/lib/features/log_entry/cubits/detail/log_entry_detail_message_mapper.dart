import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'entry_detail_state.dart';

/// Message mapper for log entry detail operations
@injectable
class LogEntryDetailMessageMapper
    implements IStateMessageMapper<EntryDetailState> {
  @override
  MessageKey? map(EntryDetailState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        EntryDetailOperation.load =>
          MessageKey.info('entry.loaded'),
        EntryDetailOperation.update =>
          MessageKey.success(L10nKeys.entryUpdated),
        EntryDetailOperation.delete =>
          MessageKey.success(L10nKeys.entryDeleted),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
