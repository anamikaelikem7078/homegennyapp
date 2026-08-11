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

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);
const Color _offWhite = Color(0xFFFBF9F8);
const Color _textColor = Color(0xFF1A1C1E);

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
    final l10n = context.l10n;

    ref.listen(biometricViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(height: 32),
              // Wordmark Branding
              Center(
                child: Text(
                  'HOMEGENNY',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: _electricBlue,
                    letterSpacing: 2.0,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              
              // Title
              Text(
                'Touch ID / Face\nID',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 36,
                  fontWeight: FontWeight.w600,
                  color: _electricBlue,
                  height: 1.1,
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 12),
              
              // Subtitle
              Text(
                'Secure, fast, and effortless access.',
                style: GoogleFonts.inter(
                  fontSize: 15,
                  fontWeight: FontWeight.w400,
                  color: const Color(0xFF1A1C1E),
                ),
                textAlign: TextAlign.center,
              ),
              SizedBox(height: 48),

              // Gestural Focus
              Center(
                child: Container(
                  width: 240,
                  height: 240,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 16,
                        spreadRadius: 2,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: Center(
                    child: Container(
                      width: 140,
                      height: 140,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF9FAFB),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF3F4F6)),
                      ),
                      child: Icon(
                        Icons.fingerprint_rounded,
                        size: 80,
                        color: _electricBlue,
                      ),
                    ),
                  ),
                ),
              ),

              const Spacer(flex: 2),
              
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
                    backgroundColor: _electricBlue,
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
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(
                          'Authenticate',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.0,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 24),
              
              // Use Password Instead
              Center(
                child: InkWell(
                  onTap: () => context.go(AppRoutes.login),
                  child: Text(
                    'Use Password Instead',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4B5563),
                    ),
                  ),
                ),
              ),
              SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
