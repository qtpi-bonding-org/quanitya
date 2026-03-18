import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'health_sync_state.freezed.dart';

/// Operations tracked by [HealthSyncCubit].
enum HealthSyncOperation { toggle }

@freezed
class HealthSyncState with _$HealthSyncState, UiFlowStateMixin implements IUiFlowState {
  const HealthSyncState._();

  const factory HealthSyncState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    HealthSyncOperation? lastOperation,
    @Default(false) bool enabled,
    @Default(0) int lastImportCount,
  }) = _HealthSyncState;
}
