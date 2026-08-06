import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../analytics/analytics_service.dart';
import '../utils/logger.dart';

/// Global crash and error reporter — production-ready hook for Crashlytics/Sentry.
class CrashReporter {
  CrashReporter({required AnalyticsService analytics}) : _analytics = analytics;

  final AnalyticsService _analytics;

  void initialize() {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      _recordError(details.exception, details.stack, fatal: true);
    };

    PlatformDispatcher.instance.onError = (error, stack) {
      _recordError(error, stack, fatal: true);
      return true;
    };
  }

  Future<void> runGuarded(Future<void> Function() appRunner) async {
    await runZonedGuarded(
      () async => appRunner(),
      (error, stack) => _recordError(error, stack, fatal: true),
    );
  }

  void _recordError(Object error, StackTrace? stack, {required bool fatal}) {
    AppLogger.e('Uncaught error (fatal: $fatal)', error, stack);
    _analytics.logEvent('app_error', parameters: {
      'fatal': fatal,
      'error': error.toString(),
    });
    // TODO: Forward to Firebase Crashlytics / Sentry in production.
  }
}
