import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/dao/analytics_inbox_dao.dart';

part 'analytics_state.freezed.dart';

enum AnalyticsOperation {
  sendAll,
  clearSent,
  clearAll,
  toggleAutoSend,
}

@freezed
abstract class AnalyticsState with _$AnalyticsState, UiFlowStateMixin implements IUiFlowState {
  const AnalyticsState._();

  const factory AnalyticsState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    AnalyticsOperation? lastOperation,
    @Default([]) List<AnalyticsInboxGroupedEntry> groupedEvents,
    @Default(0) int unsentCount,
    @Default(false) bool autoSendEnabled,
    @Default(0) int lastSentCount,
  }) = _AnalyticsState;
}
