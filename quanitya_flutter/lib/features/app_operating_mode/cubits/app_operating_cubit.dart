import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:get_it/get_it.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:flutter/foundation.dart';
import 'dart:async';

import '../../../support/extensions/cubit_ui_flow_extension.dart';
import '../models/app_operating_mode.dart';
import '../services/network_service.dart';
import '../repositories/app_operating_repository.dart';
import '../../../data/db/app_database.dart'; // For AppOperatingSetting
import '../exceptions/app_operating_exceptions.dart';
import '../../../data/sync/powersync_service.dart';
import '../../../infrastructure/purchase/i_entitlement_service.dart';
import 'app_operating_state.dart';

@injectable
class AppOperatingCubit extends QuanityaCubit<AppOperatingState> {
  final AppOperatingRepository _repository;
  final INetworkService _networkService;
  
  StreamSubscription<AppOperatingSetting>? _settingsSubscription;
  bool _isUpdatingFromSelf = false; // Prevent circular updates
  
  AppOperatingCubit(this._repository, this._networkService) : super(const AppOperatingState());

  /// Initialize cubit by loading from database and setting up streaming
  Future<void> initialize() async {
    emit(state.copyWith(status: UiFlowStatus.loading));
    try {
      final settings = await _repository.getSettings();
      
      // Load initial state from database (single source of truth)
      emit(state.copyWith(
        mode: settings.mode,
        serverpodUrl: _repository.serverpodUrl,
        selfHostedUrl: settings.selfHostedUrl,
        isConnected: settings.isConnected,
        lastConnectionTest: settings.lastConnectionTest,
        status: UiFlowStatus.success,
      ));
      
      // Set up streaming to react to external changes
      _initializeStreaming();
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    }
  }
  
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
        lastOperation: AppOperatingOperation.externalChange,
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
        lastOperation: AppOperatingOperation.externalChange,
      ));
    }
  }
  
  @override
  Future<void> close() {
    _settingsSubscription?.cancel();
    return super.close();
  }

  /// Test connection to a server URL (ping) - does NOT change operating mode
  Future<void> pingConnection([String? customUrl]) async {
    emit(state.copyWith(status: UiFlowStatus.loading));
    try {
      final url = customUrl ?? _getCurrentModeUrl();
      if (url == null) {
        throw const AppOperatingException('No URL configured for current mode');
      }
      
      final isReachable = await _networkService.testConnection(url);
      await _repository.updateConnectionStatus(isReachable);
      
      emit(state.copyWith(
        status: UiFlowStatus.success,
        isConnected: isReachable,
        hasTriedConnection: true,
        lastTestedUrl: url,
        lastConnectionTest: DateTime.now(),
        lastOperation: AppOperatingOperation.testConnection,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    }
  }

  /// Test connection to a server URL
  Future<void> testConnection([String? customUrl]) async {
    emit(state.copyWith(status: UiFlowStatus.loading));
    try {
      final url = customUrl ?? _getCurrentModeUrl();
      if (url == null) {
        throw const AppOperatingException('No URL configured for current mode');
      }
      
      final isReachable = await _networkService.testConnection(url);
      await _repository.updateConnectionStatus(isReachable);
      
      emit(state.copyWith(
        status: UiFlowStatus.success,
        isConnected: isReachable,
        hasTriedConnection: true,
        lastTestedUrl: url,
        lastConnectionTest: DateTime.now(),
        lastOperation: AppOperatingOperation.testConnection,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    }
  }

  /// Switch to local-only mode (always succeeds)
  Future<void> switchToLocal() async {
    emit(state.copyWith(status: UiFlowStatus.loading));
    _isUpdatingFromSelf = true;
    try {
      await _repository.updateMode(AppOperatingMode.local);
      
      // Handle PowerSync mode change
      await _handlePowerSyncModeChange(AppOperatingMode.local);
      
      emit(state.copyWith(
        mode: AppOperatingMode.local,
        isConnected: false, // Local doesn't need connection
        status: UiFlowStatus.success,
        lastOperation: AppOperatingOperation.switchMode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Switch to self-hosted mode and test connection
  Future<void> switchToSelfHosted(String serverUrl) async {
    emit(state.copyWith(status: UiFlowStatus.loading));
    _isUpdatingFromSelf = true;
    try {
      // Validate URL format
      if (!_isValidUrl(serverUrl)) {
        throw const AppOperatingException('Invalid server URL format');
      }
      
      // Test connection
      final isReachable = await _networkService.testConnection(serverUrl);
      await _repository.updateMode(AppOperatingMode.selfHosted, selfHostedUrl: serverUrl);
      
      // Handle PowerSync mode change
      await _handlePowerSyncModeChange(AppOperatingMode.selfHosted);
      
      emit(state.copyWith(
        mode: AppOperatingMode.selfHosted,
        selfHostedUrl: serverUrl,
        isConnected: isReachable,
        hasTriedConnection: true,
        lastTestedUrl: serverUrl,
        lastConnectionTest: DateTime.now(),
        status: UiFlowStatus.success,
        lastOperation: AppOperatingOperation.switchMode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Switch to cloud mode (requires payment verification)
  Future<void> switchToCloud() async {
    emit(state.copyWith(status: UiFlowStatus.loading));
    _isUpdatingFromSelf = true;
    try {
      // Verify entitlement (sync days) before allowing cloud mode
      if (GetIt.instance.isRegistered<IEntitlementService>()) {
        final hasSyncAccess =
            await GetIt.instance<IEntitlementService>().hasSyncAccess();
        if (!hasSyncAccess) {
          throw const AppOperatingException(
            'Cloud access requires sync days. Purchase sync time to continue.',
          );
        }
      }

      final isReachable = await _networkService.testConnection(state.baseUrl);
      await _repository.updateMode(AppOperatingMode.cloud);
      
      // Handle PowerSync mode change
      await _handlePowerSyncModeChange(AppOperatingMode.cloud);
      
      emit(state.copyWith(
        mode: AppOperatingMode.cloud,
        isConnected: isReachable,
        hasTriedConnection: true,
        lastTestedUrl: state.serverpodUrl,
        lastConnectionTest: DateTime.now(),
        status: UiFlowStatus.success,
        lastOperation: AppOperatingOperation.switchMode,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    } finally {
      _isUpdatingFromSelf = false;
    }
  }

  /// Configure self-hosted URL without switching modes
  Future<void> configureSelfHostedUrl(String serverUrl) async {
    try {
      if (!_isValidUrl(serverUrl)) {
        throw const AppOperatingException('Invalid server URL format');
      }
      
      emit(state.copyWith(
        selfHostedUrl: serverUrl,
        status: UiFlowStatus.success,
        lastOperation: AppOperatingOperation.configure,
      ));
    } catch (e) {
      emit(state.copyWith(
        status: UiFlowStatus.failure,
        error: e,
      ));
    }
  }

  /// Retry connection for current mode (ping only, no mode change)
  Future<void> retryConnection() async {
    final url = _getCurrentModeUrl();
    if (url != null) {
      await pingConnection(url);
    }
  }

  // Private helpers
  String? _getCurrentModeUrl() {
    return switch (state.mode) {
      AppOperatingMode.local => null,
      AppOperatingMode.selfHosted => state.selfHostedUrl,
      AppOperatingMode.cloud => state.serverpodUrl,
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

  /// Handle PowerSync connection/disconnection based on operating mode
  Future<void> _handlePowerSyncModeChange(AppOperatingMode mode) async {
    try {
      debugPrint('🔄 AppOperatingCubit: Handling PowerSync mode change to: ${mode.name}');
      if (GetIt.instance.isRegistered<IPowerSyncService>() && 
          GetIt.instance.isRegistered<Client>()) {
        final powerSync = GetIt.instance<IPowerSyncService>();
        final client = GetIt.instance<Client>();
        debugPrint('🔄 AppOperatingCubit: PowerSync and Client services found, calling handleModeChange...');
        await powerSync.handleModeChange(mode, client);
        debugPrint('🔄 AppOperatingCubit: PowerSync mode change completed successfully');
      } else {
        debugPrint('🔄 AppOperatingCubit: PowerSync or Client services not registered, skipping mode change');
      }
    } catch (e) {
      // Don't fail the mode switch if PowerSync fails
      // Just log the error - app can work without sync
      debugPrint('⚠️ AppOperatingCubit: PowerSync mode change failed: $e');
    }
  }
}