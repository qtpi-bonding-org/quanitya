import 'package:geolocator/geolocator.dart';

/// Lightweight location service for manual GPS capture.
///
/// Only supports "when in use" permission — no background tracking.
/// Used by location field type when user taps the capture button.
class LocationService {
  LocationService._();

  /// Captures the current GPS position.
  ///
  /// Requests permission if not already granted. Returns lat/lng map
  /// suitable for storing in entry data JSON.
  ///
  /// Throws [LocationException] if permission denied or unavailable.
  static Future<Map<String, double>> captureCurrentPosition() async {
    bool serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationException('Location services are disabled.');
    }

    LocationPermission permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationException('Location permission denied.');
      }
    }
    if (permission == LocationPermission.deniedForever) {
      throw LocationException(
        'Location permission permanently denied. Enable in Settings.',
      );
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
