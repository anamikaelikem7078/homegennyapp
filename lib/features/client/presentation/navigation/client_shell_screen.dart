import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/widgets/layout/ds_role_layout.dart';

/// Client shell with bottom navigation (tablet uses rail).
class ClientShellScreen extends StatelessWidget {
  const ClientShellScreen({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  static const _items = [
    DsBottomNavItem(
      icon: Icons.home_outlined,
      selectedIcon: Icons.home_rounded,
      label: 'Home',
    ),
    DsBottomNavItem(
      icon: Icons.people_outline,
      selectedIcon: Icons.people_alt,
      label: 'Staff',
    ),
    DsBottomNavItem(
      icon: Icons.payments_outlined,
      selectedIcon: Icons.payments_rounded,
      label: 'Pay',
    ),
    DsBottomNavItem(
      icon: Icons.settings_outlined,
      selectedIcon: Icons.settings_rounded,
      label: 'Settings',
    ),
    DsBottomNavItem(
      icon: Icons.account_circle_outlined,
      selectedIcon: Icons.account_circle_rounded,
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
