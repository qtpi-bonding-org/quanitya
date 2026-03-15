import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:powersync_sqlcipher/powersync.dart' show SyncStatus;

import '../../../data/sync/powersync_service.dart';
import '../../app_syncing_mode/models/app_syncing_mode.dart';
import 'sync_status_state.dart';

@injectable
class SyncStatusCubit extends Cubit<SyncStatusState> {
  final IPowerSyncService _powerSyncService;
  StreamSubscription<SyncStatus>? _statusSubscription;

  SyncStatusCubit(this._powerSyncService) : super(const SyncStatusState());

  void startListening(AppSyncingMode mode) {
    _statusSubscription?.cancel();

    if (!mode.supportsSync) {
      emit(const SyncStatusState(connectionState: SyncConnectionState.disabled));
      return;
    }

    if (!_powerSyncService.isConnected) {
      emit(const SyncStatusState(connectionState: SyncConnectionState.disconnected));
    }

    _statusSubscription = _powerSyncService.statusStream.listen(
      (status) {
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

  Future<void> retrySync() async {
    emit(state.copyWith(isRetrying: true));
    try {
      await _powerSyncService.retrySync();
    } catch (_) {
      emit(state.copyWith(
        connectionState: SyncConnectionState.error,
        errorMessage: 'Retry failed',
      ));
    } finally {
      emit(state.copyWith(isRetrying: false));
    }
  }

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
