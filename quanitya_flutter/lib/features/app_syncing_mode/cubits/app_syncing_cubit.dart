import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'dart:async';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../models/app_syncing_mode.dart';
import '../repositories/app_syncing_repository.dart';
import '../../../data/db/app_database.dart'; // For AppOperatingSetting
import '../exceptions/app_syncing_exceptions.dart';
import '../../../infrastructure/sync/sync_service.dart';
import 'app_syncing_state.dart';

/// Manages sync mode state (local/cloud/selfHosted).
///
/// Self-initializes from [AppSyncingRepository] stream in constructor.
/// Delegates mode persistence and connection lifecycle to [SyncService].
///
/// Pattern: cubit → service → repository.
@lazySingleton
class AppSyncingCubit extends QuanityaCubit<AppSyncingState> {
  final AppSyncingRepository _repository;
  final SyncService _syncService;

  StreamSubscription<AppOperatingSetting>? _settingsSubscription;
  bool _isUpdatingFromSelf = false;

  AppSyncingCubit(this._repository, this._syncService)
      : super(const AppSyncingState()) {
    _initialize();
  }

  /// Load initial state from database, then start streaming for changes.
  Future<void> _initialize() => tryOperation(() async {
    final settings = await _repository.getSettings();
    _initializeStreaming();
    emit(state.copyWith(
      mode: settings.mode,
      serverpodUrl: _repository.serverpodUrl,
      selfHostedUrl: settings.selfHostedUrl,
      lastConnectionTest: settings.lastConnectionTest,
      status: UiFlowStatus.success,
    ));

    if (settings.mode.supportsSync) {
      await _syncService.connect(settings.mode);
    }
    return state;
  }, emitLoading: false);

  /// Stream DB changes for external updates (e.g. another isolate).
  void _initializeStreaming() {
    _settingsSubscription?.cancel();
    _settingsSubscription = _repository.watchSettings().listen((settings) {
      if (!_isUpdatingFromSelf && settings.mode != state.mode) {
        _handleExternalModeChange(settings);
      }
      if (!_isUpdatingFromSelf &&
          settings.lastConnectionTest != state.lastConnectionTest) {
        emit(state.copyWith(
          lastConnectionTest: settings.lastConnectionTest,
        ));
      }
    });
  }

  Future<void> _handleExternalModeChange(AppOperatingSetting settings) async {
    try {
      if (settings.mode.supportsSync) {
        await _syncService.connect(settings.mode);
      } else {
        await _syncService.disconnect();
      }
      emit(state.copyWith(
        mode: settings.mode,
        selfHostedUrl: settings.selfHostedUrl,
        lastConnectionTest: settings.lastConnectionTest,
        status: UiFlowStatus.success,
        lastOperation: AppSyncingOperation.externalChange,
      ));
    } catch (e) {
      emit(state.copyWith(
        mode: settings.mode,
        selfHostedUrl: settings.selfHostedUrl,
        lastConnectionTest: settings.lastConnectionTest,
        status: UiFlowStatus.failure,
        error: e,
        lastOperation: AppSyncingOperation.externalChange,
      ));
    }
  }

  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }

  // ---------------------------------------------------------------------------
  // Mode switching — all delegate to SyncService (service owns persist + connect)
  // ---------------------------------------------------------------------------

  /// Switch to local-only mode.
  Future<void> switchToLocal({bool emitLoading = true}) async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        await _syncService.switchMode(AppSyncingMode.local);
        analytics?.trackSyncModeChanged();
        return state.copyWith(
          mode: AppSyncingMode.local,
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.switchMode,
        );
      }, emitLoading: emitLoading);
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Switch to cloud mode.
  Future<void> switchToCloud({bool emitLoading = true}) async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        await _syncService.switchMode(AppSyncingMode.cloud);
        analytics?.trackSyncModeChanged();
        return state.copyWith(
          mode: AppSyncingMode.cloud,
          hasTriedConnection: true,
          lastTestedUrl: state.serverpodUrl,
          lastConnectionTest: DateTime.now(),
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.switchMode,
        );
      }, emitLoading: emitLoading);
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Switch to self-hosted mode.
  Future<void> switchToSelfHosted(String serverUrl) async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        if (!_isValidUrl(serverUrl)) {
          throw const AppSyncingException('Invalid server URL format');
        }
        await _syncService.switchMode(AppSyncingMode.selfHosted);
        analytics?.trackSyncModeChanged();
        return state.copyWith(
          mode: AppSyncingMode.selfHosted,
          selfHostedUrl: serverUrl,
          hasTriedConnection: true,
          lastTestedUrl: serverUrl,
          lastConnectionTest: DateTime.now(),
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.switchMode,
        );
      }, emitLoading: true);
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Configure self-hosted URL without switching modes.
  Future<void> configureSelfHostedUrl(String serverUrl) => tryOperation(() async {
    if (!_isValidUrl(serverUrl)) {
      throw const AppSyncingException('Invalid server URL format');
    }
    return state.copyWith(
      selfHostedUrl: serverUrl,
      status: UiFlowStatus.success,
      lastOperation: AppSyncingOperation.configure,
    );
  });

  /// Retry connection for current mode.
  Future<void> retryConnection() async {
    if (state.mode.supportsSync) {
      await tryOperation(() async {
        await _syncService.connect(state.mode);
        return state.copyWith(
          hasTriedConnection: true,
          lastConnectionTest: DateTime.now(),
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.testConnection,
        );
      }, emitLoading: true);
    }
  }

  /// Bootstrap sync after account recovery.
  ///
  /// Resets E2EE puller checkpoints and connects through the full
  /// auth + entitlement gate. Non-fatal — app works offline if this fails.
  Future<void> startSyncAfterRecovery() => tryOperation(() async {
    await _syncService.reconnectAfterRecovery();
    return state.copyWith(
      status: UiFlowStatus.success,
      lastOperation: AppSyncingOperation.startSyncAfterRecovery,
    );
  }, emitLoading: false);

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}
