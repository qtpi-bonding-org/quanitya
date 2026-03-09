import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';
import '../cubits/app_operating_state.dart';

@injectable
class AppOperatingMessageMapper implements IStateMessageMapper<AppOperatingState> {
  @override
  MessageKey? map(AppOperatingState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AppOperatingOperation.switchMode => MessageKey.success(L10nKeys.appOperatingModeSwitched),
        AppOperatingOperation.testConnection => state.isConnected
          ? MessageKey.success(L10nKeys.appOperatingConnectionSuccess)
          : MessageKey.error(L10nKeys.appOperatingConnectionFailed),
        AppOperatingOperation.configure => MessageKey.success(L10nKeys.appOperatingConfigured),
        AppOperatingOperation.externalChange => null, // No message for external changes
      };
    }
    return null; // Use global exception mapping for errors
  }
}