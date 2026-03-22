import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'sync_status_state.dart';

@injectable
class SyncStatusMessageMapper implements IStateMessageMapper<SyncStatusState> {
  @override
  MessageKey? map(SyncStatusState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        SyncStatusOperation.retrySync => MessageKey.success(L10nKeys.syncReconnected),
      };
    }
    return null;
  }
}
