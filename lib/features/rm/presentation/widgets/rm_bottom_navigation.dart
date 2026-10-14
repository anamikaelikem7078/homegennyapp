import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/widgets/navigation/ds_navigation.dart';
import '../navigation/rm_routes.dart';

/// RM bottom navigation — shares the floating pill bar used by the Staff and
/// Client shells so all three roles look the same.
class RmBottomNavigation extends StatelessWidget {
  final int currentIndex;

  /// Kept for API compatibility; the bar always floats now.
  final bool isFloating;

  const RmBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.isFloating = false,
  });

  static const _items = [
    DsBottomNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    DsBottomNavItem(
      icon: Icons.view_kanban_outlined,
      selectedIcon: Icons.view_kanban_rounded,
      label: 'Pipeline',
    ),
    DsBottomNavItem(
      icon: Icons.check_circle_outline_rounded,
      selectedIcon: Icons.check_circle_rounded,
      label: 'Shifts',
    ),
    DsBottomNavItem(
      icon: Icons.notifications_outlined,
      selectedIcon: Icons.notifications_rounded,
      label: 'Incidents',
    ),
    DsBottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  static const _routes = [
    RmRoutes.dashboard,
    RmRoutes.pipeline,
    RmRoutes.tasks,
    RmRoutes.alerts,
    RmRoutes.profile,
  ];

  @override
  Widget build(BuildContext context) {
    return DsBottomNavigation(
      currentIndex: currentIndex,
      items: _items,
      animateIn: false,
      onTap: (i) {
        if (i != currentIndex) context.go(_routes[i]);
      },
    );
  }
}
