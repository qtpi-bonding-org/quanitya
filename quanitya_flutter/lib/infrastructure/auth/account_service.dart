import 'dart:convert';

import 'package:dart_jwk_duo/dart_jwk_duo.dart';
import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:anonaccount_client/anonaccount_client.dart'
    show AccountMethods, DataKeyMethods, DeviceMethods;

import '../core/try_operation.dart';
import '../crypto/crypto_key_repository.dart';
import '../crypto/data_encryption_service.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import '../crypto/utils/hashcash.dart';
import 'auth_repository.dart';
import 'auth_service.dart'
    show AccountCreationException, AccountCreationResult, AccountRecoveryException;
import 'registration_payload.dart';

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
          } catch (e) {
            // Cross-device key is non-critical — continue
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
        try {
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
          } catch (e) {
            // Cross-device registration is non-critical — log and continue
            debugPrint(
                '\u26a0\ufe0f Cross-device key registration failed (non-critical): $e');
          }

          // 5. Mark device as registered with server
          await _authRepo.setRegistered();
        } catch (serverError) {
          rethrow;
        }
      },
      (message, [cause]) => AccountCreationException(message, cause: cause),
      'registerAccountWithServer',
    );
  }

  /// Ensure the device is registered with the server.
  ///
  /// If not yet registered, performs server registration now.
  /// Safe to call multiple times — it's a no-op when already registered.
  Future<void> ensureRegistered({required String deviceLabel}) async {
    if (await _authRepo.isRegisteredWithServer) return;
    await registerAccountWithServer(deviceLabel: deviceLabel);
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
  }) {
    return tryMethod(
      () async {
        // 1. Import and validate ultimate JWK
        final ultimateKeyDuo = await _keyRepository.importUltimateKeyJwk(
          ultimatePrivateKey,
        );

        // 2. Derive ultimate public key hex (128 chars)
        final ultimatePublicKeyHex =
            await ultimateKeyDuo.signingKeyPair.exportPublicKeyHex();

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

        // 6. Create device blob (symmetric key encrypted with new device public key)
        final deviceBlob = await _encryption.createEncryptedBlob(
          symmetricKeyJwk,
          deviceKey.encryption.publicKey,
        );

        // 7. Register new device with account (uses ultimate key, not int id)
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

        // 8. Store symmetric key locally
        await _keyRepository.storeSymmetricDataKeyJwk(symmetricKeyJwk);

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
          throw const AccountCreationException('Device public key not found');
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
      (message, [cause]) => AccountCreationException(message, cause: cause),
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

  /// Compute hashcash proof-of-work for spam prevention.
  Future<String> _computeProofOfWork(String challenge, int difficulty) async {
    return Hashcash.mint(challenge, difficulty: difficulty);
  }
}
