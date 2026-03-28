import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

part 'sync_status_state.freezed.dart';

/// Simplified sync status for UI consumption.
enum SyncConnectionState {
  /// Not in a sync-capable mode (local mode)
  disabled,
  /// PowerSync is connecting
  connecting,
  /// PowerSync is connected and idle
  connected,
  /// Actively downloading or uploading
  syncing,
  /// Connection error
  error,
  /// Disconnected (sync mode but not connected)
  disconnected,
}

enum SyncStatusOperation {
  retrySync,
}

@freezed
abstract class SyncStatusState with _$SyncStatusState, UiFlowStateMixin implements IUiFlowState {
  const SyncStatusState._();

  const factory SyncStatusState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    SyncStatusOperation? lastOperation,
    @Default(SyncConnectionState.disabled) SyncConnectionState connectionState,
    @Default(false) bool isDownloading,
    @Default(false) bool isUploading,
    DateTime? lastSyncedAt,
    String? errorMessage,
    @Default(false) bool isRetrying,
  }) = _SyncStatusState;
}
