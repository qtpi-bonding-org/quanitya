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
import 'package:quanitya_cloud_client/src/protocol/api_response.dart' as _i4;
import 'package:quanitya_cloud_client/src/models/admin_role.dart' as _i5;
import 'package:quanitya_cloud_client/src/protocol/public_challenge_response.dart'
    as _i6;
import 'package:quanitya_cloud_client/src/protocol/cloud_llm_structured_request.dart'
    as _i7;
import 'package:quanitya_cloud_client/src/protocol/feature_access_response.dart'
    as _i8;
import 'package:quanitya_cloud_client/src/protocol/sync_access_status.dart'
    as _i9;
import 'package:quanitya_cloud_client/src/protocol/sync_usage_stats.dart'
    as _i10;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i11;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i12;
import 'package:quanitya_client/quanitya_client.dart' as _i13;
import 'package:anonaccount_client/anonaccount_client.dart' as _i14;
import 'package:anonaccred_client/anonaccred_client.dart' as _i15;
import 'protocol.dart' as _i16;

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
  _i2.Future<_i4.ApiResponse> listEvents(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    String? eventNameFilter,
    String? platformFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getEventDetails(
    String adminPublicKeyHex,
    String adminSignature,
    int eventId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getStatistics(
    String adminPublicKeyHex,
    String adminSignature, {
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> deleteEvent(
    String adminPublicKeyHex,
    String adminSignature,
    int eventId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  ///   return ResponseBuilder.authError(
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   return ResponseBuilder.permissionError(
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i5.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole?>(
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
  _i2.Future<_i5.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole>(
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
  /// Returns:
  /// - success: true if events were stored
  /// - data: Contains insertedCount
  /// - message: Success or error message
  _i2.Future<_i4.ApiResponse> submitEvents({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String eventsJson,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i6.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i6.PublicChallengeResponse>(
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
  ///   return ResponseBuilder.error(
  ///     code: ResponseBuilder.errorAuthFailed,
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
///   Future<ApiResponse> createNotification(
///     Session session,
///     String publicKeyHex,
///     String signature, {
///     required String title,
///   }) async {
///     final role = await validateAdmin(session, publicKeyHex, signature, body);
///
///     if (role == null) {
///       return ResponseBuilder.authError(
///         message: 'Invalid signature or inactive key',
///       );
///     }
///
///     // Process the admin operation...
///     return ResponseBuilder.success(data: {'notificationId': id});
///   }
/// }
/// ```
///
/// **IMPORTANT**: Never return `Map<String, dynamic>` from Serverpod endpoints.
/// Serverpod cannot deserialize `dynamic`. Use typed protocol models or
/// `ApiResponse` with JSON-encoded `jsonData` for complex responses.
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
  ///   return ResponseBuilder.authError(
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   return ResponseBuilder.permissionError(
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  _i2.Future<_i5.AdminRole?> validateAdmin(
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
  _i2.Future<_i5.AdminRole> requireAdmin(
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
///   Future<ApiResponse> submitReport(
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
///     return ResponseBuilder.success(data: {'reportId': reportId});
///   }
/// }
/// ```
///
/// **IMPORTANT**: Never return `Map<String, dynamic>` from Serverpod endpoints.
/// Serverpod cannot deserialize `dynamic`. Use typed protocol models or
/// `ApiResponse` with JSON-encoded `jsonData` for complex responses.
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
  _i2.Future<_i6.PublicChallengeResponse> getChallenge();

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
  ///   return ResponseBuilder.error(
  ///     code: ResponseBuilder.errorAuthFailed,
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
  /// MVP: This feature is disabled. Returns error response.
  _i2.Future<_i4.ApiResponse> requestAnalysis(String analysisType) =>
      caller.callServerEndpoint<_i4.ApiResponse>(
        'cloudAnalysis',
        'requestAnalysis',
        {'analysisType': analysisType},
      );

  /// Get AnonAccount configuration status
  _i2.Future<_i4.ApiResponse> getAnonAccountConfig() =>
      caller.callServerEndpoint<_i4.ApiResponse>(
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
  /// Returns ApiResponse with jsonData containing the LLM's
  /// structured JSON output (shape defined by caller's schema).
  _i2.Future<_i4.ApiResponse> generateStructured(
    _i7.CloudLlmStructuredRequest request,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
    'cloudLlm',
    'generateStructured',
    {'request': request},
  );
}

/// Consumable management endpoint for Quanitya Cloud
///
/// Provides API access to consumable balances and feature access checking.
/// User-facing operations require AnonAccred authentication.
/// Admin operations (addCredits, consumeCredits) require admin API key.
/// {@category Endpoint}
class EndpointConsumable extends _i1.EndpointRef {
  EndpointConsumable(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'consumable';

  /// Get all consumable balances for the authenticated user
  ///
  /// Returns map of consumable types (int) to current balances
  _i2.Future<Map<int, double>> getBalances() =>
      caller.callServerEndpoint<Map<int, double>>(
        'consumable',
        'getBalances',
        {},
      );

  /// Get feature access summary for the authenticated user
  ///
  /// Returns comprehensive feature access information including:
  /// - hasSync: boolean sync access
  /// - hasIntegrations: boolean integration access
  /// - syncDaysRemaining: days of sync left per tier
  /// - integrationDaysRemaining: days of integrations left
  /// - analysisCredits: analysis credits available
  /// - llmCalls: LLM call credits available
  _i2.Future<_i8.FeatureAccessResponse> getFeatureAccess() =>
      caller.callServerEndpoint<_i8.FeatureAccessResponse>(
        'consumable',
        'getFeatureAccess',
        {},
      );

  /// Get balance for a specific consumable type
  ///
  /// [consumableType] - Type of consumable to check (int)
  ///
  /// Returns current balance or 0.0 if none exists
  _i2.Future<double> getBalance(int consumableType) =>
      caller.callServerEndpoint<double>(
        'consumable',
        'getBalance',
        {'consumableType': consumableType},
      );

  /// Check if user has sufficient credits for an operation
  ///
  /// [consumableType] - Type of consumable to check (int)
  /// [requiredAmount] - Amount required for the operation
  ///
  /// Returns true if user has sufficient balance
  _i2.Future<bool> hasSufficientCredits(
    int consumableType,
    double requiredAmount,
  ) => caller.callServerEndpoint<bool>(
    'consumable',
    'hasSufficientCredits',
    {
      'consumableType': consumableType,
      'requiredAmount': requiredAmount,
    },
  );

  /// Check if user has active sync access
  ///
  /// Returns true if user has sync_days > 0
  _i2.Future<bool> hasActiveSyncAccess() => caller.callServerEndpoint<bool>(
    'consumable',
    'hasActiveSyncAccess',
    {},
  );

  /// Check if user has integration access
  ///
  /// Returns true if user has integration_days > 0
  _i2.Future<bool> hasIntegrationAccess() => caller.callServerEndpoint<bool>(
    'consumable',
    'hasIntegrationAccess',
    {},
  );

  /// Get analysis cost for a specific analysis type
  ///
  /// [analysisType] - Type of analysis to get cost for
  ///
  /// Returns credit cost for the analysis type
  _i2.Future<double> getAnalysisCost(String analysisType) =>
      caller.callServerEndpoint<double>(
        'consumable',
        'getAnalysisCost',
        {'analysisType': analysisType},
      );

  /// Add credits to user inventory (for purchases/top-ups)
  ///
  /// This endpoint is typically called after successful payment processing
  /// to add purchased consumables to the user's inventory.
  ///
  /// Requires admin or support role.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [accountId] - Target account ID
  /// [consumableType] - Type of consumable to add (int)
  /// [amount] - Amount to add (must be positive)
  ///
  /// Returns success message
  _i2.Future<String> addCredits(
    String adminPublicKeyHex,
    String adminSignature,
    int accountId,
    int consumableType,
    double amount,
  ) => caller.callServerEndpoint<String>(
    'consumable',
    'addCredits',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'accountId': accountId,
      'consumableType': consumableType,
      'amount': amount,
    },
  );

  /// Manual credit consumption (for testing/admin purposes)
  ///
  /// This endpoint allows manual consumption of credits, typically used
  /// for testing or administrative operations.
  ///
  /// Requires admin or support role.
  ///
  /// [adminPublicKeyHex] - Admin ECDSA P-256 public key (128 hex chars)
  /// [adminSignature] - ECDSA signature of request body (128 hex chars)
  /// [accountId] - Target account ID
  /// [consumableType] - Type of consumable to consume (int)
  /// [amount] - Amount to consume (must be positive)
  ///
  /// Returns success message
  _i2.Future<String> consumeCredits(
    String adminPublicKeyHex,
    String adminSignature,
    int accountId,
    int consumableType,
    double amount,
  ) => caller.callServerEndpoint<String>(
    'consumable',
    'consumeCredits',
    {
      'adminPublicKeyHex': adminPublicKeyHex,
      'adminSignature': adminSignature,
      'accountId': accountId,
      'consumableType': consumableType,
      'amount': amount,
    },
  );

  /// Get list of valid consumable types
  ///
  /// Returns array of supported consumable type IDs (int)
  _i2.Future<List<int>> getValidConsumableTypes() =>
      caller.callServerEndpoint<List<int>>(
        'consumable',
        'getValidConsumableTypes',
        {},
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
  _i2.Future<_i4.ApiResponse> listErrorReports(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    String? errorTypeFilter,
    String? errorCodeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getErrorReportDetails(
    String adminPublicKeyHex,
    String adminSignature,
    int errorReportId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getErrorStatistics(
    String adminPublicKeyHex,
    String adminSignature, {
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> deleteErrorReport(
    String adminPublicKeyHex,
    String adminSignature,
    int errorReportId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  ///   return ResponseBuilder.authError(
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   return ResponseBuilder.permissionError(
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i5.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole?>(
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
  _i2.Future<_i5.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole>(
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
  /// Returns:
  /// - success: true if report was stored
  /// - data: Contains reportId and timestamp
  /// - message: Success or error message
  _i2.Future<_i4.ApiResponse> submitErrorReport({
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
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i6.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i6.PublicChallengeResponse>(
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
  ///   return ResponseBuilder.error(
  ///     code: ResponseBuilder.errorAuthFailed,
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
  _i2.Future<_i4.ApiResponse> listFeedback(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    String? feedbackTypeFilter,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getFeedbackDetails(
    String adminPublicKeyHex,
    String adminSignature,
    int feedbackId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getFeedbackStatistics(
    String adminPublicKeyHex,
    String adminSignature, {
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> deleteFeedback(
    String adminPublicKeyHex,
    String adminSignature,
    int feedbackId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  ///   return ResponseBuilder.authError(
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   return ResponseBuilder.permissionError(
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i5.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole?>(
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
  _i2.Future<_i5.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole>(
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
  /// Returns:
  /// - success: true if feedback was stored
  /// - data: Contains feedbackId and timestamp
  /// - message: Success or error message
  _i2.Future<_i4.ApiResponse> submitFeedback({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String feedbackText,
    required String feedbackType,
    String? metadata,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i6.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i6.PublicChallengeResponse>(
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
  ///   return ResponseBuilder.error(
  ///     code: ResponseBuilder.errorAuthFailed,
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
  _i2.Future<_i4.ApiResponse> createNotifications(
    String adminPublicKeyHex,
    String adminSignature, {
    List<int>? accountIds,
    required String title,
    required String message,
    required String type,
    required int expiresInDays,
    String? actionUrl,
    String? actionLabel,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getStatistics(
    String adminPublicKeyHex,
    String adminSignature,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> listNotifications(
    String adminPublicKeyHex,
    String adminSignature, {
    required int limit,
    required int offset,
    bool? isBroadcast,
    bool? isExpired,
    DateTime? startDate,
    DateTime? endDate,
  }) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> getNotificationDetails(
    String adminPublicKeyHex,
    String adminSignature,
    String notificationId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i4.ApiResponse> deleteNotification(
    String adminPublicKeyHex,
    String adminSignature,
    String notificationId,
  ) => caller.callServerEndpoint<_i4.ApiResponse>(
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
  ///   return ResponseBuilder.authError(
  ///     message: 'Invalid signature or inactive key',
  ///   );
  /// }
  ///
  /// if (!role.canSendNotifications()) {
  ///   return ResponseBuilder.permissionError(
  ///     message: 'Insufficient permissions',
  ///   );
  /// }
  /// ```
  @override
  _i2.Future<_i5.AdminRole?> validateAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole?>(
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
  _i2.Future<_i5.AdminRole> requireAdmin(
    String publicKeyHex,
    String signature,
    String requestBody,
  ) => caller.callServerEndpoint<_i5.AdminRole>(
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
  _i2.Future<_i6.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i6.PublicChallengeResponse>(
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
  ///   return ResponseBuilder.error(
  ///     code: ResponseBuilder.errorAuthFailed,
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
  /// Throws PaymentException if no sync days remaining
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
  _i2.Future<_i9.SyncAccessStatus> checkSyncAccess() =>
      caller.callServerEndpoint<_i9.SyncAccessStatus>(
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
  /// Returns information about sync access pricing and requirements
  /// for display in the client app. Uses ApiResponse with jsonData
  /// because the response contains deeply nested pricing structures.
  _i2.Future<_i4.ApiResponse> getSyncAccessInfo() =>
      caller.callServerEndpoint<_i4.ApiResponse>(
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
  _i2.Future<_i10.SyncUsageStats> getSyncUsageStats() =>
      caller.callServerEndpoint<_i10.SyncUsageStats>(
        'syncAccess',
        'getSyncUsageStats',
        {},
      );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i11.Caller(client);
    serverpod_auth_core = _i12.Caller(client);
    community = _i13.Caller(client);
    anonaccount = _i14.Caller(client);
    anonaccred = _i15.Caller(client);
  }

  late final _i11.Caller serverpod_auth_idp;

  late final _i12.Caller serverpod_auth_core;

  late final _i13.Caller community;

  late final _i14.Caller anonaccount;

  late final _i15.Caller anonaccred;
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
         _i16.Protocol(),
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
    consumable = EndpointConsumable(this);
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

  late final EndpointConsumable consumable;

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
    'consumable': consumable,
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
