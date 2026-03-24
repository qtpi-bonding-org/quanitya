import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../../data/repositories/e2ee_puller.dart';
import '../../data/sync/powersync_service.dart';
import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import '../../features/app_syncing_mode/repositories/app_syncing_repository.dart';
import '../network/network_repository.dart';
import '../auth/account_service.dart';
import '../auth/auth_service.dart' show AuthService, DeviceAuthenticationException;
import '../config/app_config.dart';
import '../core/try_operation.dart';
import '../purchase/entitlement_repository.dart';
import '../purchase/entitlement_cache.dart' show CachedEntitlement;
import '../purchase/entitlement_service.dart' show syncEntitlementTags;

/// Exception thrown when sync lifecycle operations fail.
class SyncException implements Exception {
  final String message;
  final Object? cause;

  const SyncException(this.message, [this.cause]);

  @override
  String toString() =>
      'SyncException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Owns the sync lifecycle: connecting/disconnecting PowerSync, managing the
/// E2EE puller, and handling credential errors.
///
/// This service centralises logic previously scattered across bootstrap,
/// AppSyncingCubit, and UI pages. It does NOT call any cubits.
@lazySingleton
class SyncService {
  final IPowerSyncRepository _powerSync;
  final AppSyncingRepository _syncRepo;
  final EntitlementRepository _entitlementRepo;
  final AuthService _authService;
  final AccountService _accountService;
  final IE2EEPuller _puller;
  final INetworkRepository _networkService;
  final AppConfig _config;
  final Client _client;

  SyncService(
    this._powerSync,
    this._syncRepo,
    this._entitlementRepo,
    this._authService,
    this._accountService,
    this._puller,
    this._networkService,
    this._config,
    this._client,
  );

  // ---------------------------------------------------------------------------
  // Public API
  // ---------------------------------------------------------------------------

  /// Connect PowerSync and start the E2EE puller for [mode].
  ///
  /// No-op when [mode] is local. Skips connection if the user is not
  /// authenticated or does not have a sync entitlement.
  Future<void> connect(AppSyncingMode mode) {
    return tryMethod(() async {
      if (!mode.supportsSync) {
        debugPrint('SyncService.connect: skipping — local mode');
        return;
      }

      // Ensure the Serverpod client session is active.
      final authenticated = await _authService.isAuthenticated();
      if (!authenticated) {
        debugPrint('SyncService.connect: not authenticated — calling ensureAuthenticated');
        try {
          await _authService.ensureAuthenticated();
        } on DeviceAuthenticationException {
          // Device not found on server — re-register and retry once
          debugPrint('SyncService.connect: device auth failed — re-registering');
          await _accountService.ensureRegistered(deviceLabel: 'auto');
          await _authService.ensureAuthenticated();
        }
      }

      // Gate on sync entitlement.
      final hasSyncAccess = await _entitlementRepo.hasSyncAccess();
      if (!hasSyncAccess) {
        debugPrint('SyncService.connect: no sync entitlement — skipping');
        return;
      }

      await _powerSync.connect(_client, mode);
      debugPrint('SyncService.connect: PowerSync connected = ${_powerSync.isConnected}');

      if (!_puller.isListening) {
        await _puller.initialize();
        debugPrint('SyncService.connect: E2EE puller initialised');
      }
    }, SyncException.new, 'connect');
  }

  /// Disconnect the E2EE puller and PowerSync.
  Future<void> disconnect() {
    return tryMethod(() async {
      if (_puller.isListening) {
        await _puller.dispose();
        debugPrint('SyncService.disconnect: E2EE puller disposed');
      }

      await _powerSync.disconnect();
      debugPrint('SyncService.disconnect: PowerSync disconnected');
    }, SyncException.new, 'disconnect');
  }

  /// Persist [newMode] and connect or disconnect accordingly.
  ///
  /// Tests network reachability before switching, then delegates to
  /// [connect] or [disconnect].
  Future<void> switchMode(AppSyncingMode newMode) {
    return tryMethod(() async {
      await _networkService.testConnection(_config.baseUrl);
      await _syncRepo.updateMode(newMode);

      if (newMode.supportsSync) {
        await connect(newMode);
      } else {
        await disconnect();
      }

      debugPrint('SyncService.switchMode: mode set to ${newMode.name}');
    }, SyncException.new, 'switchMode');
  }

  /// Reconnect everything after account recovery changes the symmetric key.
  ///
  /// The symmetric key changes after recovery, so the E2EE puller must
  /// restart from its checkpoints rather than resuming mid-stream.
  Future<void> reconnectWithNewKeys() {
    return tryMethod(() async {
      debugPrint('SyncService.reconnectWithNewKeys: starting key-rotation reconnect');

      if (_puller.isListening) {
        await _puller.dispose();
      }
      await _puller.resetCheckpoints();

      if (_powerSync.isConnected) {
        await _powerSync.disconnect();
      }

      final mode = await _syncRepo.getCurrentMode();
      await _powerSync.connect(_client, mode);

      await _puller.initialize();
      debugPrint('SyncService.reconnectWithNewKeys: complete');
    }, SyncException.new, 'reconnectWithNewKeys');
  }

  /// React to an `insufficientCredits` error from the PowerSync connector.
  ///
  /// Zeroes all sync entitlement balances in the local cache so that the
  /// next bootstrap does not attempt to reconnect.
  Future<void> handleCredentialError() {
    return tryMethod(() async {
      debugPrint('SyncService.handleCredentialError: zeroing sync entitlements');
      try {
        final cached = await _entitlementRepo.load();
        final updated = cached.map((entry) {
          if (syncEntitlementTags.contains(entry.tag)) {
            return CachedEntitlement(
              tag: entry.tag,
              balance: 0.0,
              type: entry.type,
              name: entry.name,
            );
          }
          return entry;
        }).toList();
        await _entitlementRepo.store(updated);
        debugPrint('SyncService.handleCredentialError: entitlement cache zeroed');
      } catch (e) {
        // Cache update is best-effort — do not propagate.
        debugPrint('SyncService.handleCredentialError: cache update failed (non-fatal): $e');
      }
    }, SyncException.new, 'handleCredentialError');
  }
}
