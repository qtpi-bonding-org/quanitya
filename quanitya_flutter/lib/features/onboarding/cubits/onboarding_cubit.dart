import 'package:get_it/get_it.dart';
import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../../app_router.dart';
import '../../../infrastructure/auth/account_service.dart';
import '../../../infrastructure/feedback/localization_service.dart';
import '../../../infrastructure/platform/platform_local_auth.dart';
import '../../../infrastructure/crypto/crypto_key_repository.dart';
import '../../../infrastructure/crypto/exceptions/crypto_exceptions.dart';
import '../../../infrastructure/platform/exceptions/device_auth_exception.dart';
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
  final AccountService _accountService;
  final DeviceInfoService _deviceInfoService;

  OnboardingCubit(
    this._keyRepository,
    this._keyExportService,
    this._localAuthService,
    this._accountService,
    this._deviceInfoService,
  ) : super(const OnboardingState());

  /// Check if user already has keys (skip onboarding)
  Future<void> checkExistingAccount() => tryOperation(() async {
    final status = await _keyRepository.getKeyStatus();
    return state.copyWith(
      status: UiFlowStatus.success,
      hasExistingAccount: status == CryptoKeyStatus.ready,
    );
  }, emitLoading: false);

  /// Initialize backup page - check device authentication availability
  Future<void> initBackupPage() => tryOperation(() async {
    final deviceAuthAvailable = await _localAuthService.isDeviceAuthAvailable();
    return state.copyWith(
      status: UiFlowStatus.success,
      deviceAuthAvailable: deviceAuthAvailable,
    );
  }, emitLoading: false);

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
    await tryOperation(() async {
      final deviceLabel = await _deviceInfoService.getDeviceName();

      final result = await _accountService.createAccount(
        deviceLabel: deviceLabel,
      );

      AppRouter.resetKeyCheck();
      analytics?.trackAccountCreated();

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.createAccount,
        recoveryKeyJwk: result.ultimatePrivateKey,
      );
    }, emitLoading: true);
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
        throw const KeyRetrievalException('Failed to retrieve recovery key');
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
    final jwk = state.recoveryKeyJwk;
    if (jwk == null) return;

    await tryOperation(() async {
      final result = await _keyExportService.saveToICloudKeychain(
        jwk: jwk,
      );

      if (result == KeyExportResult.unavailable) {
        throw const KeyStorageException('iCloud Keychain not available on this device');
      }
      if (result == KeyExportResult.failed) {
        throw const KeyStorageException('Failed to save to iCloud Keychain');
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
    final jwk = state.recoveryKeyJwk;
    if (jwk == null) return;

    await tryOperation(() async {
      final result = await _keyExportService.shareAsFile(
        jwk: jwk,
      );

      if (result == KeyExportResult.cancelled) {
        // User cancelled - not an error, just return current state unchanged
        return state;
      }
      if (result == KeyExportResult.failed) {
        throw const KeyStorageException('Failed to export recovery key');
      }

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.exportToFile,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.file},
      );
    }, emitLoading: false);
  }

  /// Copy recovery key to clipboard
  Future<void> copyToClipboard() async {
    final jwk = state.recoveryKeyJwk;
    if (jwk == null) return;

    await tryOperation(() async {
      await _keyExportService.copyToClipboard(jwk: jwk);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.copyToClipboard,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.clipboard},
      );
    }, emitLoading: true);
  }

  /// Store recovery key on device with biometric protection
  Future<void> storeWithBiometrics() async {
    final jwk = state.recoveryKeyJwk;
    if (jwk == null) return;

    await tryOperation(() async {
      // Authenticate first (shows system biometric dialog)
      final authResult = await _localAuthService.authenticate(
        reason: GetIt.I<AppLocalizationService>().l10n.authenticateStoreRecoveryKey,
      );

      if (!authResult) {
        throw const DeviceAuthException('Biometric authentication failed');
      }

      // Store in secure storage (already encrypted by platform)
      await _keyExportService.storeInSecureStorage(jwk: jwk);

      return state.copyWith(
        status: UiFlowStatus.success,
        lastOperation: OnboardingOperation.storeWithBiometrics,
        completedBackupMethods: {...state.completedBackupMethods, BackupMethod.biometrics},
      );
    }, emitLoading: false);
  }

}
