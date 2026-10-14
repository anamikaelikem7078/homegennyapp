import 'package:geolocator/geolocator.dart';

import 'google_maps_service.dart';

/// Raised when the device location can't be resolved (services disabled,
/// permission denied/permanently denied, or the platform call failed).
class LocationServiceException implements Exception {
  LocationServiceException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thin wrapper around `geolocator` for GPS-based attendance verification
/// (check-in/check-out). Handles the permission/service-enabled dance and
/// exposes a distance helper for geofencing against a work site.
class LocationService {
  LocationService({GoogleMapsService? maps}) : _maps = maps;

  /// Backend maps proxy for reverse geocoding; null = coordinates only.
  final GoogleMapsService? _maps;

  /// Resolves the device's current GPS position, requesting permission if
  /// needed. Throws [LocationServiceException] with a user-facing message
  /// when location can't be determined.
  Future<Position> getCurrentPosition() async {
    final serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      throw LocationServiceException(
        'Location services are turned off. Please enable GPS to check in.',
      );
    }

    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        throw LocationServiceException(
          'Location permission denied. Allow location access to verify attendance.',
        );
      }
    }

    if (permission == LocationPermission.deniedForever) {
      throw LocationServiceException(
        'Location permission is permanently denied. Enable it from app settings.',
      );
    }

    final Position position;
    try {
      position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 20),
        ),
      );
    } on Exception {
      throw LocationServiceException(
        'Could not determine your location. Move to an open area and try again.',
      );
    }
    // Attendance must be marked where the staff member really is.
    if (position.isMocked) {
      throw LocationServiceException(
        'A fake-location app is turned on. Turn it off to mark attendance.',
      );
    }
    return position;
  }

  /// Resolves the full postal address for a coordinate through the backend
  /// (`GET /maps/reverse-geocode`), which calls Google with a server-side
  /// key — the app holds no key, and it works on web too (a direct browser
  /// call to Google is blocked by CORS). Returns null (never throws) when the
  /// lookup fails or the server can't resolve it — callers fall back to raw
  /// coordinates.
  Future<String?> reverseGeocodeAddress({
    required double latitude,
    required double longitude,
  }) async {
    final maps = _maps;
    if (maps == null) return null;
    try {
      final body = await maps.reverseGeocode(latitude: latitude, longitude: longitude);
      final data = body['data'] is Map ? body['data'] as Map : body;
      // Only a real Google answer. An older server returns a fixed
      // placeholder address without `source` — never show that.
      if (data['status'] != 'OK' || data['source'] != 'google') return null;
      final address = data['formattedAddress'];
      return address is String && address.trim().isNotEmpty ? address.trim() : null;
    } catch (_) {
      return null;
    }
  }

  /// Straight-line distance in meters between two coordinates (Haversine).
  double distanceInMeters({
    required double startLatitude,
    required double startLongitude,
    required double endLatitude,
    required double endLongitude,
  }) {
    return Geolocator.distanceBetween(
      startLatitude,
      startLongitude,
      endLatitude,
      endLongitude,
    );
  }
}
