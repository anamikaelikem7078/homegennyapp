import 'app_breakpoints.dart';

/// Consistent spacing scale for the design system.
abstract final class AppSpacing {
  static double get xxs => AppScale.of(4);
  static double get xs => AppScale.of(8);
  static double get sm => AppScale.of(12);
  static double get md => AppScale.of(16);
  static double get lg => AppScale.of(20);
  static double get xl => AppScale.of(24);
  static double get xxl => AppScale.of(32);
  static double get xxxl => AppScale.of(40);
  static double get huge => AppScale.of(48);

  static double get buttonHeight => AppScale.of(52);
  static double get inputHeight => AppScale.of(52);
  static double get iconSm => AppScale.of(18);
  static double get iconMd => AppScale.of(22);
  static double get iconLg => AppScale.of(28);
}
