import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_breakpoints.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_shadows.dart';
import '../../tokens/app_spacing.dart';
import '../navigation/ds_navigation.dart';
export '../navigation/ds_navigation.dart' show DsBottomNavItem;
import '../chips/ds_status_chip.dart';

/// Menu tile visual style — consolidates staff / RM / client variants.
enum DsMenuTileStyle { plain, gradient, premium }

/// Responsive content wrapper — centers on tablet/desktop.
class DsResponsiveCenter extends StatelessWidget {
  const DsResponsiveCenter({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.topCenter,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: AppBreakpoints.contentMaxWidth(context)),
        child: child,
      ),
    );
  }
}

/// Unified detail-page scaffold for all roles.
class DsPageScaffold extends StatelessWidget {
  const DsPageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.subtitle,
    this.actions,
    this.floatingActionButton,
    this.showBack = true,
    this.useGradient = false,
    this.semanticLabel,
  });

  final String title;
  final String? subtitle;
  final Widget body;
  final List<Widget>? actions;
  final Widget? floatingActionButton;
  final bool showBack;
  final bool useGradient;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: semanticLabel ?? title,
      child: Scaffold(
        appBar: DsAppBar(
          title: title,
          subtitle: subtitle,
          showBack: showBack,
          actions: actions,
          useGradient: useGradient,
        ),
        floatingActionButton: floatingActionButton,
        body: SafeArea(
          child: DsResponsiveCenter(
            child: Padding(
              padding: AppBreakpoints.pagePadding(context),
              child: body,
            ),
          ),
        ),
      ),
    );
  }
}

/// Unified navigation tile.
class DsMenuTile extends StatelessWidget {
  const DsMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.badge,
    this.accentColor,
    this.style = DsMenuTileStyle.plain,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final String? badge;
  final Color? accentColor;
  final DsMenuTileStyle style;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.iconAccent;

    return Semantics(
      button: true,
      label: subtitle != null ? '$title, $subtitle' : title,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          margin: EdgeInsets.only(bottom: AppSpacing.sm),
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.softCard(context),
          child: Row(
            children: [
              _IconBox(icon: icon, accent: accent, style: style),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleSmall),
                    if (subtitle != null)
                      Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                  ],
                ),
              ),
              if (badge != null) ...[
                DsStatusChip(label: badge!, type: DsStatusType.warning),
                SizedBox(width: AppSpacing.xs),
              ],
              trailing ?? Icon(Icons.chevron_right_rounded, color: Theme.of(context).colorScheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

class _IconBox extends StatelessWidget {
  const _IconBox({required this.icon, required this.accent, required this.style});

  final IconData icon;
  final Color accent;
  final DsMenuTileStyle style;

  @override
  Widget build(BuildContext context) {
    return switch (style) {
      DsMenuTileStyle.plain => Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            color: accent.withValues(alpha: 0.12),
            borderRadius: AppRadius.mdAll,
          ),
          child: Icon(icon, color: accent),
        ),
      DsMenuTileStyle.gradient || DsMenuTileStyle.premium => Container(
          padding: EdgeInsets.all(AppSpacing.sm),
          decoration: BoxDecoration(
            gradient: style == DsMenuTileStyle.premium
                ? AppColors.accentGradient
                : LinearGradient(colors: [accent, accent.withValues(alpha: 0.7)]),
            borderRadius: AppRadius.mdAll,
            boxShadow: style == DsMenuTileStyle.premium ? AppShadows.soft() : null,
          ),
          child: Icon(icon, color: context.theme.cardColor, size: 22),
        ),
    };
  }
}

/// Section header with optional action.
class DsSectionHeader extends StatelessWidget {
  const DsSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Row(
        children: [
          Expanded(child: Text(title, style: Theme.of(context).textTheme.titleMedium)),
          if (actionLabel != null && onAction != null)
            TextButton(onPressed: onAction, child: Text(actionLabel!)),
        ],
      ),
    );
  }
}

