import 'dart:convert';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:serverpod_client/serverpod_client.dart'
    show ClientAuthKeyProvider;
import 'package:anonaccount_client/anonaccount_client.dart'
    show AuthenticationResult, AccountDevice;

import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/data_encryption_service.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import '../crypto/utils/hashcash.dart';
import '../../features/app_operating_mode/repositories/app_operating_repository.dart';
import '../../features/app_operating_mode/models/app_operating_mode.dart';
import 'registration_payload.dart';

/// Serverpod 3.x auth key provider using device public key as Bearer token
///
/// Implements [ClientAuthKeyProvider] to provide ECDSA P-256 public key
/// (128 hex chars) as Bearer token for all authenticated requests.
///
/// Auth flow:
/// - Server extracts public key from `Authorization: Bearer <public_key_hex>`
/// - Server verifies device ownership via challenge-response when needed
class AnonAccredAuthKeyProvider implements ClientAuthKeyProvider {
  final ICryptoKeyRepository _keyRepository;

  AnonAccredAuthKeyProvider(this._keyRepository);

  @override
  Future<String?> get authHeaderValue async {
    try {
      final publicKeyHex = await _keyRepository.getDeviceSigningPublicKeyHex();
      debugPrint(
        'AuthKeyProvider: Public key hex available: ${publicKeyHex != null}',
      );
      if (publicKeyHex != null) {
        debugPrint(
          'AuthKeyProvider: Public key hex length: ${publicKeyHex.length}',
        );
        debugPrint(
          'AuthKeyProvider: Public key hex prefix: ${publicKeyHex.length > 20 ? publicKeyHex.substring(0, 20) : publicKeyHex}...',
        );
      }
      if (publicKeyHex == null) return null;

      // Return as Bearer token - server expects 128-char hex public key
      final bearerToken = 'Bearer $publicKeyHex';
      debugPrint('AuthKeyProvider: Bearer token length: ${bearerToken.length}');
      return bearerToken;
    } catch (e) {
      debugPrint('AuthKeyProvider: Error getting auth header: $e');
      // Auth provider should not throw - return null if keys unavailable
      return null;
    }
  }
}

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

/// Orchestrator for authentication with the Serverpod anonaccred backend
///
/// Coordinates between:
/// - [ICryptoKeyRepository] for key generation and storage
/// - [IDataEncryptionService] for signing and blob encryption
/// - Serverpod [Client] for server API calls (anonaccred endpoints)
///
/// Key concepts:
/// - Account: identified by publicMasterKey (device public key hex)
/// - Device: identified by deviceSigningPublicKeyHex (ECDSA P-256, 128 hex chars)
/// - Ultimate private key: serialized JWK for account recovery (NEVER sent to server)
///
/// Throws [AuthException] subclasses on failure - follows cubit_ui_flow exception pattern.
@lazySingleton
class AuthService {
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryptionService _encryption;
  final Client _client;
  final ISecureStorage _secureStorage;
  final AppOperatingRepository _appOperatingRepository;
  late final AnonAccredAuthKeyProvider _authKeyProvider;

  static const _registrationPayloadKey = 'quanitya_registration_payload';
  static const _crossDeviceRegistrationBlobKey = 'quanitya_cross_device_registration';
  static const _registeredWithServerKey = 'quanitya_registered_with_server';

  bool _isInitialized = false;

  AuthService(
    this._keyRepository,
    this._encryption,
    this._client,
    this._secureStorage,
    this._appOperatingRepository,
  ) {
    _authKeyProvider = AnonAccredAuthKeyProvider(_keyRepository);
  }

