import 'dart:convert';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_error_privserver/flutter_error_privserver.dart';

import '../config/debug_log.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:serverpod_client/serverpod_client.dart' show UuidValue;

import 'package:anonaccount_client/anonaccount_client.dart'
    show
        AccountDevice,
        AccountMethods,
        AuthenticationResult,
        DataKeyMethods,
        DeviceMethods;

import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/data_encryption_service.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import '../crypto/utils/hashcash.dart';
import 'auth_repository.dart';
import 'auth_service.dart'
    show AccountCreationException, AccountCreationResult, AccountDeletionException, AccountRecoveryException, AuthException, AuthFailure, storeAuthSession;
import 'registration_payload.dart';

const _tag = 'infrastructure/auth/account_service';

/// Account lifecycle service — create, register, recover, delete accounts.
///
/// Split from [AuthService] which retains auth-only operations
/// (authenticateDevice, ensureAuthenticated, signOut, isAuthenticated).
///
/// Uses [AuthRepository] for persistence (registration flag, registration payload)
/// instead of talking to SecurePreferences/SecureStorage directly.
@lazySingleton
class AccountService {
  final AuthRepository _authRepo;
  final ICryptoKeyRepository _keyRepository;
  final IDataEncryption _encryption;
  final Client _client;
  final ISecureStorage _secureStorage;

  static const _crossDeviceRegistrationBlobKey =
      'quanitya_cross_device_registration';

  AccountService(
    this._authRepo,
    this._keyRepository,
    this._encryption,
    this._client,
    this._secureStorage,
  );

  /// Create a new account and prepare registration payload.
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
  /// Note: Does NOT store the registration flag — that's done by [registerAccountWithServer].
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

        final devicePublicKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        if (devicePublicKeyHex == null) {
          throw const AccountCreationException(
            'Device public key not available',
          );
        }

        final ultimatePublicKey = await _keyRepository.getUltimatePublicKey();
        if (ultimatePublicKey == null) {
          throw const AccountCreationException('Ultimate key not generated');
        }

        final ultimatePublicKeyHex =
            await _keyRepository.getUltimateSigningPublicKeyHex();
        if (ultimatePublicKeyHex == null) {
          throw const AccountCreationException(
            'Ultimate public key hex not available',
          );
        }
        Log.d(_tag,'🔑 createAccount: ultimatePublicKeyHex=$ultimatePublicKeyHex (${ultimatePublicKeyHex.length} chars)');

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

        // 4b. Sign device public key with ultimate key (attestation for registerDevice)
        final attestationBytes = await _keyRepository.signWithUltimateKey(
          Uint8List.fromList(utf8.encode(devicePublicKeyHex)),
        );
        if (attestationBytes == null) {
          throw const AccountCreationException(
            'Failed to create device key attestation - ultimate key not available',
          );
        }
        final deviceKeyAttestation = attestationBytes
            .map((b) => b.toRadixString(16).padLeft(2, '0'))
            .join();

        // 4c. Generate cross-device key and attest it (before ultimate key wipe)
        String? crossDeviceKeyAttestation;
        if (_keyRepository.isCrossDeviceStorageAvailable) {
          try {
            final label = _keyRepository.crossDeviceLabel;
            final crossDeviceKeyDuo =
                await _keyRepository.generateCrossDeviceKey();

            final crossDeviceBlob = await _encryption.createEncryptedBlob(
              symmetricKeyJwk,
              crossDeviceKeyDuo.encryption.publicKey,
            );

            final crossDeviceKeyHex =
                await crossDeviceKeyDuo.signingKeyPair.exportPublicKeyHex();

            // Attest cross-device key with ultimate key
            final crossAttestBytes = await _keyRepository.signWithUltimateKey(
              Uint8List.fromList(utf8.encode(crossDeviceKeyHex)),
            );
            if (crossAttestBytes != null) {
              crossDeviceKeyAttestation = crossAttestBytes
                  .map((b) => b.toRadixString(16).padLeft(2, '0'))
                  .join();
            }

            await _secureStorage.storeSecureData(
              _crossDeviceRegistrationBlobKey,
              jsonEncode({
                'keyHex': crossDeviceKeyHex,
                'blob': crossDeviceBlob,
                'label': label,
                'attestation': crossDeviceKeyAttestation,
              }),
            );
          } catch (e, stack) {
            // Cross-device key is non-critical — continue
            Log.d(_tag,'\u26a0\ufe0f Cross-device key setup failed (non-critical): $e');
            await ErrorPrivserver.captureError(e, stack, source: 'AccountService');
          }
        }

