import 'package:flutter/material.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'app.dart';
import 'core/analytics/analytics_service.dart';
import 'core/crash/crash_reporter.dart';
import 'core/data/seed_data_service.dart';
import 'core/di/injection.dart';
import 'core/utils/logger.dart';

/// Application bootstrap — initializes all services before runApp.
Future<void> bootstrap() async {
  AppLogger.i('Bootstrapping ${DateTime.now()}');

  final analytics = DebugAnalyticsService();
  await analytics.initialize();

  final crashReporter = CrashReporter(analytics: analytics);
  crashReporter.initialize();

  await crashReporter.runGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    // Memory: cap decoded image cache for production stability.
    PaintingBinding.instance.imageCache
      ..maximumSize = 200
      ..maximumSizeBytes = 50 << 20;

    final container = ProviderContainer(
      overrides: [analyticsServiceProvider.overrideWithValue(analytics)],
    );

    try {
      final hiveService = container.read(hiveServiceProvider);
      await hiveService.init();
      AppLogger.i('Hive initialized');

      final seedDataService = SeedDataService(hiveService);
      await seedDataService.seedIfEmpty();

      final firebaseService = container.read(firebaseServiceProvider);
      await firebaseService.initialize();

      final pushService = container.read(pushNotificationServiceProvider);
      await pushService.initialize();
      AppLogger.i('Firebase & push initialized');
    } catch (e, stack) {
      AppLogger.e('Bootstrap partial failure', e, stack);
    }

    runApp(ProviderScope(parent: container, child: const HomeGennyApp()));
  });
}
