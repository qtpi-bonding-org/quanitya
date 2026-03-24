import 'package:flutter/foundation.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';
import 'package:injectable/injectable.dart';

import '../../data/repositories/e2ee_puller.dart';
import '../../data/sync/powersync_service.dart';
import '../../features/guided_tour/guided_tour_service.dart';
import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../purchase/entitlement_repository.dart';
import 'account_service.dart';
import 'auth_repository.dart';

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

  DeleteOrchestrator(
    this._accountService,
    this._authRepo,
    this._keyRepository,
    this._entitlementRepository,
    this._powerSyncRepository,
    this._e2eePuller,
    this._guidedTourService,
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
          debugPrint('Cross-device key deletion skipped: ${e.runtimeType}');
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

  /// Factory reset: wipe all local data and return the app to a fresh state.
  ///
  /// Steps:
  /// 1. Disconnect PowerSync (keep DB file — singletons still reference it)
  /// 2. Dispose E2EE puller and reset its checkpoints
  /// 3. Reset guided tour flags
  /// 4. Clear entitlement data (cache + paid flag)
  /// 5. Clear all crypto keys (includes iCloud cross-device key)
  /// 6. Clear registration flag
  ///
  /// Callers should handle UI concerns (navigation to onboarding,
  /// AppRouter.resetKeyCheck) after this completes.
  ///
  /// Throws [DeleteException] on failure.
  Future<void> factoryReset() {
    return tryMethod(
      () async {
        // 1. Disconnect PowerSync (keep DB file — singletons still reference it)
        await _powerSyncRepository.disconnect();

        // 2. Clear E2EE puller state
        await _e2eePuller.dispose();
        await _e2eePuller.resetCheckpoints();

        // 3. Reset guided tour flags
        await _guidedTourService.resetAllTours();

        // 4. Clear entitlement data (cache + paid flag)
        await _entitlementRepository.clear();

        // 5. Clear all crypto keys (includes iCloud cross-device key deletion)
        await _keyRepository.clearKeys();

        // 6. Clear registration flag
        await _authRepo.clearRegistrationFlag();
      },
      DeleteException.new,
      'factoryReset',
    );
  }
}
