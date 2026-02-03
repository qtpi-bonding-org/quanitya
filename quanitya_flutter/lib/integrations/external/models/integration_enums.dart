/// Integration enums for type-safe external service integration.
///
/// These enums provide compile-time safety and prevent magic strings
/// throughout the integration system.
library;

/// Authentication strategy types for external integrations.
///
/// Each type corresponds to a different authentication implementation:
/// - [pkce]: OAuth with PKCE flow for secure public clients
/// - [token]: API Key/Personal Access Token (uses existing ApiKeyRepository)
/// - [public]: No authentication required (public APIs)
enum IntegratorAuthType {
  /// OAuth with PKCE (Proof Key for Code Exchange) flow.
  /// Used for secure authentication without client secrets.
  pkce,

  /// API Key or Personal Access Token authentication.
  /// Leverages existing ApiKeyRepository infrastructure.
  token,

  /// No authentication required.
  /// Used for public APIs that don't require credentials.
  public,
}

/// External service providers supported by the integration system.
///
/// Each provider can support multiple data types and integrations.
enum ServiceProvider {
  /// YNAB (You Need A Budget) - Personal finance management
  ynab,

  /// GitHub - Development platform and version control
  github,

  /// Notion - Note-taking and database platform
  notion,

  /// CoinGecko - Cryptocurrency market data
  coingecko,

  /// Lunch Money - Personal finance tracking
  lunchMoney,

  /// OpenWeather - Weather data and forecasts
  openWeather,

  /// Todoist - Task and project management
  todoist,
}

/// Data types available from YNAB service.
enum YnabDataType {
  /// Financial transactions from accounts
  transactions,

  /// Budget categories and allocations
  budgets,

  /// Bank accounts and balances
  accounts,
}

/// Data types available from GitHub service.
enum GitHubDataType {
  /// Git commits and commit history
  commits,

  /// Issues and bug reports
  issues,

  /// Pull requests and code reviews
  pullRequests,

  /// Software releases and tags
  releases,
}

/// Data types available from Notion service.
enum NotionDataType {
  /// Database rows and structured data
  database,

  /// Page content and documents
  page,

  /// Formula calculations and computed values
  formula,
}

/// Data types available from CoinGecko service.
enum CoinGeckoDataType {
  /// Cryptocurrency prices and quotes
  prices,

  /// Market data and trading statistics
  marketData,
}

/// Data types available from Lunch Money service.
enum LunchMoneyDataType {
  /// Net worth calculations and trends
  netWorth,

  /// Asset values and holdings
  assets,

  /// Financial transactions
  transactions,
}

/// Data types available from OpenWeather service.
enum OpenWeatherDataType {
  /// Current weather conditions
  current,

  /// Weather forecasts
  forecast,

  /// Historical weather data
  historical,
}

/// Data types available from Todoist service.
enum TodoistDataType {
  /// Tasks and to-do items
  tasks,

  /// Projects and task organization
  projects,

  /// Productivity metrics and statistics
  productivity,
}

/// Integration status for lifecycle management.
///
/// Tracks the current state of an integration throughout its lifecycle,
/// enabling proper error handling and user feedback.
enum IntegrationStatus {
  /// Integration not yet added to the registry.
  unregistered,

  /// Added to registry but not configured with credentials.
  registered,

  /// Has authentication credentials but not yet active.
  configured,

  /// Working normally and syncing data.
  active,

  /// Authentication credentials are invalid or expired.
  authFailed,

  /// Hit API rate limits, temporarily unavailable.
  rateLimited,

  /// External service is temporarily down or unreachable.
  apiError,

  /// User manually disabled the integration.
  disabled,
}

/// Extension methods for IntegrationStatus enum.
extension IntegrationStatusExtension on IntegrationStatus {
  /// Whether the integration can currently sync data.
  bool get canSync => this == IntegrationStatus.active;

  /// Whether the integration has authentication issues.
  bool get hasAuthIssue => this == IntegrationStatus.authFailed;

  /// Whether the integration has temporary issues that may resolve.
  bool get hasTemporaryIssue => 
      this == IntegrationStatus.rateLimited || 
      this == IntegrationStatus.apiError;

  /// Whether the integration is disabled by user or system.
  bool get isDisabled => this == IntegrationStatus.disabled;

  /// Whether the integration needs user configuration.
  bool get needsConfiguration => 
      this == IntegrationStatus.unregistered || 
      this == IntegrationStatus.registered;
}