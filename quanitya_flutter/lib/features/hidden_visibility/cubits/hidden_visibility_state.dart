import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'hidden_visibility_state.freezed.dart';

enum HiddenVisibilityOperation { toggleHidden }

@freezed
class HiddenVisibilityState
    with _$HiddenVisibilityState, UiFlowStateMixin
    implements IUiFlowState {
  const HiddenVisibilityState._();

  const factory HiddenVisibilityState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    HiddenVisibilityOperation? lastOperation,
    @Default(false) bool showingHidden,
  }) = _HiddenVisibilityState;
}
