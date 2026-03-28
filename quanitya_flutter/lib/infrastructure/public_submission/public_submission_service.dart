import 'dart:convert';

import 'package:injectable/injectable.dart';
import 'package:anonaccount_client/anonaccount_client.dart'
    show PublicChallengeResponse;
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart'
    show Client, ServerException, ServerErrorCode;
import 'package:flutter/foundation.dart' show Uint8List;
import '../config/debug_log.dart';

import '../crypto/crypto_key_repository.dart';
import '../crypto/utils/hashcash.dart';
import '../core/try_operation.dart';
import 'exceptions/public_submission_exceptions.dart';
import 'interfaces/i_public_submission_service.dart';

const _tag = 'infrastructure/public_submission/public_submission_service';

/// Reusable service for public (unauthenticated) submissions.
///
/// Handles the complete challenge-response flow:
/// 1. Request challenge from server
/// 2. Mine Hashcash proof-of-work (20-bit difficulty)
/// 3. Sign payload with device ECDSA key
/// 4. Submit with all credentials
///
/// Used by:
/// - ErrorReporterService (error reporting)
/// - FeedbackService (user feedback)
@lazySingleton
class PublicSubmissionService implements IPublicSubmissionService {
  final Client _client;
  final ICryptoKeyRepository _cryptoRepo;
  
  PublicSubmissionService(
    this._client,
    this._cryptoRepo,
  );
  
  /// Submit public data with challenge-response verification.
  ///
  /// Parameters:
  /// - [endpoint]: Endpoint type ('errorReport' or 'feedback')
  /// - [payload]: Data to sign (format: 'challenge:field1:field2:...')
  /// - [submitCallback]: Function that submits to server with credentials
  ///
  /// Completes normally on success. Throws domain exceptions on failure.
  @override
  Future<void> submitWithVerification({
    required String endpoint,
    required String payload,
    required Future<void> Function(
      String challenge,
      String proofOfWork,
      String publicKeyHex,
      String signature,
    ) submitCallback,
  }) {
    return tryMethod(
      () async {
        // Step 1: Get challenge from server
        Log.d(_tag, '📤 [$endpoint] Step 1: Getting challenge...');
        final challengeResponse = await _getChallenge(endpoint);
        Log.d(_tag, '📤 [$endpoint] Step 1: Got challenge (difficulty: ${challengeResponse.difficulty})');

        // Step 2: Mine proof-of-work
        Log.d(_tag, '📤 [$endpoint] Step 2: Mining PoW...');
        final proofOfWork = await _mineProofOfWork(
          challengeResponse.challenge,
          challengeResponse.difficulty,
        );
        Log.d(_tag, '📤 [$endpoint] Step 2: PoW complete');

        // Step 3: Get device signing key
        Log.d(_tag, '📤 [$endpoint] Step 3: Getting device key...');
        final publicKeyHex = await _getDevicePublicKeyHex();
        Log.d(_tag, '📤 [$endpoint] Step 3: Got key (${publicKeyHex.substring(0, 8)}...)');

        // Step 4: Sign payload (prepend challenge)
        Log.d(_tag, '📤 [$endpoint] Step 4: Signing payload...');
        final fullPayload = '${challengeResponse.challenge}:$payload';
        final signature = await _signPayload(fullPayload);
        Log.d(_tag, '📤 [$endpoint] Step 4: Signed (${signature.substring(0, 8)}...)');

        // Step 5: Submit to server
        Log.d(_tag, '📤 [$endpoint] Step 5: Submitting to server...');
        try {
          await submitCallback(
            challengeResponse.challenge,
            proofOfWork,
            publicKeyHex,
            signature,
          );
        } on ServerException catch (e) {
          switch (e.code) {
            case ServerErrorCode.rateLimitExceeded:
              throw RateLimitExceededException(e.message);
            case ServerErrorCode.challengeExpired:
              throw ChallengeRequestException(e.message);
            case ServerErrorCode.invalidProofOfWork:
              throw ProofOfWorkException(e.message);
            case ServerErrorCode.invalidSignature:
              throw SignatureException(e.message);
            default:
              throw PublicSubmissionException(e.message);
          }
        }
        Log.d(_tag, '📤 [$endpoint] Step 5: Submission successful');
      },
      PublicSubmissionException.new,
      'submitWithVerification',
    );
  }
  
