/// Application configuration flags (compile-time environment).
abstract final class AppConfig {
  /// When true, repositories use dummy/JSON datasources instead of remote API.
  /// Defaults to false — the app talks to the real backend
  /// (`ApiConstants.baseUrl`) out of the box. `RepositoryExecutor.fetch`
  /// only skips the network when a module hasn't wired a `remote:` callback
  /// for a given call, so flipping this default doesn't break screens that
  /// still rely on dummy data — it only stops the flag from *forcing*
  /// dummy data everywhere, which previously caused hardcoded "demo"
  /// login/OTP shortcuts to hijack real accounts using the backend's
  /// documented default password.
  static const bool useDummyApi = bool.fromEnvironment(
    'USE_DUMMY_API',
    defaultValue: false,
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
