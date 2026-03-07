import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../data/dao/analytics_inbox_dao.dart';

part 'analytics_inbox_state.freezed.dart';

enum AnalyticsInboxOperation {
  sendAll,
  clearSent,
  clearAll,
  toggleAutoSend,
}

@freezed
class AnalyticsInboxState with _$AnalyticsInboxState, UiFlowStateMixin implements IUiFlowState {
  const AnalyticsInboxState._();

  const factory AnalyticsInboxState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    AnalyticsInboxOperation? lastOperation,
    @Default([]) List<AnalyticsInboxGroupedEntry> groupedEvents,
    @Default(0) int unsentCount,
    @Default(false) bool autoSendEnabled,
    @Default(0) int lastSentCount,
  }) = _AnalyticsInboxState;
}
