import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

part 'error_box_state.freezed.dart';

enum ErrorBoxOperation {
  sendOne,
  sendAll,
  markAsSent,
  markAllAsSent,
  delete,
  deleteAll,
  toggleAutoSend,
}

@freezed
class ErrorBoxState with _$ErrorBoxState, UiFlowStateMixin implements IUiFlowState {
  const ErrorBoxState._();

  const factory ErrorBoxState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    ErrorBoxOperation? lastOperation,
    @Default([]) List<ErrorBoxEntry> unsentErrors,
    @Default([]) List<String> lastSentIds,
    @Default(0) int lastSentCount,
    @Default(false) bool autoSendEnabled,
  }) = _ErrorBoxState;
}
