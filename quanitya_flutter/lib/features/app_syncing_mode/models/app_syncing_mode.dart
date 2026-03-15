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

  String get displayName => switch (this) {
    AppSyncingMode.local => 'Local Only',
    AppSyncingMode.selfHosted => 'Self-Hosted',
    AppSyncingMode.cloud => 'Quanitya Cloud',
  };

  String get description => switch (this) {
    AppSyncingMode.local => 'All data stays on your device',
    AppSyncingMode.selfHosted => 'Sync with your own server',
    AppSyncingMode.cloud => 'Managed cloud with premium features',
  };
}

/// Typedef for backward compatibility with Drift table column type
typedef AppOperatingMode = AppSyncingMode;

