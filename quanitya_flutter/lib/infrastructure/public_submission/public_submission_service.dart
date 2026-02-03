import 'package:injectable/injectable.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart';
import 'package:flutter/foundation.dart' show Uint8List, debugPrint;
import 'dart:convert';

import '../crypto/crypto_key_repository.dart';
import '../crypto/utils/hashcash.dart';
import '../core/try_operation.dart';
import 'models/challenge_response.dart';
import 'models/submission_response.dart';
import 'exceptions/public_submission_exceptions.dart';
import 'interfaces/i_public_submission_service.dart';

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
  /// Returns: SubmissionResponse with success status and data
  ///
  /// Throws: PublicSubmissionException on any failure
  @override
  Future<SubmissionResponse> submitWithVerification({
    required String endpoint,
    required String payload,
    required Future<Map<String, dynamic>> Function(
      String challenge,
      String proofOfWork,
      String publicKeyHex,
      String signature,
    ) submitCallback,
  }) {
    return tryMethod(
      () async {
        // Step 1: Get challenge from server
        final challengeResponse = await _getChallenge(endpoint);
        
        // Step 2: Mine proof-of-work
        final proofOfWork = await _mineProofOfWork(
          challengeResponse.challenge,
          challengeResponse.difficulty,
        );
        
        // Step 3: Get device signing key
        final publicKeyHex = await _getDevicePublicKeyHex();
        
        // Step 4: Sign payload (prepend challenge)
        final fullPayload = '${challengeResponse.challenge}:$payload';
        final signature = await _signPayload(fullPayload);
        
        // Step 5: Submit to server
        final result = await submitCallback(
          challengeResponse.challenge,
          proofOfWork,
          publicKeyHex,
          signature,
        );
        
        return SubmissionResponse.fromServerResponse(result);
      },
      PublicSubmissionException.new,
      'submitWithVerification',
    );
  }
  
  /// Get challenge from server for specific endpoint.
  Future<ChallengeResponse> _getChallenge(String endpoint) async {
    try {
      final Map<String, dynamic> response;
      
      switch (endpoint) {
        case 'errorReport':
          response = await _client.errorReport.getChallenge();
          break;
        case 'feedback':
          response = await _client.feedback.getChallenge();
          break;
        default:
          throw PublicSubmissionException('Unknown endpoint: $endpoint');
      }
      
      return ChallengeResponse.fromServerResponse(response);
    } catch (e) {
      throw PublicSubmissionException('Failed to get challenge: $e');
    }
  }
  
  /// Mine Hashcash proof-of-work.
  Future<String> _mineProofOfWork(String challenge, int difficulty) async {
    try {
      debugPrint('📤 Mining proof-of-work (difficulty: $difficulty)...');
      final startTime = DateTime.now();
      
      final stamp = await Hashcash.mint(challenge, difficulty: difficulty);
      
      final miningTime = DateTime.now().difference(startTime);
      debugPrint('📤 Proof-of-work complete in ${miningTime.inMilliseconds}ms');
      
      return stamp;
    } catch (e) {
      throw PublicSubmissionException('Failed to mine proof-of-work: $e');
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
      throw PublicSubmissionException('Failed to sign payload: $e');
    }
  }
}
