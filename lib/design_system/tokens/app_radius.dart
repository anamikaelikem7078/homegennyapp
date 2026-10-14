import 'package:flutter/material.dart';
import 'app_breakpoints.dart';

/// Border radius tokens for rounded UI.
abstract final class AppRadius {
  static double get xs => AppScale.of(8);
  static double get sm => AppScale.of(12);
  static double get md => AppScale.of(16);
  static double get lg => AppScale.of(20);
  static double get xl => AppScale.of(24);
  static double get xxl => AppScale.of(32);
  static double get full => AppScale.of(999);

  static BorderRadius get xsAll => BorderRadius.circular(xs);
  static BorderRadius get smAll => BorderRadius.circular(sm);
  static BorderRadius get mdAll => BorderRadius.circular(md);
  static BorderRadius get lgAll => BorderRadius.circular(lg);
  static BorderRadius get xlAll => BorderRadius.circular(xl);
  static BorderRadius get xxlAll => BorderRadius.circular(xxl);
  static BorderRadius get fullAll => BorderRadius.circular(full);
}
