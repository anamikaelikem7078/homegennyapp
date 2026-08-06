import 'package:flutter_screenutil/flutter_screenutil.dart';

/// Consistent spacing scale for the design system.
abstract final class AppSpacing {
  static double get xxs => 4.w;
  static double get xs => 8.w;
  static double get sm => 12.w;
  static double get md => 16.w;
  static double get lg => 20.w;
  static double get xl => 24.w;
  static double get xxl => 32.w;
  static double get xxxl => 40.w;
  static double get huge => 48.w;

  static double get buttonHeight => 52.h;
  static double get inputHeight => 52.h;
  static double get iconSm => 18.w;
  static double get iconMd => 22.w;
  static double get iconLg => 28.w;
}
