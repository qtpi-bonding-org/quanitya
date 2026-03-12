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
import 'package:quanitya_client/src/protocol/archived_month.dart' as _i3;
import 'package:quanitya_client/src/protocol/archive_metadata.dart' as _i4;
import 'package:quanitya_client/src/protocol/archive_search_result.dart' as _i5;
import 'package:serverpod_auth_idp_client/serverpod_auth_idp_client.dart'
    as _i6;
import 'package:serverpod_auth_core_client/serverpod_auth_core_client.dart'
    as _i7;
import 'package:quanitya_client/src/protocol/powersync_token.dart' as _i8;
import 'package:quanitya_client/src/protocol/encrypted_template.dart' as _i9;
import 'package:quanitya_client/src/protocol/encrypted_entry.dart' as _i10;
import 'package:quanitya_client/src/protocol/encrypted_schedule.dart' as _i11;
import 'package:quanitya_client/src/protocol/template_aesthetics.dart' as _i12;
import 'package:quanitya_client/src/protocol/encrypted_analysis_pipeline.dart'
    as _i13;
import 'package:quanitya_client/src/protocol/storage_usage_response.dart'
    as _i14;
import 'package:quanitya_client/src/protocol/greeting.dart' as _i15;

/// Archive retrieval endpoint for accessing historical data
///
/// Provides API access to archived data stored in R2.
/// All operations require authentication and validate user ownership.
/// {@category Endpoint}
class EndpointArchive extends _i1.EndpointRef {
  EndpointArchive(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quanitya.archive';

  /// Get archived data for a specific month
  ///
  /// [year] - Year (e.g., 2024)
  /// [month] - Month (1-12)
  ///
  /// Returns [ArchivedMonth] containing all archived data for that month
  _i2.Future<_i3.ArchivedMonth?> getArchivedMonth(
    int year,
    int month,
  ) => caller.callServerEndpoint<_i3.ArchivedMonth?>(
    'quanitya.archive',
    'getArchivedMonth',
    {
      'year': year,
      'month': month,
    },
  );

  /// Get archived data for a date range (multiple months)
  ///
  /// [startYear] - Start year
  /// [startMonth] - Start month (1-12)
  /// [endYear] - End year
  /// [endMonth] - End month (1-12)
  ///
  /// Returns list of [ArchivedMonth] objects for the date range
  _i2.Future<List<_i3.ArchivedMonth>> getArchivedDateRange(
    int startYear,
    int startMonth,
    int endYear,
    int endMonth,
  ) => caller.callServerEndpoint<List<_i3.ArchivedMonth>>(
    'quanitya.archive',
    'getArchivedDateRange',
    {
      'startYear': startYear,
      'startMonth': startMonth,
      'endYear': endYear,
      'endMonth': endMonth,
    },
  );

  /// Get metadata about available archived months for the authenticated user
  ///
  /// Returns [ArchiveMetadata] with list of available months and statistics
  _i2.Future<_i4.ArchiveMetadata> getArchiveMetadata() =>
      caller.callServerEndpoint<_i4.ArchiveMetadata>(
        'quanitya.archive',
        'getArchiveMetadata',
        {},
      );

  /// Search archived entries by date range (lightweight metadata only)
  ///
  /// [startDate] - Start date for search
  /// [endDate] - End date for search
  ///
  /// Returns list of [ArchiveSearchResult] with entry metadata (no encrypted data)
  _i2.Future<List<_i5.ArchiveSearchResult>> searchArchivedEntries(
    DateTime startDate,
    DateTime endDate,
  ) => caller.callServerEndpoint<List<_i5.ArchiveSearchResult>>(
    'quanitya.archive',
    'searchArchivedEntries',
    {
      'startDate': startDate,
      'endDate': endDate,
    },
  );

  /// Manual archival trigger for testing and maintenance
  ///
  /// Triggers the monthly archival process manually.
  /// Requires the caller's account ID to be listed in the
  /// ADMIN_ACCOUNT_IDS environment variable (comma-separated).
  _i2.Future<String> runManualArchival() => caller.callServerEndpoint<String>(
    'quanitya.archive',
    'runManualArchival',
    {},
  );
}

/// By extending [EmailIdpBaseEndpoint], the email identity provider endpoints
/// are made available on the server and enable the corresponding sign-in widget
/// on the client.
/// {@category Endpoint}
class EndpointEmailIdp extends _i6.EndpointEmailIdpBase {
  EndpointEmailIdp(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quanitya.emailIdp';

  /// Logs in the user and returns a new session.
  ///
  /// Throws an [EmailAccountLoginException] in case of errors, with reason:
  /// - [EmailAccountLoginExceptionReason.invalidCredentials] if the email or
  ///   password is incorrect.
  /// - [EmailAccountLoginExceptionReason.tooManyAttempts] if there have been
  ///   too many failed login attempts.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i2.Future<_i7.AuthSuccess> login({
    required String email,
    required String password,
  }) => caller.callServerEndpoint<_i7.AuthSuccess>(
    'quanitya.emailIdp',
    'login',
    {
      'email': email,
      'password': password,
    },
  );

