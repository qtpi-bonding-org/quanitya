import 'package:injectable/injectable.dart';

import '../../infrastructure/core/try_operation.dart';
import 'models/integration_definition.dart';
import 'models/integration_enums.dart';
import 'models/integration_state.dart';

/// Registry and orchestrator for external integrations.
///
/// Manages the lifecycle of external service integrations, providing:
/// - Registration and discovery of available integrations
/// - State management and persistence
/// - Bulk operations across providers
/// - Health monitoring and error recovery
///
/// Supports one-to-many relationships where a single service provider
/// can have multiple integrations for different data types.
@lazySingleton
class ExternalIntegrationRegistry {
  /// Integrations organized by service provider for bulk operations
  final Map<ServiceProvider, List<IntegrationDefinition>> _integrationsByProvider = {};
  
  /// Integrations indexed by ID for fast lookup
  final Map<String, IntegrationDefinition> _integrationsById = {};
  
  /// Current state of each integration
  final Map<String, IntegrationState> _integrationStates = {};

  /// Register a new integration definition.
  ///
  /// Validates the definition and adds it to the registry.
  /// Multiple integrations can be registered for the same provider.
  ///
  /// Throws [IntegrationRegistryException] if registration fails.
  Future<void> register(IntegrationDefinition definition) {
    return tryMethod(
      () async {
        // Validate the definition
        definition.validate();

        // Check for duplicate registration
        if (_integrationsById.containsKey(definition.id)) {
          throw IntegrationRegistryException(
            'Integration already registered: ${definition.id}',
          );
        }

        // Add to provider map
        final provider = definition.serviceProvider;
        _integrationsByProvider.putIfAbsent(provider, () => []);
        _integrationsByProvider[provider]!.add(definition);

        // Add to ID map
        _integrationsById[definition.id] = definition;

        // Initialize state if not exists
        if (!_integrationStates.containsKey(definition.id)) {
          _integrationStates[definition.id] = IntegrationState.initial();
        }

        // Initialize the API
        await definition.api.initialize();
      },
      IntegrationRegistryException.new,
      'register',
    );
  }

  /// Get an integration definition by ID.
  ///
  /// Returns null if the integration is not registered.
  IntegrationDefinition? get(String integrationId) {
    return _integrationsById[integrationId];
  }

  /// Get all integrations for a specific service provider.
  ///
  /// Returns empty list if no integrations are registered for the provider.
  List<IntegrationDefinition> getByProvider(ServiceProvider provider) {
    return List.unmodifiable(_integrationsByProvider[provider] ?? []);
  }

  /// Get all registered integrations.
  List<IntegrationDefinition> getAvailable() {
    return List.unmodifiable(_integrationsById.values);
  }

  /// Get all integrations that are configured and ready to use.
  Future<List<IntegrationDefinition>> getConfigured() {
    return tryMethod(
      () async {
        final configured = <IntegrationDefinition>[];
        
        for (final definition in _integrationsById.values) {
          if (await definition.isReady) {
            configured.add(definition);
          }
        }
        
        return configured;
      },
      IntegrationRegistryException.new,
      'getConfigured',
    );
  }

  /// Get the current state of an integration.
  ///
  /// Returns null if the integration is not registered.
  IntegrationState? getState(String integrationId) {
    return _integrationStates[integrationId];
  }

  /// Update the state of an integration.
  ///
  /// Throws [IntegrationRegistryException] if integration not found.
  Future<void> updateState(String integrationId, IntegrationState state) {
    return tryMethod(
      () async {
        if (!_integrationsById.containsKey(integrationId)) {
          throw IntegrationRegistryException(
            'Integration not found: $integrationId',
          );
        }

        _integrationStates[integrationId] = state;
        // TODO: Persist state to database in future implementation
      },
      IntegrationRegistryException.new,
      'updateState',
    );
  }

  /// Initialize an integration and mark it as configured.
  ///
  /// Performs authentication check and updates state accordingly.
  Future<void> initializeIntegration(String integrationId) {
    return tryMethod(
      () async {
        final definition = _integrationsById[integrationId];
        if (definition == null) {
          throw IntegrationRegistryException(
            'Integration not found: $integrationId',
          );
        }

        final currentState = _integrationStates[integrationId]!;

        try {
          // Check if authentication is working
          final isAuthenticated = await definition.auth.isAuthenticated();
          
          if (isAuthenticated) {
            // Test the connection
            final authHeaders = await definition.getAuthHeaders();
            final connectionOk = await definition.api.testConnection(authHeaders);
            
            if (connectionOk) {
              await updateState(
                integrationId,
                currentState.withStatus(IntegrationStatus.active),
              );
            } else {
              await updateState(
                integrationId,
                currentState.withStatus(IntegrationStatus.apiError),
              );
            }
          } else {
            await updateState(
              integrationId,
              currentState.withStatus(IntegrationStatus.configured),
            );
          }
        } catch (e) {
          await updateState(
            integrationId,
            currentState.withFailedSync(
              error: 'Initialization failed: $e',
              newStatus: IntegrationStatus.authFailed,
            ),
          );
        }
      },
      IntegrationRegistryException.new,
      'initializeIntegration',
    );
  }

  /// Disable an integration.
  ///
  /// Marks the integration as disabled and cleans up resources.
  Future<void> disableIntegration(String integrationId) {
    return tryMethod(
      () async {
        final definition = _integrationsById[integrationId];
        if (definition == null) {
          throw IntegrationRegistryException(
            'Integration not found: $integrationId',
          );
        }

        final currentState = _integrationStates[integrationId]!;

        // Clean up API resources
        await definition.api.cleanup();

        // Update state
        await updateState(
          integrationId,
          currentState.withStatus(IntegrationStatus.disabled),
        );
      },
      IntegrationRegistryException.new,
      'disableIntegration',
    );
  }

