import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../domain/models/user_role.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/otp_viewmodel.dart';

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);
const Color _offWhite = Color(0xFFFBF9F8);
const Color _textColor = Color(0xFF1A1C1E);

/// Premium OTP verification screen.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {});
    });
  }

  @override
  void dispose() {
    _otpController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    if (otp.length < 4) {
      context.showAppSnackBar('Please enter all 4 digits', isError: true);
      return;
    }

    final success = await ref.read(otpViewModelProvider.notifier).verifyOtp(
          phone: widget.phone,
          otp: otp,
        );

    if (!mounted || !success) return;

    final profileOk = await ref.read(authProvider.notifier).fetchProfile();
    if (!mounted) return;

    if (profileOk) {
      context.go(AppRoutes.biometricLogin);
    }
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpViewModelProvider);
    final displayPhone = widget.phone.isNotEmpty ? widget.phone : '+1 (555) 019-2834';

    ref.listen(otpViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: _offWhite,
      body: SafeArea(
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: _textColor),
                    onPressed: () => context.go(AppRoutes.login),
                  ),
                ),
                SizedBox(height: 24),
                
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
                      Icons.lock_person_outlined,
                      size: 36,
                      color: _electricBlue,
                    ),
                  ),
                ),
                SizedBox(height: 32),
                
                // Title
                Text(
                  'Verify OTP',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 36,
                    fontWeight: FontWeight.w600,
                    color: _electricBlue,
                  ),
                ),
                SizedBox(height: 12),
                
                // Subtitle
                Text(
                  'We\'ve sent a secure code to\n$displayPhone',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w400,
                    color: const Color(0xFF4B5563),
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 48),

                // Custom OTP Input
                GestureDetector(
                  onTap: () => _focusNode.requestFocus(),
                  child: Stack(
                    children: [
                      // Invisible Text Field for capturing input
                      Opacity(
                        opacity: 0,
                        child: TextField(
                          controller: _otpController,
                          focusNode: _focusNode,
                          keyboardType: TextInputType.number,
                          maxLength: 4,
                          autofillHints: const [AutofillHints.oneTimeCode],
                          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                          decoration: const InputDecoration(counterText: ''),
                        ),
                      ),
                      // Visual Boxes
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: List.generate(4, (index) {
                          final text = _otpController.text;
                          final digit = index < text.length ? text[index] : '';
                          final isFocused = index == text.length || (index == 3 && text.length == 4);
                          
                          return Container(
                            width: 64,
                            height: 72,

                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _focusNode.hasFocus && isFocused
                                    ? _electricBlue
                                    : const Color(0xFFE5E7EB),
                                width: _focusNode.hasFocus && isFocused ? 2 : 1,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withOpacity(0.04),
                                  blurRadius: 10,
                                  spreadRadius: 0,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Center(
                              child: Text(
                                digit,
                                style: GoogleFonts.inter(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: _textColor,
                                ),
                              ),
                            ),
                          );
                        }),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 48),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: otpState.isLoading ? null : _verify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _electricBlue,
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                    child: otpState.isLoading
                        ? SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'VERIFY CODE',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                  ),
                ),
                SizedBox(height: 32),

                // Resend text
                Column(
                  children: [
                    Text(
                      'Didn\'t receive the code?',
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        fontWeight: FontWeight.w400,
                        color: const Color(0xFF6B7280),
                      ),
                    ),
                    SizedBox(height: 8),
                    otpState.canResend
                        ? InkWell(
                            onTap: () {
                              ref.read(otpViewModelProvider.notifier).resendOtp();
                              context.showAppSnackBar('OTP resent successfully');
                            },
                            child: Text(
                              'Resend Code',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: _electricBlue,
                              ),
                            ),
                          )
                        : Text(
                            'Resend in 00:${otpState.resendSeconds.toString().padLeft(2, '0')}',
                            style: GoogleFonts.inter(
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                              color: const Color(0xFF9CA3AF),
                            ),
                          ),
                  ],
                ),
                SizedBox(height: 48),
                
                // Info Card
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFE5E7EB)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, color: const Color(0xFF6B7280), size: 20),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'First-Time Login?',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: _textColor,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              'If this is your first time accessing the portal, you will be prompted to set up biometric authentication after verifying this code.',
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                fontWeight: FontWeight.w400,
                                color: const Color(0xFF4B5563),
                                height: 1.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
