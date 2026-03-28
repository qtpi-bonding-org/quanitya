import 'package:injectable/injectable.dart';

import '../config/debug_log.dart';
import 'package:serverpod_client/serverpod_client.dart' show ServerpodClientUnauthorized;

import '../core/try_operation.dart';
import 'account_service.dart';
import 'auth_service.dart' show AuthService, DeviceAuthenticationException;

const _tag = 'infrastructure/auth/auth_account_orchestrator';

/// Coordinates JWT authentication with automatic device re-registration.
///
/// This is the single place that handles the "device not found on server"
/// recovery flow. Services call [ensureAuthenticated] instead of calling
/// [AuthService] and [AccountService] independently.
///
/// Auth layers that do NOT go through this orchestrator:
/// - **PoW only** (hashcash challenges) — public, no identity needed
/// - **Signed PoW** (account creation, recovery) — explicit user actions
///   handled by their own cubits
///
/// Only **JWT session auth** needs this automatic retry because it can fail
/// silently when a device is revoked from another device.
@lazySingleton
class AuthAccountOrchestrator {
  final AuthService _authService;
  final AccountService _accountService;

  AuthAccountOrchestrator(this._authService, this._accountService);

  /// Ensure the device has a valid JWT session, re-registering if needed.
  ///
  /// Flow:
  /// 1. If already authenticated, return immediately.
  /// 2. Try [AuthService.ensureAuthenticated].
  /// 3. If device was revoked ([DeviceAuthenticationException]),
  ///    re-register via [AccountService.ensureRegistered] and retry once.
  /// 4. If retry also fails, the exception propagates to the caller.
  Future<void> ensureAuthenticated() {
    return tryMethod(() async {
      if (_authService.hasValidSession) return;

      await _authenticate();
    }, (message, [cause]) => DeviceAuthenticationException(message, cause: cause),
        'ensureAuthenticated',
    );
  }

  /// Execute [action] with automatic JWT refresh on 401.
  ///
  /// Use this to wrap any authenticated Serverpod call. If the call
  /// returns 401 (e.g. server restarted and invalidated all JWTs),
  /// the session is cleared, a fresh JWT is obtained, and the call
  /// is retried once.
  Future<T> withAuth<T>(Future<T> Function() action) async {
    await ensureAuthenticated();
    try {
      return await action();
    } on ServerpodClientUnauthorized {
      Log.d(_tag,'AuthAccountOrchestrator: 401 on call — refreshing JWT');
      await _authService.clearSession();
      await _authenticate();
      return await action();
    }
  }

  Future<void> _authenticate() async {
    try {
      await _authService.ensureAuthenticated();
    } on DeviceAuthenticationException catch (e) {
      Log.d(_tag,'AuthAccountOrchestrator: device auth failed — $e');
      Log.d(_tag,'AuthAccountOrchestrator: cause: ${e.cause}');
      Log.d(_tag,'AuthAccountOrchestrator: re-registering...');
      await _accountService.ensureRegistered(deviceLabel: 'auto', force: true);
      await _authService.ensureAuthenticated();
    }
  }
}
