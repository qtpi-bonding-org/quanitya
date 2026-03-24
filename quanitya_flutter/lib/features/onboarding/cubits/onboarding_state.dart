import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

part 'onboarding_state.freezed.dart';

/// Operations tracked for message mapping
enum OnboardingOperation {
  createAccount,
  exportToICloud,
  exportToFile,
  copyToClipboard,
  storeWithBiometrics,
}

/// Backup methods available for recovery key
enum BackupMethod {
  iCloud,
  file,
  clipboard,
  biometrics,
}

@freezed
class OnboardingState with _$OnboardingState, UiFlowStateMixin implements IUiFlowState {
  const OnboardingState._();

  const factory OnboardingState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    OnboardingOperation? lastOperation,
    /// The recovery key JWK - only available after account creation
    String? recoveryKeyJwk,
    /// Backup methods that have been completed
    @Default({}) Set<BackupMethod> completedBackupMethods,
    /// Whether device-level authentication is available (biometrics, PIN, pattern, password)
    @Default(false) bool deviceAuthAvailable,
    /// Whether the user already has an existing account (keys are ready)
    @Default(false) bool hasExistingAccount,
  }) = _OnboardingState;

  /// Whether account has been created (recovery key is available)
  bool get hasAccount => recoveryKeyJwk != null;

  /// Whether at least one backup method is completed
  bool get hasCompletedBackup => completedBackupMethods.isNotEmpty;

  /// Whether user can continue - must have at least one backup method
  bool get canContinue => hasCompletedBackup;
}
