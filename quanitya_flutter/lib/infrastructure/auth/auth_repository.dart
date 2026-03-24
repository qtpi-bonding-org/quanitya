import 'package:injectable/injectable.dart';

import '../core/try_operation.dart';
import '../crypto/interfaces/i_secure_storage.dart';
import '../platform/secure_preferences.dart';
import 'registration_payload.dart';

/// Exception thrown when auth persistence operations fail.
class AuthRepositoryException implements Exception {
  const AuthRepositoryException(this.message, [this.cause]);

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'AuthRepositoryException: $message${cause != null ? ' (caused by: $cause)' : ''}';
}

/// Persistence layer for authentication state.
///
/// Owns all secure storage I/O for auth data:
/// - "registered with server" flag (via [SecurePreferences] / getBool + setBool)
/// - [RegistrationPayload] JSON (via [ISecureStorage] storeSecureData / getSecureData)
///
/// This is intentionally a thin CRUD layer. Business logic lives in [AuthService].
@lazySingleton
class AuthRepository {
  final SecurePreferences _prefs;
  final ISecureStorage _secureStorage;

  // Mirror the same storage keys used by AuthService so nothing is lost during
  // the incremental migration to this repository.
  static const _registeredWithServerKey = 'quanitya_registered_with_server';
  static const _registrationPayloadKey = 'quanitya_registration_payload';

  AuthRepository(this._prefs, this._secureStorage);

  // ─────────────────────────────────────────────────────────────────────────────
  // Registration flag
  // ─────────────────────────────────────────────────────────────────────────────

  /// Returns `true` if this device has successfully registered with the server.
  Future<bool> get isRegisteredWithServer => tryMethod(
        () async => (await _prefs.getBool(_registeredWithServerKey)) == true,
        AuthRepositoryException.new,
        'isRegisteredWithServer',
      );

  /// Marks this device as registered with the server.
  Future<void> setRegistered() => tryMethod(
        () => _prefs.setBool(_registeredWithServerKey, true),
        AuthRepositoryException.new,
        'setRegistered',
      );

  /// Clears the "registered with server" flag.
  ///
  /// Use when the server reports the device is unknown so that the next
  /// registration attempt will re-register instead of treating it as a no-op.
  Future<void> clearRegistrationFlag() => tryMethod(
        () => _prefs.remove(_registeredWithServerKey),
        AuthRepositoryException.new,
        'clearRegistrationFlag',
      );

  // ─────────────────────────────────────────────────────────────────────────────
  // Registration payload
  // ─────────────────────────────────────────────────────────────────────────────

  /// Persists [payload] to secure storage as a JSON string.
  Future<void> storeRegistrationPayload(RegistrationPayload payload) =>
      tryMethod(
        () => _secureStorage.storeSecureData(
          _registrationPayloadKey,
          payload.toJsonString(),
        ),
        AuthRepositoryException.new,
        'storeRegistrationPayload',
      );

  /// Returns the stored [RegistrationPayload], or `null` if none is present.
  Future<RegistrationPayload?> getRegistrationPayload() => tryMethod(
        () async {
          final json =
              await _secureStorage.getSecureData(_registrationPayloadKey);
          if (json == null) return null;
          return RegistrationPayloadX.fromJsonString(json);
        },
        AuthRepositoryException.new,
        'getRegistrationPayload',
      );

  /// Deletes the stored registration payload from secure storage.
  Future<void> deleteRegistrationPayload() => tryMethod(
        () => _secureStorage.deleteSecureData(_registrationPayloadKey),
        AuthRepositoryException.new,
        'deleteRegistrationPayload',
      );
}
