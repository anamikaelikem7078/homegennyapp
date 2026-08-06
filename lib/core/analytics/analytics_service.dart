import '../utils/logger.dart';

/// Analytics abstraction — swap implementation for Firebase Analytics, Mixpanel, etc.
abstract interface class AnalyticsService {
  Future<void> initialize();
  Future<void> logEvent(String name, {Map<String, Object?>? parameters});
  Future<void> setUserId(String? userId);
  Future<void> setUserProperty(String name, String? value);
  Future<void> logScreenView(String screenName, {String? screenClass});
}

/// Debug analytics that logs to console — production-ready interface.
class DebugAnalyticsService implements AnalyticsService {
  bool _initialized = false;

  @override
  Future<void> initialize() async {
    _initialized = true;
    AppLogger.i('Analytics initialized (debug)');
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {
    if (!_initialized) return;
    AppLogger.d('Analytics event: $name ${parameters ?? ''}');
  }

  @override
  Future<void> setUserId(String? userId) async {
    AppLogger.d('Analytics userId: $userId');
  }

  @override
  Future<void> setUserProperty(String name, String? value) async {
    AppLogger.d('Analytics property: $name = $value');
  }

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await logEvent('screen_view', parameters: {
      'screen_name': screenName,
      if (screenClass != null) 'screen_class': screenClass,
    });
  }
}

/// Firebase Analytics adapter stub — wire when firebase_analytics is added.
class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService();

  @override
  Future<void> initialize() async {
    AppLogger.i('Firebase Analytics ready (stub — add firebase_analytics package)');
  }

  @override
  Future<void> logEvent(String name, {Map<String, Object?>? parameters}) async {}

  @override
  Future<void> setUserId(String? userId) async {}

  @override
  Future<void> setUserProperty(String name, String? value) async {}

  @override
  Future<void> logScreenView(String screenName, {String? screenClass}) async {
    await logEvent('screen_view', parameters: {'screen_name': screenName});
  }
}
