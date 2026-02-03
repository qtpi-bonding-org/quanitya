/// External integrations library for Quanitya.
///
/// Provides interfaces and infrastructure for integrating with external
/// services like YNAB, GitHub, Notion, etc.
///
/// ## Core Components
///
/// - **Enums**: Type-safe enums for providers, auth types, and statuses
/// - **Auth**: Pluggable authentication strategies
/// - **API**: Service-specific API clients
/// - **Models**: Integration definitions and state management
/// - **Registry**: Central orchestrator for all integrations
///
/// ## Usage
///
/// ```dart
/// // Register an integration
/// final registry = getIt<ExternalIntegrationRegistry>();
/// await registry.register(IntegrationDefinition(
///   id: 'ynab.transactions',
///   displayName: 'YNAB Transactions',
///   auth: TokenIntegratorAuth(...),
///   api: YNABTransactionApi(),
///   adapter: YNABTransactionAdapter(),
/// ));
///
/// // Sync data
/// final recordCount = await registry.syncIntegration('ynab.transactions');
/// ```
library;

// Enums
export 'models/integration_enums.dart';

// Auth interfaces
export 'auth/i_integrator_auth.dart';

// API interfaces  
export 'providers/i_integrator_api.dart';

// Models
export 'models/integration_definition.dart';
export 'models/integration_state.dart';

// Registry
export 'integration_registry.dart';