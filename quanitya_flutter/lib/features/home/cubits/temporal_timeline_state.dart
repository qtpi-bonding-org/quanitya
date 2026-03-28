import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'temporal_timeline_state.freezed.dart';

@freezed
abstract class TemporalTimelineState
    with _$TemporalTimelineState, UiFlowStateMixin
    implements IUiFlowState {
  const TemporalTimelineState._();

  const factory TemporalTimelineState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    @Default(null) Null lastOperation,

    // UI Navigation State
    @Default(1) int currentPageIndex, // 0=Past, 1=Present, 2=Future
  }) = _TemporalTimelineState;
}
