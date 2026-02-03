import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../cubits/onboarding_state.dart';

/// Message mapper for onboarding operations
@injectable
class OnboardingMessageMapper implements IStateMessageMapper<OnboardingState> {
  @override
  MessageKey? map(OnboardingState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        OnboardingOperation.createAccount => MessageKey.success('onboarding.account_created'),
        OnboardingOperation.exportToICloud => MessageKey.success('onboarding.exported_icloud'),
        OnboardingOperation.exportToFile => MessageKey.success('onboarding.exported_file'),
        OnboardingOperation.copyToClipboard => MessageKey.success('onboarding.copied_clipboard'),
        OnboardingOperation.storeWithBiometrics => MessageKey.success('onboarding.stored_biometrics'),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
