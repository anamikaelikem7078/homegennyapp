import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';

/// Rounded back button tile used across app bars (matches sign-up screen).
class DsBackButton extends StatelessWidget {
  const DsBackButton({super.key, this.onPressed, this.onDark = false});

  final VoidCallback? onPressed;

  /// Use the translucent white variant on gradient / dark headers.
  final bool onDark;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = onDark
        ? Colors.white.withValues(alpha: 0.16)
        : (isDark ? AppColors.darkSurfaceVariant : Colors.white);
    final border = onDark
        ? Colors.white.withValues(alpha: 0.25)
        : (isDark ? AppColors.darkBorder : AppColors.lightBorder);
    final fg = onDark
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);

    return Center(
      child: Material(
        color: bg,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(14),
          side: BorderSide(color: border),
        ),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onPressed ?? () => Navigator.of(context).maybePop(),
          child: SizedBox(
            width: 40,
            height: 40,
            child: Icon(Icons.arrow_back_ios_new_rounded, size: 16, color: fg),
          ),
        ),
      ),
    );
  }
}

/// Custom app bar with optional gradient and actions.
class DsAppBar extends StatelessWidget implements PreferredSizeWidget {
  const DsAppBar({
    super.key,
    required this.title,
    this.subtitle,
    this.leading,
    this.actions,
    this.showBack = false,
    this.useGradient = false,
    this.centerTitle = false,
    this.onBack,
  });

  final String title;
  final String? subtitle;
  final Widget? leading;
  final List<Widget>? actions;
  final bool showBack;
  final bool useGradient;
  final bool centerTitle;
  final VoidCallback? onBack;

  @override
  Size get preferredSize =>
      Size.fromHeight(subtitle != null ? 76 : kToolbarHeight + 4);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final onDark = useGradient || isDark;
    final titleColor = useGradient
        ? Colors.white
        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary);
    final subColor = useGradient
        ? Colors.white.withValues(alpha: 0.8)
        : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary);

    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      toolbarHeight: preferredSize.height,
      systemOverlayStyle:
          onDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      backgroundColor: useGradient ? Colors.transparent : null,
      flexibleSpace: useGradient
          ? Container(
              decoration: const BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius:
                    BorderRadius.vertical(bottom: Radius.circular(24)),
              ),
            )
          : null,
      foregroundColor: titleColor,
      iconTheme: IconThemeData(color: titleColor),
      actionsIconTheme: IconThemeData(color: titleColor),
      leadingWidth: 64,
      leading: leading ??
          (showBack
              ? Padding(
                  padding: const EdgeInsets.only(left: 16),
                  child: DsBackButton(onPressed: onBack, onDark: useGradient),
                )
              : null),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment:
            centerTitle ? CrossAxisAlignment.center : CrossAxisAlignment.start,
        children: [
          Text(
            title,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 19,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.4,
              color: titleColor,
            ),
          ),
          if (subtitle != null)
            Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                subtitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: subColor,
                ),
              ),
            ),
        ],
      ),
      actions: [...?actions, const SizedBox(width: 8)],
    );
  }
}

/// Floating pill bottom navigation — blue pill indicator behind the active
/// icon with a springy pop, bold blue label (matches login / sign-up style).
class DsBottomNavigation extends StatelessWidget {
  const DsBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
    this.animateIn = true,
  });

  final int currentIndex;
  final List<DsBottomNavItem> items;
  final ValueChanged<int> onTap;

  /// Slide the bar up on first mount. Disable where each page mounts its own
  /// bar (otherwise it replays on every tab switch).
  final bool animateIn;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final muted =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    final bar = SafeArea(
      top: false,
      child: Container(
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 12),
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 8),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(28),
          border: Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0B1B4D).withValues(alpha: 0.10),
              blurRadius: 30,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Row(
          children: [
            for (var i = 0; i < items.length; i++)
              Expanded(
                child: _NavButton(
                  item: items[i],
                  selected: i == currentIndex,
                  muted: muted,
                  onTap: () {
                    if (i != currentIndex) HapticFeedback.selectionClick();
                    onTap(i);
                  },
                ),
              ),
          ],
        ),
      ),
    );
    if (!animateIn) return bar;
    return bar.animate().slideY(
          begin: 1,
          end: 0,
          duration: 500.ms,
          curve: Curves.easeOutCubic,
        );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.selected,
    required this.muted,
    required this.onTap,
  });

  final DsBottomNavItem item;
  final bool selected;
  final Color muted;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: true,
      selected: selected,
      label: item.label,
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AnimatedContainer(
              duration: 260.ms,
              curve: Curves.easeOutCubic,
              width: selected ? 52 : 40,
              height: 32,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(
                        colors: [AppColors.primaryLight, AppColors.primaryDark],
                      )
                    : null,
                borderRadius: BorderRadius.circular(20),
                boxShadow: selected
                    ? [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.35),
                          blurRadius: 12,
                          offset: const Offset(0, 4),
                        ),
                      ]
                    : null,
              ),
              child: AnimatedScale(
                scale: selected ? 1.08 : 1,
                duration: 300.ms,
                curve: Curves.easeOutBack,
                child: Icon(
                  selected ? (item.selectedIcon ?? item.icon) : item.icon,
                  size: 21,
                  color: selected ? Colors.white : muted,
                ),
              ),
            ),
            const SizedBox(height: 4),
            AnimatedDefaultTextStyle(
              duration: 220.ms,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                color: selected ? AppColors.primary : muted,
              ),
              child: Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class DsBottomNavItem {
  const DsBottomNavItem({
    required this.icon,
    required this.label,
    this.selectedIcon,
  });

  final IconData icon;
  final IconData? selectedIcon;
  final String label;
}

