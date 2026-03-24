import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'paid_account_state.freezed.dart';

enum PaidAccountOperation { load, markPurchased, reset }

@freezed
class PaidAccountState
    with _$PaidAccountState, UiFlowStateMixin
    implements IUiFlowState {
  const PaidAccountState._();

  const factory PaidAccountState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    PaidAccountOperation? lastOperation,
    @Default(false) bool hasPurchased,
  }) = _PaidAccountState;
}
