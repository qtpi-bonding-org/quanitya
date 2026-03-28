import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../../data/dao/log_entry_query_dao.dart';

part 'entry_detail_state.freezed.dart';

enum EntryDetailOperation { load, update, delete }

@freezed
abstract class EntryDetailState
    with _$EntryDetailState, UiFlowStateMixin 
    implements IUiFlowState {
  const EntryDetailState._();
  
  const factory EntryDetailState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    LogEntryWithContext? entry,
    EntryDetailOperation? lastOperation,
  }) = _EntryDetailState;
}