  /// Initialize auth service and set up auth provider on client
  Future<void> initialize() {
    return tryMethod(
      () async {
        if (_isInitialized) return;

        // Set up the new Serverpod 3.x auth key provider
        _client.authKeyProvider = _authKeyProvider;

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

  /// Create a new account and prepare registration payload
  ///
  /// Flow:
  /// 1. CryptoKeyRepository generates all keys locally
  /// 2. Create encrypted blobs while ultimate key is available
  /// 3. Sign the registration payload with ultimate key
  /// 4. Store the pre-prepared registration payload
  /// 5. Wipe ultimate key and return it for user backup
  ///
  /// Returns [AccountCreationResult] with ultimate private key that user MUST save offline.
  ///
  /// SECURITY: The ultimate private key is:
  /// - Generated locally by CryptoKeyRepository
  /// - Used to sign the registration payload (proves key ownership)
  /// - Retrieved once via getUltimatePrivateKeyOnce() and returned to caller
  /// - NEVER sent to any server
  ///
  /// Throws [AccountCreationException] on failure.
  Future<AccountCreationResult> createAccount({required String deviceLabel}) {
    return tryMethod(
      () async {
        // 1. Generate all keys locally via CryptoKeyRepository
        await _keyRepository.generateAccountKeys();

        // 2. Get all keys we need (while ultimate key is still in memory)
        final symmetricKeyJwk = await _keyRepository.getSymmetricDataKeyJwk();
        if (symmetricKeyJwk == null) {
          throw const AccountCreationException('Symmetric key not generated');
        }

        final deviceKey = await _keyRepository.getDeviceKey();
        if (deviceKey == null) {
          throw const AccountCreationException('Device key not generated');
        }

        final devicePublicKeyHex = await _keyRepository
            .getDeviceSigningPublicKeyHex();
        if (devicePublicKeyHex == null) {
          throw const AccountCreationException(
            'Device public key not available',
          );
        }

        final ultimatePublicKey = await _keyRepository.getUltimatePublicKey();
        if (ultimatePublicKey == null) {
          throw const AccountCreationException('Ultimate key not generated');
        }

        final ultimatePublicKeyHex = await _keyRepository
            .getUltimateSigningPublicKeyHex();
        if (ultimatePublicKeyHex == null) {
          throw const AccountCreationException(
            'Ultimate public key hex not available',
          );
        }

        // 3. Create encrypted blobs (while ultimate key is still available)
        final recoveryBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          ultimatePublicKey,
        );

        final deviceBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          deviceKey.encryption.publicKey,
        );

        // 4. Sign the registration payload with ultimate key
        final createdAt = DateTime.now();
        final signableData =
            '$devicePublicKeyHex:$ultimatePublicKeyHex:$recoveryBlob:$deviceBlob:${createdAt.toIso8601String()}';
        final signableBytes = Uint8List.fromList(signableData.codeUnits);

        final signatureBytes = await _keyRepository.signWithUltimateKey(
          signableBytes,
        );
        if (signatureBytes == null) {
          throw const AccountCreationException(
            'Failed to sign registration payload - ultimate key not available',
          );
        }
        final signature = base64Encode(signatureBytes);

        // 5. Create and store the registration payload
        final payload = RegistrationPayload(
          devicePublicKeyHex: devicePublicKeyHex,
          ultimatePublicKeyHex: ultimatePublicKeyHex,
          recoveryBlob: recoveryBlob,
          deviceBlob: deviceBlob,
          signature: signature,
          createdAt: createdAt,
        );
        await _storeRegistrationPayload(payload);

        // 6. Get ultimate private key JWK ONCE for user backup (clears from memory after)
        final ultimatePrivateKey = await _keyRepository.getUltimateKeyJwkOnce();
        if (ultimatePrivateKey == null) {
          throw const AccountCreationException(
            'Ultimate private key not available',
          );
        }

        // 7. Generate and register cross-device key (iOS iCloud / Android Block Store)
        if (_keyRepository.isCrossDeviceStorageAvailable) {
          try {
            final label = _keyRepository.crossDeviceLabel;
            debugPrint('🔐 AuthService: Generating cross-device key ($label)...');
            final crossDeviceKeyDuo = await _keyRepository.generateCrossDeviceKey();

            // Encrypt symmetric key with cross-device key's encryption public key
            final crossDeviceBlob = await _encryption.createEncryptedBlob(
              symmetricKeyJwk,
              crossDeviceKeyDuo.encryption.publicKey,
            );

            // Get cross-device key's signing public key hex
            final crossDeviceKeyHex = await crossDeviceKeyDuo.signingKeyPair.exportPublicKeyHex();

            // Store payload for deferred server registration
            // registerAccountWithServer will register both devices
            await _secureStorage.storeSecureData(
              _crossDeviceRegistrationBlobKey,
              jsonEncode({
                'keyHex': crossDeviceKeyHex,
                'blob': crossDeviceBlob,
                'label': label,
              }),
            );

            debugPrint('🔐 AuthService: Cross-device key generated and stored');
          } catch (e) {
            // Cross-device key is non-critical — log and continue
            debugPrint('🔐 AuthService: Cross-device key generation failed (non-critical): $e');
          }
        }

        // Return ultimate private key for user to save offline
        // SECURITY: This NEVER gets sent to server
        return AccountCreationResult(ultimatePrivateKey: ultimatePrivateKey);
      },
      (message, [cause]) => AccountCreationException(message, cause: cause),
      'createAccount',
    );
  }

  /// Store registration payload in secure storage
  Future<void> _storeRegistrationPayload(RegistrationPayload payload) async {
    final json = payload.toJsonString();
    await _secureStorage.storeSecureData(_registrationPayloadKey, json);
  }

  /// Retrieve registration payload from secure storage
  Future<RegistrationPayload?> _getRegistrationPayload() async {
    final json = await _secureStorage.getSecureData(_registrationPayloadKey);
    if (json == null) return null;
    return RegistrationPayloadX.fromJsonString(json);
  }


  /// Register existing local account with server using stored registration payload
  ///
  /// Prerequisites:
  /// - Account keys must already exist locally (call createAccount first)
  /// - Registration payload must be stored (created during createAccount)
  ///
  /// Flow:
  /// 1. Retrieve stored registration payload
  /// 2. Verify signature using the payload's own ultimatePublicKeyHex (self-consistent check)
  /// 3. Register account with server (devicePublicKeyHex, recoveryBlob, ultimatePublicKeyHex)
  /// 4. Register device with server (devicePublicKeyHex, deviceBlob, deviceLabel)
  /// 5. Delete registration payload after successful registration
  ///
  /// Throws [AccountCreationException] on failure.
  Future<void> registerAccountWithServer({required String deviceLabel}) {
    return tryMethod(
      () async {
        debugPrint(
          '🔐 AuthService: registerAccountWithServer called with deviceLabel: "$deviceLabel"',
        );

        // 1. Retrieve stored registration payload
        debugPrint('🔐 AuthService: Retrieving stored registration payload...');
        final payload = await _getRegistrationPayload();
        if (payload == null) {
          debugPrint('🔐 AuthService: ERROR - No registration payload found');
          throw const AccountCreationException(
            'No registration payload found - create account first',
          );
        }
        debugPrint(
          '🔐 AuthService: Registration payload found, devicePublicKeyHex length: ${payload.devicePublicKeyHex.length}',
        );
        debugPrint(
          '🔐 AuthService: Registration payload devicePublicKeyHex prefix: ${payload.devicePublicKeyHex.length > 20 ? payload.devicePublicKeyHex.substring(0, 20) : payload.devicePublicKeyHex}...',
        );

        // 2. Verify signature using the payload's own ultimatePublicKeyHex (self-consistent check)
        debugPrint(
          '🔐 AuthService: Verifying registration payload signature...',
        );
        final signableData = payload.signableData;
        final signableBytes = Uint8List.fromList(signableData.codeUnits);
        final signatureBytes = base64Decode(payload.signature);

        final isValid =
            await VerificationService.verifySignatureWithPublicKeyHex(
              publicKeyHex: payload.ultimatePublicKeyHex,
              signature: Uint8List.fromList(signatureBytes),
              data: signableBytes,
            );

        if (!isValid) {
          debugPrint(
            '🔐 AuthService: ERROR - Registration payload signature verification failed',
          );
          throw const AccountCreationException(
            'Registration payload signature verification failed - payload may be corrupted',
          );
        }
        debugPrint(
          '🔐 AuthService: Registration payload signature verified successfully',
        );

        // 3. Register account with server
        debugPrint('🔐 AuthService: Registering account with server...');
        debugPrint(
          '🔐 AuthService: Account registration params - devicePublicKeyHex: ${payload.devicePublicKeyHex.length} chars, recoveryBlob: ${payload.recoveryBlob.length} chars, ultimatePublicKeyHex: ${payload.ultimatePublicKeyHex.length} chars',
        );
        try {
          // Account creation requires proof-of-work via accountRegistration endpoint
          final challengeResponse = await _client.accountRegistration.getChallenge();
          final proofOfWork = await _computeProofOfWork(
            challengeResponse.challenge,
            challengeResponse.difficulty,
          );
          final signPayload =
              '${challengeResponse.challenge}:createAccount:${payload.ultimatePublicKeyHex}';
          final powSignature = await _encryption.signWithDeviceKey(signPayload);

          await _client.accountRegistration.createAccount(
            challenge: challengeResponse.challenge,
            proofOfWork: proofOfWork,
            signature: powSignature,
            ultimateSigningPublicKeyHex: payload.ultimatePublicKeyHex,
            encryptedDataKey: payload.recoveryBlob,
            ultimatePublicKey: payload.ultimatePublicKeyHex,
          );
          debugPrint(
            '🔐 AuthService: Account created successfully',
          );

          // 4. Register device — uses ultimate key to look up account
          debugPrint('🔐 AuthService: Registering device with server...');
          debugPrint(
            '🔐 AuthService: Device registration params - devicePublicKeyHex: ${payload.devicePublicKeyHex.length} chars, deviceBlob: ${payload.deviceBlob.length} chars, label: "$deviceLabel"',
          );
          await _client.modules.anonaccount.device.registerDevice(
            payload.ultimatePublicKeyHex,
            payload.devicePublicKeyHex,
            payload.deviceBlob,
            deviceLabel,
          );
          debugPrint('🔐 AuthService: Device registered successfully');

          // 4.5. Register cross-device key if prepared during createAccount
          try {
            final crossDeviceJson = await _secureStorage.getSecureData(_crossDeviceRegistrationBlobKey);
            if (crossDeviceJson != null) {
              final data = jsonDecode(crossDeviceJson) as Map<String, dynamic>;
              final keyHex = data['keyHex'] as String;
              final blob = data['blob'] as String;
              final label = data['label'] as String;

              debugPrint('🔐 AuthService: Registering cross-device key ($label) with server...');
              await _client.modules.anonaccount.device.registerDevice(
                payload.ultimatePublicKeyHex,
                keyHex,
                blob,
                label,
              );
              debugPrint('🔐 AuthService: Cross-device key registered');

              // Clean up the stored blob
              await _secureStorage.deleteSecureData(_crossDeviceRegistrationBlobKey);
            }
          } catch (e) {
            // Cross-device registration is non-critical
            debugPrint('🔐 AuthService: Cross-device key registration failed (non-critical): $e');
          }

          // 5. Mark device as registered with server
          await _secureStorage.storeSecureData(
            _registeredWithServerKey,
            'true',
          );

          // 6. Switch app to cloud mode after successful server registration
          debugPrint('🔐 AuthService: Switching app to cloud mode...');
          await _appOperatingRepository.updateMode(AppOperatingMode.cloud);
          debugPrint('🔐 AuthService: App switched to cloud mode successfully');
        } catch (serverError, serverStackTrace) {
          debugPrint(
            '🔐 AuthService: Server error during registration: $serverError',
          );
          debugPrint(
            '🔐 AuthService: Server error stack trace: $serverStackTrace',
          );
          rethrow;
        }
      },
      (message, [cause]) => AccountCreationException(message, cause: cause),
      'registerAccountWithServer',
    );
  }

  /// Check whether this device is registered with the server yet.
  ///
  /// Returns `true` if registration has completed successfully.
  Future<bool> get isRegisteredWithServer async =>
      await _secureStorage.getSecureData(_registeredWithServerKey) != null;

  /// Ensure the device is registered with the server.
  ///
  /// If a registration payload exists (account created locally but not yet
  /// registered), this performs the server registration now. Safe to call
  /// multiple times — it's a no-op when already registered.
  Future<void> ensureRegistered({required String deviceLabel}) async {
    if (await isRegisteredWithServer) return;
    await registerAccountWithServer(deviceLabel: deviceLabel);
  }

  /// Compute hashcash proof-of-work for spam prevention.
  Future<String> _computeProofOfWork(String challenge, int difficulty) async {
    return Hashcash.mint(challenge, difficulty: difficulty);
  }

  /// Recover account using ultimate private key (from user's offline backup)
  ///
  /// Flow:
  /// 1. Import and validate ultimate JWK
  /// 2. Derive ultimate public key hex
  /// 3. Look up account on server by ultimate public key
  /// 4. Decrypt recovery blob to get symmetric key
  /// 5. Generate new device keys
  /// 6. Register new device with account
  /// 7. Store keys locally
  ///
  /// SECURITY: The ultimatePrivateKey is used locally only - NEVER sent to server.
  ///
  /// Throws [AccountRecoveryException] on failure.
  Future<void> recoverAccount({
    required String ultimatePrivateKey,
    required String deviceLabel,
  }) {
    return tryMethod(
      () async {
        // 1. Import and validate ultimate JWK
        final ultimateKeyDuo = await _keyRepository.importUltimateKeyJwk(
          ultimatePrivateKey,
        );

        // 2. Derive ultimate public key hex (128 chars)
        final ultimatePublicKeyHex = await ultimateKeyDuo.signingKeyPair
            .exportPublicKeyHex();

        // 3. Look up account on server (PoW-protected)
        final challengeResponse =
            await _client.accountRegistration.getChallenge();
        final proofOfWork = await _computeProofOfWork(
          challengeResponse.challenge,
          challengeResponse.difficulty,
        );
        final recoveryPayload =
            '${challengeResponse.challenge}:getAccountForRecovery:$ultimatePublicKeyHex';
        final recoverySig =
            await _encryption.signWithKeyDuo(recoveryPayload, ultimateKeyDuo);

        final account = await _client.accountRegistration
            .getAccountForRecovery(
          challenge: challengeResponse.challenge,
          proofOfWork: proofOfWork,
          ultimatePublicKey: ultimatePublicKeyHex,
          signature: recoverySig,
        );

        if (account == null) {
          throw const AccountRecoveryException(
            'No account found for this recovery key',
          );
        }

        // 4. Decrypt recovery blob to get symmetric key
        final privateKey = ultimateKeyDuo.encryption.privateKey;
        if (privateKey == null) {
          throw const AccountRecoveryException(
            'Ultimate key missing private encryption key',
          );
        }

        final symmetricKeyJwk = await _encryption.decryptBlob(
          account.encryptedDataKey,
          privateKey,
        );

        // 5. Generate new device keys and store them
        await _keyRepository.generateAndStoreDeviceKey();
        final deviceKey = await _keyRepository.getDeviceKey();
        final devicePublicKeyHex = await _keyRepository
            .getDeviceSigningPublicKeyHex();

        if (deviceKey == null) {
          throw const AccountRecoveryException('Failed to generate device key');
        }
        if (devicePublicKeyHex == null) {
          throw const AccountRecoveryException(
            'Failed to get device public key hex',
          );
        }

        // 6. Create device blob (symmetric key encrypted with new device public key)
        final deviceBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          deviceKey.encryption.publicKey,
        );

        // 7. Register new device with account (uses ultimate key, not int id)
        await _client.modules.anonaccount.device.registerDevice(
          ultimatePublicKeyHex,
          devicePublicKeyHex,
          deviceBlob,
          deviceLabel,
        );

        // 8. Store symmetric key locally
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

        // 9. Mark device as registered with server
        await _secureStorage.storeSecureData(
          _registeredWithServerKey,
          'true',
        );

        // 10. Switch app to cloud mode after successful recovery
        debugPrint(
          '🔐 AuthService: Switching app to cloud mode after recovery...',
        );
        await _appOperatingRepository.updateMode(AppOperatingMode.cloud);
        debugPrint('🔐 AuthService: App switched to cloud mode successfully');

        // Note: Ultimate key is NOT stored - it was only used for this recovery operation
      },
      (message, [cause]) => AccountRecoveryException(message, cause: cause),
      'recoverAccount',
    );
  }

