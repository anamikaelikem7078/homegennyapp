/// Application route path constants.
abstract final class AppRoutes {
  static const String splash = '/';
  static const String login = '/login';
  static const String otp = '/otp';
  static const String forgotPassword = '/forgot-password';
  static const String biometricLogin = '/biometric-login';
  static const String sessionExpired = '/session-expired';
  static const String noInternet = '/no-internet';
  static const String updateApp = '/update-app';
  static const String chat = '/chat';

  static const String staffDashboard = '/staff/home';
  static const String rmDashboard = '/rm/dashboard';
  static const String clientDashboard = '/client/dashboard';

  static const List<String> authRoutes = [
    login,
    otp,
    forgotPassword,
    biometricLogin,
  ];

  static const List<String> publicRoutes = [
    splash,
    login,
    otp,
    forgotPassword,
    biometricLogin,
    sessionExpired,
    noInternet,
    updateApp,
  ];
}
