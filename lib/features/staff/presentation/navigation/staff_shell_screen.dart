import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/widgets/layout/ds_role_layout.dart';

/// Staff shell with bottom navigation (tablet uses rail).
class StaffShellScreen extends StatelessWidget {
  const StaffShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    DsBottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    DsBottomNavItem(
      icon: Icons.timeline_outlined,
      selectedIcon: Icons.timeline_rounded,
      label: 'Pipeline',
    ),
    DsBottomNavItem(
      icon: Icons.fingerprint_outlined,
      selectedIcon: Icons.fingerprint_rounded,
      label: 'Attendance',
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
