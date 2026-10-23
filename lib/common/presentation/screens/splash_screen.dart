import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/onboarding/onboarding_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/splash_viewmodel.dart';
// --- Palette (matches the login hero) ---
const Color _brand = Color(0xFF1A56FF);
const Color _brandDark = Color(0xFF1238B8);
const Color _deepNavy = Color(0xFF0B1B4D);
const Color _sunYellow = Color(0xFFFFD84D);
const String _appName = 'HomeGenny';
/// Index of the letter in [_appName] that zooms toward the camera on exit
/// (the "o" in "Home" — its hollow centre opens onto the next screen).
const int _zoomLetterIndex = 1;
/// Time the intro animation needs before the exit zoom may start.
const Duration _introDuration = Duration(milliseconds: 1900);

/// Splash screen — plays the brand intro while the auth bootstrap runs,
/// then zooms through a letter of the app name into the next screen.
class SplashScreen extends ConsumerStatefulWidget {
  const SplashScreen({super.key});

  @override
  ConsumerState<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends ConsumerState<SplashScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _zoom = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 950),
  );

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  @override
  void dispose() {
    _zoom.dispose();
    super.dispose();
  }

  Future<void> _initialize() async {
    final intro = Future<void>.delayed(_introDuration);
    final viewModel = ref.read(splashViewModelProvider);
    final result = await viewModel.initialize();

    if (!mounted) return;

    final String route;
    var sessionExpired = false;
    switch (result.destination) {
      case SplashDestination.noInternet:
        route = AppRoutes.noInternet;
      case SplashDestination.updateRequired:
        final url = result.updateUrl;
        route = url != null
            ? '${AppRoutes.updateApp}?url=${Uri.encodeComponent(url)}'
            : AppRoutes.updateApp;
      case SplashDestination.login:
        route = AppRoutes.login;
      case SplashDestination.biometricLogin:
        route = AppRoutes.biometricLogin;
      case SplashDestination.sessionExpired:
        sessionExpired = true;
        route = AppRoutes.sessionExpired;
      case SplashDestination.staffDashboard:
      case SplashDestination.rmDashboard:
      case SplashDestination.clientDashboard:
        final profileOk = await ref.read(authProvider.notifier).fetchProfile();
        if (!mounted) return;
        final role = ref.read(authProvider).user?.role;
        if (profileOk && role != null) {
          // The profile wizard while it is incomplete, else the home.
          route = await landingRouteAfterLogin(
            ref.read(onboardingRemoteDataSourceProvider),
            role,
          );
          if (!mounted) return;
        } else if (profileOk) {
          route = AppRoutes.clientDashboard;
        } else {
          route = AppRoutes.sessionExpired;
        }
    }

    await intro;
    if (!mounted) return;
    await _zoom.forward();
    if (!mounted) return;

    if (sessionExpired) {
      ref.read(authProvider.notifier).setSessionExpired();
    }
    context.go(route);
  }

  @override
  Widget build(BuildContext context) {
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: _deepNavy,
        body: Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [_deepNavy, _brandDark, _brand],
            ),
          ),
          child: AnimatedBuilder(
            animation: _zoom,
            builder: (context, _) {
              // Everything except the zooming letter fades out early.
              final fadeOut =
                  1 - Curves.easeOut.transform((_zoom.value * 2.2).clamp(0, 1));
              return Stack(
                fit: StackFit.expand,
                children: [
                  Opacity(opacity: fadeOut, child: const _VerticalBackdrop()),
                  Center(child: _buildCenter(fadeOut)),
                  Positioned(
                    left: 0,
                    right: 0,
                    bottom: MediaQuery.paddingOf(context).bottom + 40,
                    child: Opacity(
                      opacity: fadeOut,
                      child: const _LoadingDots(),
                    ),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildCenter(double fadeOut) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Opacity(
          opacity: fadeOut,
          child: Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(
              color: _sunYellow,
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: _sunYellow.withValues(alpha: 0.35),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: const Icon(
              Icons.home_rounded,
              color: AppColors.secondary,
              size: 38,
            ),
          )
              .animate()
              .scaleXY(
                begin: 0,
                end: 1,
                duration: 650.ms,
                curve: Curves.elasticOut,
              )
              .rotate(begin: -0.15, end: 0, duration: 650.ms)
              .then(delay: 200.ms)
              .shimmer(
                duration: 900.ms,
                color: Colors.white.withValues(alpha: 0.6),
              ),
        ),
        const SizedBox(height: 26),
        _AnimatedName(zoom: _zoom.value, fadeOut: fadeOut),
        const SizedBox(height: 14),
        Opacity(
          opacity: fadeOut,
          child: Text(
            'YOUR HOME, SIMPLIFIED',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              letterSpacing: 3,
              color: Colors.white.withValues(alpha: 0.75),
            ),
          )
              .animate(delay: 1100.ms)
              .fadeIn(duration: 500.ms)
              .custom(
                duration: 700.ms,
                curve: Curves.easeOutCubic,
                builder: (context, v, child) => Padding(
                  // Letter-spacing "settle" feel: slide up as it fades in.
                  padding: EdgeInsets.only(top: 10 * (1 - v)),
                  child: child,
                ),
              ),
        ),
      ],
    );
  }
}

