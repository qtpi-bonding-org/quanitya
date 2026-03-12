import 'package:geolocator/geolocator.dart';
import 'package:get_it/get_it.dart';

import '../permissions/permission_service.dart';

/// Lightweight location service for manual GPS capture.
///
/// Only supports "when in use" permission — no background tracking.
/// Used by location field type when user taps the capture button.
class LocationService {
  LocationService._();

  /// Captures the current GPS position.
  ///
  /// Requests permission via [PermissionService] if not already granted.
  /// Returns lat/lng map suitable for storing in entry data JSON.
  ///
  /// Throws [LocationException] if permission denied or unavailable.
  static Future<Map<String, double>> captureCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled.');
    }

    final granted = await GetIt.instance<PermissionService>().ensureLocation();
    if (!granted) {
      throw LocationException('Location permission denied.');
    }

    final position = await Geolocator.getCurrentPosition(
      locationSettings: const LocationSettings(
        accuracy: LocationAccuracy.high,
        timeLimit: Duration(seconds: 10),
      ),
    );

    return {
      'latitude': position.latitude,
      'longitude': position.longitude,
    };
  }
}

class LocationException implements Exception {
  final String message;
  LocationException(this.message);

  @override
  String toString() => message;
}
