/* AUTOMATICALLY GENERATED CODE DO NOT MODIFY */
/*   To generate run: "serverpod generate"    */

// ignore_for_file: implementation_imports
// ignore_for_file: library_private_types_in_public_api
// ignore_for_file: non_constant_identifier_names
// ignore_for_file: public_member_api_docs
// ignore_for_file: type_literal_in_constant_pattern
// ignore_for_file: use_super_parameters
// ignore_for_file: invalid_use_of_internal_member

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:serverpod_client/serverpod_client.dart' as _i1;
import 'dart:async' as _i2;
import 'package:quanitya_cloud_client/src/protocol/admin_signing_key.dart'
    as _i3;
import 'package:quanitya_cloud_client/src/models/admin_role.dart' as _i4;
import 'package:quanitya_cloud_client/src/protocol/public_challenge_response.dart'
    as _i5;
import 'package:quanitya_cloud_client/src/protocol/cloud_llm_structured_request.dart'
    as _i6;
import 'package:quanitya_cloud_client/src/protocol/sync_access_status.dart'
    as _i7;
import 'package:quanitya_cloud_client/src/protocol/sync_usage_stats.dart'
    as _i8;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i9;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i10;
import 'package:quanitya_client/quanitya_client.dart' as _i11;
import 'package:anonaccount_client/anonaccount_client.dart' as _i12;
import 'package:anonaccred_client/anonaccred_client.dart' as _i13;
import 'protocol.dart' as _i14;

/// A simple cloud-specific endpoint to verify the cloud server is working.
/// {@category Endpoint}
class EndpointCloudHealth extends _i1.EndpointRef {
  EndpointCloudHealth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudHealth';

  /// Returns a health check message for the cloud server.
  _i2.Future<String> getHealth() => caller.callServerEndpoint<String>(
    'cloudHealth',
    'getHealth',
    {},
  );
}

/// Account deletion endpoint for user-initiated account removal.
///
/// Immediately and permanently deletes all account data when requested
/// by the authenticated user. This satisfies Apple App Store requirement
/// for account deletion functionality.
/// {@category Endpoint}
class EndpointAccountDeletion extends _i1.EndpointRef {
  EndpointAccountDeletion(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'accountDeletion';

  /// Delete the authenticated user's account and all associated data.
  ///
  /// Permanently removes:
  /// - All encrypted data (entries, templates, schedules, pipelines)
  /// - Template aesthetics and storage usage records
  /// - Notification receipts and notifications
  /// - The account itself (CASCADE handles devices, entitlements, credentials)
  ///
  /// Returns true on success.
  _i2.Future<bool> deleteAccount() => caller.callServerEndpoint<bool>(
    'accountDeletion',
    'deleteAccount',
    {},
  );
}

/// Endpoint for managing admin signing keys
///
/// Provides CRUD operations for admin and support ECDSA signing keys.
/// All operations require an existing admin key for authentication.
/// {@category Endpoint}
class EndpointAdminKeyManagement extends _i1.EndpointRef {
  EndpointAdminKeyManagement(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'adminKeyManagement';

  /// Register a new admin or support public key
  ///
  /// Requires admin role. Registers a public key that was generated externally.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key for authentication (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [newPublicKeyHex] - New public key to register (128 hex chars)
  /// [role] - Role for the new key ('admin' or 'support')
  /// [description] - Human-readable description of the key
  _i2.Future<void> registerKey(
    String adminPublicKeyHex,
    String adminSignature,
    String newPublicKeyHex,
    String role,
    String description,
  ) => caller.callServerEndpoint<void>(
    'adminKeyManagement',
    'registerKey',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'newPublicKeyHex': newPublicKeyHex,
      'role': role,
      'description': description,
    },
  );

  /// Revoke a signing key (soft delete)
  ///
  /// Requires admin role. Sets isActive to false, preventing further use.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key for authentication (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [keyId] - ID of the key to revoke
  _i2.Future<void> revokeKey(
    String adminPublicKeyHex,
    String adminSignature,
    int keyId,
  ) => caller.callServerEndpoint<void>(
    'adminKeyManagement',
    'revokeKey',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'keyId': keyId,
    },
  );

  /// List all signing keys
  ///
  /// Requires admin role. Returns all keys (active and inactive).
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key for authentication (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  _i2.Future<List<_i3.AdminSigningKey>> listKeys(
    String adminPublicKeyHex,
    String adminSignature,
  ) => caller.callServerEndpoint<List<_i3.AdminSigningKey>>(
    'adminKeyManagement',
    'listKeys',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
    },
  );

  /// Get information about a specific signing key
  ///
  /// Requires admin role. Returns key metadata.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key for authentication (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [keyId] - ID of the key to retrieve
  _i2.Future<_i3.AdminSigningKey> getKeyInfo(
    String adminPublicKeyHex,
    String adminSignature,
    int keyId,
  ) => caller.callServerEndpoint<_i3.AdminSigningKey>(
    'adminKeyManagement',
    'getKeyInfo',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'keyId': keyId,
    },
  );

  /// Reactivate a previously revoked key
  ///
  /// Requires admin role. Sets isActive to true.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key for authentication (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [keyId] - ID of the key to reactivate
  _i2.Future<void> reactivateKey(
    String adminPublicKeyHex,
    String adminSignature,
    int keyId,
  ) => caller.callServerEndpoint<void>(
    'adminKeyManagement',
    'reactivateKey',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'keyId': keyId,
    },
  );
}

/// Admin endpoint for managing analytics events
///
/// Provides admin and support staff with tools to:
/// - List analytics events with filtering and pagination
/// - View detailed event information
/// - Get analytics statistics (by event name, platform)
/// - Delete analytics events
///
/// Authentication: ECDSA P-256 signature (same as other admin endpoints)
///
/// Access Levels:
/// - Support: Can view events and statistics
/// - Admin: Can view, get statistics, and delete events
/// {@category Endpoint}
class EndpointAnalyticsAdmin extends EndpointAdminManagement {
  EndpointAnalyticsAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'analyticsAdmin';

  /// List analytics events with filtering and pagination
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [limit]: Max results per page (default: 50)
  /// - [offset]: Number of results to skip (default: 0)
  /// - [eventNameFilter]: Filter by event name (optional)
  /// - [platformFilter]: Filter by platform (optional)
  /// - [startDate]: Filter by date range start (optional)
  /// - [endDate]: Filter by date range end (optional)
  ///
  /// Returns:
  /// - items: List of analytics events
  /// - total: Total count matching filters
  /// - limit: Page size used
  /// - offset: Offset used
  _i2.Future<String> listEvents(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    String? eventNameFilter,
    String? platformFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'analyticsAdmin',
    'listEvents',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'limit': limit,
      'offset': offset,
      'eventNameFilter': eventNameFilter,
      'platformFilter': platformFilter,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Get specific analytics event details
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [eventId]: ID of analytics event to retrieve
  ///
  /// Returns:
  /// - data: Full analytics event details
  _i2.Future<String> getEventDetails(
    String adminPublicKeyHex,
    String adminSignature,
    int eventId,
  ) => caller.callServerEndpoint<String>(
    'analyticsAdmin',
    'getEventDetails',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'eventId': eventId,
    },
  );

