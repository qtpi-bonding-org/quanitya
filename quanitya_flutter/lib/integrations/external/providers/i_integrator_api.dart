import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/integration_enums.dart';

part 'i_integrator_api.freezed.dart';

/// Service-specific API client interface for external integrations.
///
/// Handles the communication with external services, including:
/// - HTTP requests with proper authentication
/// - Rate limiting and retry logic
/// - Service-specific data formatting
/// - Health checks and connection testing
///
/// Each service provider can have multiple API implementations
/// for different data types (e.g., YNAB transactions vs budgets).
abstract class IIntegratorApi {
  /// The external service provider this API connects to.
  ServiceProvider get serviceProvider;

  /// The specific data type this API handles.
  /// Examples: "transactions", "commits", "database"
  String get dataType;

  /// Human-readable name for UI display.
  /// Examples: "YNAB Transactions", "GitHub Commits", "Notion Database"
  String get displayName;

  /// Base URL for the external service API.
  String get baseUrl;

  /// Unique integration identifier derived from service and data type.
  /// Format: "{serviceProvider.name}.{dataType}"
  /// Examples: "ynab.transactions", "github.commits", "notion.database"
  String get integrationId => '${serviceProvider.name}.$dataType';

  /// Initialize the API client.
  ///
  /// Performs any necessary setup such as:
  /// - Validating configuration
  /// - Setting up HTTP clients
  /// - Initializing rate limiters
  ///
  /// Should be called before using other methods.
  Future<void> initialize();

  /// Clean up API client resources.
  ///
  /// Performs cleanup such as:
  /// - Closing HTTP connections
  /// - Clearing caches
  /// - Stopping background tasks
  ///
  /// Should be called when the integration is disabled or app shuts down.
  Future<void> cleanup();

  /// Check the health and availability of the external service.
  ///
  /// Performs a lightweight check to verify:
  /// - Service is reachable
  /// - Authentication is working
  /// - API is responding normally
  ///
  /// Returns [HealthStatus] indicating current service state.
  Future<HealthStatus> checkHealth();

  /// Fetch data from the external service.
  ///
  /// Handles all aspects of data retrieval including:
  /// - Authentication via provided headers
  /// - Rate limiting and retries
  /// - Pagination (returns all pages)
  /// - Error handling and recovery
  ///
  /// Parameters:
  /// - [authHeaders]: Authentication headers from IIntegratorAuth
  /// - [params]: Optional query parameters for filtering/pagination
  ///
  /// Returns list of raw JSON objects that will be processed by adapters.
  /// Throws [IntegratorApiException] on errors.
  Future<List<Map<String, dynamic>>> fetchData({
    required Map<String, String> authHeaders,
    Map<String, dynamic>? params,
  });

  /// Test the connection to the external service.
  ///
  /// Performs a simple connectivity test with the provided authentication.
  /// Used during integration setup to verify credentials work.
  ///
  /// Parameters:
  /// - [authHeaders]: Authentication headers to test
  ///
  /// Returns true if connection successful, false otherwise.
  /// Does not throw exceptions - returns false for any error.
  Future<bool> testConnection(Map<String, String> authHeaders);
}

/// Health status of an external service.
///
/// Provides detailed information about service availability
/// and any issues that might affect data synchronization.
@freezed
abstract class HealthStatus with _$HealthStatus {
  const HealthStatus._();
  /// Service is healthy and operating normally.
  const factory HealthStatus.healthy({
    /// Optional metadata about the service state
    Map<String, dynamic>? metadata,
  }) = HealthStatusHealthy;

  /// Service is experiencing issues but may still work.
  const factory HealthStatus.degraded({
    /// Description of the degraded state
    required String message,
    /// Optional details about the issues
    Map<String, dynamic>? details,
  }) = HealthStatusDegraded;

  /// Service is unavailable or not responding.
  const factory HealthStatus.unhealthy({
    /// Error message describing the issue
    required String message,
    /// Optional error code for programmatic handling
    String? errorCode,
    /// Whether this is likely a temporary issue
    @Default(true) bool isTemporary,
  }) = HealthStatusUnhealthy;

  /// Unable to determine service health.
  const factory HealthStatus.unknown({
    /// Reason why health check failed
    required String reason,
  }) = HealthStatusUnknown;
}

/// Exception thrown by integrator API implementations.
///
/// Used for API-specific errors that need to be handled
/// differently from authentication or general integration exceptions.
class IntegratorApiException implements Exception {
  /// Error message describing the API issue
  final String message;
  
  /// Optional underlying cause of the exception
  final Object? cause;
  
  /// Service provider that threw the exception
  final ServiceProvider serviceProvider;
  
  /// Data type being accessed when error occurred
  final String dataType;
  
  /// HTTP status code if applicable
  final int? statusCode;
  
  /// Whether this is a temporary error that might resolve
  final bool isTemporary;

  const IntegratorApiException(
    this.message,
    this.serviceProvider,
    this.dataType, {
    this.cause,
    this.statusCode,
    this.isTemporary = true,
  });

  @override
  String toString() => 
      'IntegratorApiException(${serviceProvider.name}.$dataType): $message';
}

/// Extension methods for HealthStatus.
extension HealthStatusExtension on HealthStatus {
  /// Whether the service is healthy and fully operational.
  bool get isHealthy => this is HealthStatusHealthy;

  /// Whether the service has some issues but may still work.
  bool get isDegraded => this is HealthStatusDegraded;

  /// Whether the service is unavailable.
  bool get isUnhealthy => this is HealthStatusUnhealthy;

  /// Whether the health status is unknown.
  bool get isUnknown => this is HealthStatusUnknown;

  /// Whether the service can potentially be used for data sync.
  bool get canSync => isHealthy || isDegraded;

  /// Get a user-friendly status message.
  String get statusMessage => map(
    healthy: (_) => 'Service is operating normally',
    degraded: (degraded) => degraded.message,
    unhealthy: (unhealthy) => unhealthy.message,
    unknown: (unknown) => 'Unable to check service status: ${unknown.reason}',
  );
}