  @override
  Future<T> queryWithVerification<T>({
    required String endpoint,
    required String payload,
    required Future<T> Function(
      String challenge,
      String proofOfWork,
      String publicKeyHex,
      String signature,
    ) queryCallback,
  }) {
    return tryMethod(
      () async {
        Log.d(_tag, '📤 [$endpoint] Step 1: Getting challenge...');
        final challengeResponse = await _getChallenge(endpoint);
        Log.d(_tag, '📤 [$endpoint] Step 1: Got challenge (difficulty: ${challengeResponse.difficulty})');

        Log.d(_tag, '📤 [$endpoint] Step 2: Mining PoW...');
        final proofOfWork = await _mineProofOfWork(
          challengeResponse.challenge,
          challengeResponse.difficulty,
        );
        Log.d(_tag, '📤 [$endpoint] Step 2: PoW complete');

        Log.d(_tag, '📤 [$endpoint] Step 3: Getting device key...');
        final publicKeyHex = await _getDevicePublicKeyHex();
        Log.d(_tag, '📤 [$endpoint] Step 3: Got key (${publicKeyHex.substring(0, 8)}...)');

        Log.d(_tag, '📤 [$endpoint] Step 4: Signing payload...');
        final fullPayload = '${challengeResponse.challenge}:$payload';
        final signature = await _signPayload(fullPayload);
        Log.d(_tag, '📤 [$endpoint] Step 4: Signed (${signature.substring(0, 8)}...)');

        Log.d(_tag, '📤 [$endpoint] Step 5: Querying server...');
        try {
          final result = await queryCallback(
            challengeResponse.challenge,
            proofOfWork,
            publicKeyHex,
            signature,
          );
          Log.d(_tag, '📤 [$endpoint] Step 5: Query successful');
          return result;
        } on ServerException catch (e) {
          switch (e.code) {
            case ServerErrorCode.rateLimitExceeded:
              throw RateLimitExceededException(e.message);
            case ServerErrorCode.challengeExpired:
              throw ChallengeRequestException(e.message);
            case ServerErrorCode.invalidProofOfWork:
              throw ProofOfWorkException(e.message);
            case ServerErrorCode.invalidSignature:
              throw SignatureException(e.message);
            default:
              throw PublicSubmissionException(e.message);
          }
        }
      },
      PublicSubmissionException.new,
      'queryWithVerification',
    );
  }

  /// Get challenge from server via the single entrypoint endpoint.
  Future<PublicChallengeResponse> _getChallenge(String endpoint) async {
    try {
      return await _client.modules.anonaccount.entrypoint.getChallenge();
    } catch (e) {
      throw PublicSubmissionException('getChallenge failed', e);
    }
  }
  
  /// Mine Hashcash proof-of-work.
  Future<String> _mineProofOfWork(String challenge, int difficulty) async {
    try {
      Log.d(_tag, '📤 Mining proof-of-work (difficulty: $difficulty)...');
      final startTime = DateTime.now();
      
      final stamp = await Hashcash.mint(challenge, difficulty: difficulty);
      
      final miningTime = DateTime.now().difference(startTime);
      Log.d(_tag, '📤 Proof-of-work complete in ${miningTime.inMilliseconds}ms');
      
      return stamp;
    } catch (e) {
      throw PublicSubmissionException('mineProofOfWork failed', e);
    }
  }
  
  /// Get device signing public key as hex string.
  Future<String> _getDevicePublicKeyHex() async {
    final publicKeyHex = await _cryptoRepo.getDeviceSigningPublicKeyHex();
    
    if (publicKeyHex == null) {
      throw PublicSubmissionException(
        'Device signing key not found. Please initialize crypto keys.',
      );
    }
    
    return publicKeyHex;
  }
  
  /// Sign payload with device private key.
  Future<String> _signPayload(String payload) async {
    try {
      // Get device key (contains private key)
      final deviceKey = await _cryptoRepo.getDeviceKey();
      
      if (deviceKey == null) {
        throw PublicSubmissionException(
          'Device key not found. Please initialize crypto keys.',
        );
      }
      
      // Sign payload
      final payloadBytes = Uint8List.fromList(utf8.encode(payload));
      final signatureBytes = await deviceKey.sign(payloadBytes);
      
      // Convert to hex string (128 chars = 64 bytes)
      final signature = signatureBytes
          .map((b) => b.toRadixString(16).padLeft(2, '0'))
          .join();
      
      return signature;
    } catch (e) {
      throw PublicSubmissionException('signPayload failed', e);
    }
  }
}
