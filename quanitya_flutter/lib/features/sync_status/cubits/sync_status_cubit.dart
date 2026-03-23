import 'dart:async';

import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:powersync_sqlcipher/powersync.dart' show SyncStatus;

import '../../../data/sync/powersync_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'sync_status_state.dart';

/// Observes PowerSync status stream and emits UI-friendly sync state.
///
/// Auto-subscribes in constructor — no explicit startListening() needed.
/// If PowerSync isn't connected yet, starts as disconnected and updates
/// when the stream emits.
@lazySingleton
class SyncStatusCubit extends QuanityaCubit<SyncStatusState> {
  final IPowerSyncRepository _powerSync;
  StreamSubscription<SyncStatus>? _statusSubscription;

  SyncStatusCubit(this._powerSync) : super(const SyncStatusState()) {
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

  Future<void> retrySync() => tryOperation(() async {
    emit(state.copyWith(isRetrying: true));
    await _powerSync.retrySync();
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
