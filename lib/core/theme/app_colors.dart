import 'package:flutter/material.dart';

/// HomeGenny brand color palette — Orange + Blue theme.
abstract final class AppColors {
  // Brand — Orange (primary)
  static const Color primary = Color(0xFFF97316);
  static const Color primaryLight = Color(0xFFFB923C);
  static const Color primaryDark = Color(0xFFEA580C);
  static const Color primaryContainer = Color(0xFFFFEDD5);

  // Brand — Blue (secondary)
  static const Color secondary = Color(0xFF2563EB);
  static const Color secondaryLight = Color(0xFF3B82F6);
  static const Color secondaryDark = Color(0xFF1D4ED8);
  static const Color secondaryContainer = Color(0xFFDBEAFE);

  static const Color accent = Color(0xFF06B6D4);

  // Semantic
  static const Color success = Color(0xFF22C55E);
  static const Color warning = Color(0xFFF59E0B);
  static const Color error = Color(0xFFEF4444);
  static const Color info = Color(0xFF3B82F6);

  // Light theme surfaces
  static const Color lightBackground = Color(0xFFF8FAFC);
  static const Color lightSurface = Color(0xFFFFFFFF);
  static const Color lightSurfaceVariant = Color(0xFFF1F5F9);
  static const Color lightBorder = Color(0xFFE2E8F0);
  static const Color lightTextPrimary = Color(0xFF0F172A);
  static const Color lightTextSecondary = Color(0xFF64748B);
  static const Color lightTextHint = Color(0xFF94A3B8);

  // Dark theme surfaces
  static const Color darkBackground = Color(0xFF0B1120);
  static const Color darkSurface = Color(0xFF111827);
  static const Color darkSurfaceVariant = Color(0xFF1E293B);
  static const Color darkBorder = Color(0xFF334155);
  static const Color darkTextPrimary = Color(0xFFF8FAFC);
  static const Color darkTextSecondary = Color(0xFF94A3B8);
  static const Color darkTextHint = Color(0xFF64748B);

  // Gradients
  static const LinearGradient primaryGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, primaryLight],
  );

  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [primary, secondary],
  );

  static const LinearGradient authGradient = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [secondaryDark, primaryDark, primary],
  );

  static const LinearGradient blueGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [secondary, secondaryLight],
  );
}