  /// Get analytics statistics
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [startDate]: Start of date range (optional)
  /// - [endDate]: End of date range (optional)
  ///
  /// Returns:
  /// - totalEvents: Total event count
  /// - byEventName: Count by event name
  /// - byPlatform: Count by platform
  /// - recentEvents: Recent events (last 7 days, limit 10)
  _i2.Future<String> getStatistics(
    String adminPublicKeyHex,
    String adminSignature, {
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'analyticsAdmin',
    'getStatistics',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Delete analytics event
  ///
  /// Access: Admin only
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [eventId]: ID of analytics event to delete
  ///
  /// Returns:
  /// - success: true if deleted
  /// - message: Success message
  _i2.Future<String> deleteEvent(
    String adminPublicKeyHex,
    String adminSignature,
    int eventId,
  ) => caller.callServerEndpoint<String>(
    'analyticsAdmin',
    'deleteEvent',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'eventId': eventId,
    },
  );

  /// Validate admin signature and check permission.
  ///
  /// This method performs ECDSA signature verification and returns
  /// the associated admin role if valid.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [requestBody]: JSON string of request body (excluding signature fields)
  ///
  /// Returns:
  /// - AdminRole if signature is valid and key is active
  /// - null if signature is invalid or key is inactive
  ///
  /// Example:
  /// ```dart
  /// final role = await validateAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  ///
  /// if (role == null) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.insufficientPermissions,
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i4.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole?>(
    'analyticsAdmin',
    'validateAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );

  /// Require admin authentication or throw exception.
  ///
  /// Convenience method that validates the signature and throws
  /// an exception if authentication fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key
  /// - [signature]: ECDSA signature
  /// - [requestBody]: JSON string of request body
  ///
  /// Returns:
  /// - AdminRole if authentication successful
  ///
  /// Throws:
  /// - Exception if authentication fails
  ///
  /// Example:
  /// ```dart
  /// final role = await requireAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  /// // If we get here, authentication succeeded
  /// ```
  @override
  _i2.Future<_i4.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole>(
    'analyticsAdmin',
    'requireAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );
}

/// Analytics Event Endpoint for privacy-first usage analytics.
///
/// Accepts lightweight, PII-free event names (e.g. "template_created")
/// and stores them in Postgres for aggregate usage insights.
///
/// Protected by Hashcash proof-of-work + ECDSA signature for rate limiting.
/// Events are submitted in batches — one PoW covers the whole batch.
/// {@category Endpoint}
class EndpointAnalyticsEvent extends EndpointPublicSubmission {
  EndpointAnalyticsEvent(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'analyticsEvent';

  /// Submit a batch of analytics events with proof-of-work and signature.
  ///
  /// Parameters:
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature of "challenge:analytics:{eventCount}"
  /// - [eventsJson]: JSON-encoded list of event objects, each with:
  ///   - eventName: Action that occurred (e.g. "template_created")
  ///   - clientTimestamp: ISO 8601 timestamp
  ///   - platform: Client platform (optional)
  ///   - props: JSON-encoded properties (optional)
  ///
  /// Throws [ServerException] on validation, rate limit, or internal errors.
  _i2.Future<void> submitEvents({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String eventsJson,
  }) => caller.callServerEndpoint<void>(
    'analyticsEvent',
    'submitEvents',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'eventsJson': eventsJson,
    },
  );

  /// Get challenge for proof-of-work.
  ///
  /// This method is inherited by all public endpoints and provides
  /// a consistent way to generate challenges.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  ///
  /// Returns a map with:
  /// - challenge: Random challenge string (32 hex chars)
  /// - difficulty: Number of leading zero bits required (20)
  /// - expiresAt: Unix timestamp when challenge expires
  ///
  /// Example:
  /// ```dart
  /// final challenge = await getChallenge(session);
  /// // Returns: {
  /// //   'challenge': 'abc123...',
  /// //   'difficulty': 20,
  /// //   'expiresAt': 1234567890
  /// // }
  /// ```
  @override
  _i2.Future<_i5.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i5.PublicChallengeResponse>(
        'analyticsEvent',
        'getChallenge',
        {},
      );

  /// Verify submission (PoW + signature + rate limit).
  ///
  /// This method performs all verification steps:
  /// 1. Verifies proof-of-work solution
  /// 2. Verifies ECDSA signature
  /// 3. Checks and enforces rate limits
  ///
  /// Throws an exception if any verification step fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [payload]: Original payload that was signed
  ///
  /// Throws:
  /// - Exception if proof-of-work is invalid
  /// - Exception if signature is invalid
  /// - RateLimitExceededException if rate limit exceeded
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await verifySubmission(
  ///     session,
  ///     challenge,
  ///     proofOfWork,
  ///     publicKeyHex,
  ///     signature,
  ///     payload,
  ///   );
  ///   // Verification successful, process submission
  /// } catch (e) {
  ///   // Handle verification failure
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: e.toString(),
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<void> verifySubmission(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'analyticsEvent',
    'verifySubmission',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );
}

/// Base class for all admin management endpoints.
///
/// Provides standardized ECDSA signature authentication for:
/// - Notification management
/// - Error report management
/// - Admin key management
/// - Other admin operations
///
/// All admin endpoints inherit:
/// - validateAdmin() method for signature verification
/// - Consistent authentication patterns
/// - Role-based access control helpers
///
/// Usage:
/// ```dart
/// class NotificationAdminEndpoint extends AdminManagementEndpoint {
///   Future<String> createNotification(
///     Session session,
///     String publicKeyHex,
///     String signature, {
///     required String title,
///   }) async {
///     final role = await requireAdmin(session, publicKeyHex, signature, body);
///
///     // Process the admin operation...
///     return jsonEncode({'notificationId': id});
///   }
/// }
/// ```
///
/// **IMPORTANT**: Never return `Map<String, dynamic>` from Serverpod endpoints.
/// Serverpod cannot deserialize `dynamic`. Use typed protocol models or
/// `String` (JSON-encoded) for complex responses. For errors, throw
/// `ServerException` with an appropriate `ServerErrorCode`.
/// {@category Endpoint}
abstract class EndpointAdminManagement extends _i1.EndpointRef {
  EndpointAdminManagement(_i1.EndpointCaller caller) : super(caller);

  /// Validate admin signature and check permission.
  ///
  /// This method performs ECDSA signature verification and returns
  /// the associated admin role if valid.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [requestBody]: JSON string of request body (excluding signature fields)
  ///
  /// Returns:
  /// - AdminRole if signature is valid and key is active
  /// - null if signature is invalid or key is inactive
  ///
  /// Example:
  /// ```dart
  /// final role = await validateAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  ///
  /// if (role == null) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.insufficientPermissions,
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  _i2.Future<_i4.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  );

  /// Require admin authentication or throw exception.
  ///
  /// Convenience method that validates the signature and throws
  /// an exception if authentication fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key
  /// - [signature]: ECDSA signature
  /// - [requestBody]: JSON string of request body
  ///
  /// Returns:
  /// - AdminRole if authentication successful
  ///
  /// Throws:
  /// - Exception if authentication fails
  ///
  /// Example:
  /// ```dart
  /// final role = await requireAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  /// // If we get here, authentication succeeded
  /// ```
  _i2.Future<_i4.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  );
}

/// Base class for all public submission endpoints (unauthenticated).
///
/// Provides standardized proof-of-work and signature verification for:
/// - Error reports
/// - Feedback submissions
/// - Other public submissions
///
/// All public endpoints inherit:
/// - getChallenge() method for PoW challenge generation
/// - verifySubmission() method for PoW + signature + rate limit verification
/// - Consistent security patterns
///
/// Usage:
/// ```dart
/// class ErrorReportEndpoint extends PublicSubmissionEndpoint {
///   @override
///   String get endpointType => 'error_report';
///
///   Future<void> submitReport(
///     Session session,
///     String challenge,
///     String proofOfWork,
///     String publicKeyHex,
///     String signature,
///     String payload,
///   ) async {
///     await verifySubmission(
///       session, challenge, proofOfWork, publicKeyHex, signature, payload,
///     );
///
///     // Process the submission...
///   }
/// }
/// ```
///
/// **IMPORTANT**: Never return `Map<String, dynamic>` from Serverpod endpoints.
/// Serverpod cannot deserialize `dynamic`. Use typed protocol models or
/// `String` (JSON-encoded) for complex responses. For errors, throw
/// `ServerException` with an appropriate `ServerErrorCode`.
/// {@category Endpoint}
abstract class EndpointPublicSubmission extends _i1.EndpointRef {
  EndpointPublicSubmission(_i1.EndpointCaller caller) : super(caller);

  /// Get challenge for proof-of-work.
  ///
  /// This method is inherited by all public endpoints and provides
  /// a consistent way to generate challenges.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  ///
  /// Returns a map with:
  /// - challenge: Random challenge string (32 hex chars)
  /// - difficulty: Number of leading zero bits required (20)
  /// - expiresAt: Unix timestamp when challenge expires
  ///
  /// Example:
  /// ```dart
  /// final challenge = await getChallenge(session);
  /// // Returns: {
  /// //   'challenge': 'abc123...',
  /// //   'difficulty': 20,
  /// //   'expiresAt': 1234567890
  /// // }
  /// ```
  _i2.Future<_i5.PublicChallengeResponse> getChallenge();

  /// Verify submission (PoW + signature + rate limit).
  ///
  /// This method performs all verification steps:
  /// 1. Verifies proof-of-work solution
  /// 2. Verifies ECDSA signature
  /// 3. Checks and enforces rate limits
  ///
  /// Throws an exception if any verification step fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [payload]: Original payload that was signed
  ///
  /// Throws:
  /// - Exception if proof-of-work is invalid
  /// - Exception if signature is invalid
  /// - RateLimitExceededException if rate limit exceeded
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await verifySubmission(
  ///     session,
  ///     challenge,
  ///     proofOfWork,
  ///     publicKeyHex,
  ///     signature,
  ///     payload,
  ///   );
  ///   // Verification successful, process submission
  /// } catch (e) {
  ///   // Handle verification failure
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: e.toString(),
  ///   );
  /// }
  /// ```
  _i2.Future<void> verifySubmission(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  );
}

/// Cloud Analysis Endpoint - MVP Disabled
///
/// This endpoint provides pay-per-use statistical analysis features.
/// DISABLED for MVP launch - will be added post-launch.
///
/// Features (when enabled):
/// - Ed25519 public key authentication via X-QUANITYA-DEVICE-PUBKEY header
/// - X402 HTTP micropayments via X-PAYMENT header
/// - Pay-per-use analysis with different pricing tiers
/// - JWT tokens for external analysis engine access
/// {@category Endpoint}
class EndpointCloudAnalysis extends _i1.EndpointRef {
  EndpointCloudAnalysis(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudAnalysis';

  /// Request statistical analysis
  ///
  /// MVP: This feature is disabled. Throws [ServerException].
  _i2.Future<void> requestAnalysis(String analysisType) =>
      caller.callServerEndpoint<void>(
        'cloudAnalysis',
        'requestAnalysis',
        {'analysisType': analysisType},
      );

  /// Get AnonAccount configuration status
  _i2.Future<String> getAnonAccountConfig() =>
      caller.callServerEndpoint<String>(
        'cloudAnalysis',
        'getAnonAccountConfig',
        {},
      );
}

/// Cloud LLM Endpoint for proxied access to OpenRouter.
///
/// Model selection is server-controlled to prevent cost abuse.
/// Uses OpenRouter's `models` array for automatic failover.
/// {@category Endpoint}
class EndpointCloudLlm extends _i1.EndpointRef {
  EndpointCloudLlm(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudLlm';

  /// Generate structured output from LLM using server's API key.
  ///
  /// This endpoint acts as a proxy for paid users to access OpenRouter
  /// without needing their own API key (BYOK).
  ///
  /// Returns JSON string containing the LLM's
  /// structured JSON output (shape defined by caller's schema).
  _i2.Future<String> generateStructured(
    _i6.CloudLlmStructuredRequest request,
  ) => caller.callServerEndpoint<String>(
    'cloudLlm',
    'generateStructured',
    {'request': request},
  );
}

/// Admin endpoint for managing account entitlements (credits, sync days, etc.)
///
/// Requires ECDSA P-256 admin signature for all operations.
/// {@category Endpoint}
class EndpointEntitlementAdmin extends EndpointAdminManagement {
  EndpointEntitlementAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'entitlementAdmin';

  /// Add credits to an account's entitlement balance.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [accountId] - Target account ID
  /// [consumableType] - Entitlement ID to add to
  /// [amount] - Amount to add (must be positive)
  _i2.Future<String> addCredits(
    String adminPublicKeyHex,
    String adminSignature,
    int accountId,
    int consumableType,
    double amount,
  ) => caller.callServerEndpoint<String>(
    'entitlementAdmin',
    'addCredits',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'accountId': accountId,
      'consumableType': consumableType,
      'amount': amount,
    },
  );

  /// Consume credits from an account's entitlement balance.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [accountId] - Target account ID
  /// [consumableType] - Entitlement ID to consume from
  /// [amount] - Amount to consume (must be positive)
  _i2.Future<String> consumeCredits(
    String adminPublicKeyHex,
    String adminSignature,
    int accountId,
    int consumableType,
    double amount,
  ) => caller.callServerEndpoint<String>(
    'entitlementAdmin',
    'consumeCredits',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'accountId': accountId,
      'consumableType': consumableType,
      'amount': amount,
    },
  );

  /// Validate admin signature and check permission.
  ///
  /// This method performs ECDSA signature verification and returns
  /// the associated admin role if valid.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [requestBody]: JSON string of request body (excluding signature fields)
  ///
  /// Returns:
  /// - AdminRole if signature is valid and key is active
  /// - null if signature is invalid or key is inactive
  ///
  /// Example:
  /// ```dart
  /// final role = await validateAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  ///
  /// if (role == null) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.insufficientPermissions,
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i4.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole?>(
    'entitlementAdmin',
    'validateAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );

  /// Require admin authentication or throw exception.
  ///
  /// Convenience method that validates the signature and throws
  /// an exception if authentication fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key
  /// - [signature]: ECDSA signature
  /// - [requestBody]: JSON string of request body
  ///
  /// Returns:
  /// - AdminRole if authentication successful
  ///
  /// Throws:
  /// - Exception if authentication fails
  ///
  /// Example:
  /// ```dart
  /// final role = await requireAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  /// // If we get here, authentication succeeded
  /// ```
  @override
  _i2.Future<_i4.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole>(
    'entitlementAdmin',
    'requireAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );
}

/// Admin endpoint for managing error reports
///
/// Provides admin and support staff with tools to:
/// - List error reports with filtering and pagination
/// - View detailed error report information
/// - Get error statistics for analytics
/// - Delete error reports
///
/// Authentication: ECDSA P-256 signature (same as other admin endpoints)
///
/// Access Levels:
/// - Support: Can view reports and statistics
/// - Admin: Can view, get statistics, and delete reports
/// {@category Endpoint}
class EndpointErrorReportAdmin extends EndpointAdminManagement {
  EndpointErrorReportAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'errorReportAdmin';

  /// List error reports with filtering and pagination
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [limit]: Max results per page (default: 50)
  /// - [offset]: Number of results to skip (default: 0)
  /// - [errorTypeFilter]: Filter by error type (optional)
  /// - [errorCodeFilter]: Filter by error code (optional)
  /// - [startDate]: Filter by date range start (optional)
  /// - [endDate]: Filter by date range end (optional)
  ///
  /// Returns:
  /// - items: List of error reports
  /// - total: Total count matching filters
  /// - limit: Page size used
  /// - offset: Offset used
  _i2.Future<String> listErrorReports(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    String? errorTypeFilter,
    String? errorCodeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'errorReportAdmin',
    'listErrorReports',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'limit': limit,
      'offset': offset,
      'errorTypeFilter': errorTypeFilter,
      'errorCodeFilter': errorCodeFilter,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Get specific error report details
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [errorReportId]: ID of error report to retrieve
  ///
  /// Returns:
  /// - data: Full error report details
  _i2.Future<String> getErrorReportDetails(
    String adminPublicKeyHex,
    String adminSignature,
    int errorReportId,
  ) => caller.callServerEndpoint<String>(
    'errorReportAdmin',
    'getErrorReportDetails',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'errorReportId': errorReportId,
    },
  );

  /// Get error statistics
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [startDate]: Start of date range (optional)
  /// - [endDate]: End of date range (optional)
  ///
  /// Returns:
  /// - data: Statistics including totalErrors, errorsByType, errorsByCode, errorsByPlatform, recentErrors
  _i2.Future<String> getErrorStatistics(
    String adminPublicKeyHex,
    String adminSignature, {
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'errorReportAdmin',
    'getErrorStatistics',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Delete error report
  ///
  /// Access: Admin only
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [errorReportId]: ID of error report to delete
  ///
  /// Returns:
  /// - success: true if deleted
  /// - message: Success message
  _i2.Future<String> deleteErrorReport(
    String adminPublicKeyHex,
    String adminSignature,
    int errorReportId,
  ) => caller.callServerEndpoint<String>(
    'errorReportAdmin',
    'deleteErrorReport',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'errorReportId': errorReportId,
    },
  );

  /// Validate admin signature and check permission.
  ///
  /// This method performs ECDSA signature verification and returns
  /// the associated admin role if valid.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [requestBody]: JSON string of request body (excluding signature fields)
  ///
  /// Returns:
  /// - AdminRole if signature is valid and key is active
  /// - null if signature is invalid or key is inactive
  ///
  /// Example:
  /// ```dart
  /// final role = await validateAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  ///
  /// if (role == null) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.insufficientPermissions,
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i4.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole?>(
    'errorReportAdmin',
    'validateAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );

  /// Require admin authentication or throw exception.
  ///
  /// Convenience method that validates the signature and throws
  /// an exception if authentication fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key
  /// - [signature]: ECDSA signature
  /// - [requestBody]: JSON string of request body
  ///
  /// Returns:
  /// - AdminRole if authentication successful
  ///
  /// Throws:
  /// - Exception if authentication fails
  ///
  /// Example:
  /// ```dart
  /// final role = await requireAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  /// // If we get here, authentication succeeded
  /// ```
  @override
  _i2.Future<_i4.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole>(
    'errorReportAdmin',
    'requireAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );
}

/// Error Report Endpoint for privacy-preserving error reporting
///
/// Receives PII-free error reports from the Flutter app using the
/// flutter_error_privserver library. All data is already sanitized
/// by design at the client side.
///
/// Features:
/// - Anonymous (no authentication required)
/// - Interactive Hashcash proof-of-work (prevents spam/pre-mining)
/// - ECDSA P-256 signature verification for rate limiting
/// - Challenge-response protocol (5-minute TTL)
/// - Stores error reports in database WITHOUT any identifiers
/// - Adds server-side metadata (timestamp)
///
/// Security Model:
/// - Public key is used ONLY for rate limiting (stored temporarily in Redis/memory)
/// - Error reports are stored WITHOUT any public key or hash
/// - Reports remain fully anonymous in the database
/// {@category Endpoint}
class EndpointErrorReport extends EndpointPublicSubmission {
  EndpointErrorReport(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'errorReport';

  /// Submit an error report with proof-of-work and signature
  ///
  /// The error data is already PII-free by design from the
  /// flutter_error_privserver library. This endpoint:
  /// 1. Validates proof-of-work stamp
  /// 2. Verifies ECDSA signature
  /// 3. Applies rate limiting by public key
  /// 4. Adds server-side metadata
  /// 5. Stores in database WITHOUT any public key or identifier
  ///
  /// Parameters:
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars) - REQUIRED for rate limiting
  /// - [signature]: ECDSA signature (128 hex chars) - REQUIRED for verification
  /// - [source]: Cubit/class name where error occurred
  /// - [errorType]: Exception type (e.g., "NetworkException")
  /// - [errorCode]: Mapped safe code (e.g., "NET_001")
  /// - [stackTrace]: Full stack trace (no PII)
  /// - [clientTimestamp]: When error occurred on client
  /// - [userMessage]: Optional user-friendly message
  /// - [appVersion]: Optional app version
  /// - [platform]: Optional platform info (iOS, Android, etc.)
  /// - [deviceInfo]: Optional device info (already sanitized)
  ///
  /// Throws [ServerException] on validation, rate limit, or internal errors.
  _i2.Future<void> submitErrorReport({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String source,
    required String errorType,
    required String errorCode,
    required String stackTrace,
    required String clientTimestamp,
    String? userMessage,
    String? appVersion,
    String? platform,
    String? deviceInfo,
  }) => caller.callServerEndpoint<void>(
    'errorReport',
    'submitErrorReport',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'source': source,
      'errorType': errorType,
      'errorCode': errorCode,
      'stackTrace': stackTrace,
      'clientTimestamp': clientTimestamp,
      'userMessage': userMessage,
      'appVersion': appVersion,
      'platform': platform,
      'deviceInfo': deviceInfo,
    },
  );

  /// Submit a batch of error reports with a single proof-of-work and signature.
  ///
  /// Parameters:
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature of "challenge:errorReports:{count}"
  /// - [reportsJson]: JSON-encoded list of error report objects
  ///
  /// Throws [ServerException] on validation, rate limit, or internal errors.
  _i2.Future<void> submitErrorReports({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String reportsJson,
  }) => caller.callServerEndpoint<void>(
    'errorReport',
    'submitErrorReports',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'reportsJson': reportsJson,
    },
  );

  /// Get challenge for proof-of-work.
  ///
  /// This method is inherited by all public endpoints and provides
  /// a consistent way to generate challenges.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  ///
  /// Returns a map with:
  /// - challenge: Random challenge string (32 hex chars)
  /// - difficulty: Number of leading zero bits required (20)
  /// - expiresAt: Unix timestamp when challenge expires
  ///
  /// Example:
  /// ```dart
  /// final challenge = await getChallenge(session);
  /// // Returns: {
  /// //   'challenge': 'abc123...',
  /// //   'difficulty': 20,
  /// //   'expiresAt': 1234567890
  /// // }
  /// ```
  @override
  _i2.Future<_i5.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i5.PublicChallengeResponse>(
        'errorReport',
        'getChallenge',
        {},
      );

  /// Verify submission (PoW + signature + rate limit).
  ///
  /// This method performs all verification steps:
  /// 1. Verifies proof-of-work solution
  /// 2. Verifies ECDSA signature
  /// 3. Checks and enforces rate limits
  ///
  /// Throws an exception if any verification step fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [payload]: Original payload that was signed
  ///
  /// Throws:
  /// - Exception if proof-of-work is invalid
  /// - Exception if signature is invalid
  /// - RateLimitExceededException if rate limit exceeded
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await verifySubmission(
  ///     session,
  ///     challenge,
  ///     proofOfWork,
  ///     publicKeyHex,
  ///     signature,
  ///     payload,
  ///   );
  ///   // Verification successful, process submission
  /// } catch (e) {
  ///   // Handle verification failure
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: e.toString(),
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<void> verifySubmission(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'errorReport',
    'verifySubmission',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );
}

/// Admin endpoint for managing feedback reports
///
/// Provides admin and support staff with tools to:
/// - List feedback reports with filtering and pagination
/// - View detailed feedback information
/// - Get feedback statistics for analytics
/// - Delete feedback reports
///
/// Authentication: ECDSA P-256 signature (same as other admin endpoints)
///
/// Access Levels:
/// - Support: Can view feedback and statistics
/// - Admin: Can view, get statistics, and delete feedback
/// {@category Endpoint}
class EndpointFeedbackAdmin extends EndpointAdminManagement {
  EndpointFeedbackAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'feedbackAdmin';

  /// List feedback with filtering and pagination
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [limit]: Max results per page (default: 50)
  /// - [offset]: Number of results to skip (default: 0)
  /// - [feedbackTypeFilter]: Filter by feedback type (optional)
  /// - [startDate]: Filter by date range start (optional)
  /// - [endDate]: Filter by date range end (optional)
  ///
  /// Returns:
  /// - Paginated response with feedback reports
  _i2.Future<String> listFeedback(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    String? feedbackTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'feedbackAdmin',
    'listFeedback',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'limit': limit,
      'offset': offset,
      'feedbackTypeFilter': feedbackTypeFilter,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Get specific feedback details
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [feedbackId]: ID of feedback to retrieve
  ///
  /// Returns:
  /// - Feedback report details
  _i2.Future<String> getFeedbackDetails(
    String adminPublicKeyHex,
    String adminSignature,
    int feedbackId,
  ) => caller.callServerEndpoint<String>(
    'feedbackAdmin',
    'getFeedbackDetails',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'feedbackId': feedbackId,
    },
  );

  /// Get feedback statistics
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [startDate]: Start of date range (optional)
  /// - [endDate]: End of date range (optional)
  ///
  /// Returns:
  /// - totalFeedback: Total feedback count
  /// - byType: Count by feedback type
  /// - recentFeedback: Recent feedback (last 7 days, limit 10)
  _i2.Future<String> getFeedbackStatistics(
    String adminPublicKeyHex,
    String adminSignature, {
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'feedbackAdmin',
    'getFeedbackStatistics',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Delete feedback (admin only)
  ///
  /// Access: Admin only
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [feedbackId]: ID of feedback to delete
  ///
  /// Returns:
  /// - Success message
  _i2.Future<String> deleteFeedback(
    String adminPublicKeyHex,
    String adminSignature,
    int feedbackId,
  ) => caller.callServerEndpoint<String>(
    'feedbackAdmin',
    'deleteFeedback',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'feedbackId': feedbackId,
    },
  );

  /// Validate admin signature and check permission.
  ///
  /// This method performs ECDSA signature verification and returns
  /// the associated admin role if valid.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [requestBody]: JSON string of request body (excluding signature fields)
  ///
  /// Returns:
  /// - AdminRole if signature is valid and key is active
  /// - null if signature is invalid or key is inactive
  ///
  /// Example:
  /// ```dart
  /// final role = await validateAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  ///
  /// if (role == null) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.insufficientPermissions,
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i4.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole?>(
    'feedbackAdmin',
    'validateAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );

  /// Require admin authentication or throw exception.
  ///
  /// Convenience method that validates the signature and throws
  /// an exception if authentication fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key
  /// - [signature]: ECDSA signature
  /// - [requestBody]: JSON string of request body
  ///
  /// Returns:
  /// - AdminRole if authentication successful
  ///
  /// Throws:
  /// - Exception if authentication fails
  ///
  /// Example:
  /// ```dart
  /// final role = await requireAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  /// // If we get here, authentication succeeded
  /// ```
  @override
  _i2.Future<_i4.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole>(
    'feedbackAdmin',
    'requireAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );
}

/// Feedback Endpoint for privacy-preserving user feedback
///
/// Receives anonymous feedback (feature requests, bug reports, general feedback)
/// from users using the same security model as error reporting.
///
/// Features:
/// - Anonymous (no authentication required)
/// - Interactive Hashcash proof-of-work (prevents spam)
/// - ECDSA P-256 signature verification for rate limiting
/// - Challenge-response protocol (5-minute TTL)
/// - Stores feedback WITHOUT any identifiers
///
/// Security Model:
/// - Public key is used ONLY for rate limiting (stored temporarily in Redis/memory)
/// - Feedback is stored WITHOUT any public key or hash
/// - Reports remain fully anonymous in the database
/// {@category Endpoint}
class EndpointFeedback extends EndpointPublicSubmission {
  EndpointFeedback(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'feedback';

  /// Submit feedback with proof-of-work and signature
  ///
  /// Parameters:
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars) - REQUIRED for rate limiting
  /// - [signature]: ECDSA signature (128 hex chars) - REQUIRED for verification
  /// - [feedbackText]: The feedback content (10-5000 characters)
  /// - [feedbackType]: Type of feedback ('feature_request', 'bug', 'general')
  /// - [metadata]: Optional JSON metadata (app version, platform, etc.)
  ///
  /// Throws [ServerException] on validation, rate limit, or internal errors.
  _i2.Future<void> submitFeedback({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String feedbackText,
    required String feedbackType,
    String? metadata,
  }) => caller.callServerEndpoint<void>(
    'feedback',
    'submitFeedback',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'feedbackText': feedbackText,
      'feedbackType': feedbackType,
      'metadata': metadata,
    },
  );

  /// Get challenge for proof-of-work.
  ///
  /// This method is inherited by all public endpoints and provides
  /// a consistent way to generate challenges.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  ///
  /// Returns a map with:
  /// - challenge: Random challenge string (32 hex chars)
  /// - difficulty: Number of leading zero bits required (20)
  /// - expiresAt: Unix timestamp when challenge expires
  ///
  /// Example:
  /// ```dart
  /// final challenge = await getChallenge(session);
  /// // Returns: {
  /// //   'challenge': 'abc123...',
  /// //   'difficulty': 20,
  /// //   'expiresAt': 1234567890
  /// // }
  /// ```
  @override
  _i2.Future<_i5.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i5.PublicChallengeResponse>(
        'feedback',
        'getChallenge',
        {},
      );

  /// Verify submission (PoW + signature + rate limit).
  ///
  /// This method performs all verification steps:
  /// 1. Verifies proof-of-work solution
  /// 2. Verifies ECDSA signature
  /// 3. Checks and enforces rate limits
  ///
  /// Throws an exception if any verification step fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [payload]: Original payload that was signed
  ///
  /// Throws:
  /// - Exception if proof-of-work is invalid
  /// - Exception if signature is invalid
  /// - RateLimitExceededException if rate limit exceeded
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await verifySubmission(
  ///     session,
  ///     challenge,
  ///     proofOfWork,
  ///     publicKeyHex,
  ///     signature,
  ///     payload,
  ///   );
  ///   // Verification successful, process submission
  /// } catch (e) {
  ///   // Handle verification failure
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: e.toString(),
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<void> verifySubmission(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'feedback',
    'verifySubmission',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );
}

/// Admin endpoint for creating and managing notifications
///
/// Supports broadcast (global bucket) and individual (user bucket) notifications.
/// Uses ECDSA P-256 signature authentication (separate from user AnonAccred system).
///
/// Access Levels:
/// - Support: Can view notifications and statistics
/// - Admin: Can create, view, get statistics, and delete notifications
/// {@category Endpoint}
class EndpointNotificationAdmin extends EndpointAdminManagement {
  EndpointNotificationAdmin(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'notificationAdmin';

  /// Create notifications for specific users or broadcast to all
  ///
  /// Access: Admin only
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin ECDSA P-256 public key (128 hex chars)
  /// - [adminSignature]: ECDSA signature of request body (128 hex chars)
  /// - [accountIds]: List of user IDs, or null for broadcast (global bucket)
  /// - [title]: Notification title
  /// - [message]: Notification message (plain text)
  /// - [type]: 'inform', 'warning', 'failure', 'success', 'announcement'
  /// - [expiresInDays]: Days until expiration (default: 30)
  /// - [actionUrl]: Optional deep link or web URL
  /// - [actionLabel]: Optional button text
  ///
  /// Returns:
  /// - List of created notification IDs
  _i2.Future<String> createNotifications(
    String adminPublicKeyHex,
    String adminSignature, {
    List<int>? accountIds,
    required String title,
    required String message,
    required String type,
    required int expiresInDays,
    String? actionUrl,
    String? actionLabel,
  }) => caller.callServerEndpoint<String>(
    'notificationAdmin',
    'createNotifications',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'accountIds': accountIds,
      'title': title,
      'message': message,
      'type': type,
      'expiresInDays': expiresInDays,
      'actionUrl': actionUrl,
      'actionLabel': actionLabel,
    },
  );

  /// Get notification statistics
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin ECDSA P-256 public key (128 hex chars)
  /// - [adminSignature]: ECDSA signature of request body (128 hex chars)
  ///
  /// Returns:
  /// - total: Total notification count
  /// - marked: Count of marked notifications
  /// - unmarked: Count of unmarked notifications
  _i2.Future<String> getStatistics(
    String adminPublicKeyHex,
    String adminSignature,
  ) => caller.callServerEndpoint<String>(
    'notificationAdmin',
    'getStatistics',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
    },
  );

  /// List notifications with filtering
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [limit]: Max results per page (default: 50)
  /// - [offset]: Number of results to skip (default: 0)
  /// - [isBroadcast]: Filter by broadcast status (null = all, true = broadcast, false = targeted)
  /// - [isExpired]: Filter by expiration status (null = all, true = expired, false = active)
  /// - [startDate]: Filter by date range start (optional)
  /// - [endDate]: Filter by date range end (optional)
  ///
  /// Returns:
  /// - Paginated response with notifications
  _i2.Future<String> listNotifications(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    bool? isBroadcast,
    bool? isExpired,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<String>(
    'notificationAdmin',
    'listNotifications',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'limit': limit,
      'offset': offset,
      'isBroadcast': isBroadcast,
      'isExpired': isExpired,
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Get notification details including receipt analytics
  ///
  /// Access: Support or Admin
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [notificationId]: ID of notification to retrieve
  ///
  /// Returns:
  /// - notification: Notification details
  /// - receiptCount: Number of receipts
  /// - receipts: List of receipts (who acknowledged)
  _i2.Future<String> getNotificationDetails(
    String adminPublicKeyHex,
    String adminSignature,
    String notificationId,
  ) => caller.callServerEndpoint<String>(
    'notificationAdmin',
    'getNotificationDetails',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'notificationId': notificationId,
    },
  );

  /// Delete notification (admin only)
  ///
  /// Access: Admin only
  ///
  /// Parameters:
  /// - [adminPublicKeyHex]: Admin's ECDSA public key
  /// - [adminSignature]: Signature of request
  /// - [notificationId]: ID of notification to delete
  ///
  /// Returns:
  /// - Success message
  _i2.Future<String> deleteNotification(
    String adminPublicKeyHex,
    String adminSignature,
    String notificationId,
  ) => caller.callServerEndpoint<String>(
    'notificationAdmin',
    'deleteNotification',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'notificationId': notificationId,
    },
  );

  /// Validate admin signature and check permission.
  ///
  /// This method performs ECDSA signature verification and returns
  /// the associated admin role if valid.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [requestBody]: JSON string of request body (excluding signature fields)
  ///
  /// Returns:
  /// - AdminRole if signature is valid and key is active
  /// - null if signature is invalid or key is inactive
  ///
  /// Example:
  /// ```dart
  /// final role = await validateAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  ///
  /// if (role == null) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   throw ServerException(
  ///     code: ServerErrorCode.insufficientPermissions,
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i4.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole?>(
    'notificationAdmin',
    'validateAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );

  /// Require admin authentication or throw exception.
  ///
  /// Convenience method that validates the signature and throws
  /// an exception if authentication fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [publicKeyHex]: ECDSA P-256 public key
  /// - [signature]: ECDSA signature
  /// - [requestBody]: JSON string of request body
  ///
  /// Returns:
  /// - AdminRole if authentication successful
  ///
  /// Throws:
  /// - Exception if authentication fails
  ///
  /// Example:
  /// ```dart
  /// final role = await requireAdmin(
  ///   session,
  ///   publicKeyHex,
  ///   signature,
  ///   requestBody,
  /// );
  /// // If we get here, authentication succeeded
  /// ```
  @override
  _i2.Future<_i4.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i4.AdminRole>(
    'notificationAdmin',
    'requireAdmin',
    {
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'requestBody': requestBody,
    },
  );
}

/// Product catalog endpoint — returns active store product IDs.
///
/// Protected by HashCash proof-of-work + ECDSA signature (inherited from
/// PublicSubmissionEndpoint). No IP addresses are stored or used.
///
/// The actual product data lives in AnonAccred's rail_product table.
/// This endpoint wraps the query with Quanitya's PoW protection.
/// {@category Endpoint}
class EndpointProductCatalog extends EndpointPublicSubmission {
  EndpointProductCatalog(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'productCatalog';

  /// Get active store product IDs for a given payment rail.
  ///
  /// Requires HashCash proof-of-work and ECDSA signature.
  ///
  /// Parameters:
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature of "challenge:railName"
  /// - [railName]: Payment rail name (e.g. 'apple_iap', 'google_iap')
  ///
  /// Returns: List of active store product ID strings.
  _i2.Future<List<String>> getActiveStoreProductIds(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String railName,
  ) => caller.callServerEndpoint<List<String>>(
    'productCatalog',
    'getActiveStoreProductIds',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'railName': railName,
    },
  );

  /// Get challenge for proof-of-work.
  ///
  /// This method is inherited by all public endpoints and provides
  /// a consistent way to generate challenges.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  ///
  /// Returns a map with:
  /// - challenge: Random challenge string (32 hex chars)
  /// - difficulty: Number of leading zero bits required (20)
  /// - expiresAt: Unix timestamp when challenge expires
  ///
  /// Example:
  /// ```dart
  /// final challenge = await getChallenge(session);
  /// // Returns: {
  /// //   'challenge': 'abc123...',
  /// //   'difficulty': 20,
  /// //   'expiresAt': 1234567890
  /// // }
  /// ```
  @override
  _i2.Future<_i5.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i5.PublicChallengeResponse>(
        'productCatalog',
        'getChallenge',
        {},
      );

  /// Verify submission (PoW + signature + rate limit).
  ///
  /// This method performs all verification steps:
  /// 1. Verifies proof-of-work solution
  /// 2. Verifies ECDSA signature
  /// 3. Checks and enforces rate limits
  ///
  /// Throws an exception if any verification step fails.
  ///
  /// Parameters:
  /// - [session]: Serverpod session
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature (128 hex chars)
  /// - [payload]: Original payload that was signed
  ///
  /// Throws:
  /// - Exception if proof-of-work is invalid
  /// - Exception if signature is invalid
  /// - RateLimitExceededException if rate limit exceeded
  ///
  /// Example:
  /// ```dart
  /// try {
  ///   await verifySubmission(
  ///     session,
  ///     challenge,
  ///     proofOfWork,
  ///     publicKeyHex,
  ///     signature,
  ///     payload,
  ///   );
  ///   // Verification successful, process submission
  /// } catch (e) {
  ///   // Handle verification failure
  ///   throw ServerException(
  ///     code: ServerErrorCode.authenticationFailed,
  ///     message: e.toString(),
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<void> verifySubmission(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'productCatalog',
    'verifySubmission',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );
}

/// Sync access endpoint for PowerSync integration
///
/// Provides API access for PowerSync JWT generation and sync access management
/// based on consumable balances. All operations require AnonAccred authentication.
/// {@category Endpoint}
class EndpointSyncAccess extends _i1.EndpointRef {
  EndpointSyncAccess(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'syncAccess';

  /// Generate PowerSync JWT token for authenticated user
  ///
  /// Checks if user has active sync access (sync_days > 0) and generates
  /// a JWT token for PowerSync authentication.
  ///
  /// Returns JWT token string
  ///
  /// Throws ServerException if no sync days remaining
  _i2.Future<String> generatePowerSyncToken() =>
      caller.callServerEndpoint<String>(
        'syncAccess',
        'generatePowerSyncToken',
        {},
      );

  /// Check sync access status for authenticated user
  ///
  /// Returns detailed information about user's sync access including:
  /// - hasAccess: boolean sync access status
  /// - syncDaysRemaining: days of sync remaining
  /// - accessExpiry: estimated expiry date
  /// - needsTopUp: whether user needs to purchase more sync days
  _i2.Future<_i7.SyncAccessStatus> checkSyncAccess() =>
      caller.callServerEndpoint<_i7.SyncAccessStatus>(
        'syncAccess',
        'checkSyncAccess',
        {},
      );

  /// Validate ongoing sync access for authenticated user
  ///
  /// This endpoint can be called periodically by PowerSync clients
  /// to ensure the user still has active sync access.
  ///
  /// Returns true if user has active sync access
  _i2.Future<bool> validateSyncAccess() => caller.callServerEndpoint<bool>(
    'syncAccess',
    'validateSyncAccess',
    {},
  );

  /// Get sync access requirements and pricing
  ///
  /// Returns JSON string with sync access pricing and requirements
  /// for display in the client app. Contains deeply nested pricing structures.
  _i2.Future<String> getSyncAccessInfo() => caller.callServerEndpoint<String>(
    'syncAccess',
    'getSyncAccessInfo',
    {},
  );

  /// Refresh PowerSync token (extend expiry)
  ///
  /// Generates a new PowerSync JWT token with extended expiry,
  /// provided the user still has active sync access.
  _i2.Future<String> refreshPowerSyncToken() =>
      caller.callServerEndpoint<String>(
        'syncAccess',
        'refreshPowerSyncToken',
        {},
      );

  /// Get sync usage statistics for authenticated user
  ///
  /// Returns usage information and consumption history
  _i2.Future<_i8.SyncUsageStats> getSyncUsageStats() =>
      caller.callServerEndpoint<_i8.SyncUsageStats>(
        'syncAccess',
        'getSyncUsageStats',
        {},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i9.Caller(client);
    serverpod_auth_core = _i10.Caller(client);
    community = _i11.Caller(client);
    anonaccount = _i12.Caller(client);
    anonaccred = _i13.Caller(client);
  }

  late final _i9.Caller serverpod_auth_idp;

  late final _i10.Caller serverpod_auth_core;

  late final _i11.Caller community;

  late final _i12.Caller anonaccount;

  late final _i13.Caller anonaccred;
}

class Client extends _i1.ServerpodClientShared {
  Client(
    String host, {
    dynamic securityContext,
    @Deprecated(
      'Use authKeyProvider instead. This will be removed in future releases.',
    )
    super.authenticationKeyManager,
    Duration? streamingConnectionTimeout,
    Duration? connectionTimeout,
    Function(
      _i1.MethodCallContext,
      Object,
      StackTrace,
    )?
    onFailedCall,
    Function(_i1.MethodCallContext)? onSucceededCall,
    bool? disconnectStreamsOnLostInternetConnection,
  }) : super(
         host,
         _i14.Protocol(),
         securityContext: securityContext,
         streamingConnectionTimeout: streamingConnectionTimeout,
         connectionTimeout: connectionTimeout,
         onFailedCall: onFailedCall,
         onSucceededCall: onSucceededCall,
         disconnectStreamsOnLostInternetConnection:
             disconnectStreamsOnLostInternetConnection,
       ) {
    cloudHealth = EndpointCloudHealth(this);
    accountDeletion = EndpointAccountDeletion(this);
    adminKeyManagement = EndpointAdminKeyManagement(this);
    analyticsAdmin = EndpointAnalyticsAdmin(this);
    analyticsEvent = EndpointAnalyticsEvent(this);
    cloudAnalysis = EndpointCloudAnalysis(this);
    cloudLlm = EndpointCloudLlm(this);
    entitlementAdmin = EndpointEntitlementAdmin(this);
    errorReportAdmin = EndpointErrorReportAdmin(this);
    errorReport = EndpointErrorReport(this);
    feedbackAdmin = EndpointFeedbackAdmin(this);
    feedback = EndpointFeedback(this);
    notificationAdmin = EndpointNotificationAdmin(this);
    productCatalog = EndpointProductCatalog(this);
    syncAccess = EndpointSyncAccess(this);
    modules = Modules(this);
  }

  late final EndpointCloudHealth cloudHealth;

  late final EndpointAccountDeletion accountDeletion;

  late final EndpointAdminKeyManagement adminKeyManagement;

  late final EndpointAnalyticsAdmin analyticsAdmin;

  late final EndpointAnalyticsEvent analyticsEvent;

  late final EndpointCloudAnalysis cloudAnalysis;

  late final EndpointCloudLlm cloudLlm;

  late final EndpointEntitlementAdmin entitlementAdmin;

  late final EndpointErrorReportAdmin errorReportAdmin;

  late final EndpointErrorReport errorReport;

  late final EndpointFeedbackAdmin feedbackAdmin;

  late final EndpointFeedback feedback;

  late final EndpointNotificationAdmin notificationAdmin;

  late final EndpointProductCatalog productCatalog;

  late final EndpointSyncAccess syncAccess;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'cloudHealth': cloudHealth,
    'accountDeletion': accountDeletion,
    'adminKeyManagement': adminKeyManagement,
    'analyticsAdmin': analyticsAdmin,
    'analyticsEvent': analyticsEvent,
    'cloudAnalysis': cloudAnalysis,
    'cloudLlm': cloudLlm,
    'entitlementAdmin': entitlementAdmin,
    'errorReportAdmin': errorReportAdmin,
    'errorReport': errorReport,
    'feedbackAdmin': feedbackAdmin,
    'feedback': feedback,
    'notificationAdmin': notificationAdmin,
    'productCatalog': productCatalog,
    'syncAccess': syncAccess,
  };

  @override
  Map<String, _i1.ModuleEndpointCaller> get moduleLookup => {
    'serverpod_auth_idp': modules.serverpod_auth_idp,
    'serverpod_auth_core': modules.serverpod_auth_core,
    'community': modules.community,
    'anonaccount': modules.anonaccount,
    'anonaccred': modules.anonaccred,
  };
}
