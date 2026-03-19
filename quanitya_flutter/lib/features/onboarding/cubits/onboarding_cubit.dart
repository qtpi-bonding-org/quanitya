import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../infrastructure/auth/auth_service.dart';
import '../../../infrastructure/feedback/localization_service.dart';
import '../../../infrastructure/platform/platform_local_auth.dart';
import '../../../infrastructure/crypto/crypto_key_repository.dart';
import '../../../infrastructure/crypto/key_export_service.dart';
import '../../../infrastructure/device/device_info_service.dart';
import '../../../support/extensions/cubit_ui_flow_extension.dart';
import 'onboarding_state.dart';

/// Cubit for account creation with server registration and recovery key backup.
/// 
/// Flow:
/// 1. User taps "Get Started"
/// 2. createAccount() generates keys AND registers with server
/// 3. Recovery key backup page shows checklist of methods
/// 4. User can complete multiple backup methods
/// 5. User continues when at least one method done (or acknowledges risk)
@injectable
class OnboardingCubit extends QuanityaCubit<OnboardingState> {
  final ICryptoKeyRepository _keyRepository;
  final KeyExportService _keyExportService;
  final PlatformLocalAuth _localAuthService;
  final AuthService _authService;
  final DeviceInfoService _deviceInfoService;

  OnboardingCubit(
    this._keyRepository,
    this._keyExportService,
    this._localAuthService,
    this._authService,
    this._deviceInfoService,
  ) : super(const OnboardingState());

  /// Check if user already has keys (skip onboarding)
  Future<bool> checkExistingAccount() async {
    final status = await _keyRepository.getKeyStatus();
    return status == CryptoKeyStatus.ready;
  }

  /// Initialize backup page - check device authentication availability
  Future<void> initBackupPage() async {
    final deviceAuthAvailable = await _localAuthService.isDeviceAuthAvailable();
    emit(state.copyWith(deviceAuthAvailable: deviceAuthAvailable));
  }

  /// Create account with server registration and all encryption keys.
  /// 
  /// Generates locally:
  /// - Ultimate Key (4096-bit) → returned for user backup
  /// - Device Key (3072-bit) → stored in secure storage
  /// - Symmetric Key (AES-256) → stored in secure storage
  /// 
  /// Registers with server:
  /// - Account with publicMasterKey + encrypted recovery blob
  /// - This device with deviceSigningPublicKeyHex + encrypted device blob
  Future<void> createAccount() async {
    debugPrint('OnboardingCubit: createAccount() called');
    await tryOperation(() async {
      debugPrint('OnboardingCubit: Inside tryOperation, calling authService.createAccount...');
      
      // Get device name automatically
      final deviceLabel = await _deviceInfoService.getDeviceName();
      debugPrint('OnboardingCubit: Device label: $deviceLabel');
      
      // Create account on server (also generates all keys locally)
      final result = await _authService.createAccount(
        deviceLabel: deviceLabel,
      );
      debugPrint('OnboardingCubit: authService.createAccount returned, recoveryKey length: ${result.ultimatePrivateKey.length}');

      // Reset router key check since we now have keys
      AppRouter.resetKeyCheck();

      analytics?.trackAccountCreated();

      final newState = state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.createAccount,
        recoveryKeyJwk: result.ultimatePrivateKey,
      );
      debugPrint('OnboardingCubit: Returning new state with hasAccount=${newState.hasAccount}');
      return newState;
    }, emitLoading: true);
    debugPrint('OnboardingCubit: createAccount() completed, current state hasAccount=${state.hasAccount}, status=${state.status}');
  }

  /// Create a local-only account (offline mode, no server registration)
  /// 
  /// Use this when server is unavailable or user wants offline-only mode.
  Future<void> createLocalAccount() async {
    await tryOperation(() async {
      // Generate all keys locally only (repository guards against duplicates)
      await _keyRepository.generateAccountKeys();

      // Get the recovery key (one-time retrieval, wipes from memory)
      final recoveryKeyJwk = await _keyRepository.getUltimateKeyJwkOnce();
      if (recoveryKeyJwk == null) {
        throw Exception('Failed to retrieve recovery key');
      }

      // Reset router key check since we now have keys
      AppRouter.resetKeyCheck();

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.createAccount,
        recoveryKeyJwk: recoveryKeyJwk,
      );
    }, emitLoading: true);
  }

  /// Export recovery key to iCloud Keychain (iOS only)
  Future<void> exportToICloud() async {
    if (state.recoveryKeyJwk == null) return;

    await tryOperation(() async {
      final result = await _keyExportService.saveToICloudKeychain(
        jwk: state.recoveryKeyJwk!,
      );

      if (result == KeyExportResult.unavailable) {
        throw Exception('iCloud Keychain not available on this device');
      }
      if (result == KeyExportResult.failed) {
        throw Exception('Failed to save to iCloud Keychain');
      }

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.exportToICloud,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.iCloud},
      );
    }, emitLoading: true);
  }

  /// Export recovery key via share sheet as file
  Future<void> exportToFile() async {
    if (state.recoveryKeyJwk == null) return;

    await tryOperation(() async {
      final result = await _keyExportService.shareAsFile(
        jwk: state.recoveryKeyJwk!,
      );

      if (result == KeyExportResult.cancelled) {
        // User cancelled - not an error, just return to idle
        return state.copyWith(status: UiFlowStatus.idle);
      }
      if (result == KeyExportResult.failed) {
        throw Exception('Failed to export recovery key');
      }

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.exportToFile,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.file},
      );
    }, emitLoading: true);
  }

  /// Copy recovery key to clipboard
  Future<void> copyToClipboard() async {
    if (state.recoveryKeyJwk == null) return;

    await tryOperation(() async {
      await _keyExportService.copyToClipboard(jwk: state.recoveryKeyJwk!);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.copyToClipboard,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.clipboard},
      );
    }, emitLoading: true);
  }

  /// Store recovery key on device with biometric protection
  Future<void> storeWithBiometrics() async {
    if (state.recoveryKeyJwk == null) return;

    await tryOperation(() async {
      // Authenticate first
      final authResult = await _localAuthService.authenticate(
        reason: GetIt.I<AppLocalizationService>().l10n.authenticateStoreRecoveryKey,
      );

      if (!authResult) {
        throw Exception('Biometric authentication failed');
      }

      // Store in secure storage (already encrypted by platform)
      await _keyExportService.storeInSecureStorage(jwk: state.recoveryKeyJwk!);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.storeWithBiometrics,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.biometrics},
      );
    }, emitLoading: true);
  }

}
