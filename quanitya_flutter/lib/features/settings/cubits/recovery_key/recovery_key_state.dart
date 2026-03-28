import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'recovery_key_state.freezed.dart';

/// Operations that can be performed with recovery keys
enum RecoveryKeyOperation {
  /// Validating the recovery key format
  validate,
  /// Full account recovery using the key
  recover,
}

@freezed
abstract class RecoveryKeyState with _$RecoveryKeyState, UiFlowStateMixin implements IUiFlowState {
  const RecoveryKeyState._();

  const factory RecoveryKeyState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    RecoveryKeyOperation? lastOperation,
  }) = _RecoveryKeyState;
}
