/// Application configuration flags (compile-time environment).
abstract final class AppConfig {
  /// When true, repositories use dummy/JSON datasources instead of remote API.
  static const bool useDummyApi = bool.fromEnvironment(
    'USE_DUMMY_API',
    defaultValue: true,
  );

  /// When true, repositories read/write Hive offline cache.
  static const bool enableOfflineCache = bool.fromEnvironment(
    'ENABLE_OFFLINE_CACHE',
    defaultValue: true,
  );

  static const String googleMapsApiKey = String.fromEnvironment(
    'GOOGLE_MAPS_API_KEY',
    defaultValue: '',
  );
}
