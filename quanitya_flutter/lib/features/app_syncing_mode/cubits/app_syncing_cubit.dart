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
/// Self-hydrates from AppSyncingRepository stream in constructor.
/// Delegates mode changes and PowerSync connection to SyncService.
@lazySingleton
class AppSyncingCubit extends QuanityaCubit<AppSyncingState> {
  final AppSyncingRepository _repository;
  final SyncService _syncService;

  StreamSubscription<AppOperatingSetting>? _settingsSubscription;
  bool _isUpdatingFromSelf = false;

  AppSyncingCubit(this._repository, this._syncService)
      : super(const AppSyncingState()) {
    _initializeStreaming();
    _hydrate();
  }

  /// Load initial state from database
  Future<void> _hydrate() async {
    try {
      final settings = await _repository.getSettings();
      emit(state.copyWith(
        mode: settings.mode,
        serverpodUrl: _repository.serverpodUrl,
        selfHostedUrl: settings.selfHostedUrl,
        isConnected: settings.isConnected,
        lastConnectionTest: settings.lastConnectionTest,
        status: UiFlowStatus.success,
      ));

      // Auto-connect if mode supports sync
      if (settings.mode.supportsSync) {
        await _syncService.connect(settings.mode);
      }
    } catch (e) {
      // Hydration failure is non-fatal — app works in default state
    }
  }

  /// Stream DB changes for external updates
  void _initializeStreaming() {
    _settingsSubscription?.cancel();
    _settingsSubscription = _repository.watchSettings().listen((settings) {
      if (!_isUpdatingFromSelf && settings.mode != state.mode) {
        _handleExternalModeChange(settings);
      }
      if (!_isUpdatingFromSelf &&
          (settings.isConnected != state.isConnected ||
           settings.lastConnectionTest != state.lastConnectionTest)) {
        emit(state.copyWith(
          isConnected: settings.isConnected,
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
        isConnected: settings.isConnected,
        selfHostedUrl: settings.selfHostedUrl,
        lastConnectionTest: settings.lastConnectionTest,
        status: UiFlowStatus.success,
        lastOperation: AppSyncingOperation.externalChange,
      ));
    } catch (e) {
      emit(state.copyWith(
        mode: settings.mode,
        isConnected: settings.isConnected,
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

  /// Switch to local-only mode
  Future<void> switchToLocal() async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        await _syncService.disconnect();
        await _repository.updateMode(AppSyncingMode.local);
        analytics?.trackSyncModeChanged();
        return state.copyWith(
          mode: AppSyncingMode.local,
          isConnected: false,
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.switchMode,
        );
      }, emitLoading: true);
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Switch to self-hosted mode and test connection
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
          isConnected: true,
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

  /// Switch to cloud mode
  Future<void> switchToCloud() async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        await _syncService.switchMode(AppSyncingMode.cloud);
        analytics?.trackSyncModeChanged();
        return state.copyWith(
          mode: AppSyncingMode.cloud,
          isConnected: true,
          hasTriedConnection: true,
          lastTestedUrl: state.serverpodUrl,
          lastConnectionTest: DateTime.now(),
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.switchMode,
        );
      }, emitLoading: true);
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Configure self-hosted URL without switching modes
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

  /// Retry connection for current mode
  Future<void> retryConnection() async {
    if (state.mode.supportsSync) {
      await tryOperation(() async {
        await _syncService.connect(state.mode);
        return state.copyWith(
          isConnected: true,
          hasTriedConnection: true,
          lastConnectionTest: DateTime.now(),
          status: UiFlowStatus.success,
          lastOperation: AppSyncingOperation.testConnection,
        );
      }, emitLoading: true);
    }
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }
}

/// Typedef for backward compatibility
typedef AppOperatingCubit = AppSyncingCubit;
