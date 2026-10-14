import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../design_system/tokens/app_breakpoints.dart';

import 'app_colors.dart';

/// Typography configuration using Google Fonts (Plus Jakarta Sans) —
/// heavy, tightly-tracked headings to match the login / sign-up screens.
abstract final class AppTypography {
  static TextTheme textTheme({required bool isDark}) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    final primaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: AppScale.of(57),
        fontWeight: FontWeight.w800,
        letterSpacing: -1.2,
        color: primaryColor,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: AppScale.of(45),
        fontWeight: FontWeight.w800,
        letterSpacing: -1,
        color: primaryColor,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: AppScale.of(36),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primaryColor,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: AppScale.of(32),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.8,
        color: primaryColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: AppScale.of(28),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.6,
        color: primaryColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: AppScale.of(24),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: AppScale.of(20),
        fontWeight: FontWeight.w800,
        letterSpacing: -0.3,
        color: primaryColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: AppScale.of(16),
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: AppScale.of(14),
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: AppScale.of(16),
        fontWeight: FontWeight.w500,
        color: primaryColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: AppScale.of(14),
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: AppScale.of(12),
        fontWeight: FontWeight.w500,
        color: secondaryColor,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: AppScale.of(14),
        fontWeight: FontWeight.w700,
        letterSpacing: 0.2,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: AppScale.of(12),
        fontWeight: FontWeight.w600,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: AppScale.of(11),
        fontWeight: FontWeight.w600,
        letterSpacing: 0.4,
      ),
    );
  }
}
