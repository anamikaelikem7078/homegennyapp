import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../common/presentation/providers/auth_provider.dart';
import '../../common/presentation/screens/biometric_login_screen.dart';
import '../../common/presentation/screens/forgot_password_screen.dart';
import '../../common/presentation/screens/reset_password_screen.dart';
import '../../common/presentation/screens/change_password_screen.dart';
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
import '../../common/domain/models/user_role.dart';

final _rootNavigatorKey = GlobalKey<NavigatorState>();

/// Notifies GoRouter to re-run [redirect] on the current location whenever
/// auth state changes, without rebuilding the router itself — rebuilding
/// the GoRouter instance resets its navigation stack back to
/// [AppRoutes.splash], which caused an infinite splash loop every time
/// auth state changed after the initial navigation (e.g. the fetchProfile
/// call following OTP verification).
class _AuthRouterRefreshNotifier extends ChangeNotifier {
  _AuthRouterRefreshNotifier(Ref ref) {
    _subscription = ref.listen<AuthState>(
      authProvider,
      (_, _) => notifyListeners(),
    );
  }

  late final ProviderSubscription<AuthState> _subscription;

  @override
  void dispose() {
    _subscription.close();
    super.dispose();
  }
}

final routerProvider = Provider<GoRouter>((ref) {
  final refreshNotifier = _AuthRouterRefreshNotifier(ref);
  ref.onDispose(refreshNotifier.dispose);

  return GoRouter(
    navigatorKey: _rootNavigatorKey,
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: false,
    refreshListenable: refreshNotifier,
    redirect: (context, state) {
      final authState = ref.read(authProvider);
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

        // Role-based route guards
        if (location.startsWith('/rm') && authState.user?.role != UserRole.rm) {
          return authState.user?.role.dashboardRoute;
        }
        if (location.startsWith('/staff') && authState.user?.role != UserRole.staff) {
          return authState.user?.role.dashboardRoute;
        }
        if (location.startsWith('/client') && authState.user?.role != UserRole.client) {
          return authState.user?.role.dashboardRoute;
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
        path: AppRoutes.resetPassword,
        name: 'resetPassword',
        builder: (context, state) {
          final phone = state.uri.queryParameters['phone'] ?? '';
          return ResetPasswordScreen(phone: phone);
        },
      ),
      fadeRoute(
        path: AppRoutes.changePassword,
        name: 'changePassword',
        builder: (context, state) => const ChangePasswordScreen(),
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
