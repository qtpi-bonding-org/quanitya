import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:injectable/injectable.dart';
import 'package:powersync_sqlcipher/powersync.dart' show SyncStatus;

import '../../../data/sync/powersync_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../../app_syncing_mode/models/app_syncing_mode.dart';
import 'sync_status_state.dart';

@lazySingleton
class SyncStatusCubit extends QuanityaCubit<SyncStatusState> {
  final IPowerSyncRepository _powerSyncService;
  StreamSubscription<SyncStatus>? _statusSubscription;

  SyncStatusCubit(this._powerSyncService) : super(const SyncStatusState());

  void startListening(AppSyncingMode mode) {
    _statusSubscription?.cancel();
    debugPrint('🔄 SyncStatusCubit: startListening(mode=${mode.name}, psConnected=${_powerSyncService.isConnected})');

    if (!mode.supportsSync) {
      debugPrint('🔄 SyncStatusCubit: mode does not support sync → disabled');
      emit(const SyncStatusState(connectionState: SyncConnectionState.disabled));
      return;
    }

    if (!_powerSyncService.isConnected) {
      debugPrint('🔄 SyncStatusCubit: PowerSync not connected → disconnected');
      emit(const SyncStatusState(connectionState: SyncConnectionState.disconnected));
    }

    _statusSubscription = _powerSyncService.statusStream.listen(
      (status) {
        debugPrint('🔄 SyncStatusCubit: PS status → connected=${status.connected} downloading=${status.downloading} uploading=${status.uploading} error=${status.anyError}');
        emit(_mapStatus(status));
      },
      onError: (error) {
        emit(state.copyWith(
          connectionState: SyncConnectionState.error,
          errorMessage: error.toString(),
        ));
      },
    );
  }

  void onModeChanged(AppSyncingMode mode) {
    if (!mode.supportsSync) {
      _statusSubscription?.cancel();
      emit(const SyncStatusState(connectionState: SyncConnectionState.disabled));
    } else {
      startListening(mode);
    }
  }

  Future<void> retrySync() => tryOperation(() async {
    emit(state.copyWith(isRetrying: true));
    await _powerSyncService.retrySync();
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
