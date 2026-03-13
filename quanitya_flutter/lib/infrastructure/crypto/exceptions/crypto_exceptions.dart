/// Custom exceptions for crypto operations.
/// 
/// Provides specific error types for better error handling and user feedback.
library;

/// Base class for all crypto-related exceptions.
abstract class CryptoException implements Exception {
  const CryptoException(this.message, [this.cause]);
  
  final String message;
  final Object? cause;
  
  @override
  String toString() => 'CryptoException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Describes why key generation failed.
enum KeyGenerationFailure {
  keysAlreadyExist,
  verificationFailed,
  generationFailed,
}

/// Thrown when key generation fails
class KeyGenerationException extends CryptoException {
  const KeyGenerationException(String message, {this.kind = KeyGenerationFailure.generationFailed, Object? cause}) : super(message, cause);

  final KeyGenerationFailure kind;

  @override
  String toString() => 'KeyGenerationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when key storage operations fail
class KeyStorageException extends CryptoException {
  const KeyStorageException(super.message, [super.cause]);
  
  @override
  String toString() => 'KeyStorageException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when key retrieval operations fail
class KeyRetrievalException extends CryptoException {
  const KeyRetrievalException(super.message, [super.cause]);
  
  @override
  String toString() => 'KeyRetrievalException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when encryption/decryption operations fail
class CryptoOperationException extends CryptoException {
  const CryptoOperationException(super.message, [super.cause]);
  
  @override
  String toString() => 'CryptoOperationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when device provisioning operations fail
class DeviceProvisioningException extends CryptoException {
  const DeviceProvisioningException(super.message, [super.cause]);
  
  @override
  String toString() => 'DeviceProvisioningException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when recovery operations fail
class RecoveryException extends CryptoException {
  const RecoveryException(super.message, [super.cause]);
  
  @override
  String toString() => 'RecoveryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when device revocation operations fail
class DeviceRevocationException extends CryptoException {
  const DeviceRevocationException(super.message, [super.cause]);
  
  @override
  String toString() => 'DeviceRevocationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when network operations fail
class NetworkException extends CryptoException {
  const NetworkException(super.message, [super.cause]);
  
  @override
  String toString() => 'NetworkException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Thrown when validation operations fail
class ValidationException extends CryptoException {
  const ValidationException(super.message, [super.cause]);
  
  @override
  String toString() => 'ValidationException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}