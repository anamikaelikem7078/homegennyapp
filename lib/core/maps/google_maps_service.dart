import '../config/app_config.dart';
import '../network/dio_client.dart';

/// Google Maps integration service (backend-ready).
/// Uses backend geocoding proxy; swap for google_maps_flutter in UI layer.
class GoogleMapsService {
  GoogleMapsService({required DioClient dioClient}) : _dio = dioClient;

  final DioClient _dio;

  String get apiKey => AppConfig.googleMapsApiKey;

  /// Reverse geocode coordinates via backend proxy.
  Future<Map<String, dynamic>> reverseGeocode({
    required double latitude,
    required double longitude,
  }) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/maps/reverse-geocode',
      queryParameters: {
        'lat': latitude,
        'lng': longitude,
      },
    );
    return response.data ?? {};
  }

  /// Geocode address string via backend proxy.
  Future<Map<String, dynamic>> geocode({required String address}) async {
    final response = await _dio.get<Map<String, dynamic>>(
      '/maps/geocode',
      queryParameters: {'address': address},
    );
    return response.data ?? {};
  }
}
