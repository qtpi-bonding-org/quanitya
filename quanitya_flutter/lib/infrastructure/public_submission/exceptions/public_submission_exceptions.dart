/// Base exception for public submission operations.
class PublicSubmissionException implements Exception {
  final String message;
  final Object? cause;
  
  const PublicSubmissionException(this.message, [this.cause]);
  
  @override
  String toString() => 'PublicSubmissionException: $message';
}

/// Challenge request failed.
class ChallengeRequestException extends PublicSubmissionException {
  const ChallengeRequestException(super.message, [super.cause]);
  
  @override
  String toString() => 'ChallengeRequestException: $message';
}

/// Proof-of-work mining failed.
class ProofOfWorkException extends PublicSubmissionException {
  const ProofOfWorkException(super.message, [super.cause]);
  
  @override
  String toString() => 'ProofOfWorkException: $message';
}

/// Signature generation failed.
class SignatureException extends PublicSubmissionException {
  const SignatureException(super.message, [super.cause]);
  
  @override
  String toString() => 'SignatureException: $message';
}

/// Rate limit exceeded.
class RateLimitExceededException extends PublicSubmissionException {
  const RateLimitExceededException(super.message, [super.cause]);
  
  @override
  String toString() => 'RateLimitExceededException: $message';
}
