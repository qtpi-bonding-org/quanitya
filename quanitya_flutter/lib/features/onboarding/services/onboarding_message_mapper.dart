import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import '../cubits/onboarding_state.dart';

/// Message mapper for onboarding operations
@injectable
class OnboardingMessageMapper implements IStateMessageMapper<OnboardingState> {
  @override
  MessageKey? map(OnboardingState state) {
    final op = state.lastOperation;
    if (state.status.isSuccess && op != null) {
      return switch (op) {
        OnboardingOperation.createAccount => MessageKey.success(L10nKeys.onboardingAccountCreated),
        OnboardingOperation.exportToICloud => MessageKey.success(L10nKeys.onboardingExportedICloud),
        OnboardingOperation.exportToFile => MessageKey.success(L10nKeys.onboardingExportedFile),
        OnboardingOperation.copyToClipboard => MessageKey.success(L10nKeys.onboardingCopiedClipboard),
        OnboardingOperation.storeWithBiometrics => MessageKey.success(L10nKeys.onboardingStoredBiometrics),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
