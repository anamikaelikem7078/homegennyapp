import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Responsive breakpoints for Staff, RM, and Client modules.
abstract final class AppBreakpoints {
  static const double mobile = 600;
  static const double tablet = 900;
  static const double desktop = 1200;

  static bool isMobile(BuildContext context) =>
      MediaQuery.sizeOf(context).width < mobile;

  static bool isTablet(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return width >= mobile && width < desktop;
  }

  static bool isDesktop(BuildContext context) =>
      MediaQuery.sizeOf(context).width >= desktop;

  static double contentMaxWidth(BuildContext context) {
    if (isDesktop(context)) return 1100;
    if (isTablet(context)) return 800;
    return double.infinity;
  }

  static EdgeInsets pagePadding(BuildContext context) {
    if (isDesktop(context)) {
      return const EdgeInsets.symmetric(horizontal: 32, vertical: 24);
    }
    if (isTablet(context)) {
      return const EdgeInsets.symmetric(horizontal: 24, vertical: 20);
    }
    return const EdgeInsets.symmetric(horizontal: 16, vertical: 16);
  }
}

/// Gentle, clamped size scaling for design tokens.
///
/// Unlike raw ScreenUtil `.w/.h/.r`, this never shrinks UI on landscape
/// phones or blows it up on tablets — sizes stay within ±10% of the design.
abstract final class AppScale {
  static double get factor {
    try {
      return ScreenUtil().scaleWidth.clamp(0.9, 1.1).toDouble();
    } catch (_) {
      return 1;
    }
  }

  static double of(num value) => value * factor;
}