/// "HomeGenny" with letters dropping in one by one. During exit the letter at
/// [_zoomLetterIndex] scales up until it fills the screen.
class _AnimatedName extends StatelessWidget {
  const _AnimatedName({required this.zoom, required this.fadeOut});

  final double zoom;
  final double fadeOut;

  @override
  Widget build(BuildContext context) {
    final style = GoogleFonts.plusJakartaSans(
      fontSize: 54,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: -1,
    );

    final zoomCurve = Curves.easeInExpo.transform(zoom);
    final zoomScale = 1 + zoomCurve * 90;
    // Fade the zooming letter in the last stretch so the hand-off is clean
    // even if its hollow centre is slightly off the screen centre.
    final zoomOpacity =
        1 - Curves.easeIn.transform(((zoom - 0.7) / 0.3).clamp(0, 1));

    return Semantics(
      label: _appName,
      header: true,
      child: ExcludeSemantics(
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            for (var i = 0; i < _appName.length; i++)
              _letter(i, style, zoomScale, zoomOpacity),
          ],
        ),
      ),
    );
  }

  Widget _letter(int i, TextStyle style, double zoomScale, double zoomOpacity) {
    final isGenny = i >= 4;
    final isZoom = i == _zoomLetterIndex;

    Widget letter = Text(
      _appName[i],
      style: style.copyWith(color: isGenny ? _sunYellow : Colors.white),
    )
        .animate(delay: (350 + i * 75).ms)
        .fadeIn(duration: 350.ms)
        .slideY(begin: 0.9, end: 0, duration: 550.ms, curve: Curves.easeOutBack)
        .scaleXY(begin: 0.4, end: 1, duration: 550.ms, curve: Curves.easeOutBack)
        // A little wave once everything has landed.
        .then(delay: (500 + (_appName.length - i) * 40).ms)
        .moveY(begin: 0, end: -8, duration: 180.ms, curve: Curves.easeOut)
        .then()
        .moveY(begin: 0, end: 8, duration: 260.ms, curve: Curves.bounceOut);

    if (isZoom) {
      return Opacity(
        opacity: zoomOpacity,
        child: Transform.scale(
          scale: zoomScale,
          // Centre of the "o" bowl sits a little below the text box middle.
          alignment: const Alignment(0, 0.22),
          child: letter,
        ),
      );
    }
    return Opacity(opacity: fadeOut, child: letter);
  }
}

/// Giant outlined "HOMEGENNY" columns drifting vertically behind the content.
class _VerticalBackdrop extends StatelessWidget {
  const _VerticalBackdrop();

  @override
  Widget build(BuildContext context) {
    final outline = GoogleFonts.plusJakartaSans(
      fontSize: 150,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: 4,
      foreground: Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.6
        ..color = Colors.white.withValues(alpha: 0.14),
    );
    final filled = GoogleFonts.plusJakartaSans(
      fontSize: 150,
      fontWeight: FontWeight.w800,
      height: 1,
      letterSpacing: 4,
      color: Colors.white.withValues(alpha: 0.05),
    );

    return Stack(
      children: [
        Positioned(
          left: -28,
          top: 0,
          bottom: 0,
          width: 170,
          child: _column(outline, quarterTurns: 3, drift: 1),
        ),
        Positioned(
          right: -28,
          top: 0,
          bottom: 0,
          width: 170,
          child: _column(filled, quarterTurns: 1, drift: -1),
        ),
      ],
    )
        .animate()
        .fadeIn(duration: 900.ms);
  }

  Widget _column(TextStyle style, {required int quarterTurns, required int drift}) {
    return OverflowBox(
      maxHeight: double.infinity,
      child: RotatedBox(
        quarterTurns: quarterTurns,
        child: Text('HOMEGENNY', style: style, maxLines: 1, softWrap: false),
      ),
    )
        .animate()
        .slideY(
          begin: 0.25 * drift,
          end: 0,
          duration: 1400.ms,
          curve: Curves.easeOutCubic,
        )
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(
          begin: 0,
          end: -60.0 * drift,
          duration: 5.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _LoadingDots extends StatelessWidget {
  const _LoadingDots();

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        for (var i = 0; i < 3; i++) ...[
          Container(
            width: 8,
            height: 8,
            decoration: BoxDecoration(
              color: i == 1 ? _sunYellow : Colors.white,
              shape: BoxShape.circle,
            ),
          )
              .animate(
                delay: (1200 + i * 150).ms,
                onPlay: (c) => c.repeat(reverse: true),
              )
              .fadeIn(duration: 300.ms)
              .then()
              .moveY(begin: 0, end: -8, duration: 450.ms, curve: Curves.easeInOut),
          if (i < 2) const SizedBox(width: 8),
        ],
      ],
    );
  }
}
