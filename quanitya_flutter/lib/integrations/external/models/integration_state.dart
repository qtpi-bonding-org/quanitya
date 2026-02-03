import 'package:freezed_annotation/freezed_annotation.dart';

import 'integration_enums.dart';

part 'integration_state.freezed.dart';
part 'integration_state.g.dart';

/// Represents the current state of an external integration.
///
/// Tracks the lifecycle status, sync history, error conditions,
/// and metadata for an integration. Used by the registry to
/// manage integration health and provide user feedback.
@freezed
class IntegrationState with _$IntegrationState {
  const factory IntegrationState({
    /// Current status of the integration
    required IntegrationStatus status,

    /// When the integration was last successfully synced
    DateTime? lastSync,

    /// When the next sync is scheduled (if applicable)
    DateTime? nextSync,

    /// When to retry after a rate limit or temporary error
    DateTime? retryAfter,

    /// Number of consecutive sync failures
    @Default(0) int consecutiveFailures,

    /// Last error message if sync failed
    String? lastError,

    /// Last error code for programmatic handling
    String? lastErrorCode,

    /// Number of records synced in last successful sync
    @Default(0) int lastSyncCount,

    /// Total number of records synced over all time
    @Default(0) int totalSyncCount,

    /// Service-specific metadata and configuration
    @Default({}) Map<String, dynamic> metadata,

    /// When this state was last updated
    required DateTime updatedAt,
  }) = _IntegrationState;

  const IntegrationState._();

  factory IntegrationState.fromJson(Map<String, dynamic> json) =>
      _$IntegrationStateFromJson(json);

  /// Create a new integration state with default values.
  factory IntegrationState.initial() => IntegrationState(
        status: IntegrationStatus.registered,
        updatedAt: DateTime.now(),
      );

  /// Whether the integration is currently operational.
  bool get isOperational => status.canSync;

  /// Whether the integration has authentication issues.
  bool get hasAuthIssue => status.hasAuthIssue;

  /// Whether the integration has temporary issues.
  bool get hasTemporaryIssue => status.hasTemporaryIssue;

  /// Whether the integration is disabled.
  bool get isDisabled => status.isDisabled;

  /// Whether the integration needs user configuration.
  bool get needsConfiguration => status.needsConfiguration;

  /// Whether the integration has never synced successfully.
  bool get hasNeverSynced => lastSync == null;

  /// Whether the integration is currently in a retry backoff period.
  bool get isInRetryBackoff => 
      retryAfter != null && DateTime.now().isBefore(retryAfter!);

  /// Time until retry is allowed (null if not in backoff).
  Duration? get timeUntilRetry {
    if (retryAfter == null) return null;
    final now = DateTime.now();
    if (now.isAfter(retryAfter!)) return null;
    return retryAfter!.difference(now);
  }

  /// Whether the integration has had recent failures.
  bool get hasRecentFailures => consecutiveFailures > 0;

  /// Whether the integration should be considered unhealthy.
  bool get isUnhealthy => 
      consecutiveFailures >= 3 || 
      status == IntegrationStatus.apiError ||
      status == IntegrationStatus.authFailed;

  /// Get a user-friendly status description.
  String get statusDescription => switch (status) {
    IntegrationStatus.unregistered => 'Not registered',
    IntegrationStatus.registered => 'Registered but not configured',
    IntegrationStatus.configured => 'Configured but not active',
    IntegrationStatus.active => 'Active and syncing',
    IntegrationStatus.authFailed => 'Authentication failed',
    IntegrationStatus.rateLimited => 'Rate limited',
    IntegrationStatus.apiError => 'Service unavailable',
    IntegrationStatus.disabled => 'Disabled by user',
  };

  /// Create a copy with updated status and timestamp.
  IntegrationState withStatus(IntegrationStatus newStatus) => copyWith(
        status: newStatus,
        updatedAt: DateTime.now(),
      );

  /// Create a copy marking a successful sync.
  IntegrationState withSuccessfulSync({
    required int recordCount,
    DateTime? nextSyncTime,
  }) => copyWith(
        status: IntegrationStatus.active,
        lastSync: DateTime.now(),
        nextSync: nextSyncTime,
        consecutiveFailures: 0,
        lastError: null,
        lastErrorCode: null,
        lastSyncCount: recordCount,
        totalSyncCount: totalSyncCount + recordCount,
        updatedAt: DateTime.now(),
      );

  /// Create a copy marking a failed sync.
  IntegrationState withFailedSync({
    required String error,
    String? errorCode,
    IntegrationStatus? newStatus,
    DateTime? retryTime,
  }) => copyWith(
        status: newStatus ?? status,
        consecutiveFailures: consecutiveFailures + 1,
        lastError: error,
        lastErrorCode: errorCode,
        retryAfter: retryTime,
        updatedAt: DateTime.now(),
      );

  /// Create a copy with updated metadata.
  IntegrationState withMetadata(Map<String, dynamic> newMetadata) => copyWith(
        metadata: {...metadata, ...newMetadata},
        updatedAt: DateTime.now(),
      );

  /// Create a copy clearing error state.
  IntegrationState clearErrors() => copyWith(
        consecutiveFailures: 0,
        lastError: null,
        lastErrorCode: null,
        retryAfter: null,
        updatedAt: DateTime.now(),
      );
}