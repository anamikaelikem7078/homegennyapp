import 'package:flutter/material.dart';

import '../../core/theme/app_colors.dart';

/// Soft shadow tokens for elevated surfaces.
abstract final class AppShadows {
  static List<BoxShadow> soft({bool isDark = false}) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.35)
              : AppColors.navy.withValues(alpha: 0.08),
          blurRadius: 28,
          offset: const Offset(0, 10),
        ),
      ];

  static List<BoxShadow> card({bool isDark = false}) => [
        BoxShadow(
          color: isDark
              ? Colors.black.withValues(alpha: 0.4)
              : AppColors.navy.withValues(alpha: 0.06),
          blurRadius: 20,
          offset: const Offset(0, 6),
        ),
      ];

  static List<BoxShadow> button({bool isDark = false}) => [
        BoxShadow(
          color: AppColors.primary.withValues(alpha: isDark ? 0.25 : 0.35),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ];
}
