import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/core/theme/app_colors.dart';
import 'package:homegennyapp/design_system/widgets/buttons/ds_buttons.dart';
import '../widgets/auth_hero_scaffold.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../domain/models/user_role.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/otp_viewmodel.dart';

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);
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
    if (otp.length < 6) {
      context.showAppSnackBar('Please enter all 6 digits', isError: true);
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
      final role = ref.read(authProvider).user?.role ?? UserRole.client;
      context.go(role.dashboardRoute);
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

    return AuthHeroScaffold(
      onBack: () => context.go(AppRoutes.login),
      badge: 'Secure verification',
      badgeIcon: Icons.shield_rounded,
      titleLine1: 'Verify your',
      titleHighlight: 'number.',
      subtitle: 'We\'ve sent a 6-digit code to $displayPhone',
      floatingIcons: const [
        Icons.sms_rounded,
        Icons.lock_rounded,
        Icons.verified_user_rounded,
      ],
      sheetTitle: 'Enter the code',
      sheetSubtitle: 'Tap the boxes to type your one-time code',
      children: [
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
                  maxLength: 6,
                  autofillHints: const [AutofillHints.oneTimeCode],
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  decoration: const InputDecoration(counterText: ''),
                ),
              ),
              // Visual Boxes
              Row(
                children: List.generate(6, (index) {
                  final text = _otpController.text;
                  final digit = index < text.length ? text[index] : '';
                  final isFocused = _focusNode.hasFocus &&
                      (index == text.length || (index == 5 && text.length == 6));
                  final filled = digit.isNotEmpty;

                  return Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(right: index == 5 ? 0 : 8),
                      child: AnimatedContainer(
                        duration: const Duration(milliseconds: 220),
                        curve: Curves.easeOut,
                        height: 60,
                        decoration: BoxDecoration(
                          color: filled || isFocused
                              ? Colors.white
                              : AppColors.lightSurfaceVariant,
                          borderRadius: BorderRadius.circular(16),
                          border: Border.all(
                            color: isFocused
                                ? _electricBlue
                                : (filled
                                    ? _electricBlue.withValues(alpha: 0.35)
                                    : Colors.transparent),
                            width: isFocused ? 1.8 : 1.2,
                          ),
                          boxShadow: isFocused
                              ? [
                                  BoxShadow(
                                    color: _electricBlue.withValues(alpha: 0.18),
                                    blurRadius: 16,
                                    offset: const Offset(0, 6),
                                  ),
                                ]
                              : null,
                        ),
                        child: Center(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 200),
                            transitionBuilder: (c, a) =>
                                ScaleTransition(scale: a, child: c),
                            child: Text(
                              digit,
                              key: ValueKey('$index-$digit'),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: _textColor,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Verify Button
        DsGradientButton(
          label: 'Verify & continue',
          isLoading: otpState.isLoading,
          onPressed: otpState.isLoading ? null : _verify,
        ),
        const SizedBox(height: 24),

        // Resend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Didn\'t receive it? ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            otpState.canResend
                ? GestureDetector(
                    onTap: () {
                      ref.read(otpViewModelProvider.notifier).resendOtp();
                      context.showAppSnackBar('OTP resent successfully');
                    },
                    child: Text(
                      'Resend code',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: _electricBlue,
                        decoration: TextDecoration.underline,
                        decorationColor: _electricBlue.withValues(alpha: 0.35),
                        decorationThickness: 2,
                      ),
                    ),
                  )
                : Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      'Resend in 00:${otpState.resendSeconds.toString().padLeft(2, '0')}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                        color: _electricBlue,
                      ),
                    ),
                  ),
          ],
        ),
        const SizedBox(height: 28),

        // Info Card
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.secondaryContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 34,
                height: 34,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(11),
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: AppColors.secondary,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'First-time login?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'After verifying this code you\'ll be prompted to set up biometric login.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: const Color(0xFF4B5563),
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
