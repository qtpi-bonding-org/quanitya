import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'app_operating_state.dart';

/// Message mapper for app operating mode operations
@injectable
class AppOperatingMessageMapper
    implements IStateMessageMapper<AppOperatingState> {
  @override
  MessageKey? map(AppOperatingState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AppOperatingOperation.testConnection =>
          MessageKey.success(L10nKeys.appOperatingConnectionTested),
        AppOperatingOperation.switchMode =>
          MessageKey.success(L10nKeys.appOperatingModeSwitched),
        AppOperatingOperation.configure =>
          MessageKey.success(L10nKeys.appOperatingConfigured),
        AppOperatingOperation.externalChange =>
          MessageKey.info(L10nKeys.appOperatingModeChangedExternally),
      };
    }
    return null; // Use global exception mapping for errors
  }
}
