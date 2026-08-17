import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/change_password_viewmodel.dart';

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);
const Color _offWhite = Color(0xFFFBF9F8);
const Color _textColor = Color(0xFF1A1C1E);
const Color _obsidianError = Color(0xFFD32F2F);

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController(text: '123456');
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _otpController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(changePasswordViewModelProvider.notifier)
        .changePassword(
          otp: _otpController.text.trim(),
          newPassword: _passwordController.text,
        );

    if (!mounted || !success) return;

    // Check session again since now password is changed and we want to go to dashboard
    final profileOk = await ref.read(authProvider.notifier).fetchProfile();
    if (!mounted) return;

    if (profileOk) {
      context.go(AppRoutes.biometricLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(changePasswordViewModelProvider);

    ref.listen(changePasswordViewModelProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
      if (next.success && !prev!.success) {
        context.showAppSnackBar('Password changed successfully');
      }
    });

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    // Icon
                    Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0F4FF),
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(color: const Color(0xFFE0E7FF)),
                        ),
                        child: Icon(
                          Icons.lock_reset,
                          size: 36,
                          color: _electricBlue,
                        ),
                      ),
                    ),
                    SizedBox(height: 32),
                    
                    Text(
                      'Change Password',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 32,
                        fontWeight: FontWeight.w600,
                        color: _electricBlue,
                      ),
                    ),
                    SizedBox(height: 12),
                    
                    Text(
                      'You must change your password before continuing.',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                        height: 1.5,
                      ),
                    ),
                    SizedBox(height: 48),

                    // OTP Field
                    Text(
                      'OTP CODE',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: _inputCardDecoration(),
                      child: TextFormField(
                        controller: _otpController,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.next,
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _textColor,
                          fontWeight: FontWeight.w500,
                        ),
                        decoration: _inputDecoration(
                          hint: 'Enter OTP',
                          prefixIcon: Icons.message_outlined,
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'OTP is required' : null,
                      ),
                    ),
                    SizedBox(height: 24),

                    // Password Field
                    Text(
                      'NEW PASSWORD',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: _textColor,
                        letterSpacing: 1.0,
                      ),
                    ),
                    SizedBox(height: 8),
                    Container(
                      decoration: _inputCardDecoration(),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscurePassword,
                        textInputAction: TextInputAction.done,
                        onFieldSubmitted: (_) => _submit(),
                        style: GoogleFonts.inter(
                          fontSize: 16,
                          color: _textColor,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2.0,
                        ),
                        decoration: _inputDecoration(
                          hint: '••••••••',
                          prefixIcon: Icons.lock_outline_rounded,
                          suffixIcon: IconButton(
                            icon: Icon(
                              _obscurePassword
                                  ? Icons.visibility_off_outlined
                                  : Icons.visibility_outlined,
                              color: const Color(0xFF6B7280),
                            ),
                            onPressed: () {
                              setState(() {
                                _obscurePassword = !_obscurePassword;
                              });
                            },
                          ),
                        ),
                        validator: (v) {
                          final err = Validators.password(v);
                          if (err == 'passwordRequired') return context.l10n.passwordRequired;
                          if (err == 'passwordTooShort') return context.l10n.passwordTooShort;
                          return err;
                        },
                      ),
                    ),
                    SizedBox(height: 48),

                    // Submit Button
                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: ElevatedButton(
                        onPressed: state.isLoading ? null : _submit,
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
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Text(
                                    'UPDATE PASSWORD',
                                    style: GoogleFonts.inter(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w600,
                                      letterSpacing: 1.2,
                                    ),
                                  ),
                                ],
                              ),
                      ),
                    ),
                    SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  BoxDecoration _inputCardDecoration() {
    return BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(4),
      border: Border.all(color: const Color(0xFFE5E7EB)),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.03),
          blurRadius: 10,
          spreadRadius: 0,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData prefixIcon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: const Color(0xFF9CA3AF),
        fontSize: 16,
        letterSpacing: 0,
      ),
      filled: true,
      fillColor: Colors.white,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      prefixIcon: Icon(prefixIcon, color: const Color(0xFF9CA3AF)),
      suffixIcon: suffixIcon,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(4),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: BorderRadius.circular(4),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: BorderSide(color: _electricBlue, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _obsidianError),
        borderRadius: BorderRadius.circular(4),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _obsidianError, width: 1.5),
        borderRadius: BorderRadius.circular(4),
      ),
    );
  }
}
