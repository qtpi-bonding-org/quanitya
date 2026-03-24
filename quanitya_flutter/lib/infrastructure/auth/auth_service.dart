import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show AuthSuccess, FlutterAuthSessionManagerExtension;
import 'package:serverpod_client/serverpod_client.dart' show UuidValue;
import 'package:anonaccount_client/anonaccount_client.dart'
    show AuthenticationResult, DeviceMethods;

import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/data_encryption_service.dart';
import '../crypto/utils/hashcash.dart';

/// Result of account creation - contains the ultimate private key for user backup
class AccountCreationResult {
  /// The serialized ultimate private key (JWK Set JSON with ECDSA + RSA private keys).
  ///
  /// SECURITY: This is the master recovery key. It:
  /// - NEVER leaves the client device except to user's offline backup
  /// - NEVER gets sent to any server
  /// - Must be saved offline by user for account recovery
  final String ultimatePrivateKey;

  const AccountCreationResult({required this.ultimatePrivateKey});
}

/// Describes why an auth operation failed.
enum AuthFailure {
  networkError,
  general,
}

/// Exception thrown when authentication operations fail
class AuthException implements Exception {
  const AuthException(this.message, {this.kind = AuthFailure.general, this.cause});

  final String message;
  final AuthFailure kind;
  final Object? cause;

  @override
  String toString() =>
      'AuthException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when account creation fails
class AccountCreationException extends AuthException {
  const AccountCreationException(super.message, {super.kind, super.cause});

  @override
  String toString() =>
      'AccountCreationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when account recovery fails
class AccountRecoveryException extends AuthException {
  const AccountRecoveryException(super.message, {super.kind, super.cause});

  @override
  String toString() =>
      'AccountRecoveryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Exception thrown when device authentication fails
class DeviceAuthenticationException extends AuthException {
  const DeviceAuthenticationException(super.message, {super.kind, super.cause});

  @override
  String toString() =>
      'DeviceAuthenticationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Wraps an error as an [AuthException], detecting network errors from the cause.
AuthException _wrapAuthError(String message, [Object? cause]) {
  final causeStr = cause?.toString() ?? '';
  final isNetwork = causeStr.contains('SocketException') ||
      causeStr.contains('Connection refused');
  return AuthException(
    message,
    kind: isNetwork ? AuthFailure.networkError : AuthFailure.general,
    cause: cause,
  );
}

/// Pure JWT session management for the Serverpod anonaccred backend.
///
/// Handles device authentication (PoW + sign-in → JWT) and session storage.
/// Account lifecycle operations (create, register, recover, delete) live in
/// [AccountService] and [DeleteService].
///
/// Throws [DeviceAuthenticationException] on failure — callers handle retry.
@lazySingleton
class AuthService {
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryption _encryption;
  final Client _client;

  bool _isInitialized = false;

  AuthService(
    this._keyRepository,
    this._encryption,
    this._client,
  );

  /// Initialize auth service
  ///
  /// Note: The FlutterAuthSessionManager is set up in bootstrap.dart via
  /// `_initializeClientAuth()`. This method no longer sets an auth key provider.
  Future<void> initialize() {
    return tryMethod(
      () async {
        if (_isInitialized) return;
        _isInitialized = true;
      },
      _wrapAuthError,
      'initialize',
    );
  }

  /// Check if user is authenticated (has stored device keys)
  Future<bool> isAuthenticated() {
    return tryMethod(
      () async {
        final status = await _keyRepository.getKeyStatus();
        return status == CryptoKeyStatus.ready;
      },
      _wrapAuthError,
      'isAuthenticated',
    );
  }

  /// Perform challenge-response authentication (for sensitive operations)
  ///
  /// Flow:
  /// 1. Get challenge from server
  /// 2. Sign challenge with device private key (ECDSA P-256) via DataEncryption
  /// 3. Server verifies signature and issues JWT
  /// 4. Store JWT in Serverpod's FlutterAuthSessionManager
  ///
  /// Returns [AuthenticationResult] with success status and account/device IDs
  ///
  /// Throws [DeviceAuthenticationException] on failure.
  Future<AuthenticationResult> authenticateDevice() {
    return tryMethod(
      () async {
        // Get device public key
        final devicePublicKeyHex = await _keyRepository
            .getDeviceSigningPublicKeyHex();
        if (devicePublicKeyHex == null) {
          throw const DeviceAuthenticationException(
            'Device public key not found',
          );
        }

        // 1. Get PoW challenge, then generate auth challenge
        final powChallengeResponse =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final powProof = await _computeProofOfWork(
          powChallengeResponse.challenge,
          powChallengeResponse.difficulty,
        );
        final powSignPayload =
            '${powChallengeResponse.challenge}:${DeviceMethods.signIn}:$devicePublicKeyHex';
        final powSignature =
            await _encryption.signWithDeviceKey(powSignPayload);

        // 2. Sign in with server (PoW + signature verification)
        final result = await _client.modules.anonaccount.device
            .signIn(
          challenge: powChallengeResponse.challenge,
          proofOfWork: powProof,
          signature: powSignature,
          devicePublicKeyHex: devicePublicKeyHex,
        );

        if (!result.success) {
          throw DeviceAuthenticationException(
            result.errorMessage ?? 'Authentication failed',
          );
        }

        // 3. Store JWT in Serverpod's session manager
        await _storeAuthSession(result);

        return result;
      },
      (message, [cause]) => DeviceAuthenticationException(message, cause: cause),
      'authenticateDevice',
    );
  }

  /// Ensure the device has a valid JWT session.
  /// If not authenticated, performs device authentication.
  /// Throws [DeviceAuthenticationException] on failure — caller handles retry.
  Future<void> ensureAuthenticated() async {
    if (_client.auth.isAuthenticated) return;
    await authenticateDevice();
  }

  /// Store authentication result as a Serverpod auth session.
  ///
  /// Constructs an [AuthSuccess] from the [AuthenticationResult.details] map
  /// and stores it via the [FlutterAuthSessionManager]. This enables
  /// Serverpod's built-in JWT auth header management and token refresh.
  Future<void> _storeAuthSession(AuthenticationResult result) async {
    final details = result.details;
    if (details == null) return;

    final token = details['token'];
    final authUserIdStr = details['authUserId'];
    final authStrategy = details['authStrategy'] ?? 'jwt';
    if (token == null || authUserIdStr == null) return;

    final tokenExpiresAtStr = details['tokenExpiresAt'];
    final refreshToken = details['refreshToken'];

    final authSuccess = AuthSuccess(
      authStrategy: authStrategy,
      token: token,
      tokenExpiresAt: tokenExpiresAtStr != null
          ? DateTime.tryParse(tokenExpiresAtStr)
          : null,
      refreshToken: refreshToken,
      authUserId: UuidValue.fromString(authUserIdStr),
      scopeNames: {},
    );

    await _client.auth.updateSignedInUser(authSuccess);
  }

  /// Compute hashcash proof-of-work for spam prevention.
  Future<String> _computeProofOfWork(String challenge, int difficulty) async {
    return Hashcash.mint(challenge, difficulty: difficulty);
  }
}
