import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../design_system/widgets/layout/ds_role_layout.dart';
import '../../data/services/location_sharing_service.dart';
import '../screens/attendance/location_consent.dart';

/// Staff shell with bottom navigation (tablet uses rail).
class StaffShellScreen extends ConsumerStatefulWidget {
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
  ConsumerState<StaffShellScreen> createState() => _StaffShellScreenState();
}

class _StaffShellScreenState extends ConsumerState<StaffShellScreen> {
  @override
  void initState() {
    super.initState();
    // After an app restart mid-shift, pick location sharing back up.
    if (hasLocationSharingConsent(ref)) {
      ref.read(locationSharingServiceProvider).resumeIfCheckedIn();
    }
    // Never keep sharing after logout.
    ref.listenManual(authProvider, (_, next) {
      if (next.status == AuthStatus.unauthenticated) ref.read(locationSharingServiceProvider).stop();
    });
  }

  @override
  Widget build(BuildContext context) {
    return DsRoleShellScreen(
      navigationShell: widget.navigationShell,
      items: StaffShellScreen._items,
    );
  }
}
