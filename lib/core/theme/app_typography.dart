import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import 'app_colors.dart';

/// Typography configuration using Google Fonts (Plus Jakarta Sans).
abstract final class AppTypography {
  static TextTheme textTheme({required bool isDark}) {
    final base = GoogleFonts.plusJakartaSansTextTheme();
    final primaryColor =
        isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary;
    final secondaryColor =
        isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return base.copyWith(
      displayLarge: base.displayLarge?.copyWith(
        fontSize: 57.sp,
        fontWeight: FontWeight.w700,
        letterSpacing: -0.5,
        color: primaryColor,
      ),
      displayMedium: base.displayMedium?.copyWith(
        fontSize: 45.sp,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      displaySmall: base.displaySmall?.copyWith(
        fontSize: 36.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineLarge: base.headlineLarge?.copyWith(
        fontSize: 32.sp,
        fontWeight: FontWeight.w700,
        color: primaryColor,
      ),
      headlineMedium: base.headlineMedium?.copyWith(
        fontSize: 28.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      headlineSmall: base.headlineSmall?.copyWith(
        fontSize: 24.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleLarge: base.titleLarge?.copyWith(
        fontSize: 22.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleMedium: base.titleMedium?.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      titleSmall: base.titleSmall?.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        color: primaryColor,
      ),
      bodyLarge: base.bodyLarge?.copyWith(
        fontSize: 16.sp,
        fontWeight: FontWeight.w400,
        color: primaryColor,
      ),
      bodyMedium: base.bodyMedium?.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      bodySmall: base.bodySmall?.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w400,
        color: secondaryColor,
      ),
      labelLarge: base.labelLarge?.copyWith(
        fontSize: 14.sp,
        fontWeight: FontWeight.w600,
        letterSpacing: 0.5,
      ),
      labelMedium: base.labelMedium?.copyWith(
        fontSize: 12.sp,
        fontWeight: FontWeight.w500,
      ),
      labelSmall: base.labelSmall?.copyWith(
        fontSize: 11.sp,
        fontWeight: FontWeight.w500,
        letterSpacing: 0.5,
      ),
    );
  }
}
