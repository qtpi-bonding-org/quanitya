import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'dart:async';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../models/app_syncing_mode.dart';
import '../../../infrastructure/network/network_repository.dart';
import '../repositories/app_syncing_repository.dart';
import '../../../data/db/app_database.dart'; // For AppOperatingSetting
import '../exceptions/app_syncing_exceptions.dart';
import '../../../data/sync/powersync_service.dart';
import 'app_syncing_state.dart';

@lazySingleton
class AppSyncingCubit extends QuanityaCubit<AppSyncingState> {
  final AppSyncingRepository _repository;
  final INetworkRepository _networkService;

  StreamSubscription<AppOperatingSetting>? _settingsSubscription;
  bool _isUpdatingFromSelf = false; // Prevent circular updates

  AppSyncingCubit(this._repository, this._networkService) : super(const AppSyncingState());

  /// Initialize cubit by loading from database and setting up streaming
  Future<void> initialize() => tryOperation(() async {
    final settings = await _repository.getSettings();

    // Set up streaming to react to external changes
    _initializeStreaming();

    // Load initial state from database (single source of truth)
    return state.copyWith(
      mode: settings.mode,
      serverpodUrl: _repository.serverpodUrl,
      selfHostedUrl: settings.selfHostedUrl,
      isConnected: settings.isConnected,
      lastConnectionTest: settings.lastConnectionTest,
      status: UiFlowStatus.success,
    );
  }, emitLoading: true);

  /// Set up streaming to listen for external database changes
  void _initializeStreaming() {
    _settingsSubscription?.cancel(); // Cancel any existing subscription

    _settingsSubscription = _repository.watchSettings().listen((settings) {
      // Only react to external changes (not our own updates)
      if (!_isUpdatingFromSelf && settings.mode != state.mode) {
        _handleExternalModeChange(settings);
      }

      // Always update connection status and timestamps (these can change externally)
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

  /// Handle mode changes that came from external sources (like AuthService)
  Future<void> _handleExternalModeChange(AppOperatingSetting settings) async {
    try {
      // Handle PowerSync connection change
      await _handlePowerSyncModeChange(settings.mode);

      // Update UI state to reflect external change
      emit(state.copyWith(
        mode: settings.mode,
        isConnected: settings.isConnected,
        selfHostedUrl: settings.selfHostedUrl,
        lastConnectionTest: settings.lastConnectionTest,
        // Don't set status to loading - this is an external change
        status: UiFlowStatus.success,
        lastOperation: AppSyncingOperation.externalChange,
      ));
    } catch (e) {
      // If PowerSync fails, still update the mode but show error
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

  /// Test connection to a server URL — does NOT change syncing mode
  Future<void> testConnection([String? customUrl]) => tryOperation(() async {
    final url = customUrl ?? _getCurrentModeUrl();
    if (url == null) {
      throw const AppSyncingException('No URL configured for current mode');
    }

    final isReachable = await _networkService.testConnection(url);
    await _repository.updateConnectionStatus(isReachable);

    return state.copyWith(
      status: UiFlowStatus.success,
      isConnected: isReachable,
      hasTriedConnection: true,
      lastTestedUrl: url,
      lastConnectionTest: DateTime.now(),
      lastOperation: AppSyncingOperation.testConnection,
    );
  }, emitLoading: true);

  /// Switch to local-only mode (always succeeds)
  Future<void> switchToLocal() async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        await _repository.updateMode(AppSyncingMode.local);
        await _handlePowerSyncModeChange(AppSyncingMode.local);
        analytics?.trackSyncModeChanged();
        return state.copyWith(
          mode: AppSyncingMode.local,
          isConnected: false, // Local doesn't need connection
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
        // Validate URL format
        if (!_isValidUrl(serverUrl)) {
          throw const AppSyncingException('Invalid server URL format');
        }

        // Test connection
        final isReachable = await _networkService.testConnection(serverUrl);
        await _repository.updateMode(AppSyncingMode.selfHosted, selfHostedUrl: serverUrl);

        // Handle PowerSync mode change
        await _handlePowerSyncModeChange(AppSyncingMode.selfHosted);

        analytics?.trackSyncModeChanged();

        return state.copyWith(
          mode: AppSyncingMode.selfHosted,
          selfHostedUrl: serverUrl,
          isConnected: isReachable,
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

  /// Switch to cloud mode — test connection and switch
  Future<void> switchToCloud() async {
    _isUpdatingFromSelf = true;
    try {
      await tryOperation(() async {
        final isReachable = await _networkService.testConnection(state.baseUrl);

        await _repository.updateMode(AppSyncingMode.cloud);

        // Handle PowerSync mode change
        await _handlePowerSyncModeChange(AppSyncingMode.cloud);

        analytics?.trackSyncModeChanged();

        return state.copyWith(
          mode: AppSyncingMode.cloud,
          isConnected: isReachable,
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

  /// Retry connection for current mode (ping only, no mode change)
  Future<void> retryConnection() async {
    final url = _getCurrentModeUrl();
    if (url != null) {
      await testConnection(url);
    }
  }

  // Private helpers
  String? _getCurrentModeUrl() {
    return switch (state.mode) {
      AppSyncingMode.local => null,
      AppSyncingMode.selfHosted => state.selfHostedUrl,
      AppSyncingMode.cloud => state.serverpodUrl,
    };
  }

  bool _isValidUrl(String url) {
    try {
      final uri = Uri.parse(url);
      return uri.hasScheme && (uri.scheme == 'http' || uri.scheme == 'https');
    } catch (e) {
      return false;
    }
  }

  /// Handle PowerSync connection/disconnection based on syncing mode.
  ///
  /// Throws on failure — callers are responsible for handling errors:
  /// - User-initiated switches (switchToLocal/Cloud/SelfHosted): wrapped in
  ///   tryOperation, which catches and shows error toast.
  /// - External changes (_handleExternalModeChange): has its own catch that
  ///   updates mode but sets failure status.
  Future<void> _handlePowerSyncModeChange(AppSyncingMode mode) async {
    if (GetIt.instance.isRegistered<IPowerSyncRepository>() &&
        GetIt.instance.isRegistered<Client>()) {
      final powerSync = GetIt.instance<IPowerSyncRepository>();
      final client = GetIt.instance<Client>();
      await powerSync.handleModeChange(mode, client);
    }
  }
}

/// Typedef for backward compatibility
typedef AppOperatingCubit = AppSyncingCubit;
