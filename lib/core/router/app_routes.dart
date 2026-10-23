/// Application route path constants.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String register = '/register';
  static const String otp = '/otp';
  /// Sign-up: "Client or Staff?" for a new number (`?phone=`).
  static const String signupRole = '/signup/role';
  static const String forgotPassword = '/forgot-password';
  static const String resetPassword = '/reset-password';
  static const String biometricLogin = '/biometric-login';
  static const String sessionExpired = '/session-expired';
  static const String changePassword = '/change-password';
  static const String noInternet = '/no-internet';
  static const String updateApp = '/update-app';
  static const String chat = '/chat';

  static const String staffDashboard = '/staff/home';
  static const String rmDashboard = '/rm/dashboard';
  static const String clientDashboard = '/client/dashboard';

  // "Complete your profile" wizards (§6, §8 of the registration brief).
  // Both take `?step=<index>` to open at the first missing field.
  static const String staffCompleteProfile = '/staff/complete-profile';
  static const String clientCompleteProfile = '/client/complete-profile';

  static const List<String> authRoutes = [
    login,
    register,
    otp,
    signupRole,
    forgotPassword,
    resetPassword,
    changePassword,
    biometricLogin,
  ];

  static const List<String> publicRoutes = [
    splash,
    login,
    register,
    otp,
    signupRole,
    forgotPassword,
    resetPassword,
    changePassword,
    biometricLogin,
    sessionExpired,
    noInternet,
    updateApp,
  ];
}
