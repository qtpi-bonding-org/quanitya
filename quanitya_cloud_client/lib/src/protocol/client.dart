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
import 'package:anonaccount_client/anonaccount_client.dart' as _i3;
import 'package:quanitya_cloud_client/src/protocol/batch_submission_result.dart'
    as _i4;
import 'package:quanitya_cloud_client/src/protocol/cloud_llm_structured_response.dart'
    as _i5;
import 'package:quanitya_cloud_client/src/protocol/cloud_llm_structured_request.dart'
    as _i6;
import 'package:quanitya_client/quanitya_client.dart' as _i7;
import 'package:quanitya_cloud_client/src/protocol/feedback_type.dart' as _i8;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i9;
import 'package:quanitya_cloud_client/src/protocol/platform_catalog_response.dart'
    as _i10;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i11;
import 'package:anonaccred_client/anonaccred_client.dart' as _i12;
import 'protocol.dart' as _i13;

/// A simple cloud-specific endpoint to verify the cloud server is working.
/// {@category Endpoint}
class EndpointCloudHealth extends _i1.EndpointRef {
  EndpointCloudHealth(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudHealth';

  /// Returns a health check message for the cloud server.
  ///
  /// Verifies database connectivity by running a simple query.
  /// Returns 'ok' on success, throws [ServerException] on failure.
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
class EndpointAccountDeletion extends _i3.EndpointJwt {
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

/// Account registration and recovery with proof-of-work spam prevention.
///
/// Extends [SignedPowEndpoint] from anonaccount for hashcash PoW +
/// ECDSA signature verification + rate limiting.
/// {@category Endpoint}
class EndpointAccountRegistration extends _i3.EndpointSignedPow {
  EndpointAccountRegistration(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'accountRegistration';

  /// Create a new anonymous account with proof-of-work verification.
  _i2.Future<_i3.AnonAccount> createAccount({
    required String challenge,
    required String proofOfWork,
    required String signature,
    required String publicKeyHex,
    required String ultimateSigningPublicKeyHex,
    required String encryptedDataKey,
    required String ultimatePublicKey,
  }) => caller.callServerEndpoint<_i3.AnonAccount>(
    'accountRegistration',
    'createAccount',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'signature': signature,
      'publicKeyHex': publicKeyHex,
      'ultimateSigningPublicKeyHex': ultimateSigningPublicKeyHex,
      'encryptedDataKey': encryptedDataKey,
      'ultimatePublicKey': ultimatePublicKey,
    },
  );

  /// Throws — use [EntrypointEndpoint.getChallenge] instead.
  ///
  /// Overridden without `@doNotGenerate` so the generated client class gets a
  /// concrete implementation, satisfying the abstract [EndpointPow.getChallenge].
  @override
  _i2.Future<_i3.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i3.PublicChallengeResponse>(
        'accountRegistration',
        'getChallenge',
        {},
      );

  /// Verify PoW + ECDSA signature + rate limit.
  ///
  /// Call this at the top of each protected endpoint method.
  ///
  /// - [session] Serverpod session
  /// - [challenge] The challenge string from [getChallenge]
  /// - [proofOfWork] The hashcash stamp mined by the client
  /// - [publicKeyHex] The ECDSA P-256 public key (128 hex chars)
  /// - [signature] ECDSA signature over [payload]
  /// - [payload] The signed payload (typically `'$challenge:methodName:$publicKeyHex'`)
  @override
  _i2.Future<void> verifySignedPow(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'accountRegistration',
    'verifySignedPow',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );

  /// Verify hashcash proof-of-work only (no signature, no rate limit).
  ///
  /// Checks stamp format, challenge existence, and hash quality.
  /// Consumes the challenge (one-time use).
  @override
  _i2.Future<void> verifyHashcash(
    String challenge,
    String proofOfWork,
  ) => caller.callServerEndpoint<void>(
    'accountRegistration',
    'verifyHashcash',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
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
class EndpointAnalyticsEvent extends _i3.EndpointSignedPow {
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
  _i2.Future<_i4.BatchSubmissionResult> submitEvents({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String eventsJson,
  }) => caller.callServerEndpoint<_i4.BatchSubmissionResult>(
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

  /// Throws — use [EntrypointEndpoint.getChallenge] instead.
  ///
  /// Overridden without `@doNotGenerate` so the generated client class gets a
  /// concrete implementation, satisfying the abstract [EndpointPow.getChallenge].
  @override
  _i2.Future<_i3.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i3.PublicChallengeResponse>(
        'analyticsEvent',
        'getChallenge',
        {},
      );

  /// Verify PoW + ECDSA signature + rate limit.
  ///
  /// Call this at the top of each protected endpoint method.
  ///
  /// - [session] Serverpod session
  /// - [challenge] The challenge string from [getChallenge]
  /// - [proofOfWork] The hashcash stamp mined by the client
  /// - [publicKeyHex] The ECDSA P-256 public key (128 hex chars)
  /// - [signature] ECDSA signature over [payload]
  /// - [payload] The signed payload (typically `'$challenge:methodName:$publicKeyHex'`)
  @override
  _i2.Future<void> verifySignedPow(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'analyticsEvent',
    'verifySignedPow',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );

  /// Verify hashcash proof-of-work only (no signature, no rate limit).
  ///
  /// Checks stamp format, challenge existence, and hash quality.
  /// Consumes the challenge (one-time use).
  @override
  _i2.Future<void> verifyHashcash(
    String challenge,
    String proofOfWork,
  ) => caller.callServerEndpoint<void>(
    'analyticsEvent',
    'verifyHashcash',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
    },
  );
}

/// Cloud Analysis Endpoint - MVP Disabled
///
/// This endpoint provides pay-per-use statistical analysis features.
/// DISABLED for MVP launch - will be added post-launch.
/// {@category Endpoint}
class EndpointCloudAnalysis extends _i3.EndpointJwt {
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
}

/// Cloud LLM Endpoint for proxied access to OpenRouter.
///
/// Model selection is server-controlled to prevent cost abuse.
/// Uses OpenRouter's `models` array for automatic failover.
/// {@category Endpoint}
class EndpointCloudLlm extends _i3.EndpointJwt {
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
  _i2.Future<_i5.CloudLlmStructuredResponse> generateStructured(
    _i6.CloudLlmStructuredRequest request,
  ) => caller.callServerEndpoint<_i5.CloudLlmStructuredResponse>(
    'cloudLlm',
    'generateStructured',
    {'request': request},
  );
}

/// Cloud override of the community PowerSync endpoint.
///
/// Adds entitlement gating: the user must have sync_days > 0 to receive
/// a PowerSync JWT. JWT generation is delegated to the community base class.
///
/// Route: `cloudPowerSync.getToken()`
/// {@category Endpoint}
class EndpointCloudPowerSync extends _i7.EndpointPowerSync {
  EndpointCloudPowerSync(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'cloudPowerSync';

  @override
  _i2.Future<_i7.PowerSyncToken> getToken() =>
      caller.callServerEndpoint<_i7.PowerSyncToken>(
        'cloudPowerSync',
        'getToken',
        {},
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
class EndpointErrorReport extends _i3.EndpointSignedPow {
  EndpointErrorReport(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'errorReport';

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
  _i2.Future<_i4.BatchSubmissionResult> submitErrorReports({
    required String challenge,
    required String proofOfWork,
    required String publicKeyHex,
    required String signature,
    required String reportsJson,
  }) => caller.callServerEndpoint<_i4.BatchSubmissionResult>(
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

  /// Throws — use [EntrypointEndpoint.getChallenge] instead.
  ///
  /// Overridden without `@doNotGenerate` so the generated client class gets a
  /// concrete implementation, satisfying the abstract [EndpointPow.getChallenge].
  @override
  _i2.Future<_i3.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i3.PublicChallengeResponse>(
        'errorReport',
        'getChallenge',
        {},
      );

  /// Verify PoW + ECDSA signature + rate limit.
  ///
  /// Call this at the top of each protected endpoint method.
  ///
  /// - [session] Serverpod session
  /// - [challenge] The challenge string from [getChallenge]
  /// - [proofOfWork] The hashcash stamp mined by the client
  /// - [publicKeyHex] The ECDSA P-256 public key (128 hex chars)
  /// - [signature] ECDSA signature over [payload]
  /// - [payload] The signed payload (typically `'$challenge:methodName:$publicKeyHex'`)
  @override
  _i2.Future<void> verifySignedPow(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'errorReport',
    'verifySignedPow',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );

  /// Verify hashcash proof-of-work only (no signature, no rate limit).
  ///
  /// Checks stamp format, challenge existence, and hash quality.
  /// Consumes the challenge (one-time use).
  @override
  _i2.Future<void> verifyHashcash(
    String challenge,
    String proofOfWork,
  ) => caller.callServerEndpoint<void>(
    'errorReport',
    'verifyHashcash',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
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
class EndpointFeedback extends _i3.EndpointSignedPow {
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
    required _i8.FeedbackType feedbackType,
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

  /// Throws — use [EntrypointEndpoint.getChallenge] instead.
  ///
  /// Overridden without `@doNotGenerate` so the generated client class gets a
  /// concrete implementation, satisfying the abstract [EndpointPow.getChallenge].
  @override
  _i2.Future<_i3.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i3.PublicChallengeResponse>(
        'feedback',
        'getChallenge',
        {},
      );

  /// Verify PoW + ECDSA signature + rate limit.
  ///
  /// Call this at the top of each protected endpoint method.
  ///
  /// - [session] Serverpod session
  /// - [challenge] The challenge string from [getChallenge]
  /// - [proofOfWork] The hashcash stamp mined by the client
  /// - [publicKeyHex] The ECDSA P-256 public key (128 hex chars)
  /// - [signature] ECDSA signature over [payload]
  /// - [payload] The signed payload (typically `'$challenge:methodName:$publicKeyHex'`)
  @override
  _i2.Future<void> verifySignedPow(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'feedback',
    'verifySignedPow',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );

  /// Verify hashcash proof-of-work only (no signature, no rate limit).
  ///
  /// Checks stamp format, challenge existence, and hash quality.
  /// Consumes the challenge (one-time use).
  @override
  _i2.Future<void> verifyHashcash(
    String challenge,
    String proofOfWork,
  ) => caller.callServerEndpoint<void>(
    'feedback',
    'verifyHashcash',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
    },
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i9.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'jwtRefresh';

  /// Creates a new token pair for the given [refreshToken].
  ///
  /// Can throw the following exceptions:
  /// -[RefreshTokenMalformedException]: refresh token is malformed and could
  ///   not be parsed. Not expected to happen for tokens issued by the server.
  /// -[RefreshTokenNotFoundException]: refresh token is unknown to the server.
  ///   Either the token was deleted or generated by a different server.
  /// -[RefreshTokenExpiredException]: refresh token has expired. Will happen
  ///   only if it has not been used within configured `refreshTokenLifetime`.
  /// -[RefreshTokenInvalidSecretException]: refresh token is incorrect, meaning
  ///   it does not refer to the current secret refresh token. This indicates
  ///   either a malfunctioning client or a malicious attempt by someone who has
  ///   obtained the refresh token. In this case the underlying refresh token
  ///   will be deleted, and access to it will expire fully when the last access
  ///   token is elapsed.
  ///
  /// This endpoint is unauthenticated, meaning the client won't include any
  /// authentication information with the call.
  @override
  _i2.Future<_i9.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i9.AuthSuccess>(
    'jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// Product catalog endpoint — returns platform-specific rail statuses and products.
///
/// Protected by HashCash proof-of-work + ECDSA signature via [SignedPowEndpoint].
/// No IP addresses are stored or used.
///
/// Rail configuration is read from Redis (seeded from platform_rails.csv).
/// Product data lives in AnonAccred's rail_product table.
/// {@category Endpoint}
class EndpointProductCatalog extends _i3.EndpointSignedPow {
  EndpointProductCatalog(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'productCatalog';

  /// Get the product catalog for a platform.
  ///
  /// Returns rail statuses and active product IDs for each rail
  /// configured for the given platform.
  ///
  /// Parameters:
  /// - [challenge]: Challenge string from getChallenge()
  /// - [proofOfWork]: Hashcash stamp (format: "1:20:challenge:nonce")
  /// - [publicKeyHex]: ECDSA P-256 public key (128 hex chars)
  /// - [signature]: ECDSA signature of "challenge:platformName"
  /// - [platformName]: Platform identifier (e.g. 'ios', 'android', 'web')
  ///
  /// Returns: PlatformCatalogResponse with rails and their product IDs.
  _i2.Future<_i10.PlatformCatalogResponse> getCatalog(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String platformName,
  ) => caller.callServerEndpoint<_i10.PlatformCatalogResponse>(
    'productCatalog',
    'getCatalog',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'platformName': platformName,
    },
  );

  /// Throws — use [EntrypointEndpoint.getChallenge] instead.
  ///
  /// Overridden without `@doNotGenerate` so the generated client class gets a
  /// concrete implementation, satisfying the abstract [EndpointPow.getChallenge].
  @override
  _i2.Future<_i3.PublicChallengeResponse> getChallenge() =>
      caller.callServerEndpoint<_i3.PublicChallengeResponse>(
        'productCatalog',
        'getChallenge',
        {},
      );

  /// Verify PoW + ECDSA signature + rate limit.
  ///
  /// Call this at the top of each protected endpoint method.
  ///
  /// - [session] Serverpod session
  /// - [challenge] The challenge string from [getChallenge]
  /// - [proofOfWork] The hashcash stamp mined by the client
  /// - [publicKeyHex] The ECDSA P-256 public key (128 hex chars)
  /// - [signature] ECDSA signature over [payload]
  /// - [payload] The signed payload (typically `'$challenge:methodName:$publicKeyHex'`)
  @override
  _i2.Future<void> verifySignedPow(
    String challenge,
    String proofOfWork,
    String publicKeyHex,
    String signature,
    String payload,
  ) => caller.callServerEndpoint<void>(
    'productCatalog',
    'verifySignedPow',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
      'publicKeyHex': publicKeyHex,
      'signature': signature,
      'payload': payload,
    },
  );

  /// Verify hashcash proof-of-work only (no signature, no rate limit).
  ///
  /// Checks stamp format, challenge existence, and hash quality.
  /// Consumes the challenge (one-time use).
  @override
  _i2.Future<void> verifyHashcash(
    String challenge,
    String proofOfWork,
  ) => caller.callServerEndpoint<void>(
    'productCatalog',
    'verifyHashcash',
    {
      'challenge': challenge,
      'proofOfWork': proofOfWork,
    },
  );
}

class Modules {
  Modules(Client client) {
    serverpod_auth_idp = _i11.Caller(client);
    serverpod_auth_core = _i9.Caller(client);
    community = _i7.Caller(client);
    anonaccount = _i3.Caller(client);
    anonaccred = _i12.Caller(client);
  }

  late final _i11.Caller serverpod_auth_idp;

  late final _i9.Caller serverpod_auth_core;

  late final _i7.Caller community;

  late final _i3.Caller anonaccount;

  late final _i12.Caller anonaccred;
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
         _i13.Protocol(),
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
    accountRegistration = EndpointAccountRegistration(this);
    analyticsEvent = EndpointAnalyticsEvent(this);
    cloudAnalysis = EndpointCloudAnalysis(this);
    cloudLlm = EndpointCloudLlm(this);
    cloudPowerSync = EndpointCloudPowerSync(this);
    errorReport = EndpointErrorReport(this);
    feedback = EndpointFeedback(this);
    jwtRefresh = EndpointJwtRefresh(this);
    productCatalog = EndpointProductCatalog(this);
    modules = Modules(this);
  }

  late final EndpointCloudHealth cloudHealth;

  late final EndpointAccountDeletion accountDeletion;

  late final EndpointAccountRegistration accountRegistration;

  late final EndpointAnalyticsEvent analyticsEvent;

  late final EndpointCloudAnalysis cloudAnalysis;

  late final EndpointCloudLlm cloudLlm;

  late final EndpointCloudPowerSync cloudPowerSync;

  late final EndpointErrorReport errorReport;

  late final EndpointFeedback feedback;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointProductCatalog productCatalog;

  late final Modules modules;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'cloudHealth': cloudHealth,
    'accountDeletion': accountDeletion,
    'accountRegistration': accountRegistration,
    'analyticsEvent': analyticsEvent,
    'cloudAnalysis': cloudAnalysis,
    'cloudLlm': cloudLlm,
    'cloudPowerSync': cloudPowerSync,
    'errorReport': errorReport,
    'feedback': feedback,
    'jwtRefresh': jwtRefresh,
    'productCatalog': productCatalog,
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