/// KPI stat card.
class DsKpiCard extends StatelessWidget {
  const DsKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.secondary;

    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.softCard(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: AppDecorations.iconTile(color: accent),
                child: Icon(icon, color: accent, size: 22),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                    ),
              ),
              Text(label, style: Theme.of(context).textTheme.bodySmall),
              if (subtitle != null)
                Text(subtitle!, style: Theme.of(context).textTheme.bodySmall?.copyWith(color: accent)),
            ],
          ),
        ),
      ),
    );
  }
}

/// Hero-wrapped avatar for shared-element transitions.
class DsHeroAvatar extends StatelessWidget {
  const DsHeroAvatar({
    super.key,
    required this.tag,
    required this.name,
    this.radius = 28,
    this.imageUrl,
  });

  final String tag;
  final String name;
  final double radius;
  final String? imageUrl;

  @override
  Widget build(BuildContext context) {
    return Hero(
      tag: tag,
      child: Material(
        color: Colors.transparent,
        child: CircleAvatar(
          radius: radius,
          backgroundColor: AppColors.primary.withValues(alpha: 0.15),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null
              ? Text(
                  name.isNotEmpty ? name[0].toUpperCase() : '?',
                  style: TextStyle(
                    fontSize: radius * 0.75,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                )
              : null,
        ),
      ),
    );
  }
}

/// Shared role shell with bottom navigation.
class DsRoleShellScreen extends StatelessWidget {
  const DsRoleShellScreen({
    super.key,
    required this.navigationShell,
    required this.items,
  });

  final StatefulNavigationShell navigationShell;
  final List<DsBottomNavItem> items;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    final isTablet = AppBreakpoints.isTablet(context) || AppBreakpoints.isDesktop(context);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor, // Ethereal Luxe textured grey-white
      extendBody: true,
      body: isTablet
          ? Row(
              children: [
                Container(
                  decoration: BoxDecoration(
                    color: Colors.white,
                    boxShadow: [
                      BoxShadow(
                        color: AppColors.navy.withValues(alpha: 0.06),
                        blurRadius: 20,
                        offset: const Offset(4, 0),
                      ),
                    ],
                  ),
                  child: SafeArea(
                    right: false,
                    child: NavigationRail(
                      backgroundColor: Colors.white,
                      selectedIndex: navigationShell.currentIndex,
                      onDestinationSelected: _onTap,
                      labelType: NavigationRailLabelType.all,
                      groupAlignment: -0.85,
                      minWidth: 84,
                      indicatorColor: AppColors.primaryContainer,
                      indicatorShape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                      selectedIconTheme: const IconThemeData(color: AppColors.primary, size: 24),
                      unselectedIconTheme: const IconThemeData(color: Color(0xFF94A3B8), size: 23),
                      selectedLabelTextStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primary,
                      ),
                      unselectedLabelTextStyle: const TextStyle(
                        fontFamily: 'Plus Jakarta Sans',
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: Color(0xFF94A3B8),
                      ),
                      leading: Padding(
                        padding: const EdgeInsets.only(top: 8, bottom: 20),
                        child: Container(
                          width: 46,
                          height: 46,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            gradient: AppColors.brandGradient,
                            borderRadius: BorderRadius.circular(15),
                          ),
                          child: const Text(
                            'HG',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                      destinations: items
                          .map(
                            (item) => NavigationRailDestination(
                              icon: Icon(item.icon),
                              selectedIcon: Icon(item.selectedIcon),
                              label: Text(item.label),
                              padding: const EdgeInsets.symmetric(vertical: 4),
                            ),
                          )
                          .toList(),
                    ),
                  ),
                ),
                Expanded(child: navigationShell),
              ],
            )
          : navigationShell,
      bottomNavigationBar: isTablet
          ? null
          : DsBottomNavigation(
              currentIndex: navigationShell.currentIndex,
              onTap: _onTap,
              items: items,
            ),
    );
  }
}