  /// Sync data for a specific integration.
  ///
  /// Returns the number of records synced, or -1 if sync failed.
  Future<int> syncIntegration(String integrationId) {
    return tryMethod(
      () async {
        final definition = _integrationsById[integrationId];
        if (definition == null) {
          throw IntegrationRegistryException(
            'Integration not found: $integrationId',
          );
        }

        final currentState = _integrationStates[integrationId]!;

        // Check if integration can sync
        if (!currentState.isOperational) {
          throw IntegrationRegistryException(
            'Integration not operational: $integrationId (${currentState.status})',
          );
        }

        // Check retry backoff
        if (currentState.isInRetryBackoff) {
          throw IntegrationRegistryException(
            'Integration in retry backoff: $integrationId',
          );
        }

        try {
          // Get authentication headers
          final authHeaders = await definition.getAuthHeaders();

          // Fetch data from external service
          final rawData = await definition.api.fetchData(
            authHeaders: authHeaders,
          );

          // TODO: Process data through adapter and ingestion service
          // This will be implemented in Phase 3 with concrete implementations
          
          // For now, just update state with successful sync
          await updateState(
            integrationId,
            currentState.withSuccessfulSync(recordCount: rawData.length),
          );

          return rawData.length;
        } catch (e) {
          // Determine appropriate status based on error type
          IntegrationStatus errorStatus = IntegrationStatus.apiError;
          DateTime? retryAfter;

          if (e.toString().contains('auth')) {
            errorStatus = IntegrationStatus.authFailed;
          } else if (e.toString().contains('rate limit')) {
            errorStatus = IntegrationStatus.rateLimited;
            retryAfter = DateTime.now().add(const Duration(hours: 1));
          }

          await updateState(
            integrationId,
            currentState.withFailedSync(
              error: e.toString(),
              newStatus: errorStatus,
              retryTime: retryAfter,
            ),
          );

          return -1;
        }
      },
      IntegrationRegistryException.new,
      'syncIntegration',
    );
  }

  /// Sync all integrations for a specific service provider.
  ///
  /// Useful for bulk operations when user wants to sync all data types
  /// from a single service (e.g., all YNAB data types).
  Future<void> syncProvider(ServiceProvider provider) {
    return tryMethod(
      () async {
        final integrations = getByProvider(provider);
        
        if (integrations.isEmpty) {
          throw IntegrationRegistryException(
            'No integrations found for provider: ${provider.name}',
          );
        }

        // Sync all integrations for this provider
        final futures = integrations.map((integration) => 
          syncIntegration(integration.id).catchError((e) {
            // Log error but don't fail the entire batch
            // TODO: Add proper logging in future implementation
            return -1;
          }),
        );

        await Future.wait(futures);
      },
      IntegrationRegistryException.new,
      'syncProvider',
    );
  }

  /// Test connection for a specific integration.
  ///
  /// Returns true if the integration can successfully connect to its service.
  Future<bool> testIntegration(String integrationId) {
    return tryMethod(
      () async {
        final definition = _integrationsById[integrationId];
        if (definition == null) {
          throw IntegrationRegistryException(
            'Integration not found: $integrationId',
          );
        }

        try {
          // Check authentication
          final isAuthenticated = await definition.auth.isAuthenticated();
          if (!isAuthenticated) {
            return false;
          }

          // Test API connection
          final authHeaders = await definition.getAuthHeaders();
          return await definition.api.testConnection(authHeaders);
        } catch (e) {
          return false;
        }
      },
      IntegrationRegistryException.new,
      'testIntegration',
    );
  }

  /// Get health status for all registered integrations.
  ///
  /// Returns a map of integration ID to health status.
  Future<Map<String, bool>> getHealthStatus() {
    return tryMethod(
      () async {
        final healthMap = <String, bool>{};
        
        final futures = _integrationsById.keys.map((integrationId) async {
          final isHealthy = await testIntegration(integrationId);
          healthMap[integrationId] = isHealthy;
        });

        await Future.wait(futures);
        return healthMap;
      },
      IntegrationRegistryException.new,
      'getHealthStatus',
    );
  }

  /// Remove an integration from the registry.
  ///
  /// Cleans up all resources and removes from all internal maps.
  Future<void> unregister(String integrationId) {
    return tryMethod(
      () async {
        final definition = _integrationsById[integrationId];
        if (definition == null) {
          return; // Already unregistered
        }

        // Clean up API resources
        await definition.api.cleanup();

        // Remove from provider map
        final provider = definition.serviceProvider;
        _integrationsByProvider[provider]?.removeWhere(
          (d) => d.id == integrationId,
        );
        
        // Clean up empty provider entries
        if (_integrationsByProvider[provider]?.isEmpty == true) {
          _integrationsByProvider.remove(provider);
        }

        // Remove from ID map
        _integrationsById.remove(integrationId);

        // Remove state
        _integrationStates.remove(integrationId);
      },
      IntegrationRegistryException.new,
      'unregister',
    );
  }
}

/// Exception thrown by the integration registry.
class IntegrationRegistryException implements Exception {
  /// Error message describing the registry issue
  final String message;
  
  /// Optional underlying cause of the exception
  final Object? cause;

  const IntegrationRegistryException(this.message, [this.cause]);

  @override
  String toString() => 'IntegrationRegistryException: $message';
}