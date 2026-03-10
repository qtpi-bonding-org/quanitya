import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import '../../data/repositories/log_entry_repository.dart';
import '../../data/repositories/template_with_aesthetics_repository.dart';
import '../../features/device_pairing/services/pairing_service.dart' show PairingException;
import '../auth/auth_service.dart' show AuthException;
import '../crypto/exceptions/crypto_exceptions.dart';
import '../public_submission/exceptions/public_submission_exceptions.dart';
import '../purchase/purchase_exception.dart';
import '../purchase/entitlement_exception.dart';
import '../user_feedback/exceptions/feedback_exceptions.dart';
import '../../features/settings/exceptions/llm_provider_exception.dart';

/// Global exception mapper for the Quanitya application.
/// 
/// Maps all application exceptions to user-friendly message keys
/// that can be localized and displayed to users.
@LazySingleton(as: IExceptionKeyMapper)
class QuanityaExceptionKeyMapper implements IExceptionKeyMapper {
  @override
  MessageKey? map(Object exception) {
    return switch (exception) {
      // Network-related exceptions
      NetworkException() => MessageKey.networkError,
      TimeoutException() => const MessageKey.error(L10nKeys.errorTimeout),

      // Authentication exceptions - check cause for more specific errors
      AuthException e => _mapAuthException(e),
      UnauthorizedException() => const MessageKey.error(L10nKeys.errorAuthUnauthorized),

      // Validation exceptions
      ValidationException e => MessageKey.error(
          'validation.${e.field}',
          {'field': e.field, 'value': e.value},
        ),

      // Repository-specific exceptions
      LogEntryValidationException e => MessageKey.errorFrom(
          L10nKeys.errorLogEntryValidation(e.errors.join(', ')),
        ),
      TemplateNotFoundException e => MessageKey.error(
          L10nKeys.errorTemplateNotFound,
          {'templateId': e.templateId},
        ),
      SchemaChangeException e => MessageKey.error(
          L10nKeys.errorTemplateSchemaChange,
          {'message': e.message},
        ),

      // Storage/Database exceptions
      StorageException() => const MessageKey.error(L10nKeys.errorStorageFailed),
      DatabaseException() => const MessageKey.error(L10nKeys.errorDatabaseFailed),

      // PowerSync exceptions
      PowerSyncException() => const MessageKey.error(L10nKeys.errorSyncFailed),

      // Serverpod exceptions
      ServerpodException e => MessageKey.error(
          'error.server.${e.errorCode}',
          {'code': e.errorCode},
        ),

      // Encryption exceptions
      EncryptionException() => const MessageKey.error(L10nKeys.errorEncryptionFailed),
      KeyManagementException() => const MessageKey.error(L10nKeys.errorKeysFailed),
      KeyGenerationException e => e.message.contains('already exist')
          ? const MessageKey.error(L10nKeys.errorKeysAlreadyExist)
          : const MessageKey.error(L10nKeys.errorKeysFailed),

      // Pairing exceptions
      PairingException e => e.message.contains('already set up')
          ? const MessageKey.error(L10nKeys.errorPairingDeviceAlreadySetup)
          : const MessageKey.error(L10nKeys.errorPairingFailed),

      // Public submission exceptions (most specific first)
      ChallengeRequestException() => const MessageKey.error(L10nKeys.errorChallengeRequestFailed),
      ProofOfWorkException() => const MessageKey.error(L10nKeys.errorProofOfWorkFailed),
      SignatureException() => const MessageKey.error(L10nKeys.errorSignatureFailed),
      RateLimitExceededException() => const MessageKey.error(L10nKeys.errorRateLimitExceeded),
      PublicSubmissionException() => const MessageKey.error(L10nKeys.errorPublicSubmissionFailed),

      // Feedback exceptions
      FeedbackException e => _mapFeedbackException(e),

      // Purchase exceptions
      PurchaseException() => const MessageKey.error(L10nKeys.errorPurchaseFailed),
      EntitlementException() => const MessageKey.error(L10nKeys.errorEntitlementFailed),

      // LLM provider exceptions
      LlmProviderException() => const MessageKey.error(L10nKeys.errorLlmProviderFailed),

      // Generic exceptions
      FormatException() => const MessageKey.error(L10nKeys.errorFormatInvalid),
      ArgumentError() => const MessageKey.error(L10nKeys.errorArgumentInvalid),
      StateError() => const MessageKey.error(L10nKeys.errorStateInvalid),
      
      // Fallback to null for unknown exceptions (will use generic error)
      _ => null,
    };
  }

  /// Maps AuthException, checking cause for more specific errors
  MessageKey _mapAuthException(AuthException e) {
    final cause = e.cause;
    
    // Check if cause is a KeyGenerationException with "already exist" message
    if (cause is KeyGenerationException) {
      if (cause.message.contains('already exist')) {
        return const MessageKey.error(L10nKeys.errorKeysAlreadyExist);
      }
      return const MessageKey.error(L10nKeys.errorKeysFailed);
    }
    
    // Check for connection/network errors (ServerpodClientException with SocketException)
    final causeString = cause?.toString() ?? '';
    final messageString = e.message;
    if (causeString.contains('Connection refused') || 
        causeString.contains('SocketException') ||
        messageString.contains('Connection refused') ||
        messageString.contains('SocketException')) {
      return const MessageKey.error(L10nKeys.errorOffline);
    }

    // Default auth error
    return const MessageKey.error(L10nKeys.errorAuthFailed);
  }

  /// Maps FeedbackException to specific error messages
  MessageKey _mapFeedbackException(FeedbackException e) {
    if (e.message.contains('at least 10 characters')) {
      return const MessageKey.error(L10nKeys.errorFeedbackTooShort);
    }
    if (e.message.contains('less than 5000 characters')) {
      return const MessageKey.error(L10nKeys.errorFeedbackTooLong);
    }
    if (e.message.contains('Invalid feedback type')) {
      return const MessageKey.error(L10nKeys.errorFeedbackInvalidType);
    }
    return const MessageKey.error(L10nKeys.errorPublicSubmissionFailed);
  }
}

// Exception classes for the Quanitya application
// These should be defined in their respective modules, but included here for reference

class NetworkException implements Exception {
  final String message;
  const NetworkException(this.message);
}

class TimeoutException implements Exception {
  final String message;
  const TimeoutException(this.message);
}

class UnauthorizedException implements Exception {
  final String message;
  const UnauthorizedException(this.message);
}

class ValidationException implements Exception {
  final String field;
  final dynamic value;
  final String message;
  
  const ValidationException({
    required this.field,
    required this.value,
    required this.message,
  });
}

class StorageException implements Exception {
  final String message;
  const StorageException(this.message);
}

class DatabaseException implements Exception {
  final String message;
  const DatabaseException(this.message);
}

class PowerSyncException implements Exception {
  final String message;
  const PowerSyncException(this.message);
}

class ServerpodException implements Exception {
  final String errorCode;
  final String message;
  
  const ServerpodException({
    required this.errorCode,
    required this.message,
  });
}

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);
}

class KeyManagementException implements Exception {
  final String message;
  const KeyManagementException(this.message);
}