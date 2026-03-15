import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import 'app_syncing_state.dart';

/// Message mapper for app syncing mode operations
///
/// Consolidates the cubits and services versions — handles testConnection
/// with connected/failed branching.
@injectable
class AppSyncingMessageMapper implements IStateMessageMapper<AppSyncingState> {
  @override
  MessageKey? map(AppSyncingState state) {
    if (state.status.isSuccess && state.lastOperation != null) {
      return switch (state.lastOperation!) {
        AppSyncingOperation.switchMode => MessageKey.success(L10nKeys.appOperatingModeSwitched),
        AppSyncingOperation.testConnection => state.isConnected
          ? MessageKey.success(L10nKeys.appOperatingConnectionSuccess)
          : MessageKey.error(L10nKeys.appOperatingConnectionFailed),
        AppSyncingOperation.configure => MessageKey.success(L10nKeys.appOperatingConfigured),
        AppSyncingOperation.externalChange => null, // No message for external changes
      };
    }
    return null; // Use global exception mapping for errors
  }
}

/// Typedef for backward compatibility
typedef AppOperatingMessageMapper = AppSyncingMessageMapper;