        // 5. Create and store the registration payload
        final payload = RegistrationPayload(
          devicePublicKeyHex: devicePublicKeyHex,
          ultimatePublicKeyHex: ultimatePublicKeyHex,
          recoveryBlob: recoveryBlob,
          deviceBlob: deviceBlob,
          signature: signature,
          deviceKeyAttestation: deviceKeyAttestation,
          crossDeviceKeyAttestation: crossDeviceKeyAttestation,
          createdAt: createdAt,
        );
        await _authRepo.storeRegistrationPayload(payload);

        // 6. Get ultimate private key JWK ONCE for user backup (clears from memory after)
        final ultimatePrivateKey =
            await _keyRepository.getUltimateKeyJwkOnce();
        if (ultimatePrivateKey == null) {
          throw const AccountCreationException(
            'Ultimate private key not available',
          );
        }

        // Return ultimate private key for user to save offline
        // SECURITY: This NEVER gets sent to server
        return AccountCreationResult(ultimatePrivateKey: ultimatePrivateKey);
      },
      (message, [cause]) => AccountCreationException(message, cause: cause),
      'createAccount',
    );
  }

  /// Register existing local account with server using stored registration payload.
  ///
  /// Prerequisites:
  /// - Account keys must already exist locally (call createAccount first)
  /// - Registration payload must be stored (created during createAccount)
  ///
  /// Flow:
  /// 1. Retrieve stored registration payload
  /// 2. Verify signature using the payload's own ultimatePublicKeyHex (self-consistent check)
  /// 3. Register account with server (devicePublicKeyHex, recoveryBlob, ultimatePublicKeyHex)
  /// 4. Register cross-device key if prepared during createAccount
  /// 5. Mark device as registered with server
  ///
  /// Throws [AccountCreationException] on failure.
  Future<void> registerAccountWithServer({required String deviceLabel}) {
    return tryMethod(
      () async {
        // 1. Retrieve stored registration payload
        final payload = await _authRepo.getRegistrationPayload();
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
        // Account creation + first device registration (atomic, single PoW)
        final challengeResponse =
              await _client.modules.anonaccount.entrypoint.getChallenge();
          final proofOfWork = await _computeProofOfWork(
            challengeResponse.challenge,
            challengeResponse.difficulty,
          );
          final signPayload =
              '${challengeResponse.challenge}:${AccountMethods.createAccount}:${payload.ultimatePublicKeyHex}';
          final powSignature =
              await _encryption.signWithDeviceKey(signPayload);

          await _client.modules.anonaccount.account.createAccount(
            challenge: challengeResponse.challenge,
            proofOfWork: proofOfWork,
            signature: powSignature,
            publicKeyHex: payload.devicePublicKeyHex,
            ultimateSigningPublicKeyHex: payload.ultimatePublicKeyHex,
            encryptedDataKey: payload.recoveryBlob,
            ultimatePublicKey: payload.ultimatePublicKeyHex,
            deviceKeyAttestation: payload.deviceKeyAttestation,
            deviceSigningPublicKeyHex: payload.devicePublicKeyHex,
            deviceEncryptedDataKey: payload.deviceBlob,
            deviceLabel: deviceLabel,
          );

          // Register cross-device key if prepared during createAccount
          try {
            final crossDeviceJson = await _secureStorage
                .getSecureData(_crossDeviceRegistrationBlobKey);
            if (crossDeviceJson != null) {
              final data =
                  jsonDecode(crossDeviceJson) as Map<String, dynamic>;
              final keyHex = data['keyHex'] as String;
              final blob = data['blob'] as String;
              final label = data['label'] as String;
              final attestation = data['attestation'] as String? ??
                  payload.crossDeviceKeyAttestation ??
                  '';

              final crossChallenge =
                  await _client.modules.anonaccount.entrypoint.getChallenge();
              final crossPow = await _computeProofOfWork(
                crossChallenge.challenge,
                crossChallenge.difficulty,
              );
              final crossSignPayload =
                  '${crossChallenge.challenge}:${DeviceMethods.registerDevice}:$keyHex';
              final crossDeviceKeyDuo =
                  await _keyRepository.getCrossDeviceKey();
              if (crossDeviceKeyDuo == null) {
                throw const AccountCreationException(
                  'Cross-device key not available for signing',
                );
              }
              final crossSignature = await _encryption.signWithKeyDuo(
                  crossSignPayload, crossDeviceKeyDuo);

              await _client.modules.anonaccount.device.registerDevice(
                challenge: crossChallenge.challenge,
                proofOfWork: crossPow,
                signature: crossSignature,
                deviceKeyAttestation: attestation,
                ultimateSigningPublicKeyHex: payload.ultimatePublicKeyHex,
                deviceSigningPublicKeyHex: keyHex,
                encryptedDataKey: blob,
                label: label,
              );

              // Clean up the stored blob
              await _secureStorage
                  .deleteSecureData(_crossDeviceRegistrationBlobKey);
            }
          } catch (e, stack) {
            // Cross-device registration is non-critical — log and continue
            Log.d(_tag,
                '\u26a0\ufe0f Cross-device key registration failed (non-critical): $e');
            await ErrorPrivserver.captureError(e, stack, source: 'AccountService');
          }

        // 5. Mark device as registered with server
        await _authRepo.setRegistered();
      },
      (message, [cause]) => AccountCreationException(message, cause: cause),
      'registerAccountWithServer',
    );
  }

  /// Ensure the device is registered with the server.
  ///
  /// If not yet registered, performs server registration now.
  /// Safe to call multiple times — it's a no-op when already registered.
  ///
  /// Set [force] to bypass the local registration flag (e.g. after a DB wipe
  /// where the server no longer has the account but the local flag is stale).
  Future<void> ensureRegistered({
    required String deviceLabel,
    bool force = false,
  }) {
    return tryMethod(() async {
      if (!force && await _authRepo.isRegisteredWithServer) return;
      if (force) await _authRepo.clearRegistrationFlag();
      await registerAccountWithServer(deviceLabel: deviceLabel);
    }, (msg, [cause]) => AccountCreationException(msg, cause: cause), 'ensureRegistered');
  }

  /// Recover account using ultimate private key (from user's offline backup).
  ///
  /// Flow:
  /// 1. Import and validate ultimate JWK
  /// 2. Derive ultimate public key hex
  /// 3. Look up account on server by ultimate public key
  /// 4. Decrypt recovery blob to get symmetric key
  /// 5. Generate new device keys
  /// 6. Register new device with account
  /// 7. Store keys locally
  /// 8. Mark device as registered with server
  ///
  /// SECURITY: The ultimatePrivateKey is used locally only - NEVER sent to server.
  ///
  /// Throws [AccountRecoveryException] on failure.
  Future<void> recoverAccount({
    required String ultimatePrivateKey,
    required String deviceLabel,
    bool eraseExisting = false,
  }) {
    return tryMethod(
      () async {
        // 0. Clear existing keys if requested (recovery over existing account)
        if (eraseExisting) {
          await _keyRepository.clearKeys();
        }

        // 1. Import and validate ultimate JWK
        final ultimateKeyDuo = await _keyRepository.importUltimateKeyJwk(
          ultimatePrivateKey,
        );

        // 2. Derive ultimate public key hex (128 chars)
        final ultimatePublicKeyHex =
            await ultimateKeyDuo.signingKeyPair.exportPublicKeyHex();
        Log.d(_tag,'🔑 recoverAccount: derived ultimatePublicKeyHex=$ultimatePublicKeyHex (${ultimatePublicKeyHex.length} chars)');

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
        final devicePublicKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();

        if (deviceKey == null) {
          throw const AccountRecoveryException(
              'Failed to generate device key');
        }
        if (devicePublicKeyHex == null) {
          throw const AccountRecoveryException(
            'Failed to get device public key hex',
          );
        }

        // 6. Store symmetric key locally BEFORE registering with server.
        // If the app crashes after registration but before this write, the
        // device would be registered without a local key — unrecoverable
        // without re-entering the recovery phrase. Storing first means a
        // crash before registration leaves us with a key but unregistered,
        // which ensureRegistered() can recover from automatically.
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

        // 7. Create device blob (symmetric key encrypted with new device public key)
        final deviceBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          deviceKey.encryption.publicKey,
        );

        // 8. Register new device with account (uses ultimate key, not int id)
        // Generate attestation: ultimate key signs device public key
        final recoveryAttestation = await _encryption.signWithKeyDuo(
          devicePublicKeyHex,
          ultimateKeyDuo,
        );

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
          deviceKeyAttestation: recoveryAttestation,
          ultimateSigningPublicKeyHex: ultimatePublicKeyHex,
          deviceSigningPublicKeyHex: devicePublicKeyHex,
          encryptedDataKey: deviceBlob,
          label: deviceLabel,
        );

        // 9. Mark device as registered with server
        await _authRepo.setRegistered();

        // Note: Ultimate key is NOT stored - it was only used for this recovery operation
      },
      (message, [cause]) => AccountRecoveryException(message, cause: cause),
      'recoverAccount',
    );
  }

  /// Delete account on server using proof-of-work + ECDSA signature.
  ///
  /// Caller is responsible for local cleanup (clearing keys, navigating away).
  Future<void> deleteAccount() {
    return tryMethod(
      () async {
        final devicePublicKeyHex =
            await _keyRepository.getDeviceSigningPublicKeyHex();
        if (devicePublicKeyHex == null) {
          throw const AccountDeletionException('Device public key not found');
        }

        final challengeResponse =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final proofOfWork = await _computeProofOfWork(
          challengeResponse.challenge,
          challengeResponse.difficulty,
        );
        final signPayload =
            '${challengeResponse.challenge}:deleteAccount:$devicePublicKeyHex';
        final signature = await _encryption.signWithDeviceKey(signPayload);

        await _client.accountDeletion.deleteAccount(
          challenge: challengeResponse.challenge,
          proofOfWork: proofOfWork,
          publicKeyHex: devicePublicKeyHex,
          signature: signature,
        );
      },
      (message, [cause]) => AccountDeletionException(message, cause: cause),
      'deleteAccount',
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
        if (callerKeyHex == null) throw const AccountRecoveryException('Device public key not available after generation');
        final regDevSignPayload =
            '${regDevChallenge.challenge}:registerDeviceForAccount:$callerKeyHex';
        final regDevSignature =
            await _encryption.signWithDeviceKey(regDevSignPayload);
        await _client.modules.anonaccount.deviceManagement.registerDeviceForAccount(
          challenge: regDevChallenge.challenge,
          proofOfWork: regDevPow,
          publicKeyHex: callerKeyHex,
          signature: regDevSignature,
          newDeviceSigningPublicKeyHex: localKeyHex,
          newDeviceEncryptedDataKey: localBlob,
          label: deviceLabel,
        );

        // 7. Store symmetric key locally
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

        // 8. Mark device as registered with server
        await _authRepo.setRegistered();
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
        if (cdCallerKeyHex == null) throw const AuthException('Device signing key not available');
        final cdSignPayload =
            '${cdChallenge.challenge}:registerDeviceForAccount:$cdCallerKeyHex';
        final cdSignature =
            await _encryption.signWithDeviceKey(cdSignPayload);
        await _client.modules.anonaccount.deviceManagement.registerDeviceForAccount(
          challenge: cdChallenge.challenge,
          proofOfWork: cdPow,
          publicKeyHex: cdCallerKeyHex,
          signature: cdSignature,
          newDeviceSigningPublicKeyHex: crossDeviceKeyHex,
          newDeviceEncryptedDataKey: crossDeviceBlob,
          label: label,
        );
      },
      (message, [cause]) => AuthException(message, cause: cause),
      'recreateCrossDeviceKey',
    );
  }

  Future<void> _storeAuthSession(AuthenticationResult result) =>
      storeAuthSession(_client, result);

  /// Import ultimate key and hold for follow-up operations (e.g., revoke devices).
  /// Call [clearUltimateKeySession] when navigating away.
  Future<void> importUltimateKeyForSession(String jwk) {
    return tryMethod(
      () async {
        await _keyRepository.importUltimateKeyTemporary(jwk);
      },
      (message, [cause]) => AccountRecoveryException(message, cause: cause),
      'importUltimateKeyForSession',
    );
  }

  /// Clear the temporary ultimate key from memory.
  void clearUltimateKeySession() {
    _keyRepository.clearTemporaryUltimateKey();
  }

  /// Get list of devices registered to this account.
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
        if (pubKeyHex == null) throw const AuthException('Device public key not available');
        final signPayload =
            '${challenge.challenge}:listDevices:$pubKeyHex';
        final sig = await _encryption.signWithDeviceKey(signPayload);
        return await _client.modules.anonaccount.deviceManagement.listDevices(
          challenge: challenge.challenge,
          proofOfWork: pow,
          publicKeyHex: pubKeyHex,
          signature: sig,
        );
      },
      _wrapAccountError,
      'listDevices',
    );
  }

  /// Revoke a device by ID.
  ///
  /// Requires the ultimate private key (recovery key) to sign the request.
  /// The server verifies the signature against the ultimate public key.
  ///
  /// Throws [AuthException] on failure.
  Future<void> revokeDevice(UuidValue deviceId, {required String ultimateKeyJwk}) {
    return tryMethod(
      () async {
        // Import ultimate key for signing
        final ultimateKeyDuo = await _keyRepository.importUltimateKeyJwk(ultimateKeyJwk);
        final ultimatePublicKeyHex =
            await ultimateKeyDuo.signingKeyPair.exportPublicKeyHex();

        final challenge =
            await _client.modules.anonaccount.entrypoint.getChallenge();
        final pow = await _computeProofOfWork(
          challenge.challenge,
          challenge.difficulty,
        );
        final signPayload =
            '${challenge.challenge}:revokeDevice:$ultimatePublicKeyHex';
        final sig = await _encryption.signWithKeyDuo(signPayload, ultimateKeyDuo);
        await _client.modules.anonaccount.deviceManagement.revokeDevice(
          challenge: challenge.challenge,
          proofOfWork: pow,
          publicKeyHex: ultimatePublicKeyHex,
          signature: sig,
          deviceId: deviceId,
        );
      },
      _wrapAccountError,
      'revokeDevice',
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
      _wrapAccountError,
      'getCurrentDevicePublicKeyHex',
    );
  }

  /// Compute hashcash proof-of-work for spam prevention.
  Future<String> _computeProofOfWork(String challenge, int difficulty) async {
    return Hashcash.mint(challenge, difficulty: difficulty);
  }
}

/// Wraps an error as an [AuthException], detecting network errors from the cause.
AuthException _wrapAccountError(String message, [Object? cause]) {
  final causeStr = cause?.toString() ?? '';
  final isNetwork = causeStr.contains('SocketException') ||
      causeStr.contains('Connection refused');
  return AuthException(
    message,
    kind: isNetwork ? AuthFailure.networkError : AuthFailure.general,
    cause: cause,
  );
}
