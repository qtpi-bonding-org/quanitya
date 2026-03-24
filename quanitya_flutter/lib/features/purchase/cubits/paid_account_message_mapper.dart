import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'paid_account_state.dart';

@injectable
class PaidAccountMessageMapper implements IStateMessageMapper<PaidAccountState> {
  @override
  MessageKey? map(PaidAccountState state) {
    // No user-facing messages needed for this cubit
    return null;
  }
}
