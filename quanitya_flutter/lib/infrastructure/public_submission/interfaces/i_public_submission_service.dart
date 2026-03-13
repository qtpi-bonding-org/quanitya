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

  /// Query server data with challenge-response verification.
  ///
  /// Same PoW ceremony as [submitWithVerification], but returns a value.
  Future<T> queryWithVerification<T>({
    required String endpoint,
    required String payload,
    required Future<T> Function(
      String challenge,
      String proofOfWork,
      String publicKeyHex,
      String signature,
    ) queryCallback,
  });
}
