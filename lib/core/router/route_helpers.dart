import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import 'page_transitions.dart';

/// Slide transition route for detail / push navigation.
GoRoute slideRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  String? name,
  List<RouteBase> routes = const [],
}) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => dsSlidePage(child: builder(context, state)),
    routes: routes,
  );
}

/// Fade transition route for auth flows.
GoRoute fadeRoute({
  required String path,
  required Widget Function(BuildContext context, GoRouterState state) builder,
  String? name,
  List<RouteBase> routes = const [],
}) {
  return GoRoute(
    path: path,
    name: name,
    pageBuilder: (context, state) => dsFadePage(child: builder(context, state)),
    routes: routes,
  );
}
