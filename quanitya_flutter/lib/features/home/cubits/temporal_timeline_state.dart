import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'temporal_timeline_state.freezed.dart';

enum TemporalTimelineOperation { toggleHidden }

@freezed
class TemporalTimelineState
    with _$TemporalTimelineState, UiFlowStateMixin
    implements IUiFlowState {
  const TemporalTimelineState._();

  const factory TemporalTimelineState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    TemporalTimelineOperation? lastOperation,
    
    // UI Navigation State
    @Default(1) int currentPageIndex, // 0=Past, 1=Present, 2=Future
    
    // Hidden templates visibility (requires auth to enable)
    @Default(false) bool showingHidden,
  }) = _TemporalTimelineState;
}
