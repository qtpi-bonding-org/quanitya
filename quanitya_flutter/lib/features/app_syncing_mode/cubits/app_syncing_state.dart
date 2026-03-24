import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../models/app_syncing_mode.dart';

part 'app_syncing_state.freezed.dart';

/// Operations tracked for message mapping
enum AppSyncingOperation {
  testConnection,
  switchMode,
  configure,
  recoverFromCloudSync, // Reconnect with new keys after account recovery
  externalChange, // Mode changed by external source (e.g., AuthService)
}

/// Typedef for backward compatibility

@freezed
class AppSyncingState with _$AppSyncingState, UiFlowStateMixin implements IUiFlowState {
  const factory AppSyncingState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    AppSyncingOperation? lastOperation,

    // Core state
    @Default(AppSyncingMode.local) AppSyncingMode mode,
    @Default(false) bool hasTriedConnection,

    // Server URLs
    @Default('http://localhost:8080/') String serverpodUrl,
    String? selfHostedUrl,

    // Connection test results
    String? lastTestedUrl,
    DateTime? lastConnectionTest,
  }) = _AppSyncingState;

  const AppSyncingState._();
}

/// Typedef for backward compatibility

extension AppSyncingStateExtension on AppSyncingState {
  /// Current server URL based on mode
  String? get currentServerUrl {
    return switch (mode) {
      AppSyncingMode.local => null,
      AppSyncingMode.selfHosted => selfHostedUrl,
      AppSyncingMode.cloud => serverpodUrl,
    };
  }

  /// Extract base URL from serverpod URL for health checks
  /// e.g., https://staging.quanitya.com/api/ -> https://staging.quanitya.com
  String get baseUrl {
    final uri = Uri.parse(serverpodUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }

  /// Can create accounts (requires server mode or local mode)
  bool get canCreateAccount => switch (mode) {
    AppSyncingMode.local => true, // Always can create locally
    AppSyncingMode.selfHosted || AppSyncingMode.cloud => true,
  };

  /// Should show sync features in UI
  bool get showSyncFeatures => mode.supportsSync;

  /// Needs configuration (self-hosted mode without URL)
  bool get needsConfiguration => switch (mode) {
    AppSyncingMode.local => false,
    AppSyncingMode.selfHosted => selfHostedUrl == null,
    AppSyncingMode.cloud => false,
  };
}

