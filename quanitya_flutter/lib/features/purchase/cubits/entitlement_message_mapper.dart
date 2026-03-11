import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'entitlement_state.dart';

@injectable
class EntitlementMessageMapper implements IStateMessageMapper<EntitlementState> {
  @override
  MessageKey? map(EntitlementState state) {
    // All entitlement operations are silent loads — errors go through global mapper
    return null;
  }
}
