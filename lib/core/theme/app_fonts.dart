import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Font helpers shared by screens that build text styles inline.
abstract final class AppFonts {
  /// Display / heading style — heavy, tightly-tracked Plus Jakarta Sans,
  /// matching the headline on the login and sign-up screens.
  ///
  /// Weights lighter than w700 are bumped to w800 so headings keep their
  /// punch regardless of what the call site asked for.
  static TextStyle display({
    TextStyle? textStyle,
    Color? color,
    double? fontSize,
    FontWeight? fontWeight,
    FontStyle? fontStyle,
    double? letterSpacing,
    double? height,
  }) {
    final weight = (fontWeight == null || fontWeight.value < 700)
        ? FontWeight.w800
        : fontWeight;
    return GoogleFonts.plusJakartaSans(
      textStyle: textStyle,
      color: color,
      fontSize: fontSize,
      fontWeight: weight,
      fontStyle: fontStyle,
      letterSpacing: letterSpacing ?? -0.4,
      height: height,
    );
  }
}
