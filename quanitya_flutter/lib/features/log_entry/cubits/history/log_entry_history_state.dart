import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../../../../logic/log_entries/models/log_entry.dart';
import '../../../../data/repositories/template_with_aesthetics_repository.dart';

part 'log_entry_history_state.freezed.dart';

enum LogEntryHistoryOperation { load }

@freezed
class LogEntryHistoryState
    with _$LogEntryHistoryState, UiFlowStateMixin
    implements IUiFlowState {
  const LogEntryHistoryState._();
  
  const factory LogEntryHistoryState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    LogEntryHistoryOperation? lastOperation,
    TemplateWithAesthetics? template,
    @Default([]) List<LogEntryModel> entries,
  }) = _LogEntryHistoryState;
}
