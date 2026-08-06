import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/widgets/layout/ds_role_layout.dart';

/// RM shell with bottom navigation (tablet uses rail).
class RmShellScreen extends StatelessWidget {
  const RmShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    DsBottomNavItem(
      icon: Icons.dashboard_outlined,
      selectedIcon: Icons.dashboard_rounded,
      label: 'Dashboard',
    ),
    DsBottomNavItem(
      icon: Icons.people_outline_rounded,
      selectedIcon: Icons.people_rounded,
      label: 'Staff',
    ),
    DsBottomNavItem(
      icon: Icons.home_work_outlined,
      selectedIcon: Icons.home_work_rounded,
      label: 'Clients',
    ),
    DsBottomNavItem(
      icon: Icons.analytics_outlined,
      selectedIcon: Icons.analytics_rounded,
      label: 'Reports',
    ),
    DsBottomNavItem(
      icon: Icons.person_outline_rounded,
      selectedIcon: Icons.person_rounded,
      label: 'Profile',
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return DsRoleShellScreen(
      navigationShell: navigationShell,
      items: _items,
    );
  }
}
