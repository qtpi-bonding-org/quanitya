import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import 'results_list_state.dart';

/// Message mapper for results list operations.
///
/// ResultsListState has no operations — it is load-only, so all
/// state transitions are silent.
@injectable
class ResultsListMessageMapper
    implements IStateMessageMapper<ResultsListState> {
  @override
  MessageKey? map(ResultsListState state) {
    // Load-only state — no user-facing messages.
    return null;
  }
}
