import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

abstract final class RmTheme {
  // Brand Colors
  static const Color offWhite = Color(0xFFF6F8FC);
  static const Color electricBlue = Color(0xFF1A56FF);
  static const Color electricBlueLight = Color(0xFF2F6BFF);

  // Orange accent for icons (matches login / sign-up)
  static const Color iconAccent = AppColors.secondary;
  static const Color iconAccentSoft = AppColors.secondaryContainer;
  static const Color navy = AppColors.navy;
  
  // Semantic Colors
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color crimsonDanger = Color(0xFFE5484D);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Surfaces & Borders
  static const Color cardSurface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF3F5FA);
  static const Color borderSubtle = Color(0xFFE8EBF2);
  
  // Typography
  static TextStyle headline(BuildContext? context) {
    return GoogleFonts.plusJakartaSans(
      color: textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: 24,
      letterSpacing: -0.6,
    );
  }

  static TextStyle title(BuildContext? context) {
    return GoogleFonts.plusJakartaSans(
      color: textPrimary,
      fontWeight: FontWeight.w800,
      fontSize: 20,
      letterSpacing: -0.3,
    );
  }

  static TextStyle body(BuildContext? context) {
    return GoogleFonts.plusJakartaSans(
      color: textSecondary,
      fontWeight: FontWeight.w500,
      fontSize: 14,
    );
  }

  static TextStyle label(BuildContext? context) {
    return GoogleFonts.plusJakartaSans(
      color: textPrimary,
      fontWeight: FontWeight.w700,
      fontSize: 12,
    );
  }

  // Shadows
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 16,
      offset: Offset(0, 4),
    ),
  ];

  static const List<BoxShadow> sophisticatedShadow = [
    BoxShadow(
      color: Color(0x0F0F172A),
      blurRadius: 20,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x0A1A56FF),
      blurRadius: 30,
      offset: Offset(0, 14),
    ),
  ];

  static const List<BoxShadow> glassmorphismShadow = [
    BoxShadow(
      color: Color(0x14000000),
      blurRadius: 20,
      offset: Offset(0, 8),
    ),
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 40,
      offset: Offset(0, 16),
    ),
  ];
}
