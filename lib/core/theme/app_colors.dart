import 'package:flutter/material.dart';

/// HomeGenny brand color palette — Electric Blue brand with Orange icon accent
/// (matches the login / sign-up screens).
abstract final class AppColors {
  // Brand — Electric Blue (primary: buttons, links, focus, selection)
  static const Color primary = Color(0xFF1A56FF);
  static const Color primaryLight = Color(0xFF2F6BFF);
  static const Color primaryDark = Color(0xFF1238B8);
  static const Color primaryContainer = Color(0xFFE8EEFF);

  // Accent — Orange (icons, icon tiles, small highlights)
  static const Color secondary = Color(0xFFF97316);
  static const Color secondaryLight = Color(0xFFFB923C);
  static const Color secondaryDark = Color(0xFFEA580C);
  static const Color secondaryContainer = Color(0xFFFFEDD5);

  /// Alias for icon tint — prefer this name in new code.
  static const Color iconAccent = secondary;
  static const Color iconAccentSoft = secondaryContainer;

  static const Color accent = Color(0xFF06B6D4);

  // Hero / brand extras
  static const Color navy = Color(0xFF0B1B4D);
  static const Color sunYellow = Color(0xFFFFD84D);

  // Semantic
  static const Color success = Color(0xFF16A34A);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFE5484D);
  static const Color info = Color(0xFF1A56FF);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF6F8FC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF3F5FA);
  static const Color lightBorder = Color(0xFFE8EBF2);
  static const Color lightTextPrimary = Color(0xFF111827);
  static const Color lightTextSecondary = Color(0xFF6B7280);
  static const Color lightTextHint = Color(0xFF9CA3AF);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  // Gradients
  /// Button / pill gradient.
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primaryLight, primary, primaryDark],
  );

  /// Hero header gradient (same as login hero).
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [navy, primaryDark, primary],
  );

  static const LinearGradient authGradient = brandGradient;

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  /// Orange gradient for icon tiles.
  static const LinearGradient accentGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondaryLight, secondaryDark],
  );
}
