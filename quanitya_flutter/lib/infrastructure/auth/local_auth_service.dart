import 'package:flutter/services.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../core/try_operation.dart';
import '../platform/exceptions/device_auth_exception.dart';

/// Result of a device authentication attempt.
enum LocalAuthResult {
  /// Authentication succeeded
  success,

  /// User cancelled authentication
  cancelled,

  /// Authentication failed (wrong biometric, too many attempts, etc.)
  failed,

  /// Device authentication not available on this device
  notAvailable,
}

/// Service for local device authentication (Face ID, Touch ID, fingerprint, PIN, pattern, password).
///
/// We accept any device-level authentication - if the user trusts their device
/// unlock method, we trust it too.
@lazySingleton
class LocalAuthService {
  final LocalAuthentication _localAuth = LocalAuthentication();

  /// Check if any device-level authentication is available.
  ///
  /// This includes biometrics (Face ID, Touch ID, fingerprint) OR
  /// device credentials (PIN, pattern, password).
  Future<bool> isDeviceAuthAvailable() {
    return tryMethod(
      () async {
        return await _localAuth.isDeviceSupported();
      },
      DeviceAuthException.new,
      'isDeviceAuthAvailable',
    );
  }

  /// Check if biometric authentication specifically is available.
  Future<bool> isBiometricAvailable() {
    return tryMethod(
      () async {
        return await _localAuth.canCheckBiometrics;
      },
      DeviceAuthException.new,
      'isBiometricAvailable',
    );
  }

  /// Get the list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() {
    return tryMethod(
      () async {
        return await _localAuth.getAvailableBiometrics();
      },
      DeviceAuthException.new,
      'getAvailableBiometrics',
    );
  }

  /// Authenticate using device authentication (biometrics or device credentials).
  ///
  /// [reason] is shown to the user explaining why authentication is needed.
  ///
  /// Allows fallback to PIN/pattern/password - we trust whatever the user
  /// uses to secure their device.
  Future<LocalAuthResult> authenticate({
    required String reason,
  }) {
    return tryMethod(
      () async {
        // Check availability first
        final isAvailable = await _localAuth.isDeviceSupported();
        if (!isAvailable) {
          return LocalAuthResult.notAvailable;
        }

        try {
          final didAuthenticate = await _localAuth.authenticate(
            localizedReason: reason,
          );
          return didAuthenticate
              ? LocalAuthResult.success
              : LocalAuthResult.failed;
        } on PlatformException catch (e) {
          if (e.code == 'NotAvailable') {
            return LocalAuthResult.notAvailable;
          }
          if (e.code == 'LockedOut' || e.code == 'PermanentlyLockedOut') {
            return LocalAuthResult.failed;
          }
          // User cancelled
          return LocalAuthResult.cancelled;
        }
      },
      DeviceAuthException.new,
      'authenticate',
    );
  }

  /// Get a human-readable name for the available authentication type.
  Future<String> getAuthTypeName() {
    return tryMethod(
      () async {
        final biometrics = await _localAuth.getAvailableBiometrics();
        if (biometrics.contains(BiometricType.face)) {
          return 'Face ID';
        }
        if (biometrics.contains(BiometricType.fingerprint)) {
          return 'Touch ID';
        }
        if (biometrics.contains(BiometricType.strong)) {
          return 'Biometrics';
        }
        // Fallback to device credentials
        final isAvailable = await _localAuth.isDeviceSupported();
        if (isAvailable) {
          return 'Device Passcode';
        }
        return 'Device Authentication';
      },
      DeviceAuthException.new,
      'getAuthTypeName',
    );
  }
}
