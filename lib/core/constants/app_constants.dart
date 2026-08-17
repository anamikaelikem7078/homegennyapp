/// Global application constants.
abstract final class AppConstants {
  static const String appName = 'HomeGenny';
  static const String appVersion = '1.0.0';
  static const int minSupportedVersionCode = 1;

  static const Duration splashMinDuration = Duration(seconds: 2);
  static const Duration apiTimeout = Duration(seconds: 60);
  // The live backend (Render free tier) cold-starts when idle — observed
  // needing up to ~90s to respond on a cold hit during this integration.
  // 15s/30s timeouts were aborting requests mid-cold-start, surfacing as a
  // generic undifferentiated network error rather than a real API failure.
  static const Duration connectTimeout = Duration(seconds: 20);
  static const Duration receiveTimeout = Duration(seconds: 60);

  static const int otpLength = 6;
  static const int otpResendSeconds = 60;

  static const String defaultLocale = 'en';
}
