import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:homegennyapp/design_system/widgets/buttons/ds_buttons.dart';
import '../widgets/auth_hero_scaffold.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../domain/models/user_role.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/biometric_viewmodel.dart';

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);

/// Premium Biometric Login Screen
class BiometricLoginScreen extends ConsumerStatefulWidget {
  const BiometricLoginScreen({super.key});

  @override
  ConsumerState<BiometricLoginScreen> createState() =>
      _BiometricLoginScreenState();
}

class _BiometricLoginScreenState extends ConsumerState<BiometricLoginScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ref.read(biometricViewModelProvider.notifier).checkBiometricAvailability();
    });
  }

  Future<void> _authenticate() async {
    final success =
        await ref.read(biometricViewModelProvider.notifier).authenticate();

    if (!mounted || !success) return;

    final profileOk = await ref.read(authProvider.notifier).fetchProfile();
    if (!mounted) return;

    if (profileOk) {
      final role = ref.read(authProvider).user?.role ?? UserRole.client;
      context.go(role.dashboardRoute);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(biometricViewModelProvider);

    ref.listen(biometricViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return AuthHeroScaffold(
      onBack: () => context.go(AppRoutes.login),
      badge: 'Quick sign-in',
      badgeIcon: Icons.bolt_rounded,
      titleLine1: 'Touch ID /',
      titleHighlight: 'Face ID.',
      subtitle: 'Secure, fast, and effortless access.',
      floatingIcons: const [
        Icons.fingerprint_rounded,
        Icons.face_rounded,
        Icons.lock_open_rounded,
      ],
      children: [
        const SizedBox(height: 8),
        Center(
          child: GestureDetector(
            onTap: state.isAvailable && !state.isLoading ? _authenticate : null,
            child: SizedBox(
              width: 190,
              height: 190,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  for (var i = 0; i < 2; i++)
                    Container(
                      width: 190,
                      height: 190,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: _electricBlue.withValues(alpha: 0.25),
                          width: 2,
                        ),
                      ),
                    )
                        .animate(
                          delay: (i * 900).ms,
                          onPlay: (c) => c.repeat(),
                        )
                        .scaleXY(
                          begin: 0.55,
                          end: 1,
                          duration: 1800.ms,
                          curve: Curves.easeOut,
                        )
                        .fadeOut(duration: 1800.ms, curve: Curves.easeIn),
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFFFFF4EB), Color(0xFFFFE2CC)],
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFF97316).withValues(alpha: 0.25),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: const Icon(
                      Icons.fingerprint_rounded,
                      size: 68,
                      color: Color(0xFFF97316),
                    ),
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .scaleXY(
                        begin: 1,
                        end: 1.05,
                        duration: 1100.ms,
                        curve: Curves.easeInOut,
                      ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),
        Text(
          state.isAvailable
              ? 'Tap the fingerprint or the button below'
              : 'Biometric authentication is not available on this device',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13.5,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF6B7280),
          ),
        ),
        const SizedBox(height: 28),
        DsGradientButton(
          label: 'Authenticate',
          icon: Icons.fingerprint_rounded,
          isLoading: state.isLoading,
          onPressed:
              state.isAvailable && !state.isLoading ? _authenticate : null,
        ),
        const SizedBox(height: 12),
        DsOutlineButton(
          label: 'Use password instead',
          icon: Icons.password_rounded,
          onPressed: () => context.go(AppRoutes.login),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
