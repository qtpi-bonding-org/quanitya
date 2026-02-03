/// How the app operates - local-first by default
enum AppOperatingMode {
  /// Default: No server, everything local
  local,
  
  /// User's own Serverpod instance
  selfHosted,
  
  /// Paid Quanitya cloud service
  cloud,
}

extension AppOperatingModeExtension on AppOperatingMode {
  bool get requiresServer => this != AppOperatingMode.local;
  
  bool get supportsSync => this != AppOperatingMode.local;
  
  String get displayName => switch (this) {
    AppOperatingMode.local => 'Local Only',
    AppOperatingMode.selfHosted => 'Self-Hosted',
    AppOperatingMode.cloud => 'Quanitya Cloud',
  };
  
  String get description => switch (this) {
    AppOperatingMode.local => 'All data stays on your device',
    AppOperatingMode.selfHosted => 'Sync with your own server',
    AppOperatingMode.cloud => 'Managed cloud with premium features',
  };
}