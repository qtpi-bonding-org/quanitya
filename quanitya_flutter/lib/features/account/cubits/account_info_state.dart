import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'account_info_state.freezed.dart';

enum AccountInfoOperation { load }

@freezed
abstract class AccountInfoState with _$AccountInfoState, UiFlowStateMixin implements IUiFlowState {
  const AccountInfoState._();

  const factory AccountInfoState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    AccountInfoOperation? lastOperation,
    String? accountPublicKeyHex,
  }) = _AccountInfoState;
}
