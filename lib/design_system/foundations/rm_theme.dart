import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/theme/app_colors.dart';

abstract final class RmTheme {
  // Brand Colors
  static const Color offWhite = Color(0xFFFBF9F8);
  static const Color electricBlue = Color(0xFF1A56FF);
  static const Color electricBlueLight = Color(0xFF4A7BFF);
  
  // Semantic Colors
  static const Color emeraldGreen = Color(0xFF10B981);
  static const Color amberWarning = Color(0xFFF59E0B);
  static const Color crimsonDanger = Color(0xFFDC2626);
  
  // Text Colors
  static const Color textPrimary = Color(0xFF111827);
  static const Color textSecondary = Color(0xFF6B7280);
  
  // Surfaces & Borders
  static const Color cardSurface = Colors.white;
  static const Color surfaceSecondary = Color(0xFFF3F4F6); // Gray 100
  static const Color borderSubtle = Color(0xFFE5E7EB);
  
  // Typography
  static TextStyle headline(BuildContext? context) {
    return GoogleFonts.libreCaslonText(
      color: textPrimary,
      fontWeight: FontWeight.w600,
      fontSize: 24,
    );
  }

  static TextStyle title(BuildContext? context) {
    return GoogleFonts.libreCaslonText(
      color: electricBlue,
      fontWeight: FontWeight.w600,
      fontSize: 20,
    );
  }

  static TextStyle body(BuildContext? context) {
    return GoogleFonts.inter(
      color: textSecondary,
      fontWeight: FontWeight.w400,
      fontSize: 14,
    );
  }

  static TextStyle label(BuildContext? context) {
    return GoogleFonts.inter(
      color: textPrimary,
      fontWeight: FontWeight.w500,
      fontSize: 12,
    );
  }

  // Shadows
  static const List<BoxShadow> subtleShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> sophisticatedShadow = [
    BoxShadow(
      color: Color(0x0A000000),
      blurRadius: 4,
      offset: Offset(0, 2),
    ),
    BoxShadow(
      color: Color(0x05000000),
      blurRadius: 10,
      offset: Offset(0, 6),
    ),
    BoxShadow(
      color: Color(0x03000000),
      blurRadius: 20,
      offset: Offset(0, 12),
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