/// App drawer with header and menu items.
class DsDrawer extends StatelessWidget {
  const DsDrawer({
    super.key,
    required this.headerTitle,
    this.headerSubtitle,
    this.avatarUrl,
    required this.items,
    this.footer,
  });

  final String headerTitle;
  final String? headerSubtitle;
  final String? avatarUrl;
  final List<DsDrawerItem> items;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: Column(
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.fromLTRB(
              AppSpacing.xl,
              MediaQuery.paddingOf(context).top + AppSpacing.xl,
              AppSpacing.xl,
              AppSpacing.xl,
            ),
            decoration: const BoxDecoration(
              gradient: AppColors.brandGradient,
              borderRadius: BorderRadius.only(
                bottomRight: Radius.circular(28),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                CircleAvatar(
                  radius: 32,
                  backgroundColor: AppColors.sunYellow,
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child: avatarUrl == null
                      ? Text(
                          headerTitle.isNotEmpty
                              ? headerTitle[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.plusJakartaSans(
                            color: AppColors.navy,
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                          ),
                        )
                      : null,
                ),
                SizedBox(height: AppSpacing.md),
                Text(
                  headerTitle,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                if (headerSubtitle != null)
                  Text(
                    headerSubtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontWeight: FontWeight.w500,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: EdgeInsets.all(AppSpacing.sm),
              itemCount: items.length,
              itemBuilder: (context, index) {
                final item = items[index];
                return ListTile(
                  leading: Container(
                    width: 38,
                    height: 38,
                    decoration: BoxDecoration(
                      color: item.isDestructive
                          ? AppColors.error.withValues(alpha: 0.1)
                          : AppColors.iconAccentSoft,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      item.icon,
                      size: 20,
                      color: item.isDestructive
                          ? AppColors.error
                          : AppColors.iconAccent,
                    ),
                  ),
                  title: Text(
                    item.label,
                    style: TextStyle(
                      color: item.isDestructive ? AppColors.error : null,
                    ),
                  ),
                  selected: item.isSelected,
                  selectedTileColor: AppColors.primaryContainer,
                  onTap: item.onTap,
                );
              },
            ),
          ),
          if (footer != null) footer!,
        ],
      ),
    );
  }
}

class DsDrawerItem {
  const DsDrawerItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.isSelected = false,
    this.isDestructive = false,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final bool isSelected;
  final bool isDestructive;
}

/// Branded floating action button.
class DsFab extends StatelessWidget {
  const DsFab({
    super.key,
    required this.onPressed,
    this.icon = Icons.add_rounded,
    this.label,
    this.useGradient = true,
    this.mini = false,
  });

  final VoidCallback onPressed;
  final IconData icon;
  final String? label;
  final bool useGradient;
  final bool mini;

  @override
  Widget build(BuildContext context) {
    final fab = label != null
        ? FloatingActionButton.extended(
            onPressed: onPressed,
            icon: Icon(icon),
            label: Text(label!),
            elevation: useGradient ? 0 : 6,
            backgroundColor:
                useGradient ? Colors.transparent : AppColors.primary,
            foregroundColor: Colors.white,
          )
        : FloatingActionButton(
            mini: mini,
            onPressed: onPressed,
            elevation: useGradient ? 0 : 6,
            backgroundColor:
                useGradient ? Colors.transparent : AppColors.primary,
            foregroundColor: Colors.white,
            child: Icon(icon),
          );

    if (!useGradient) return fab;

    return DecoratedBox(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(40),
        gradient: AppColors.primaryGradient,
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.4),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: fab,
    ).animate().scale(
          begin: const Offset(0.6, 0.6),
          duration: 400.ms,
          curve: Curves.easeOutBack,
        );
  }
}
