import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

part 'errors_state.freezed.dart';

enum ErrorsOperation {
  sendOne,
  sendAll,
  markAsSent,
  markAllAsSent,
  delete,
  deleteAll,
  toggleAutoSend,
}

@freezed
abstract class ErrorsState with _$ErrorsState, UiFlowStateMixin implements IUiFlowState {
  const ErrorsState._();

  const factory ErrorsState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    ErrorsOperation? lastOperation,
    @Default([]) List<ErrorBoxEntry> unsentErrors,
    @Default([]) List<String> lastSentIds,
    @Default(0) int lastSentCount,
    @Default(false) bool autoSendEnabled,
  }) = _ErrorsState;
}
