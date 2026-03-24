import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:powersync_sqlcipher/powersync.dart' show SyncStatus;

import '../../../data/sync/powersync_service.dart';
import '../../../infrastructure/sync/sync_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'sync_status_state.dart';

/// Observes PowerSync status stream and emits UI-friendly sync state.
///
/// Auto-subscribes in constructor — no explicit startListening() needed.
/// Retry goes through [SyncService] so auth and entitlement checks run.
@lazySingleton
class SyncStatusCubit extends QuanityaCubit<SyncStatusState> {
  final IPowerSyncRepository _powerSync;
  final SyncService _syncService;
  StreamSubscription<SyncStatus>? _statusSubscription;

  SyncStatusCubit(this._powerSync, this._syncService)
      : super(const SyncStatusState()) {
    _subscribe();
  }

  void _subscribe() {
    _statusSubscription?.cancel();
    _statusSubscription = _powerSync.statusStream.listen(
      (status) => emit(_mapStatus(status)),
      onError: (error) => emit(state.copyWith(
        connectionState: SyncConnectionState.error,
        errorMessage: error.toString(),
      )),
    );
  }

  /// Retry sync connection through [SyncService] (checks auth + entitlements).
  Future<void> retrySync() => tryOperation(() async {
    emit(state.copyWith(isRetrying: true));
    await _syncService.reconnect();
    return state.copyWith(
      isRetrying: false,
      status: UiFlowStatus.success,
      lastOperation: SyncStatusOperation.retrySync,
    );
  });

  SyncStatusState _mapStatus(SyncStatus status) {
    final SyncConnectionState connectionState;

    if (status.downloading || status.uploading) {
      connectionState = SyncConnectionState.syncing;
    } else if (status.connecting) {
      connectionState = SyncConnectionState.connecting;
    } else if (status.connected) {
      connectionState = SyncConnectionState.connected;
    } else if (status.anyError != null) {
      connectionState = SyncConnectionState.error;
    } else {
      connectionState = SyncConnectionState.disconnected;
    }

    return SyncStatusState(
      connectionState: connectionState,
      isDownloading: status.downloading,
      isUploading: status.uploading,
      lastSyncedAt: status.lastSyncedAt,
      errorMessage: status.anyError?.toString(),
    );
  }

  @override
  Future<void> close() {
    _statusSubscription?.cancel();
    return super.close();
  }
}
