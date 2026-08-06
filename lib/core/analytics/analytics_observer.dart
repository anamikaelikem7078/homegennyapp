import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../di/injection.dart';

/// Logs screen views to analytics on route changes.
class AnalyticsRouteObserver extends NavigatorObserver {
  AnalyticsRouteObserver(this._container);

  final ProviderContainer _container;

  @override
  void didPush(Route<dynamic> route, Route<dynamic>? previousRoute) {
    _logRoute(route);
    super.didPush(route, previousRoute);
  }

  @override
  void didReplace({Route<dynamic>? newRoute, Route<dynamic>? oldRoute}) {
    if (newRoute != null) _logRoute(newRoute);
    super.didReplace(newRoute: newRoute, oldRoute: oldRoute);
  }

  void _logRoute(Route<dynamic> route) {
    final name = route.settings.name;
    if (name == null || name.isEmpty) return;
    _container.read(analyticsServiceProvider).logScreenView(name);
  }
}

/// GoRouter observer adapter.
class GoRouterAnalyticsObserver extends NavigatorObserver {
  GoRouterAnalyticsObserver(this._container);

  final ProviderContainer _container;

  void logLocation(String location) {
    _container.read(analyticsServiceProvider).logScreenView(location);
  }
}
