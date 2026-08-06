/// Global application constants.
abstract final class AppConstants {
  static const String appName = 'HomeGenny';
  static const String appVersion = '1.0.0';
  static const int minSupportedVersionCode = 1;

  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration apiTimeout = Duration(seconds: 30);
  static const Duration connectTimeout = Duration(seconds: 15);
  static const Duration receiveTimeout = Duration(seconds: 30);

  static const int otpLength = 6;
  static const int otpResendSeconds = 60;

  static const String defaultLocale = 'en';
}
