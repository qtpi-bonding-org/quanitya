import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../data/dao/log_entry_query_dao.dart';

part 'search_state.freezed.dart';

enum SearchOperation { search, clear }

@freezed
class SearchState with _$SearchState, UiFlowStateMixin implements IUiFlowState {
  const SearchState._();

  const factory SearchState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    SearchOperation? lastOperation,
    @Default('') String query,
    @Default([]) List<LogEntryWithContext> results,
  }) = _SearchState;
}
