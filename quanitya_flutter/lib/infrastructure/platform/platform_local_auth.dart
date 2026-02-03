import 'package:flutter/foundation.dart';
import 'package:injectable/injectable.dart';
import 'package:local_auth/local_auth.dart';

import '../core/try_operation.dart';
import 'platform_capability_service.dart';
import 'exceptions/device_auth_exception.dart';

/// Platform-aware local authentication that gracefully handles unsupported platforms.
/// 
/// On supported platforms: Uses LocalAuthentication directly
/// On unsupported platforms: Returns appropriate unavailable results
@injectable
class PlatformLocalAuth {
  final PlatformCapabilityService _capabilities;
  final LocalAuthentication? _localAuth;
  
  PlatformLocalAuth(this._capabilities) 
    : _localAuth = _capabilities.supportsLocalAuth 
        ? LocalAuthentication() 
        : null;

  /// Check if any device-level authentication is available.
  Future<bool> isDeviceAuthAvailable() {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalAuth) {
          return false;
        }
        if (_localAuth == null) {
          throw StateError('LocalAuthentication not initialized');
        }
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
        if (!_capabilities.supportsLocalAuth) {
          return false;
        }
        if (_localAuth == null) {
          throw StateError('LocalAuthentication not initialized');
        }
        return await _localAuth.canCheckBiometrics;
      },
      DeviceAuthException.new,
      'isBiometricAvailable',
    );
  }

  /// Authenticate using any available device authentication method.
  /// Accepts biometrics, PIN, password, pattern - whatever the user prefers.
  Future<bool> authenticate({
    required String reason,
  }) {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalAuth) {
          debugPrint('⚠️ ${_capabilities.platformName}: Local auth not supported');
          return false;
        }
        
        if (_localAuth == null) {
          throw StateError('LocalAuthentication not initialized');
        }
        return await _localAuth.authenticate(
          localizedReason: reason,
        );
      },
      DeviceAuthException.new,
      'authenticate',
    );
  }

  /// Get list of available biometric types.
  Future<List<BiometricType>> getAvailableBiometrics() {
    return tryMethod(
      () async {
        if (!_capabilities.supportsLocalAuth) {
          return <BiometricType>[];
        }
        if (_localAuth == null) {
          throw StateError('LocalAuthentication not initialized');
        }
        return await _localAuth.getAvailableBiometrics();
      },
      DeviceAuthException.new,
      'getAvailableBiometrics',
    );
  }
  
  /// Whether local auth is supported on this platform.
  bool get isSupported => _capabilities.supportsLocalAuth;
  
  /// User-friendly message explaining why local auth is unavailable.
  String? get unavailabilityReason {
    if (!_capabilities.supportsLocalAuth) {
      return 'Device authentication is not available on ${_capabilities.platformName}. '
             'Please use password authentication instead.';
    }
    return null;
  }
}