  /// Recover account using cross-device key (Flow B — new device, synced key exists)
  ///
  /// Flow:
  /// 1. Get cross-device key from platform storage
  /// 2. Auth with server using cross-device key
  /// 3. Get encrypted data key blob for cross-device entry
  /// 4. Decrypt to recover symmetric data key
  /// 5. Generate new local device key
  /// 6. Register new local device under the same account
  /// 7. Store local keys
  ///
  /// Throws [AccountRecoveryException] on failure.
  Future<void> recoverFromCrossDeviceKey({required String deviceLabel}) {
    return tryMethod(
      () async {
        final crossDeviceLabel = _keyRepository.crossDeviceLabel;
        debugPrint('🔐 AuthService: Starting cross-device key recovery ($crossDeviceLabel)...');

        // 1. Get cross-device key
        final crossDeviceKeyDuo = await _keyRepository.getCrossDeviceKey();
        if (crossDeviceKeyDuo == null) {
          throw const AccountRecoveryException(
            'Cross-device key not found in platform storage',
          );
        }

        // 2. Auth with server using cross-device key
        final crossDeviceKeyHex = await crossDeviceKeyDuo.signingKeyPair.exportPublicKeyHex();
        debugPrint('🔐 AuthService: Authenticating with cross-device key...');

        final challenge = await _client.modules.anonaccount.device
            .generateAuthChallenge(crossDeviceKeyHex);
        final signature = await _encryption.signWithKeyDuo(challenge, crossDeviceKeyDuo);
        final authResult = await _client.modules.anonaccount.device
            .authenticateDevice(challenge, signature);

        if (!authResult.success) {
          throw AccountRecoveryException(
            authResult.errorMessage ?? 'Cross-device key authentication failed',
          );
        }
        debugPrint('🔐 AuthService: Cross-device key authenticated');

        // 3. Get encrypted data key for cross-device entry
        final deviceInfo = await _client.modules.anonaccount.device
            .getDeviceBySigningKey(crossDeviceKeyHex);
        if (deviceInfo == null) {
          throw const AccountRecoveryException(
            'Cross-device entry not found on server',
          );
        }

        // 4. Decrypt to recover symmetric data key
        final privateKey = crossDeviceKeyDuo.encryption.privateKey;
        if (privateKey == null) {
          throw const AccountRecoveryException(
            'Cross-device key missing private encryption key',
          );
        }
        final symmetricKeyJwk = await _encryption.decryptBlob(
          deviceInfo.encryptedDataKey,
          privateKey,
        );
        debugPrint('🔐 AuthService: Symmetric key recovered from cross-device entry');

        // 5. Generate new local device key
        await _keyRepository.generateAndStoreDeviceKey();
        final localDeviceKey = await _keyRepository.getDeviceKey();
        final localKeyHex = await _keyRepository.getDeviceSigningPublicKeyHex();

        if (localDeviceKey == null || localKeyHex == null) {
          throw const AccountRecoveryException(
            'Failed to generate local device key',
          );
        }

        // 6. Register new local device under the same account
        final localBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          localDeviceKey.encryption.publicKey,
        );
        await _client.modules.anonaccount.device.registerDeviceForAccount(
          localKeyHex,
          localBlob,
          deviceLabel,
        );
        debugPrint('🔐 AuthService: New local device registered');

        // 7. Store symmetric key locally
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

        // 8. Mark device as registered with server
        await _secureStorage.storeSecureData(
          _registeredWithServerKey,
          'true',
        );

        // 9. Switch app to cloud mode
        await _appOperatingRepository.updateMode(AppOperatingMode.cloud);
        debugPrint('🔐 AuthService: Cross-device key recovery complete');
      },
      (message, [cause]) => AccountRecoveryException(message, cause: cause),
      'recoverFromCrossDeviceKey',
    );
  }

  /// Recreate cross-device key (Flow D — re-enable after revoking)
  ///
  /// Generates a new cross-device key, registers it with the server,
  /// and stores it in platform storage.
  ///
  /// Throws [AuthException] on failure.
  Future<void> recreateCrossDeviceKey() {
    return tryMethod(
      () async {
        final label = _keyRepository.crossDeviceLabel;
        debugPrint('🔐 AuthService: Recreating cross-device key ($label)...');

        // Get symmetric key to create encrypted blob
        final symmetricKeyJwk = await _keyRepository.getSymmetricDataKeyJwk();
        if (symmetricKeyJwk == null) {
          throw const AuthException('Symmetric key not available');
        }

        // Generate new cross-device key (stores in platform storage)
        final crossDeviceKeyDuo = await _keyRepository.generateCrossDeviceKey();
        final crossDeviceKeyHex = await crossDeviceKeyDuo.signingKeyPair.exportPublicKeyHex();

        // Encrypt symmetric key with cross-device key
        final crossDeviceBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          crossDeviceKeyDuo.encryption.publicKey,
        );

        // Register with server using authenticated session
        await _client.modules.anonaccount.device.registerDeviceForAccount(
          crossDeviceKeyHex,
          crossDeviceBlob,
          label,
        );

        debugPrint('🔐 AuthService: Cross-device key recreated and registered');
      },
      _wrapAuthError,
      'recreateCrossDeviceKey',
    );
  }

  /// Perform challenge-response authentication (for sensitive operations)
  ///
  /// Flow:
  /// 1. Get challenge from server
  /// 2. Sign challenge with device private key (ECDSA P-256) via DataEncryptionService
  /// 3. Server verifies signature
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

        // 1. Get challenge from server (pass device public key)
        final challenge = await _client.modules.anonaccount.device
            .generateAuthChallenge(devicePublicKeyHex);

        // 2. Sign challenge with ECDSA P-256 via DataEncryptionService
        final signature = await _encryption.signWithDeviceKey(challenge);

        // 3. Verify with server
        final result = await _client.modules.anonaccount.device
            .authenticateDevice(challenge, signature);

        if (!result.success) {
          throw DeviceAuthenticationException(
            result.errorMessage ?? 'Authentication failed',
          );
        }

        return result;
      },
      (message, [cause]) => DeviceAuthenticationException(message, cause: cause),
      'authenticateDevice',
    );
  }

  /// Get list of devices registered to this account
  ///
  /// Throws [AuthException] on failure.
  Future<List<AccountDevice>> listDevices() {
    return tryMethod(
      () async {
        return await _client.modules.anonaccount.device.listDevices();
      },
      _wrapAuthError,
      'listDevices',
    );
  }

  /// Revoke a device by ID
  ///
  /// Throws [AuthException] on failure.
  Future<void> revokeDevice(int deviceId) {
    return tryMethod(
      () async {
        await _client.modules.anonaccount.device.revokeDevice(deviceId);
      },
      _wrapAuthError,
      'revokeDevice',
    );
  }

  /// Sign out (clear local keys)
  ///
  /// Throws [AuthException] on failure.
  Future<void> signOut() {
    return tryMethod(
      () async {
        await _keyRepository.clearKeys();
      },
      _wrapAuthError,
      'signOut',
    );
  }

  /// Validate a recovery key JWK format without performing recovery.
  ///
  /// Use case: Pre-validate user input before attempting full recovery.
  ///
  /// Throws [AccountRecoveryException] if JWK is invalid.
  Future<void> validateRecoveryKey(String jwk) {
    return tryMethod(
      () async {
        await _keyRepository.validateUltimateKeyJwk(jwk);
      },
      (message, [cause]) => AccountRecoveryException(message, cause: cause),
      'validateRecoveryKey',
    );
  }

  /// Get current device's signing public key hex.
  ///
  /// Facade for [ICryptoKeyRepository.getDeviceSigningPublicKeyHex].
  /// Used by DeviceManagementCubit to identify current device in list.
  ///
  /// Throws [AuthException] on failure.
  Future<String?> getCurrentDevicePublicKeyHex() {
    return tryMethod(
      () async {
        return await _keyRepository.getDeviceSigningPublicKeyHex();
      },
      _wrapAuthError,
      'getCurrentDevicePublicKeyHex',
    );
  }
}
