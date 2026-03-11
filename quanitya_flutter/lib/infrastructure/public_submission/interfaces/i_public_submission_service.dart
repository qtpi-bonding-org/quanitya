/// Interface for public submission service (for testing).
abstract class IPublicSubmissionService {
  /// Submit public data with challenge-response verification.
  ///
  /// Completes normally on success. Throws domain exceptions on failure.
  Future<void> submitWithVerification({
    required String endpoint,
    required String payload,
    required Future<void> Function(
      String challenge,
      String proofOfWork,
      String publicKeyHex,
      String signature,
    ) submitCallback,
  });
}
