import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'recovery_key_state.dart';

@injectable
class RecoveryKeyMessageMapper implements IStateMessageMapper<RecoveryKeyState> {
  @override
  MessageKey? map(RecoveryKeyState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        RecoveryKeyOperation.validate => MessageKey.success(L10nKeys.settingsRecoveryKeyVerified),
        RecoveryKeyOperation.recover => MessageKey.success(L10nKeys.settingsRecoveryAccountRecovered),
      };
    }
    return null;
  }
}
