import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import '../models/app_operating_mode.dart';

part 'app_operating_state.freezed.dart';

/// Operations tracked for message mapping
enum AppOperatingOperation {
  testConnection,
  switchMode,
  configure,
  externalChange, // Mode changed by external source (e.g., AuthService)
}

@freezed
class AppOperatingState with _$AppOperatingState implements IUiFlowState {
  const factory AppOperatingState({
    @Default(UiFlowStatus.idle) UiFlowStatus status,
    Object? error,
    AppOperatingOperation? lastOperation,
    
    // Core state
    @Default(AppOperatingMode.local) AppOperatingMode mode,
    @Default(false) bool isConnected,
    @Default(false) bool hasTriedConnection,
    
    // Server URLs
    @Default('http://localhost:8080/') String serverpodUrl,
    String? selfHostedUrl,
    
    // Connection test results
    String? lastTestedUrl,
    DateTime? lastConnectionTest,
  }) = _AppOperatingState;

  // IUiFlowState implementations
  const AppOperatingState._();
  
  @override
  bool get isIdle => status == UiFlowStatus.idle;
  
  @override
  bool get isLoading => status == UiFlowStatus.loading;
  
  @override
  bool get isSuccess => status == UiFlowStatus.success;
  
  @override
  bool get isFailure => status == UiFlowStatus.failure;
  
  @override
  bool get hasError => error != null;
}

extension AppOperatingStateExtension on AppOperatingState {
  /// Current server URL based on mode and connection status
  String? get currentServerUrl {
    if (!isConnected) return null;
    
    return switch (mode) {
      AppOperatingMode.local => null,
      AppOperatingMode.selfHosted => selfHostedUrl,
      AppOperatingMode.cloud => serverpodUrl,
    };
  }
  
  /// Extract base URL from serverpod URL for health checks
  /// e.g., https://staging.quanitya.com/api/ -> https://staging.quanitya.com
  String get baseUrl {
    final uri = Uri.parse(serverpodUrl);
    return '${uri.scheme}://${uri.host}${uri.hasPort ? ':${uri.port}' : ''}';
  }
  
  /// Can create accounts (requires server connection or local mode)
  bool get canCreateAccount => switch (mode) {
    AppOperatingMode.local => true, // Always can create locally
    AppOperatingMode.selfHosted || AppOperatingMode.cloud => isConnected,
  };
  
  /// Should show sync features in UI
  bool get showSyncFeatures => mode.supportsSync && isConnected;
  
  /// Needs configuration (server modes without connection)
  bool get needsConfiguration => switch (mode) {
    AppOperatingMode.local => false,
    AppOperatingMode.selfHosted => selfHostedUrl == null || !isConnected,
    AppOperatingMode.cloud => !isConnected,
  };
}