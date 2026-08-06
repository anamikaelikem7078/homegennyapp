import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../domain/models/user_role.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/biometric_viewmodel.dart';
import '../widgets/app_button.dart';
import '../widgets/app_widgets.dart';

/// Biometric login screen.
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
    final l10n = context.l10n;

    ref.listen(biometricViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  icon: Icon(Icons.arrow_back_ios_new_rounded,
                      color: Color(0xFF1A1C1E)),
                  onPressed: () => context.go(AppRoutes.login),
                ),
              ),
              const Spacer(flex: 2),
              
              // Biometric Icon Container
              Center(
                child: Container(
                  width: 120,
                  height: 120,
                  decoration: BoxDecoration(
                    color: context.colors.surfaceVariant,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: const Color(0xFF1A56FF).withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Center(
                    child: Icon(
                      Icons.fingerprint,
                      size: 64,
                      color: Color(0xFF1A56FF),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
              
              // Title
              Text(
                'Quick sign in',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A1C1E),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 16),
              
              // Subtitle
              Text(
                'Use your fingerprint or face to sign in\nsecurely',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF6B7280),
                  height: 1.5,
                ),
                textAlign: TextAlign.center,
              ),
              const Spacer(flex: 3),
              
              // Not Available Text
              if (!state.isAvailable)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    'Biometric authentication is not available on this device',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 13,
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                
              // Authenticate Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: state.isAvailable && !state.isLoading ? _authenticate : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: state.isLoading
                      ? SizedBox(
                          width: 24,
                          height: 24,
                          child: CircularProgressIndicator(strokeWidth: 2, color: context.theme.cardColor),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.fingerprint, size: 20),
                            SizedBox(width: 8),
                            Text(
                              'Authenticate',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
              SizedBox(height: 16),
              
              // Use Password Instead
              TextButton(
                onPressed: () => context.go(AppRoutes.login),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF1A56FF),
                ),
                child: Text(
                  'Use password instead',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
