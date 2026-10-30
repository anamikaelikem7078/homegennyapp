import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/core/theme/app_colors.dart';
import 'package:homegennyapp/design_system/widgets/buttons/ds_buttons.dart';
import '../widgets/auth_hero_scaffold.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/onboarding/onboarding_providers.dart';
import '../../../core/router/app_routes.dart';
import '../../domain/models/user_role.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/otp_viewmodel.dart';
import '../widgets/office_login_sheet.dart';
import '../widgets/role_picker_sheet.dart';

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);
const Color _textColor = Color(0xFF1A1C1E);

/// OTP sign-in screen — the step that signs the user in (`POST
/// /auth/otp/verify`) and saves the tokens. For a new number it also signs
/// them up, with the role picked on the login screen.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone, this.role});

  final String phone;

  /// CLIENT / STAFF — set only for a number with no account yet.
  final UserRole? role;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  late UserRole? _role = widget.role;

  @override
  void initState() {
    super.initState();
    _otpController.addListener(() {
      setState(() {});
      if (_otpController.text.length == 6 && !ref.read(otpViewModelProvider).isLoading) {
        _verify();
      }
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

    final outcome = await ref
        .read(otpViewModelProvider.notifier)
        .verify(phone: widget.phone, otp: otp, role: _role);
    if (!mounted) return;

    switch (outcome) {
      case OtpVerified(:final user):
        // Captured up front: setting the auth state makes the router leave
        // this screen, after which `context`/`ref` are no longer usable.
        final router = GoRouter.of(context);
        final container = ProviderScope.containerOf(context, listen: false);
        final landing = await landingRouteAfterLogin(
          container.read(onboardingRemoteDataSourceProvider),
          user.role,
        );
        container.invalidate(onboardingProvider);
        container.read(authProvider.notifier).setAuthenticated(user);
        router.go(landing);
      case OtpNeedsRole():
        // The number is new — ask the role, then verify again with the same
        // code (it stays valid).
        final role = await showRolePickerSheet(context);
        if (!mounted || role == null) return;
        setState(() => _role = role);
        await _verify();
      case OtpOfficeAccount():
        // Office accounts sign in with their password instead.
        await signInOfficeAccount(context, widget.phone);
      case OtpFailed():
        _otpController.clear();
        _focusNode.requestFocus();
    }
  }

  Future<void> _resend() async {
    final ok = await ref.read(otpViewModelProvider.notifier).resend(widget.phone);
    if (!mounted || !ok) return;
    _otpController.clear();
    context.showAppSnackBar('A new code has been sent');
  }

  @override
  Widget build(BuildContext context) {
    final otpState = ref.watch(otpViewModelProvider);

    ref.listen(otpViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return AuthHeroScaffold(
      onBack: () => context.canPop() ? context.pop() : context.go(AppRoutes.login),
      badge: 'Secure verification',
      badgeIcon: Icons.shield_rounded,
      titleLine1: 'Verify your',
      titleHighlight: 'number.',
      subtitle: 'We\'ve sent a 6-digit code to +91 ${widget.phone}',
      floatingIcons: const [
        Icons.sms_rounded,
        Icons.lock_rounded,
        Icons.verified_user_rounded,
      ],
      sheetTitle: 'Enter the code',
      sheetSubtitle: 'Tap the boxes to type your one-time code',
      children: [
        if (_role != null) ...[
          _SignupRoleChip(
            role: _role!,
            // Back to "Client or Staff?" — or straight to the picker if this
            // screen wasn't reached through it.
            onChange: () async {
              if (context.canPop()) {
                context.pop();
                return;
              }
              final role = await showRolePickerSheet(context);
              if (mounted && role != null) setState(() => _role = role);
            },
          ),
          const SizedBox(height: 18),
        ],
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

        // Resend — Wrap so it drops to two lines on narrow phones.
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          runSpacing: 6,
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
                    onTap: otpState.isLoading ? null : _resend,
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
                      _role != null ? 'New to HomeGenny?' : 'Signing in',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: _textColor,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _role != null
                          ? 'After this code you\'ll complete your profile in a few quick steps.'
                          : 'You can turn on fingerprint or face unlock later in Settings.',
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

/// "Signing up as Staff · Change" — shown only for a new number.
class _SignupRoleChip extends StatelessWidget {
  const _SignupRoleChip({required this.role, required this.onChange});

  final UserRole role;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    final info = role == UserRole.staff ? RoleOptionInfo.staff : RoleOptionInfo.client;
    final accent = info.gradient.last;
    return Container(
      padding: const EdgeInsets.fromLTRB(10, 10, 6, 10),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: accent.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              gradient: LinearGradient(colors: info.gradient),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(info.icon, color: Colors.white, size: 19),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Signing up as ${role == UserRole.staff ? 'Staff' : 'Client'}',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: _textColor),
                ),
                Text(
                  info.title,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w500, color: const Color(0xFF6B7280)),
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onChange,
            style: TextButton.styleFrom(foregroundColor: accent),
            child: Text('Change', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800)),
          ),
        ],
      ),
    );
  }
}
