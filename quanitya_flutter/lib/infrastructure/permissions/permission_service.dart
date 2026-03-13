import 'package:flutter/foundation.dart';
import 'package:health/health.dart';
import 'package:injectable/injectable.dart';
import 'package:permission_handler/permission_handler.dart';

/// Centralized permission service for all OS-level permission requests.
///
/// Wraps `permission_handler` for most permissions and the `health` package
/// for HealthKit/Health Connect authorization. Each `ensure*()` method is
/// idempotent — if permission is already granted, it returns immediately.
///
/// Usage at call sites:
/// ```dart
/// if (!await permissionService.ensureCamera()) return;
/// // proceed with camera work
/// ```
@lazySingleton
class PermissionService {
  final Health _health;

  PermissionService() : _health = Health();

  @visibleForTesting
  PermissionService.forTesting(this._health);

  /// Ensure notification permission is granted.
  ///
  /// Called when the user creates or enables a schedule.
  Future<bool> ensureNotification() async {
    return _ensure(Permission.notification, 'notification');
  }

  /// Ensure camera permission is granted.
  ///
  /// Called when the user opens the QR code scanner.
  Future<bool> ensureCamera() async {
    return _ensure(Permission.camera, 'camera');
  }

  /// Ensure location permission is granted.
  ///
  /// Called when the user taps the location capture button.
  Future<bool> ensureLocation() async {
    return _ensure(Permission.locationWhenInUse, 'location');
  }

  /// Ensure health data permission is granted for the given types.
  ///
  /// Uses the `health` package's own authorization API because
  /// HealthKit requires per-type authorization.
  ///
  /// Called when the user enables health sync in settings.
  Future<bool> ensureHealth(List<HealthDataType> types) async {
    try {
      final granted = await _health.requestAuthorization(
        types,
        permissions: List.filled(types.length, HealthDataAccess.READ),
      );
      debugPrint('PermissionService: health = $granted');
      return granted;
    } catch (e) {
      debugPrint('PermissionService: health request failed: $e');
      return false;
    }
  }

  /// Check if health permissions are currently granted.
  ///
  /// Returns true on iOS if permissions were previously requested
  /// (Apple doesn't disclose READ permission status).
  Future<bool> hasHealth(List<HealthDataType> types) async {
    try {
      final result = await _health.hasPermissions(
        types,
        permissions: List.filled(types.length, HealthDataAccess.READ),
      );
      // hasPermissions returns bool? — null means undetermined (iOS READ)
      return result ?? true;
    } catch (e) {
      debugPrint('PermissionService: health check failed: $e');
      return false;
    }
  }

  /// Internal: check and request a single permission.
  Future<bool> _ensure(Permission permission, String label) async {
    try {
      var status = await permission.status;
      if (status.isGranted) {
        return true;
      }

      if (status.isPermanentlyDenied) {
        debugPrint('PermissionService: $label permanently denied — open Settings to grant');
        return false;
      }

      status = await permission.request();
      debugPrint('PermissionService: $label = $status');
      return status.isGranted;
    } catch (e) {
      debugPrint('PermissionService: $label request failed: $e');
      return false;
    }
  }
}
