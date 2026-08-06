import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/presentation/widgets/hero_page.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/splash_viewmodel.dart';
import '../widgets/app_widgets.dart';

/// Splash screen — orchestrates the full auth bootstrap flow.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  Future<void> _initialize() async {
    final viewModel = ref.read(splashViewModelProvider);
    final result = await viewModel.initialize();

    if (!mounted) return;

    switch (result.destination) {
      case SplashDestination.noInternet:
        context.go(AppRoutes.noInternet);
      case SplashDestination.updateRequired:
        final url = result.updateUrl;
        context.go(
          url != null
              ? '${AppRoutes.updateApp}?url=${Uri.encodeComponent(url)}'
              : AppRoutes.updateApp,
        );
      case SplashDestination.login:
        context.go(AppRoutes.login);
      case SplashDestination.biometricLogin:
        context.go(AppRoutes.biometricLogin);
      case SplashDestination.sessionExpired:
        ref.read(authProvider.notifier).setSessionExpired();
        context.go(AppRoutes.sessionExpired);
      case SplashDestination.staffDashboard:
      case SplashDestination.rmDashboard:
      case SplashDestination.clientDashboard:
        final profileOk = await ref.read(authProvider.notifier).fetchProfile();
        if (!mounted) return;
        if (profileOk) {
          final role = ref.read(authProvider).user?.role;
          context.go(role?.dashboardRoute ?? AppRoutes.clientDashboard);
        } else {
          context.go(AppRoutes.sessionExpired);
        }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: HeroPage(
        tag: 'splash-hero',
        child: SafeArea(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              SizedBox(height: 24), // Top padding
              
              // Center Content
              Expanded(
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Floating Logo Container
                      Container(
                        width: 120,
                        height: 120,
                        decoration: BoxDecoration(
                          color: context.theme.cardColor,
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.04),
                              blurRadius: 20,
                              spreadRadius: 4,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              Icon(
                                Icons.home_rounded,
                                size: 54,
                                color: const Color(0xFF1A56FF),
                              ),
                              Positioned(
                                bottom: 20,
                                right: 20,
                                child: Container(
                                  padding: const EdgeInsets.all(4),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF1A56FF),
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: Icon(
                                    Icons.bolt_rounded,
                                    size: 14,
                                    color: context.theme.cardColor,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ).animate().fadeIn(duration: 600.ms).scale(begin: const Offset(0.8, 0.8)),
                      
                      SizedBox(height: 32),
                      
                      // App Name
                      Text(
                        'HomeGenny',
                        style: GoogleFonts.libreCaslonText(
                          color: context.colors.onSurface,
                          fontSize: 36,
                          fontWeight: FontWeight.w600,
                        ),
                      ).animate().fadeIn(delay: 300.ms, duration: 600.ms).slideY(begin: 0.2, end: 0),
                      
                      SizedBox(height: 8),
                      
                      // Tagline
                      Text(
                        'YOUR HOME, SIMPLIFIED',
                        style: GoogleFonts.inter(
                          color: context.colors.onSurfaceVariant,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 500.ms, duration: 500.ms),
                      
                      SizedBox(height: 32),
                      
                      // Divider line
                      Container(
                        width: 60,
                        height: 1,
                        color: context.theme.dividerColor,
                      ).animate().fadeIn(delay: 600.ms),
                      
                      SizedBox(height: 64),
                      
                      // Loading section
                      SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: const Color(0xFF1A56FF),
                        ),
                      ).animate().fadeIn(delay: 800.ms),
                      
                      SizedBox(height: 16),
                      
                      Text(
                        'INITIALIZING ENVIRONMENT',
                        style: GoogleFonts.inter(
                          color: Colors.black45,
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 1.5,
                        ),
                      ).animate().fadeIn(delay: 900.ms),
                    ],
                  ),
                ),
              ),
              
              // Bottom dots
              Padding(
                padding: const EdgeInsets.only(bottom: 48),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A56FF).withOpacity(0.4),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A56FF).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                    SizedBox(width: 8),
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A56FF).withOpacity(0.15),
                        shape: BoxShape.circle,
                      ),
                    ),
                  ],
                ).animate().fadeIn(delay: 1000.ms),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
