import 'package:get_it/get_it.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart' as cubit_ui_flow;

import '../../../l10n/l10n_key_resolver.g.dart';

/// How the app syncs data - local-first by default
enum AppSyncingMode {
  /// Default: No server, everything local
  local,

  /// User's own Serverpod instance
  selfHosted,

  /// Paid Quanitya cloud service
  cloud,
}

extension AppSyncingModeExtension on AppSyncingMode {
  bool get requiresServer => this != AppSyncingMode.local;

  bool get supportsSync => this != AppSyncingMode.local;

  String get displayName => _translate(switch (this) {
    AppSyncingMode.local => L10nKeys.operatingModeLocal,
    AppSyncingMode.selfHosted => L10nKeys.operatingModeSelfHosted,
    AppSyncingMode.cloud => L10nKeys.operatingModeCloud,
  });

  String get description => _translate(switch (this) {
    AppSyncingMode.local => L10nKeys.operatingModeLocalDescription,
    AppSyncingMode.selfHosted => L10nKeys.operatingModeSelfHostedDescription,
    AppSyncingMode.cloud => L10nKeys.operatingModeCloudDescription,
  });

  String _translate(String key) =>
      GetIt.I<cubit_ui_flow.ILocalizationService>().translate(key);
}

/// Typedef for backward compatibility with Drift table column type
typedef AppOperatingMode = AppSyncingMode;

