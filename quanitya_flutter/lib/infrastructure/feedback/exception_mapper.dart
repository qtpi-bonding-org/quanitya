import 'package:injectable/injectable.dart';
import 'package:cubit_ui_flow/cubit_ui_flow.dart';
import 'package:quanitya_cloud_client/quanitya_cloud_client.dart' show ServerException, ServerErrorCode;
import 'package:quanitya_flutter/l10n/l10n_key_resolver.g.dart';

import '../../data/repositories/analytics_inbox_repository.dart' show AnalyticsInboxException;
import '../../data/repositories/data_export_repository.dart' show ImportFailedException, ImportCancelledException;
import '../../data/repositories/log_entry_repository.dart';
import '../../data/repositories/template_with_aesthetics_repository.dart';
import '../../features/app_operating_mode/exceptions/app_operating_exceptions.dart' show AppOperatingException;
import '../../features/device_pairing/services/pairing_service.dart' show PairingException, PairingFailure;
import '../../logic/log_entries/exceptions/log_entry_exceptions.dart';
import '../auth/auth_service.dart' show AuthException, AuthFailure;
import '../crypto/exceptions/crypto_exceptions.dart';
import '../llm/services/llm_service.dart' show LlmException;
import '../location/location_service.dart' show LocationException;
import '../notifications/exceptions/notification_exception.dart' show NotificationException;
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
      LogEntrySaveException() => const MessageKey.error(L10nKeys.errorLogEntrySaveFailed),
      LogEntryUpdateException() => const MessageKey.error(L10nKeys.errorLogEntryUpdateFailed),
      LogEntryDeleteException() => const MessageKey.error(L10nKeys.errorLogEntryDeleteFailed),
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
      AnalyticsInboxException() => const MessageKey.error(L10nKeys.errorAnalyticsFailed),
      ImportCancelledException() => null, // User-initiated, no toast needed
      ImportFailedException() => const MessageKey.error(L10nKeys.errorImportFailed),

      // Storage/Database exceptions
      StorageException() => const MessageKey.error(L10nKeys.errorStorageFailed),
      DatabaseException() => const MessageKey.error(L10nKeys.errorDatabaseFailed),

      // PowerSync exceptions
      PowerSyncException() => const MessageKey.error(L10nKeys.errorSyncFailed),

      // Server exceptions (typed from quanitya_cloud_client)
      ServerException e => _mapServerException(e),

      // Crypto subtypes (most specific first, before base CryptoException types)
      KeyStorageException() => const MessageKey.error(L10nKeys.errorKeysFailed),
      KeyRetrievalException() => const MessageKey.error(L10nKeys.errorKeysFailed),
      CryptoOperationException() => const MessageKey.error(L10nKeys.errorEncryptionFailed),
      DeviceProvisioningException() => const MessageKey.error(L10nKeys.errorKeysFailed),
      RecoveryException() => const MessageKey.error(L10nKeys.errorRecoveryFailed),
      DeviceRevocationException() => const MessageKey.error(L10nKeys.errorDeviceRevocationFailed),
      KeyGenerationException e => e.kind == KeyGenerationFailure.keysAlreadyExist
          ? const MessageKey.error(L10nKeys.errorKeysAlreadyExist)
          : const MessageKey.error(L10nKeys.errorKeysFailed),

      // Encryption exceptions (local types defined below)
      EncryptionException() => const MessageKey.error(L10nKeys.errorEncryptionFailed),
      KeyManagementException() => const MessageKey.error(L10nKeys.errorKeysFailed),

      // Pairing exceptions
      PairingException e => e.kind == PairingFailure.deviceAlreadySetUp
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
      EntitlementException() => const MessageKey.info(L10nKeys.errorEntitlementFailed),

      // LLM exceptions
      LlmException() => const MessageKey.error(L10nKeys.errorLlmFailed),
      LlmProviderException() => const MessageKey.error(L10nKeys.errorLlmProviderFailed),

      // Notification exceptions
      NotificationException() => const MessageKey.error(L10nKeys.errorNotificationFailed),

      // App settings / operating mode exceptions
      AppOperatingException() => const MessageKey.error(L10nKeys.errorSettingsFailed),

      // Location exceptions
      LocationException() => const MessageKey.error(L10nKeys.errorLocationFailed),

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

    // Check if cause is a KeyGenerationException — use its kind
    if (cause is KeyGenerationException) {
      if (cause.kind == KeyGenerationFailure.keysAlreadyExist) {
        return const MessageKey.error(L10nKeys.errorKeysAlreadyExist);
      }
      return const MessageKey.error(L10nKeys.errorKeysFailed);
    }

    // Network error detected at wrapping time
    if (e.kind == AuthFailure.networkError) {
      return const MessageKey.error(L10nKeys.errorOffline);
    }

    // Default auth error
    return const MessageKey.error(L10nKeys.errorAuthFailed);
  }

  /// Maps ServerException to specific error message keys.
  MessageKey _mapServerException(ServerException e) {
    return switch (e.code) {
      ServerErrorCode.rateLimitExceeded => const MessageKey.error(L10nKeys.errorRateLimitExceeded),
      ServerErrorCode.validationFailed => const MessageKey.error(L10nKeys.errorFormatInvalid),
      ServerErrorCode.notFound => const MessageKey.error(L10nKeys.errorTemplateNotFound),
      ServerErrorCode.insufficientCredits => const MessageKey.error(L10nKeys.errorPurchaseFailed),
      ServerErrorCode.authenticationFailed => const MessageKey.error(L10nKeys.errorAuthFailed),
      ServerErrorCode.insufficientPermissions => const MessageKey.error(L10nKeys.errorAuthUnauthorized),
      ServerErrorCode.challengeExpired => const MessageKey.error(L10nKeys.errorChallengeRequestFailed),
      ServerErrorCode.invalidProofOfWork => const MessageKey.error(L10nKeys.errorProofOfWorkFailed),
      ServerErrorCode.invalidSignature => const MessageKey.error(L10nKeys.errorSignatureFailed),
      ServerErrorCode.internalError => const MessageKey.error(L10nKeys.errorGeneric),
      ServerErrorCode.jwtSigningKeyMissing => const MessageKey.error(L10nKeys.errorAuthFailed),
      ServerErrorCode.jwtGenerationFailed => const MessageKey.error(L10nKeys.errorAuthFailed),
    };
  }

  /// Maps FeedbackException to specific error messages
  MessageKey _mapFeedbackException(FeedbackException e) {
    return switch (e.kind) {
      FeedbackFailure.tooShort => const MessageKey.error(L10nKeys.errorFeedbackTooShort),
      FeedbackFailure.tooLong => const MessageKey.error(L10nKeys.errorFeedbackTooLong),
      FeedbackFailure.invalidType => const MessageKey.error(L10nKeys.errorFeedbackInvalidType),
      FeedbackFailure.submissionFailed => const MessageKey.error(L10nKeys.errorPublicSubmissionFailed),
    };
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

class EncryptionException implements Exception {
  final String message;
  const EncryptionException(this.message);
}

class KeyManagementException implements Exception {
  final String message;
  const KeyManagementException(this.message);
}