  /// Starts the registration for a new user account with an email-based login
  /// associated to it.
  ///
  /// Upon successful completion of this method, an email will have been
  /// sent to [email] with a verification link, which the user must open to
  /// complete the registration.
  ///
  /// Always returns a account request ID, which can be used to complete the
  /// registration. If the email is already registered, the returned ID will not
  /// be valid.
  @override
  _i2.Future<_i1.UuidValue> startRegistration({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'quanitya.emailIdp',
        'startRegistration',
        {'email': email},
      );

  /// Verifies an account request code and returns a token
  /// that can be used to complete the account creation.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if no request exists
  ///   for the given [accountRequestId] or [verificationCode] is invalid.
  @override
  _i2.Future<String> verifyRegistrationCode({
    required _i1.UuidValue accountRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'quanitya.emailIdp',
    'verifyRegistrationCode',
    {
      'accountRequestId': accountRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a new account registration, creating a new auth user with a
  /// profile and attaching the given email account to it.
  ///
  /// Throws an [EmailAccountRequestException] in case of errors, with reason:
  /// - [EmailAccountRequestExceptionReason.expired] if the account request has
  ///   already expired.
  /// - [EmailAccountRequestExceptionReason.policyViolation] if the password
  ///   does not comply with the password policy.
  /// - [EmailAccountRequestExceptionReason.invalid] if the [registrationToken]
  ///   is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  ///
  /// Returns a session for the newly created user.
  @override
  _i2.Future<_i7.AuthSuccess> finishRegistration({
    required String registrationToken,
    required String password,
  }) => caller.callServerEndpoint<_i7.AuthSuccess>(
    'quanitya.emailIdp',
    'finishRegistration',
    {
      'registrationToken': registrationToken,
      'password': password,
    },
  );

  /// Requests a password reset for [email].
  ///
  /// If the email address is registered, an email with reset instructions will
  /// be send out. If the email is unknown, this method will have no effect.
  ///
  /// Always returns a password reset request ID, which can be used to complete
  /// the reset. If the email is not registered, the returned ID will not be
  /// valid.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to request a password reset.
  ///
  @override
  _i2.Future<_i1.UuidValue> startPasswordReset({required String email}) =>
      caller.callServerEndpoint<_i1.UuidValue>(
        'quanitya.emailIdp',
        'startPasswordReset',
        {'email': email},
      );

  /// Verifies a password reset code and returns a finishPasswordResetToken
  /// that can be used to finish the password reset.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.tooManyAttempts] if the user has
  ///   made too many attempts trying to verify the password reset.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// If multiple steps are required to complete the password reset, this endpoint
  /// should be overridden to return credentials for the next step instead
  /// of the credentials for setting the password.
  @override
  _i2.Future<String> verifyPasswordResetCode({
    required _i1.UuidValue passwordResetRequestId,
    required String verificationCode,
  }) => caller.callServerEndpoint<String>(
    'quanitya.emailIdp',
    'verifyPasswordResetCode',
    {
      'passwordResetRequestId': passwordResetRequestId,
      'verificationCode': verificationCode,
    },
  );

  /// Completes a password reset request by setting a new password.
  ///
  /// The [verificationCode] returned from [verifyPasswordResetCode] is used to
  /// validate the password reset request.
  ///
  /// Throws an [EmailAccountPasswordResetException] in case of errors, with reason:
  /// - [EmailAccountPasswordResetExceptionReason.expired] if the password reset
  ///   request has already expired.
  /// - [EmailAccountPasswordResetExceptionReason.policyViolation] if the new
  ///   password does not comply with the password policy.
  /// - [EmailAccountPasswordResetExceptionReason.invalid] if no request exists
  ///   for the given [passwordResetRequestId] or [verificationCode] is invalid.
  ///
  /// Throws an [AuthUserBlockedException] if the auth user is blocked.
  @override
  _i2.Future<void> finishPasswordReset({
    required String finishPasswordResetToken,
    required String newPassword,
  }) => caller.callServerEndpoint<void>(
    'quanitya.emailIdp',
    'finishPasswordReset',
    {
      'finishPasswordResetToken': finishPasswordResetToken,
      'newPassword': newPassword,
    },
  );

  @override
  _i2.Future<bool> hasAccount() => caller.callServerEndpoint<bool>(
    'quanitya.emailIdp',
    'hasAccount',
    {},
  );
}

/// By extending [RefreshJwtTokensEndpoint], the JWT token refresh endpoint
/// is made available on the server and enables automatic token refresh on the client.
/// {@category Endpoint}
class EndpointJwtRefresh extends _i7.EndpointRefreshJwtTokens {
  EndpointJwtRefresh(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quanitya.jwtRefresh';

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
  _i2.Future<_i7.AuthSuccess> refreshAccessToken({
    required String refreshToken,
  }) => caller.callServerEndpoint<_i7.AuthSuccess>(
    'quanitya.jwtRefresh',
    'refreshAccessToken',
    {'refreshToken': refreshToken},
    authenticated: false,
  );
}

/// PowerSync JWT endpoint for client authentication
///
/// Issues JWT tokens for PowerSync client authentication.
/// Tokens include user_id claim for sync bucket filtering.
/// Uses RS256 signing with RSA keys for PowerSync verification.
/// {@category Endpoint}
class EndpointPowerSync extends _i1.EndpointRef {
  EndpointPowerSync(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quanitya.powerSync';

  /// Get PowerSync JWT token for authenticated user
  ///
  /// Returns a [PowerSyncToken] containing the JWT token, expiry time,
  /// and PowerSync endpoint URL.
  ///
  /// Token expires in 5 minutes - client should refresh before expiry.
  _i2.Future<_i8.PowerSyncToken> getToken() =>
      caller.callServerEndpoint<_i8.PowerSyncToken>(
        'quanitya.powerSync',
        'getToken',
        {},
      );
}

/// Sync endpoint for PowerSync data operations
///
/// Handles CRUD operations for E2EE encrypted data and template aesthetics.
/// All operations require authentication via AnonAccred device key.
/// New inserts are gated by per-account storage quota.
/// {@category Endpoint}
class EndpointSync extends _i1.EndpointRef {
  EndpointSync(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quanitya.sync';

  /// Upsert encrypted template
  _i2.Future<_i9.EncryptedTemplate> upsertEncryptedTemplate(
    String id,
    String encryptedData,
  ) => caller.callServerEndpoint<_i9.EncryptedTemplate>(
    'quanitya.sync',
    'upsertEncryptedTemplate',
    {
      'id': id,
      'encryptedData': encryptedData,
    },
  );

  /// Delete encrypted template
  _i2.Future<bool> deleteEncryptedTemplate(String id) =>
      caller.callServerEndpoint<bool>(
        'quanitya.sync',
        'deleteEncryptedTemplate',
        {'id': id},
      );

  /// Upsert encrypted entry
  _i2.Future<_i10.EncryptedEntry> upsertEncryptedEntry(
    String id,
    String encryptedData,
  ) => caller.callServerEndpoint<_i10.EncryptedEntry>(
    'quanitya.sync',
    'upsertEncryptedEntry',
    {
      'id': id,
      'encryptedData': encryptedData,
    },
  );

  /// Delete encrypted entry
  _i2.Future<bool> deleteEncryptedEntry(String id) =>
      caller.callServerEndpoint<bool>(
        'quanitya.sync',
        'deleteEncryptedEntry',
        {'id': id},
      );

  /// Upsert encrypted schedule
  _i2.Future<_i11.EncryptedSchedule> upsertEncryptedSchedule(
    String id,
    String encryptedData,
  ) => caller.callServerEndpoint<_i11.EncryptedSchedule>(
    'quanitya.sync',
    'upsertEncryptedSchedule',
    {
      'id': id,
      'encryptedData': encryptedData,
    },
  );

  /// Delete encrypted schedule
  _i2.Future<bool> deleteEncryptedSchedule(String id) =>
      caller.callServerEndpoint<bool>(
        'quanitya.sync',
        'deleteEncryptedSchedule',
        {'id': id},
      );

  /// Upsert template aesthetics
  _i2.Future<_i12.TemplateAesthetics> upsertTemplateAesthetics(
    String id,
    String templateId,
    String? themeName,
    String? icon,
    String? emoji,
    String? paletteJson,
    String? fontConfigJson,
    String? colorMappingsJson,
    String? updatedAt,
  ) => caller.callServerEndpoint<_i12.TemplateAesthetics>(
    'quanitya.sync',
    'upsertTemplateAesthetics',
    {
      'id': id,
      'templateId': templateId,
      'themeName': themeName,
      'icon': icon,
      'emoji': emoji,
      'paletteJson': paletteJson,
      'fontConfigJson': fontConfigJson,
      'colorMappingsJson': colorMappingsJson,
      'updatedAt': updatedAt,
    },
  );

  /// Delete template aesthetics
  _i2.Future<bool> deleteTemplateAesthetics(String id) =>
      caller.callServerEndpoint<bool>(
        'quanitya.sync',
        'deleteTemplateAesthetics',
        {'id': id},
      );

  /// Upsert encrypted analysis pipeline
  _i2.Future<_i13.EncryptedAnalysisPipeline> upsertEncryptedAnalysisPipeline(
    String id,
    String encryptedData,
  ) => caller.callServerEndpoint<_i13.EncryptedAnalysisPipeline>(
    'quanitya.sync',
    'upsertEncryptedAnalysisPipeline',
    {
      'id': id,
      'encryptedData': encryptedData,
    },
  );

  /// Delete encrypted analysis pipeline
  _i2.Future<bool> deleteEncryptedAnalysisPipeline(String id) =>
      caller.callServerEndpoint<bool>(
        'quanitya.sync',
        'deleteEncryptedAnalysisPipeline',
        {'id': id},
      );

  /// Get storage usage for authenticated user
  _i2.Future<_i14.StorageUsageResponse> getStorageUsage() =>
      caller.callServerEndpoint<_i14.StorageUsageResponse>(
        'quanitya.sync',
        'getStorageUsage',
        {},
      );
}

/// This is an example endpoint that returns a greeting message through
/// its [hello] method.
/// {@category Endpoint}
class EndpointGreeting extends _i1.EndpointRef {
  EndpointGreeting(_i1.EndpointCaller caller) : super(caller);

  @override
  String get name => 'quanitya.greeting';

  /// Returns a personalized greeting message: "Hello {name}".
  _i2.Future<_i15.Greeting> hello(String name) =>
      caller.callServerEndpoint<_i15.Greeting>(
        'quanitya.greeting',
        'hello',
        {'name': name},
      );
}

class Caller extends _i1.ModuleEndpointCaller {
  Caller(_i1.ServerpodClientShared client) : super(client) {
    archive = EndpointArchive(this);
    emailIdp = EndpointEmailIdp(this);
    jwtRefresh = EndpointJwtRefresh(this);
    powerSync = EndpointPowerSync(this);
    sync = EndpointSync(this);
    greeting = EndpointGreeting(this);
  }

  late final EndpointArchive archive;

  late final EndpointEmailIdp emailIdp;

  late final EndpointJwtRefresh jwtRefresh;

  late final EndpointPowerSync powerSync;

  late final EndpointSync sync;

  late final EndpointGreeting greeting;

  @override
  Map<String, _i1.EndpointRef> get endpointRefLookup => {
    'quanitya.archive': archive,
    'quanitya.emailIdp': emailIdp,
    'quanitya.jwtRefresh': jwtRefresh,
    'quanitya.powerSync': powerSync,
    'quanitya.sync': sync,
    'quanitya.greeting': greeting,
  };
}
