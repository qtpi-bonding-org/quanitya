import 'package:freezed_annotation/freezed_annotation.dart';

import '../../../logic/ingestion/adapters/i_data_source_adapter.dart';
import '../auth/i_integrator_auth.dart';
import '../providers/i_integrator_api.dart';
import 'integration_enums.dart';

part 'integration_definition.freezed.dart';

/// Defines a complete external integration configuration.
///
/// Combines authentication, API client, and data adapter into a single
/// cohesive integration that can be registered and managed by the
/// ExternalIntegrationRegistry.
///
/// Each integration definition represents one specific data type from
/// one service provider (e.g., "YNAB Transactions", "GitHub Commits").
@freezed
class IntegrationDefinition with _$IntegrationDefinition {
  const factory IntegrationDefinition({
    /// Unique identifier for this integration.
    /// Format: "{serviceProvider.name}.{dataType}"
    /// Examples: "ynab.transactions", "github.commits", "notion.database"
    required String id,

    /// Human-readable name for UI display.
    /// Examples: "YNAB Transactions", "GitHub Commits", "Notion Database Rows"
    required String displayName,

    /// Authentication strategy for this integration.
    /// Can be shared across multiple integrations from the same provider.
    required IIntegratorAuth auth,

    /// API client for communicating with the external service.
    /// Handles service-specific communication and data retrieval.
    required IIntegratorApi api,

    /// Data adapter for transforming external data to Quanitya models.
    /// Implements IDataSourceAdapter to work with existing ingestion system.
    required IDataSourceAdapter<Map<String, dynamic>> adapter,

    /// Optional metadata for this integration.
    /// Can store provider-specific configuration or settings.
    @Default({}) Map<String, dynamic> metadata,
  }) = _IntegrationDefinition;

  const IntegrationDefinition._();

  /// The service provider for this integration.
  ServiceProvider get serviceProvider => api.serviceProvider;

  /// The data type handled by this integration.
  String get dataType => api.dataType;

  /// Whether this integration requires authentication setup.
  bool get requiresAuth => auth.requiresSetup;

  /// Whether this integration is ready to sync data.
  /// Requires both API initialization and authentication.
  Future<bool> get isReady async {
    try {
      return await auth.isAuthenticated();
    } catch (e) {
      return false;
    }
  }

  /// Get authentication headers for API requests.
  /// 
  /// Convenience method that delegates to the auth strategy.
  /// Throws [AuthStrategyException] if not authenticated.
  Future<Map<String, String>> getAuthHeaders() => auth.getAuthHeaders();

  /// Validate that all components are properly configured.
  ///
  /// Checks that:
  /// - ID matches the API's integration ID
  /// - All required components are present
  /// - Configuration is consistent
  ///
  /// Throws [IntegrationDefinitionException] if validation fails.
  void validate() {
    if (id != api.integrationId) {
      throw IntegrationDefinitionException(
        'Integration ID mismatch: expected ${api.integrationId}, got $id',
      );
    }

    if (displayName.isEmpty) {
      throw IntegrationDefinitionException(
        'Display name cannot be empty for integration $id',
      );
    }

    if (adapter.adapterId != id) {
      throw IntegrationDefinitionException(
        'Adapter ID mismatch: expected $id, got ${adapter.adapterId}',
      );
    }
  }
}

/// Exception thrown when integration definition validation fails.
class IntegrationDefinitionException implements Exception {
  /// Error message describing the validation issue
  final String message;
  
  /// Optional underlying cause of the exception
  final Object? cause;

  const IntegrationDefinitionException(this.message, [this.cause]);

  @override
  String toString() => 'IntegrationDefinitionException: $message';
}