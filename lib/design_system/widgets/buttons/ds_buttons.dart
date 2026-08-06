import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_durations.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_shadows.dart';
import '../../tokens/app_spacing.dart';

enum DsButtonSize { small, medium, large }

/// Shared button internals for the design system.
class DsButtonBase extends StatelessWidget {
  const DsButtonBase({
    super.key,
    required this.label,
    required this.onPressed,
    required this.child,
    this.isLoading = false,
    this.isExpanded = true,
    this.height,
    this.padding,
    this.decoration,
    this.foregroundColor = Colors.white,
    this.border,
  });

  final String label;
  final VoidCallback? onPressed;
  final Widget child;
  final bool isLoading;
  final bool isExpanded;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final BoxDecoration? decoration;
  final Color foregroundColor;
  final BoxBorder? border;

  @override
  Widget build(BuildContext context) {
    final buttonHeight = height ?? AppSpacing.buttonHeight;

    final content = AnimatedContainer(
      duration: AppDurations.normal,
      height: buttonHeight,
      padding: padding ?? EdgeInsets.symmetric(horizontal: AppSpacing.xl),
      decoration: decoration,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: isLoading ? null : onPressed,
          borderRadius: AppRadius.mdAll,
          child: Center(
            child: isLoading
                ? SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                      strokeWidth: 2.5,
                      color: foregroundColor,
                    ),
                  )
                : child,
          ),
        ),
      ),
    )
        .animate(target: onPressed == null || isLoading ? 0 : 1)
        .scale(
          begin: const Offset(1, 1),
          end: const Offset(0.98, 0.98),
          duration: AppDurations.fast,
        );

    if (!isExpanded) return content;
    return SizedBox(width: double.infinity, child: content);
  }
}

/// Primary action button — Orange brand color.
class DsPrimaryButton extends StatelessWidget {
  const DsPrimaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
    this.size = DsButtonSize.medium,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;
  final DsButtonSize size;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      height: _height,
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        color: onPressed == null
            ? AppColors.primary.withValues(alpha: 0.4)
            : AppColors.primary,
        borderRadius: AppRadius.mdAll,
        boxShadow: onPressed == null ? null : AppShadows.button(isDark: isDark),
      ),
      child: _buildContent(Colors.white),
    );
  }

  double get _height => switch (size) {
        DsButtonSize.small => 44,
        DsButtonSize.medium => AppSpacing.buttonHeight,
        DsButtonSize.large => 56,
      };

  Widget _buildContent(Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (icon != null) ...[
          Icon(icon, size: 20, color: color),
          SizedBox(width: AppSpacing.xs),
        ],
        Text(
          label,
          style: TextStyle(
            color: color,
            fontWeight: FontWeight.w600,
            fontSize: size == DsButtonSize.small ? 14 : 16,
          ),
        ),
      ],
    );
  }
}

/// Secondary action button — Blue brand color.
class DsSecondaryButton extends StatelessWidget {
  const DsSecondaryButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;

  @override
  Widget build(BuildContext context) {
    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        color: onPressed == null
            ? AppColors.secondary.withValues(alpha: 0.4)
            : AppColors.secondary,
        borderRadius: AppRadius.mdAll,
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: context.theme.cardColor),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(color: context.theme.cardColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Outline button with orange border.
class DsOutlineButton extends StatelessWidget {
  const DsOutlineButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
    this.color,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      foregroundColor: accent,
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
        borderRadius: AppRadius.mdAll,
        border: Border.all(color: accent),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: accent),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(
              color: accent,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}

/// Gradient button — Orange to Blue brand gradient.
class DsGradientButton extends StatelessWidget {
  const DsGradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.isLoading = false,
    this.icon,
    this.isExpanded = true,
    this.gradient,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool isLoading;
  final IconData? icon;
  final bool isExpanded;
  final Gradient? gradient;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return DsButtonBase(
      label: label,
      onPressed: onPressed,
      isLoading: isLoading,
      isExpanded: isExpanded,
      foregroundColor: Colors.white,
      decoration: BoxDecoration(
        gradient: onPressed == null
            ? LinearGradient(
                colors: [
                  AppColors.primary.withValues(alpha: 0.4),
                  AppColors.secondary.withValues(alpha: 0.4),
                ],
              )
            : (gradient ?? AppColors.brandGradient),
        borderRadius: AppRadius.mdAll,
        boxShadow: onPressed == null ? null : AppShadows.button(isDark: isDark),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 20, color: context.theme.cardColor),
            SizedBox(width: AppSpacing.xs),
          ],
          Text(
            label,
            style: TextStyle(color: context.theme.cardColor,
              fontWeight: FontWeight.w600,
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }
}
