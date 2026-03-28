import 'package:injectable/injectable.dart';

import '../config/debug_log.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';

import '../../data/repositories/e2ee_puller.dart';
import '../../data/sync/powersync_service.dart';
import '../../features/app_syncing_mode/models/app_syncing_mode.dart';
import '../../features/app_syncing_mode/repositories/app_syncing_repository.dart';
import '../network/network_repository.dart';
import '../auth/auth_account_orchestrator.dart';
import '../config/app_config.dart';
import '../core/try_operation.dart';
import '../purchase/entitlement_repository.dart';

const _tag = 'infrastructure/sync/sync_service';

/// Exception thrown when sync lifecycle operations fail.
class SyncException implements Exception {
  final String message;
  final Object? cause;

  const SyncException(this.message, [this.cause]);

  @override
  String toString() =>
      'SyncException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Owns the sync lifecycle: connecting/disconnecting PowerSync and managing
/// the E2EE puller.
///
/// Persists mode via [AppSyncingRepository] and manages the runtime
/// connection. Cubits call this service — they do not call the repo directly
/// for sync concerns.
@lazySingleton
class SyncService {
  final IPowerSyncRepository _powerSync;
  final AppSyncingRepository _syncRepo;
  final EntitlementRepository _entitlementRepo;
  final AuthAccountOrchestrator _authOrchestrator;
  final IE2EEPuller _puller;
  final INetworkRepository _networkService;
  final AppConfig _config;
  final Client _client;

  SyncService(
    this._powerSync,
    this._syncRepo,
    this._entitlementRepo,
    this._authOrchestrator,
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
        Log.d(_tag,'SyncService.connect: skipping — local mode');
        return;
      }

      // Ensure the Serverpod client session is active.
      // AuthAccountOrchestrator handles device re-registration if needed.
      await _authOrchestrator.ensureAuthenticated();

      // Gate on sync entitlement.
      final hasSyncAccess = await _entitlementRepo.hasSyncAccess();
      if (!hasSyncAccess) {
        Log.d(_tag,'SyncService.connect: no sync entitlement');
        throw const SyncException('No sync access — purchase a sync plan to enable cloud sync');
      }

      await _powerSync.connect(_client, mode);
      Log.d(_tag,'SyncService.connect: PowerSync connected = ${_powerSync.isConnected}');

      if (!_puller.isListening) {
        await _puller.initialize();
        Log.d(_tag,'SyncService.connect: E2EE puller initialised');
      }
    }, SyncException.new, 'connect');
  }

  /// Disconnect the E2EE puller and PowerSync.
  Future<void> disconnect() {
    return tryMethod(() async {
      if (_puller.isListening) {
        await _puller.dispose();
        Log.d(_tag,'SyncService.disconnect: E2EE puller disposed');
      }

      await _powerSync.disconnect();
      Log.d(_tag,'SyncService.disconnect: PowerSync disconnected');
    }, SyncException.new, 'disconnect');
  }

  /// Connect or disconnect, then persist [newMode] on success.
  ///
  /// Tests network reachability first. Mode is persisted only after the
  /// connection succeeds, so a failed connect never leaves stale mode in DB.
  Future<void> switchMode(AppSyncingMode newMode) {
    return tryMethod(() async {
      await _networkService.testConnection(_config.baseUrl);

      if (newMode.supportsSync) {
        await connect(newMode);
      } else {
        await disconnect();
      }

      await _syncRepo.updateMode(newMode);
      Log.d(_tag,'SyncService.switchMode: mode set to ${newMode.name}');
    }, SyncException.new, 'switchMode');
  }

  /// Disconnect and reconnect for the current persisted mode.
  ///
  /// Used by [SyncStatusCubit] retry — goes through full auth + entitlement
  /// checks unlike a raw PowerSync retry.
  Future<void> reconnect() {
    return tryMethod(() async {
      final mode = await _syncRepo.getCurrentMode();
      await disconnect();
      await connect(mode);
      Log.d(_tag,'SyncService.reconnect: reconnected in ${mode.name} mode');
    }, SyncException.new, 'reconnect');
  }

  /// Bootstrap sync after account recovery.
  ///
  /// Recovery restores the same symmetric key (not a rotation), but this
  /// device has never synced with this account's data. Checkpoints are
  /// reset so the E2EE puller processes everything from scratch.
  ///
  /// Goes through the full [connect] gate (auth + entitlement checks).
  Future<void> reconnectAfterRecovery() {
    return tryMethod(() async {
      Log.d(_tag,'SyncService.reconnectAfterRecovery: starting post-recovery sync');

      await disconnect();
      await _puller.resetCheckpoints();

      // Clear the PowerSync upload queue so stale local deletes (from factory
      // reset) aren't pushed upstream, wiping the server data.
      Log.d(_tag,'SyncService.reconnectAfterRecovery: clearing upload queue');
      await _powerSync.powerSyncDb.execute('DELETE FROM ps_crud');

      // Recovery implies the user had sync — check entitlement and force
      // cloud mode instead of reading the (possibly stale) stored mode.
      final hasSyncAccess = await _entitlementRepo.hasSyncAccess();
      final mode = hasSyncAccess ? AppSyncingMode.cloud : await _syncRepo.getCurrentMode();
      await connect(mode);

      Log.d(_tag,'SyncService.reconnectAfterRecovery: complete');
    }, SyncException.new, 'reconnectAfterRecovery');
  }
}
