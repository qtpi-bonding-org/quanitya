import '../models/submission_response.dart';

/// Interface for public submission service (for testing).
abstract class IPublicSubmissionService {
  /// Submit public data with challenge-response verification.
  Future<SubmissionResponse> submitWithVerification({
    required String endpoint,
    required String payload,
    required Future<Map<String, dynamic>> Function(
      String challenge,
      String proofOfWork,
      String publicKeyHex,
      String signature,
    ) submitCallback,
  });
}
