import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';

import 'search_state.dart';

@injectable
class SearchMessageMapper implements IStateMessageMapper<SearchState> {
  @override
  MessageKey? map(SearchState state) {
    // Search results are the feedback — no toasts needed.
    return null;
  }
}
