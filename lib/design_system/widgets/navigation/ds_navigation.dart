import 'dart:ui';

import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';

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
  Size get preferredSize => Size.fromHeight(subtitle != null ? 72 : kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return AppBar(
      centerTitle: centerTitle,
      elevation: 0,
      scrolledUnderElevation: 0,
      systemOverlayStyle:
          isDark ? SystemUiOverlayStyle.light : SystemUiOverlayStyle.dark,
      backgroundColor: useGradient ? Colors.transparent : null,
      flexibleSpace: useGradient
          ? Container(
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
            )
          : null,
      foregroundColor: useGradient ? Colors.white : null,
      leading: leading ??
          (showBack
              ? IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded),
                  onPressed: onBack ?? () => Navigator.of(context).maybePop(),
                )
              : null),
      title: subtitle != null
          ? Column(
              crossAxisAlignment: centerTitle
                  ? CrossAxisAlignment.center
                  : CrossAxisAlignment.start,
              children: [
                Text(title, style: const TextStyle(fontSize: 18)),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 12,
                    color: useGradient
                        ? Colors.white.withValues(alpha: 0.8)
                        : Theme.of(context).textTheme.bodySmall?.color,
                  ),
                ),
              ],
            )
          : Text(title),
      actions: actions,
    );
  }
}

/// Bottom navigation with floating glassmorphic active states.
class DsBottomNavigation extends StatelessWidget {
  const DsBottomNavigation({
    super.key,
    required this.currentIndex,
    required this.items,
    required this.onTap,
  });

  final int currentIndex;
  final List<DsBottomNavItem> items;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 16),
        decoration: BoxDecoration(
          color: context.theme.cardColor.withValues(alpha: 0.85),
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 20,
              spreadRadius: 0,
              offset: const Offset(0, 8),
            ),
          ],
          border: Border.all(color: context.theme.cardColor.withValues(alpha: 0.5), width: 1.5),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: BackdropFilter(
            filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              child: Row(
                children: items.asMap().entries.map((entry) {
                  final index = entry.key;
                  final item = entry.value;
                  final isSelected = index == currentIndex;

                  return Expanded(
                    child: GestureDetector(
                      onTap: () => onTap(index),
                      behavior: HitTestBehavior.opaque,
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 200),
                        curve: Curves.easeInOut,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        margin: const EdgeInsets.symmetric(horizontal: 12),
                        decoration: BoxDecoration(
                          color: isSelected ? const Color(0xFF1A56FF) : Colors.transparent,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isSelected
                              ? [
                                  BoxShadow(
                                    color: const Color(0xFF1A56FF).withValues(alpha: 0.3),
                                    blurRadius: 12,
                                    spreadRadius: 0,
                                    offset: const Offset(0, 4),
                                  ),
                                ]
                              : [],
                        ),
                        child: Icon(
                          isSelected ? (item.selectedIcon ?? item.icon) : item.icon,
                          color: isSelected ? Colors.white : const Color(0xFF4B5563),
                          size: 24,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
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
      child: SafeArea(
        child: Column(
          children: [
            Container(
              width: double.infinity,
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 32,
                    backgroundColor: context.theme.cardColor.withValues(alpha: 0.2),
                    backgroundImage:
                        avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                    child: avatarUrl == null
                        ? Text(
                            headerTitle.isNotEmpty
                                ? headerTitle[0].toUpperCase()
                                : '?',
                            style: TextStyle(color: context.theme.cardColor,
                              fontSize: 24,
                              fontWeight: FontWeight.w700,
                            ),
                          )
                        : null,
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(
                    headerTitle,
                    style: TextStyle(color: context.theme.cardColor,
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  if (headerSubtitle != null)
                    Text(
                      headerSubtitle!,
                      style: TextStyle(
                        color: context.theme.cardColor.withValues(alpha: 0.85),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                padding: EdgeInsets.symmetric(vertical: AppSpacing.sm),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return ListTile(
                    leading: Icon(
                      item.icon,
                      color: item.isDestructive
                          ? AppColors.error
                          : AppColors.primary,
                    ),
                    title: Text(
                      item.label,
                      style: TextStyle(
                        color: item.isDestructive ? AppColors.error : null,
                      ),
                    ),
                    selected: item.isSelected,
                    onTap: item.onTap,
                  );
                },
              ),
            ),
            ?footer,
          ],
        ),
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
    if (label != null) {
      return FloatingActionButton.extended(
        onPressed: onPressed,
        icon: Icon(icon),
        label: Text(label!),
        backgroundColor: useGradient ? null : AppColors.primary,
        foregroundColor: Colors.white,
      );
    }

    return Container(
      decoration: useGradient
          ? BoxDecoration(
              shape: BoxShape.circle,
              gradient: AppColors.brandGradient,
            )
          : null,
      child: FloatingActionButton(
        mini: mini,
        onPressed: onPressed,
        backgroundColor: useGradient ? Colors.transparent : AppColors.primary,
        foregroundColor: Colors.white,
        elevation: useGradient ? 0 : 4,
        child: Icon(icon),
      ),
    );
  }
}
