import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'health_sync_state.dart';

@injectable
class HealthSyncMessageMapper
    implements IStateMessageMapper<HealthSyncState> {
  @override
  MessageKey? map(HealthSyncState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        HealthSyncOperation.toggle => state.enabled && state.lastImportCount > 0
            ? () {
                final (key, args) =
                    L10nKeys.healthEntriesImported(state.lastImportCount);
                return MessageKey.success(key, args);
              }()
            : null,
      };
    }
    return null;
  }
}
