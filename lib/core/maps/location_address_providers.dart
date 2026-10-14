import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../di/injection.dart';

/// Coordinate pair used as the family key for [locationAddressProvider].
class LatLngParams {
  const LatLngParams({required this.latitude, required this.longitude});

  final double latitude;
  final double longitude;

  @override
  bool operator ==(Object other) =>
      other is LatLngParams &&
      other.latitude == latitude &&
      other.longitude == longitude;

  @override
  int get hashCode => Object.hash(latitude, longitude);
}

/// Resolves the human-readable address for a coordinate pair.
///
/// Riverpod caches this per [LatLngParams] while it has listeners, and
/// [LocationAddressService] itself caches successful lookups for the lifetime
/// of the app, so the same coordinates are never reverse-geocoded twice.
final locationAddressProvider =
    FutureProvider.family<String, LatLngParams>((ref, params) async {
  final service = ref.watch(locationAddressServiceProvider);
  return service.getAddressFromLatLng(params.latitude, params.longitude);
});
