import '../utils/logger.dart';
import 'location_service.dart';

/// Reusable reverse-geocoding service: converts a lat/lng pair into a
/// human-readable address string.
///
/// Built on top of [LocationService.reverseGeocodeAddress] (Google's
/// Geocoding REST API via `dio`) rather than the `geocoding` plugin, which
/// has no implementation on Windows/web — platforms this app also runs on
/// during development. This keeps a single reverse-geocoding code path for
/// the whole app.
///
/// Never throws: any failure (invalid coordinates, no network, empty
/// result, missing API key) resolves to [fallbackAddress]. Successful
/// lookups are cached in memory per coordinate so the same point is never
/// looked up twice.
class LocationAddressService {
  LocationAddressService({LocationService? locationService})
      : _locationService = locationService ?? LocationService();

  final LocationService _locationService;
  final Map<String, String> _cache = {};

  static const String fallbackAddress = 'Address unavailable';

  /// Resolves a full formatted address for [latitude]/[longitude].
  /// Always resolves — falls back to [fallbackAddress] instead of throwing.
  Future<String> getAddressFromLatLng(
    double latitude,
    double longitude,
  ) async {
    if (!_isValidCoordinate(latitude, longitude)) {
      AppLogger.w(
        'LocationAddressService: invalid coordinates ($latitude, $longitude)',
      );
      return fallbackAddress;
    }

    final cacheKey = _cacheKeyFor(latitude, longitude);
    final cached = _cache[cacheKey];
    if (cached != null) return cached;

    try {
      final result = await _locationService.reverseGeocodeAddress(
        latitude: latitude,
        longitude: longitude,
      );

      final address = _cleanAddress(result);
      if (address == null) {
        AppLogger.w(
          'LocationAddressService: empty reverse-geocode result for '
          '($latitude, $longitude)',
        );
        return fallbackAddress;
      }

      _cache[cacheKey] = address;
      return address;
    } catch (error, stackTrace) {
      AppLogger.e(
        'LocationAddressService: reverse geocoding failed for '
        '($latitude, $longitude)',
        error,
        stackTrace,
      );
      return fallbackAddress;
    }
  }

  /// De-duplicates consecutive comma-separated components (Google's
  /// formatted address occasionally repeats a component, e.g. when the
  /// locality and sub-administrative area share a name) and trims blanks.
  String? _cleanAddress(String? raw) {
    if (raw == null) return null;
    final trimmed = raw.trim();
    if (trimmed.isEmpty) return null;

    final seen = <String>{};
    final parts = <String>[];
    for (final part in trimmed.split(',')) {
      final value = part.trim();
      if (value.isEmpty) continue;
      final key = value.toLowerCase();
      if (seen.add(key)) parts.add(value);
    }

    if (parts.isEmpty) return null;
    return parts.join(', ');
  }

  bool _isValidCoordinate(double latitude, double longitude) {
    if (latitude.isNaN || longitude.isNaN) return false;
    return latitude >= -90 &&
        latitude <= 90 &&
        longitude >= -180 &&
        longitude <= 180;
  }

  /// Rounds to ~1m precision so nearly-identical points share a cache entry.
  String _cacheKeyFor(double latitude, double longitude) {
    return '${latitude.toStringAsFixed(5)},${longitude.toStringAsFixed(5)}';
  }

  /// Clears cached lookups. Exposed for tests; not needed in normal use
  /// since coordinates resolve to stable addresses.
  void clearCache() => _cache.clear();
}
