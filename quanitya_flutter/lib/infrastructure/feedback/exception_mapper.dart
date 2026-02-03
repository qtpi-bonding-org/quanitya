import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';

import '../../data/repositories/log_entry_repository.dart';
import '../../data/repositories/template_with_aesthetics_repository.dart';
import '../../features/device_pairing/services/pairing_service.dart' show PairingException;
import '../auth/auth_service.dart' show AuthException;
import '../crypto/exceptions/crypto_exceptions.dart';
import '../public_submission/exceptions/public_submission_exceptions.dart';
import '../user_feedback/exceptions/feedback_exceptions.dart';

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
      TimeoutException() => const MessageKey.error('error.timeout'),
      
      // Authentication exceptions - check cause for more specific errors
      AuthException e => _mapAuthException(e),
      UnauthorizedException() => const MessageKey.error('error.auth.unauthorized'),
      
      // Validation exceptions
      ValidationException e => MessageKey.error(
          'validation.${e.field}',
          {'field': e.field, 'value': e.value},
        ),
      
      // Repository-specific exceptions
      LogEntryValidationException e => MessageKey.error(
          'error.log_entry.validation',
          {'errors': e.errors.join(', ')},
        ),
      TemplateNotFoundException e => MessageKey.error(
          'error.template.not_found',
          {'templateId': e.templateId},
        ),
      SchemaChangeException e => MessageKey.error(
          'error.template.schema_change',
          {'message': e.message},
        ),
      
      // Storage/Database exceptions
      StorageException() => const MessageKey.error('error.storage.failed'),
      DatabaseException() => const MessageKey.error('error.database.failed'),
      
      // PowerSync exceptions
      PowerSyncException() => const MessageKey.error('error.sync.failed'),
      
      // Serverpod exceptions
      ServerpodException e => MessageKey.error(
          'error.server.${e.errorCode}',
          {'code': e.errorCode},
        ),
      
      // Encryption exceptions
      EncryptionException() => const MessageKey.error('error.encryption.failed'),
      KeyManagementException() => const MessageKey.error('error.keys.failed'),
      KeyGenerationException e => e.message.contains('already exist')
          ? const MessageKey.error('error.keys.already.exist')
          : const MessageKey.error('error.keys.failed'),
      
      // Pairing exceptions
      PairingException e => e.message.contains('already set up')
          ? const MessageKey.error('error.pairing.device.already.setup')
          : const MessageKey.error('error.pairing.failed'),
      
      // Public submission exceptions (most specific first)
      ChallengeRequestException() => const MessageKey.error('error.challenge.request.failed'),
      ProofOfWorkException() => const MessageKey.error('error.proof.of.work.failed'),
      SignatureException() => const MessageKey.error('error.signature.failed'),
      RateLimitExceededException() => const MessageKey.error('error.rate.limit.exceeded'),
      PublicSubmissionException() => const MessageKey.error('error.public.submission.failed'),
      
      // Feedback exceptions
      FeedbackException e => _mapFeedbackException(e),
      
      // Generic exceptions
      FormatException() => const MessageKey.error('error.format.invalid'),
      ArgumentError() => const MessageKey.error('error.argument.invalid'),
      StateError() => const MessageKey.error('error.state.invalid'),
      
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
        return const MessageKey.error('error.keys.already.exist');
      }
      return const MessageKey.error('error.keys.failed');
    }
    
    // Check for connection/network errors (ServerpodClientException with SocketException)
    final causeString = cause?.toString() ?? '';
    final messageString = e.message;
    if (causeString.contains('Connection refused') || 
        causeString.contains('SocketException') ||
        messageString.contains('Connection refused') ||
        messageString.contains('SocketException')) {
      return const MessageKey.error('error.offline');
    }
    
    // Default auth error
    return const MessageKey.error('error.auth.failed');
  }

  /// Maps FeedbackException to specific error messages
  MessageKey _mapFeedbackException(FeedbackException e) {
    if (e.message.contains('at least 10 characters')) {
      return const MessageKey.error('error.feedback.too.short');
    }
    if (e.message.contains('less than 5000 characters')) {
      return const MessageKey.error('error.feedback.too.long');
    }
    if (e.message.contains('Invalid feedback type')) {
      return const MessageKey.error('error.feedback.invalid.type');
    }
    return const MessageKey.error('error.public.submission.failed');
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