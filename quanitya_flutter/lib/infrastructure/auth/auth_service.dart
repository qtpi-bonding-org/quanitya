import 'dart:convert';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:serverpod_auth_idp_flutter/serverpod_auth_idp_flutter.dart'
    show AuthSuccess, FlutterAuthSessionManagerExtension;
import 'package:serverpod_client/serverpod_client.dart' show UuidValue;
import 'package:anonaccount_client/anonaccount_client.dart'
    show AccountDevice, AccountMethods, AuthenticationResult, DataKeyMethods, DeviceMethods;

import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/data_encryption_service.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import '../crypto/utils/hashcash.dart';
import 'registration_payload.dart';

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

  static const _registrationPayloadKey = 'quanitya_registration_payload';
  static const _crossDeviceRegistrationBlobKey = 'quanitya_cross_device_registration';
  static const _registeredWithServerKey = 'quanitya_registered_with_server';

  bool _isInitialized = false;

  AuthService(
    this._keyRepository,
    this._encryption,
    this._client,
    this._secureStorage,
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
          } catch (e) {
            // Cross-device key is non-critical — continue
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
        // 1. Retrieve stored registration payload
        final payload = await _getRegistrationPayload();
        if (payload == null) {
          throw const AccountCreationException(
            'No registration payload found - create account first',
          );
        }

        // 2. Verify signature using the payload's own ultimatePublicKeyHex (self-consistent check)
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
          throw const AccountCreationException(
            'Registration payload signature verification failed - payload may be corrupted',
          );
        }

        // 3. Register account with server
        try {
          // Account creation requires proof-of-work via accountRegistration endpoint
          final challengeResponse = await _client.modules.anonaccount.entrypoint.getChallenge();
          final proofOfWork = await _computeProofOfWork(
            challengeResponse.challenge,
            challengeResponse.difficulty,
          );
          final signPayload =
              '${challengeResponse.challenge}:${AccountMethods.createAccount}:${payload.ultimatePublicKeyHex}';
          final powSignature = await _encryption.signWithDeviceKey(signPayload);

          await _client.accountRegistration.createAccount(
            challenge: challengeResponse.challenge,
            proofOfWork: proofOfWork,
            signature: powSignature,
            publicKeyHex: payload.devicePublicKeyHex,
            ultimateSigningPublicKeyHex: payload.ultimatePublicKeyHex,
            encryptedDataKey: payload.recoveryBlob,
            ultimatePublicKey: payload.ultimatePublicKeyHex,
          );

          // 4. Register device — uses ultimate key to look up account
          final deviceChallenge =
              await _client.modules.anonaccount.entrypoint.getChallenge();
          final devicePow = await _computeProofOfWork(
            deviceChallenge.challenge,
            deviceChallenge.difficulty,
          );
          final deviceSignPayload =
              '${deviceChallenge.challenge}:${DeviceMethods.registerDevice}:${payload.devicePublicKeyHex}';
          final deviceSignature =
              await _encryption.signWithDeviceKey(deviceSignPayload);

          await _client.modules.anonaccount.device.registerDevice(
            challenge: deviceChallenge.challenge,
            proofOfWork: devicePow,
            signature: deviceSignature,
            ultimateSigningPublicKeyHex: payload.ultimatePublicKeyHex,
            deviceSigningPublicKeyHex: payload.devicePublicKeyHex,
            encryptedDataKey: payload.deviceBlob,
            label: deviceLabel,
          );

          // 4.5. Register cross-device key if prepared during createAccount
          try {
            final crossDeviceJson = await _secureStorage.getSecureData(_crossDeviceRegistrationBlobKey);
            if (crossDeviceJson != null) {
              final data = jsonDecode(crossDeviceJson) as Map<String, dynamic>;
              final keyHex = data['keyHex'] as String;
              final blob = data['blob'] as String;
              final label = data['label'] as String;

              final crossChallenge =
                  await _client.modules.anonaccount.entrypoint.getChallenge();
              final crossPow = await _computeProofOfWork(
                crossChallenge.challenge,
                crossChallenge.difficulty,
              );
              final crossSignPayload =
                  '${crossChallenge.challenge}:${DeviceMethods.registerDevice}:$keyHex';
              final crossDeviceKeyDuo = await _keyRepository.getCrossDeviceKey();
              if (crossDeviceKeyDuo == null) {
                throw const AccountCreationException(
                  'Cross-device key not available for signing',
                );
              }
              final crossSignature =
                  await _encryption.signWithKeyDuo(crossSignPayload, crossDeviceKeyDuo);

              await _client.modules.anonaccount.device.registerDevice(
                challenge: crossChallenge.challenge,
                proofOfWork: crossPow,
                signature: crossSignature,
                ultimateSigningPublicKeyHex: payload.ultimatePublicKeyHex,
                deviceSigningPublicKeyHex: keyHex,
                encryptedDataKey: blob,
                label: label,
              );

              // Clean up the stored blob
              await _secureStorage.deleteSecureData(_crossDeviceRegistrationBlobKey);
            }
          } catch (e) {
            // Cross-device registration is non-critical
          }

          // 5. Mark device as registered with server
          await _secureStorage.storeSecureData(
            _registeredWithServerKey,
            'true',
          );
        } catch (serverError) {
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

        // 3. Recover encrypted data key from server (PoW-protected)
        final challengeResponse =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final proofOfWork = await _computeProofOfWork(
          challengeResponse.challenge,
          challengeResponse.difficulty,
        );
        final recoveryPayload =
            '${challengeResponse.challenge}:${DataKeyMethods.recoverEncryptedDataKey}:$ultimatePublicKeyHex';
        final recoverySig =
            await _encryption.signWithKeyDuo(recoveryPayload, ultimateKeyDuo);

        final dataKeyResponse = await _client.modules.anonaccount.dataKey
            .recoverEncryptedDataKey(
          challenge: challengeResponse.challenge,
          proofOfWork: proofOfWork,
          ultimateSigningPublicKeyHex: ultimatePublicKeyHex,
          signature: recoverySig,
        );

        // 4. Decrypt recovery blob to get symmetric key
        final privateKey = ultimateKeyDuo.encryption.privateKey;
        if (privateKey == null) {
          throw const AccountRecoveryException(
            'Ultimate key missing private encryption key',
          );
        }

        final symmetricKeyJwk = await _encryption.decryptBlob(
          dataKeyResponse.encryptedDataKey,
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
        final regChallenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final regPow = await _computeProofOfWork(
          regChallenge.challenge,
          regChallenge.difficulty,
        );
        final regSignPayload =
            '${regChallenge.challenge}:${DeviceMethods.registerDevice}:$devicePublicKeyHex';
        final regSignature =
            await _encryption.signWithDeviceKey(regSignPayload);

        await _client.modules.anonaccount.device.registerDevice(
          challenge: regChallenge.challenge,
          proofOfWork: regPow,
          signature: regSignature,
          ultimateSigningPublicKeyHex: ultimatePublicKeyHex,
          deviceSigningPublicKeyHex: devicePublicKeyHex,
          encryptedDataKey: deviceBlob,
          label: deviceLabel,
        );

        // 8. Store symmetric key locally
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

        // 9. Mark device as registered with server
        await _secureStorage.storeSecureData(
          _registeredWithServerKey,
          'true',
        );

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
        // 1. Get cross-device key
        final crossDeviceKeyDuo = await _keyRepository.getCrossDeviceKey();
        if (crossDeviceKeyDuo == null) {
          throw const AccountRecoveryException(
            'Cross-device key not found in platform storage',
          );
        }

        // 2. Auth with server using cross-device key
        final crossDeviceKeyHex = await crossDeviceKeyDuo.signingKeyPair.exportPublicKeyHex();

        final authChallengeResponse =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final authPow = await _computeProofOfWork(
          authChallengeResponse.challenge,
          authChallengeResponse.difficulty,
        );
        final authSignPayload =
            '${authChallengeResponse.challenge}:${DeviceMethods.signIn}:$crossDeviceKeyHex';
        final authPowSignature =
            await _encryption.signWithKeyDuo(authSignPayload, crossDeviceKeyDuo);

        final authResult = await _client.modules.anonaccount.device
            .signIn(
          challenge: authChallengeResponse.challenge,
          proofOfWork: authPow,
          signature: authPowSignature,
          devicePublicKeyHex: crossDeviceKeyHex,
        );

        if (!authResult.success) {
          throw AccountRecoveryException(
            authResult.errorMessage ?? 'Cross-device key authentication failed',
          );
        }

        // Store JWT session from sign-in
        await _storeAuthSession(authResult);

        // 3. Get encrypted data key for cross-device entry
        final deviceInfoChallenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final deviceInfoPow = await _computeProofOfWork(
          deviceInfoChallenge.challenge,
          deviceInfoChallenge.difficulty,
        );
        final deviceInfoSignPayload =
            '${deviceInfoChallenge.challenge}:${DataKeyMethods.retrieveEncryptedDataKey}:$crossDeviceKeyHex';
        final deviceInfoSignature =
            await _encryption.signWithKeyDuo(deviceInfoSignPayload, crossDeviceKeyDuo);

        final deviceDataKeyResponse = await _client.modules.anonaccount.dataKey
            .retrieveEncryptedDataKey(
          challenge: deviceInfoChallenge.challenge,
          proofOfWork: deviceInfoPow,
          signature: deviceInfoSignature,
          deviceSigningPublicKeyHex: crossDeviceKeyHex,
        );

        // 4. Decrypt to recover symmetric data key
        final privateKey = crossDeviceKeyDuo.encryption.privateKey;
        if (privateKey == null) {
          throw const AccountRecoveryException(
            'Cross-device key missing private encryption key',
          );
        }
        final symmetricKeyJwk = await _encryption.decryptBlob(
          deviceDataKeyResponse.encryptedDataKey,
          privateKey,
        );

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
        final regDevChallenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final regDevPow = await _computeProofOfWork(
          regDevChallenge.challenge,
          regDevChallenge.difficulty,
        );
        final callerKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        final regDevSignPayload =
            '${regDevChallenge.challenge}:registerDeviceForAccount:$callerKeyHex';
        final regDevSignature =
            await _encryption.signWithDeviceKey(regDevSignPayload);
        await _client.modules.anonaccount.deviceManagement.registerDeviceForAccount(
          challenge: regDevChallenge.challenge,
          proofOfWork: regDevPow,
          publicKeyHex: callerKeyHex!,
          signature: regDevSignature,
          newDeviceSigningPublicKeyHex: localKeyHex,
          newDeviceEncryptedDataKey: localBlob,
          label: deviceLabel,
        );

        // 7. Store symmetric key locally
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

        // 8. Mark device as registered with server
        await _secureStorage.storeSecureData(
          _registeredWithServerKey,
          'true',
        );
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

        // Register with server using SignedPoW
        final cdChallenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final cdPow = await _computeProofOfWork(
          cdChallenge.challenge,
          cdChallenge.difficulty,
        );
        final cdCallerKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        final cdSignPayload =
            '${cdChallenge.challenge}:registerDeviceForAccount:$cdCallerKeyHex';
        final cdSignature =
            await _encryption.signWithDeviceKey(cdSignPayload);
        await _client.modules.anonaccount.deviceManagement.registerDeviceForAccount(
          challenge: cdChallenge.challenge,
          proofOfWork: cdPow,
          publicKeyHex: cdCallerKeyHex!,
          signature: cdSignature,
          newDeviceSigningPublicKeyHex: crossDeviceKeyHex,
          newDeviceEncryptedDataKey: crossDeviceBlob,
          label: label,
        );
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

  /// Get list of devices registered to this account
  ///
  /// Throws [AuthException] on failure.
  Future<List<AccountDevice>> listDevices() {
    return tryMethod(
      () async {
        final challenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final pow = await _computeProofOfWork(
          challenge.challenge,
          challenge.difficulty,
        );
        final pubKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        final signPayload =
            '${challenge.challenge}:listDevices:$pubKeyHex';
        final sig = await _encryption.signWithDeviceKey(signPayload);
        return await _client.modules.anonaccount.deviceManagement.listDevices(
          challenge: challenge.challenge,
          proofOfWork: pow,
          publicKeyHex: pubKeyHex!,
          signature: sig,
        );
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
        final challenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final pow = await _computeProofOfWork(
          challenge.challenge,
          challenge.difficulty,
        );
        final pubKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        final signPayload =
            '${challenge.challenge}:revokeDevice:$pubKeyHex';
        final sig = await _encryption.signWithDeviceKey(signPayload);
        await _client.modules.anonaccount.deviceManagement.revokeDevice(
          challenge: challenge.challenge,
          proofOfWork: pow,
          publicKeyHex: pubKeyHex!,
          signature: sig,
          deviceId: deviceId,
        );
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
