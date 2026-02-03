import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'recovery_key_state.dart';

@injectable
class RecoveryKeyMessageMapper implements IStateMessageMapper<RecoveryKeyState> {
  @override
  MessageKey? map(RecoveryKeyState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        RecoveryKeyOperation.validate => MessageKey.success('settings.recovery.key.verified'),
        RecoveryKeyOperation.recover => MessageKey.success('settings.recovery.account.recovered'),
      };
    }
    return null;
  }
}
