import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/presentation/providers/auth_provider.dart';
import '../../common/presentation/screens/biometric_login_screen.dart';
import '../../common/presentation/screens/forgot_password_screen.dart';
import '../../common/presentation/screens/login_screen.dart';
import '../../common/presentation/screens/no_internet_screen.dart';
import '../../common/presentation/screens/otp_screen.dart';
import '../../common/presentation/screens/session_expired_screen.dart';
import '../../common/presentation/screens/splash_screen.dart';
import '../../common/presentation/screens/update_app_screen.dart';
import '../../common/presentation/screens/chat_screen.dart';
import '../../features/staff/presentation/navigation/staff_router.dart';
import '../../features/rm/presentation/navigation/rm_router.dart';
import '../../features/client/presentation/navigation/client_router.dart';
import '../presentation/screens/error_not_found_screen.dart';
import 'app_routes.dart';
import 'route_helpers.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    redirect: (context, state) {
      final location = state.matchedLocation;
      final isAuthenticated = authState.status == AuthStatus.authenticated;
      final isSessionExpired = authState.status == AuthStatus.sessionExpired;
      final isLoading =
          authState.status == AuthStatus.loading ||
          authState.status == AuthStatus.initial;

      if (location == AppRoutes.splash || isLoading) {
        return null;
      }

      if (isSessionExpired && location != AppRoutes.sessionExpired) {
        return AppRoutes.sessionExpired;
      }

      if (isAuthenticated) {
        if (AppRoutes.authRoutes.contains(location) ||
            location == AppRoutes.splash) {
          return authState.user?.role.dashboardRoute ??
              AppRoutes.clientDashboard;
        }
      }

      return null;
    },
    routes: [
      fadeRoute(
        path: AppRoutes.splash,
        name: 'splash',
        builder: (context, state) => const SplashScreen(),
      ),
      fadeRoute(
        path: AppRoutes.login,
        name: 'login',
        builder: (context, state) => const LoginScreen(),
      ),
      fadeRoute(
        path: AppRoutes.otp,
        name: 'otp',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return OtpScreen(phone: phone);
        },
      ),
      fadeRoute(
        path: AppRoutes.forgotPassword,
        name: 'forgotPassword',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      fadeRoute(
        path: AppRoutes.biometricLogin,
        name: 'biometricLogin',
        builder: (context, state) => const BiometricLoginScreen(),
      ),
      slideRoute(
        path: AppRoutes.sessionExpired,
        name: 'sessionExpired',
        builder: (context, state) => const SessionExpiredScreen(),
      ),
      slideRoute(
        path: AppRoutes.noInternet,
        name: 'noInternet',
        builder: (context, state) => const NoInternetScreen(),
      ),
      slideRoute(
        path: AppRoutes.updateApp,
        name: 'updateApp',
        builder: (context, state) {
          final updateUrl = state.uri.queryParameters['url'];
          return UpdateAppScreen(updateUrl: updateUrl);
        },
      ),
      slideRoute(
        path: AppRoutes.chat,
        name: 'chat',
        builder: (context, state) {
          final recipientName = state.uri.queryParameters['recipientName'];
          final recipientRole = state.uri.queryParameters['recipientRole'];
          final avatarUrl = state.uri.queryParameters['avatarUrl'];
          return ChatScreen(
            recipientName: recipientName,
            recipientRole: recipientRole,
            avatarUrl: avatarUrl,
          );
        },
      ),
      ...staffRoutes,
      ...rmRoutes,
      ...clientRoutes,
    ],
    errorBuilder: (context, state) => ErrorNotFoundScreen(
      message: state.error?.toString() ?? 'Page not found: ${state.uri}',
    ),
  );
});
