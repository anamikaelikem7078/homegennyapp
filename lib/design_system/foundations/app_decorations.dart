import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';
import '../tokens/app_radius.dart';
import '../tokens/app_shadows.dart';

/// Shared decoration helpers for design system widgets.
abstract final class AppDecorations {
  static BoxDecoration softCard(
    BuildContext context, {
    Color? color,
    BorderRadius? borderRadius,
    Border? border,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return BoxDecoration(
      color: color ??
          (isDark ? AppColors.darkSurface : AppColors.lightSurface),
      borderRadius: borderRadius ?? AppRadius.lgAll,
      border: border ??
          Border.all(
            color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          ),
      boxShadow: AppShadows.card(isDark: isDark),
    );
  }

  static InputDecoration inputDecoration(
    BuildContext context, {
    String? hint,
    String? label,
    Widget? prefix,
    Widget? suffix,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final borderColor =
        isDark ? AppColors.darkBorder : AppColors.lightBorder;

    return InputDecoration(
      hintText: hint,
      labelText: label,
      prefixIcon: prefix,
      suffixIcon: suffix,
      errorText: errorText,
      filled: true,
      fillColor: isDark
          ? AppColors.darkSurfaceVariant
          : AppColors.lightSurfaceVariant,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: borderColor),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: BorderSide(color: borderColor),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.primary, width: 2),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: AppRadius.mdAll,
        borderSide: const BorderSide(color: AppColors.error),
      ),
    );
  }
}
