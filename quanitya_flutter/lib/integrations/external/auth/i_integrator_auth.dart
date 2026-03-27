import 'package:freezed_annotation/freezed_annotation.dart';

import '../models/integration_enums.dart';

part 'i_integrator_auth.freezed.dart';

/// Authentication strategy interface for external integrations.
///
/// Provides a pluggable authentication system that can handle different
/// auth methods (OAuth PKCE, API tokens, public access) while maintaining
/// a consistent interface for integration consumers.
///
/// Implementations:
/// - [PKCEIntegratorAuth]: OAuth with PKCE flow
/// - [TokenIntegratorAuth]: API Key/PAT (wraps existing ApiKeyRepository)
/// - [PublicIntegratorAuth]: No authentication required
abstract class IIntegratorAuth {
  /// The authentication strategy type.
  IntegratorAuthType get authType;

  /// Human-readable name for UI display.
  /// Examples: "OAuth (PKCE)", "API Token", "Public Access"
  String get displayName;

  /// Whether this auth strategy requires user setup/configuration.
  bool get requiresSetup;

  /// Check if the user is currently authenticated.
  ///
  /// Returns true if valid credentials are available and not expired.
  /// For public auth, this always returns true.
  Future<bool> isAuthenticated();

  /// Initiate the authentication process.
  ///
  /// For OAuth: Opens browser flow and handles callback
  /// For Token: Prompts user for API key input
  /// For Public: Returns immediate success
  ///
  /// Returns [IntegratorAuthResult] indicating success, failure, or cancellation.
  Future<IntegratorAuthResult> authenticate();

  /// Get authentication headers for API requests.
  ///
  /// Returns headers map that should be included in HTTP requests.
  /// For token auth: {"Authorization": "Bearer token"}
  /// For API key: {"X-API-Key": "key"} or custom header
  /// For public: {} (empty map)
  ///
  /// Throws [AuthStrategyException] if not authenticated.
  Future<Map<String, String>> getAuthHeaders();

  /// Clear stored authentication credentials.
  ///
  /// Removes tokens, clears secure storage, and resets auth state.
  /// After logout, [isAuthenticated] should return false.
  Future<void> logout();
}

/// Result of an authentication attempt.
///
/// Provides detailed information about the authentication outcome
/// for proper error handling and user feedback.
@freezed
abstract class IntegratorAuthResult with _$IntegratorAuthResult {
  const IntegratorAuthResult._();
  /// Authentication completed successfully.
  const factory IntegratorAuthResult.success({
    /// Optional metadata about the authentication
    Map<String, dynamic>? metadata,
  }) = IntegratorAuthResultSuccess;

  /// Authentication failed due to an error.
  const factory IntegratorAuthResult.failure({
    /// Error message describing what went wrong
    required String message,
    /// Optional error code for programmatic handling
    String? errorCode,
    /// Whether the user can retry the authentication
    @Default(true) bool canRetry,
  }) = IntegratorAuthResultFailure;

  /// Authentication was cancelled by the user.
  const factory IntegratorAuthResult.cancelled() = IntegratorAuthResultCancelled;
}

/// Exception thrown by authentication strategies.
///
/// Used for authentication-specific errors that need to be handled
/// differently from general integration exceptions.
class AuthStrategyException implements Exception {
  /// Error message describing the authentication issue
  final String message;
  
  /// Optional underlying cause of the exception
  final Object? cause;
  
  /// Authentication type that threw the exception
  final IntegratorAuthType authType;

  const AuthStrategyException(
    this.message, 
    this.authType, [
    this.cause,
  ]);

  @override
  String toString() => 'AuthStrategyException($authType): $message';
}

/// Extension methods for IntegratorAuthResult.
extension IntegratorAuthResultExtension on IntegratorAuthResult {
  /// Whether the authentication was successful.
  bool get isSuccess => this is IntegratorAuthResultSuccess;

  /// Whether the authentication failed.
  bool get isFailure => this is IntegratorAuthResultFailure;

  /// Whether the authentication was cancelled.
  bool get isCancelled => this is IntegratorAuthResultCancelled;

  /// Get the error message if authentication failed.
  String? get errorMessage => mapOrNull(
    failure: (failure) => failure.message,
  );

  /// Whether the user can retry after a failure.
  bool get canRetry => mapOrNull(
    failure: (failure) => failure.canRetry,
  ) ?? false;
}