import 'package:flutter/foundation.dart';
import 'package:logging/logging.dart';

/// Development-only configuration settings
///
/// These settings are only available in debug mode and are intended
/// for developers to control various aspects of the app during development.
///
/// ## Quick Toggle Instructions:
///
/// To disable PowerSync logging (recommended when it's too noisy):
/// 1. Change `enablePowerSyncLogging = false` below
/// 2. Hot restart the app (hot reload won't work for this change)
///
/// To re-enable PowerSync logging:
/// 1. Change `enablePowerSyncLogging = true` below
/// 2. Hot restart the app
class DevConfig {
  /// Controls PowerSync logging output
  ///
  /// When true (default), PowerSync logs are shown in debug console.
  /// When false, PowerSync logs are suppressed.
  ///
  /// This only affects debug builds - release builds never show PowerSync logs.
  ///
  /// ⚠️ DEVELOPER NOTE: Change this value and hot restart to toggle logging
  static bool enablePowerSyncLogging = true;

  /// Controls PowerSync connection error messages
  ///
  /// When true (default), connection errors from PowerSyncService are shown.
  /// When false, connection error messages are suppressed.
  ///
  /// This only affects debug builds.
  ///
  /// ⚠️ DEVELOPER NOTE: Change this value and hot restart to toggle error logging
  static bool enablePowerSyncConnectionErrors = true;

  /// Apply logging configuration based on current settings
  static void applyLoggingConfig() {
    // Enable hierarchical logging for fine-grained control
    hierarchicalLoggingEnabled = true;

    if (!kDebugMode) {
      // Always disable logging in release mode
      Logger.root.level = Level.OFF;
      return;
    }

    // In debug mode, keep root logger active for other app logs
    Logger.root.level = Level.ALL;
  }

  /// Get a logger for PowerSync based on current settings
  static Logger getPowerSyncLogger() {
    final logger = Logger('PowerSyncLogger');
    logger.level = enablePowerSyncLogging ? Level.ALL : Level.OFF;
    return logger;
  }
}
