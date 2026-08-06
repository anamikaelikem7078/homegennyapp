// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for English (`en`).
class AppLocalizationsEn extends AppLocalizations {
  AppLocalizationsEn([String locale = 'en']) : super(locale);

  @override
  String get appName => 'HomeGenny';

  @override
  String get splashTagline => 'Your home, simplified';

  @override
  String get loginTitle => 'Welcome back';

  @override
  String get loginSubtitle => 'Sign in to continue to HomeGenny';

  @override
  String get emailLabel => 'Email address';

  @override
  String get passwordLabel => 'Password';

  @override
  String get loginButton => 'Sign In';

  @override
  String get forgotPassword => 'Forgot password?';

  @override
  String get orContinueWith => 'Or continue with';

  @override
  String get biometricLogin => 'Biometric Login';

  @override
  String get otpTitle => 'Verify OTP';

  @override
  String otpSubtitle(String phone) {
    return 'Enter the 6-digit code sent to $phone';
  }

  @override
  String get verifyOtp => 'Verify';

  @override
  String get resendOtp => 'Resend code';

  @override
  String resendOtpIn(int seconds) {
    return 'Resend in ${seconds}s';
  }

  @override
  String get forgotPasswordTitle => 'Reset password';

  @override
  String get forgotPasswordSubtitle =>
      'Enter your email and we\'ll send reset instructions';

  @override
  String get sendResetLink => 'Send reset link';

  @override
  String get backToLogin => 'Back to login';

  @override
  String get biometricTitle => 'Quick sign in';

  @override
  String get biometricSubtitle =>
      'Use your fingerprint or face to sign in securely';

  @override
  String get useBiometric => 'Authenticate';

  @override
  String get usePasswordInstead => 'Use password instead';

  @override
  String get sessionExpiredTitle => 'Session expired';

  @override
  String get sessionExpiredMessage =>
      'Your session has expired. Please sign in again to continue.';

  @override
  String get signInAgain => 'Sign in again';

  @override
  String get noInternetTitle => 'No internet connection';

  @override
  String get noInternetMessage => 'Please check your connection and try again.';

  @override
  String get retry => 'Retry';

  @override
  String get updateAppTitle => 'Update required';

  @override
  String get updateAppMessage =>
      'A new version of HomeGenny is available. Please update to continue.';

  @override
  String get updateNow => 'Update now';

  @override
  String get staffDashboard => 'Staff Dashboard';

  @override
  String get rmDashboard => 'RM Dashboard';

  @override
  String get clientDashboard => 'Client Dashboard';

  @override
  String get logout => 'Logout';

  @override
  String get loading => 'Loading...';

  @override
  String get errorGeneric => 'Something went wrong. Please try again.';

  @override
  String get emailRequired => 'Email is required';

  @override
  String get emailInvalid => 'Enter a valid email';

  @override
  String get passwordRequired => 'Password is required';

  @override
  String get passwordTooShort => 'Password must be at least 6 characters';

  @override
  String get otpRequired => 'OTP is required';

  @override
  String get otpInvalid => 'Enter a valid 6-digit OTP';

  @override
  String get offlineBanner =>
      'You are offline. Showing cached data where available.';

  @override
  String get languageSettings => 'Language';

  @override
  String get themeSettings => 'Theme';

  @override
  String get darkMode => 'Dark mode';

  @override
  String get lightMode => 'Light mode';

  @override
  String get systemDefault => 'System default';
}
