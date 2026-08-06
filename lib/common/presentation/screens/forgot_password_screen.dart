import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/forgot_password_viewmodel.dart';
import '../widgets/app_button.dart';

/// Forgot password screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  String? _localizedValidator(String? key) {
    if (key == null) return null;
    return switch (key) {
      'emailRequired' => context.l10n.emailRequired,
      'emailInvalid' => context.l10n.emailInvalid,
      _ => key,
    };
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(forgotPasswordViewModelProvider.notifier)
        .sendResetLink(email: _emailController.text.trim());

    if (!mounted) return;

    if (success) {
      context.showAppSnackBar('Reset link sent to your email');
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(forgotPasswordViewModelProvider);
    final l10n = context.l10n;

    ref.listen(forgotPasswordViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Color(0xFF1A1C1E)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SizedBox(height: 24),
                // Icon Container
                Center(
                  child: Container(
                    width: 80,
                    height: 80,
                    decoration: BoxDecoration(
                      color: const Color(0xFF1A56FF).withOpacity(0.1),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.settings_backup_restore_rounded, // Similar to lock_reset but circular
                        size: 40,
                        color: Color(0xFF1A56FF),
                      ),
                    ),
                  ),
                ),
                SizedBox(height: 32),
                // Title
                Text(
                  'Reset password',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 28,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A1C1E),
                  ),
                  textAlign: TextAlign.center,
                ),
                SizedBox(height: 16),
                // Subtitle
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'Enter your email and we\'ll send reset instructions to your inbox.',
                    style: GoogleFonts.inter(
                      fontSize: 15,
                      fontWeight: FontWeight.w400,
                      color: const Color(0xFF6B7280),
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
                SizedBox(height: 48),
                // Email Field
                Text(
                  'Email Address',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF6B7280),
                  ),
                ),
                SizedBox(height: 8),
                TextFormField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    color: const Color(0xFF1A1C1E),
                  ),
                  decoration: InputDecoration(
                    hintText: 'hello@example.com',
                    hintStyle: GoogleFonts.inter(
                      color: const Color(0xFF9CA3AF),
                    ),
                    prefixIcon: Icon(Icons.mail_outline, color: Color(0xFF6B7280)),
                    filled: true,
                    fillColor: Colors.white,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8),
                      borderSide: const BorderSide(color: Color(0xFF1A56FF), width: 1.5),
                    ),
                  ),
                  validator: (v) => _localizedValidator(Validators.email(v)),
                ),
                SizedBox(height: 32),
                // Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: state.isLoading ? null : _sendResetLink,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
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
                              Text(
                                'Send reset link',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              SizedBox(width: 8),
                              Icon(Icons.send_outlined, size: 18),
                            ],
                          ),
                  ),
                ),
                SizedBox(height: 48),
                // Back to login
                Center(
                  child: TextButton(
                    onPressed: () => context.go(AppRoutes.login),
                    style: TextButton.styleFrom(
                      foregroundColor: const Color(0xFF1A56FF),
                    ),
                    child: Text(
                      'Back to login',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
