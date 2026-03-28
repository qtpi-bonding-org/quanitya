import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:injectable/injectable.dart';
import '../config/debug_log.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart' show Client;
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show FlutterAuthSessionManagerExtension;

import '../../data/repositories/e2ee_puller.dart';
import '../../data/sync/powersync_service.dart';
import '../../features/guided_tour/guided_tour_service.dart';
import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/key_export_service.dart';
import '../purchase/entitlement_repository.dart';
import '../security/database_key_service.dart';
import 'account_service.dart';
import 'auth_repository.dart';

const _tag = 'infrastructure/auth/delete_orchestrator';

/// Exception for delete/reset operations.
class DeleteException implements Exception {
  const DeleteException(this.message, [this.cause]);
  final String message;
  final Object? cause;

  @override
  String toString() =>
      'DeleteException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Service for destructive account operations: deletion and factory reset.
///
/// Centralises the multi-step teardown sequences that were previously
/// scattered across UI widgets (settings page and dev tools sheet).
///
/// Callers are still responsible for UI concerns such as navigation
/// (e.g. routing to onboarding) and cubit updates (e.g. switchToLocal).
@lazySingleton
class DeleteOrchestrator {
  final AccountService _accountService;
  final AuthRepository _authRepo;
  final ICryptoKeyRepository _keyRepository;
  final EntitlementRepository _entitlementRepository;
  final IPowerSyncRepository _powerSyncRepository;
  final IE2EEPuller _e2eePuller;
  final GuidedTourService _guidedTourService;
  final Client _client;
  final DatabaseKeyService _dbKeyService;
  final KeyExportService _keyExportService;

  DeleteOrchestrator(
    this._accountService,
    this._authRepo,
    this._keyRepository,
    this._entitlementRepository,
    this._powerSyncRepository,
    this._e2eePuller,
    this._guidedTourService,
    this._client,
    this._dbKeyService,
    this._keyExportService,
  );

  /// Delete the user's account on the server and clean up local state.
  ///
  /// Steps:
  /// 1. Server-side account deletion (via [AccountService.deleteAccount])
  /// 2. Delete cross-device key from iCloud (non-critical)
  /// 3. Clear the "registered with server" flag
  /// 4. Clear entitlement cache (server data is gone)
  /// 5. Disconnect PowerSync (nothing to sync anymore)
  ///
  /// Callers should handle UI concerns (toast, navigation, switchToLocal)
  /// after this completes.
  ///
  /// Throws [DeleteException] on failure.
  Future<void> deleteAccount() {
    return tryMethod(
      () async {
        // 1. Delete server-side account and all associated data
        await _accountService.deleteAccount();

        // 2. Delete cross-device key (orphaned — server registration is gone)
        try {
          await _keyRepository.deleteCrossDeviceKey();
        } catch (e, stack) {
          // Non-critical — key may not exist
          Log.d(_tag, 'Cross-device key deletion skipped: ${e.runtimeType}');
          await ErrorPrivserver.captureError(e, stack, source: 'DeleteOrchestrator');
        }

        // 3. Clear registration flag so the app knows it's no longer registered
        await _authRepo.clearRegistrationFlag();

        // 4. Clear entitlement data (cache + paid flag)
        await _entitlementRepository.clear();

        // 5. Disconnect PowerSync (nothing to sync anymore)
        await _powerSyncRepository.disconnect();
      },
      DeleteException.new,
      'deleteAccount',
    );
  }

  /// Factory reset: wipe all local state and return the app to fresh install.
  ///
  /// Requires a hot restart after completion — the stale SQLite DB file is
  /// deleted on next launch when the missing SQLCipher key is detected.
  ///
  /// Throws [DeleteException] on failure.
  Future<void> factoryReset() {
    return tryMethod(
      () async {
        // 1. Disconnect PowerSync
        await _powerSyncRepository.disconnect();

        // 2. Clear JWT session (in-memory)
        await _client.auth.updateSignedInUser(null);

        // 3. Wipe ALL device-local secure storage (crypto keys, registration
        //    flag, SQLCipher key). On next cold start, missing SQLCipher key
        //    triggers DB file deletion → fresh PowerSync DB.
        await const FlutterSecureStorage().deleteAll();

        // 4. Delete iCloud cross-device key (separate from device storage).
        await _keyRepository.deleteCrossDeviceKey();

        // 5. Delete ultimate key from iCloud Keychain.
        await _keyExportService.deleteFromICloudKeychain();
      },
      DeleteException.new,
      'factoryReset',
    );
  }
}
