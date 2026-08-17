import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmBottomNavigation extends StatelessWidget {
  final int currentIndex;
  final bool isFloating;

  const RmBottomNavigation({
    super.key,
    this.currentIndex = 0,
    this.isFloating = false,
  });

  @override
  Widget build(BuildContext context) {
    if (isFloating) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                Icons.dashboard_outlined,
                'Dashboard',
                0,
                RmRoutes.dashboard,
              ),
              _buildNavItem(
                context,
                Icons.view_kanban_outlined,
                'Pipeline',
                1,
                RmRoutes.pipeline,
              ),
              _buildNavItem(
                context,
                Icons.check_circle_outline,
                'Shifts',
                2,
                RmRoutes.tasks,
              ),
              _buildNavItem(
                context,
                Icons.notifications_outlined,
                'Incidents',
                3,
                RmRoutes.alerts,
              ),
              _buildNavItem(
                context,
                Icons.person_outline,
                'Profile',
                4,
                RmRoutes.profile,
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                context,
                Icons.dashboard_outlined,
                'Dashboard',
                0,
                RmRoutes.dashboard,
              ),
              _buildNavItem(
                context,
                Icons.view_kanban_outlined,
                'Pipeline',
                1,
                RmRoutes.pipeline,
              ),
              _buildNavItem(
                context,
                Icons.check_circle_outline,
                'Shifts',
                2,
                RmRoutes.tasks,
              ),
              _buildNavItem(
                context,
                Icons.notifications_outlined,
                'Incidents',
                3,
                RmRoutes.alerts,
              ),
              _buildNavItem(
                context,
                Icons.person_outline,
                'Profile',
                4,
                RmRoutes.profile,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    BuildContext context,
    IconData icon,
    String label,
    int index,
    String routePath,
  ) {
    final isActive = currentIndex == index;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: () {
          if (!isActive) {
            context.go(routePath);
          }
        },
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          margin: const EdgeInsets.symmetric(horizontal: 4),
          decoration: isActive
              ? BoxDecoration(
                  color: RmTheme.electricBlue,
                  borderRadius: BorderRadius.circular(12),
                )
              : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              currentIndex == index ? _getActiveIcon(icon) : icon,
              color: isActive ? Colors.white : RmTheme.textSecondary,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: RmTheme.label(context).copyWith(
                color: isActive ? Colors.white : RmTheme.textSecondary,
                fontSize: 10,
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

  IconData _getActiveIcon(IconData icon) {
    if (icon == Icons.dashboard_outlined) return Icons.dashboard;
    if (icon == Icons.view_kanban_outlined) return Icons.view_kanban;
    if (icon == Icons.check_circle_outline) return Icons.check_circle;
    if (icon == Icons.notifications_outlined) return Icons.notifications;
    if (icon == Icons.person_outline) return Icons.person;
    return icon;
  }
}
