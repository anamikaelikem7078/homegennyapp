import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../tokens/app_shadows.dart';

/// Shared decoration helpers for design system widgets.
abstract final class AppDecorations {
  /// White rounded card with a hairline border and soft navy shadow.
  static BoxDecoration softCard(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ?? (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      borderRadius: borderRadius ?? BorderRadius.circular(20),
      border: border ??
          Border.all(
            color: isDark
                ? AppColors.darkBorder
                : AppColors.lightBorder.withValues(alpha: 0.7),
          ),
      boxShadow: AppShadows.card(isDark: isDark),
    );
  }

  /// Rounded orange icon tile (section / list icons).
  static BoxDecoration iconTile({Color? color, double radius = 12}) {
    final c = color ?? AppColors.iconAccent;
    return BoxDecoration(
      color: c.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  /// Filled, borderless input with blue focus ring (login style).
  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hint,
    String? label,
    Widget? prefix,
    Widget? suffix,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final radius = BorderRadius.circular(16);

    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefix,
      suffixIcon: suffix,
      errorText: errorText,
      filled: true,
      fillColor:
          isDark ? AppColors.darkSurfaceVariant : AppColors.lightSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      border: OutlineInputBorder(
        borderRadius: radius,
        borderSide: BorderSide.none,
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: Colors.transparent),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.primary, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: radius,
        borderSide: const BorderSide(color: AppColors.error, width: 1.6),
      ),
    );
  }
}
