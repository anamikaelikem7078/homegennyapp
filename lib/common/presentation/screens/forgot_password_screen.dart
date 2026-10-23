import 'package:flutter/material.dart';
import 'package:homegennyapp/design_system/widgets/buttons/ds_buttons.dart';
import '../widgets/auth_hero_scaffold.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/forgot_password_viewmodel.dart';

/// Forgot password screen.
class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }

  String? _localizedValidator(String? key) {
    if (key == null) return null;
    return switch (key) {
      'phoneRequired' => 'Mobile number is required',
      'phoneInvalid' => 'Enter a valid mobile number',
      _ => key,
    };
  }

  Future<void> _sendResetLink() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final success = await ref
        .read(forgotPasswordViewModelProvider.notifier)
        .sendResetLink(phone: phone);

    if (!mounted) return;

    if (success) {
      context.showAppSnackBar('OTP sent');
      context.go(Uri(
        path: AppRoutes.resetPassword,
        queryParameters: {'phone': phone},
      ).toString());
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

    return AuthHeroScaffold(
      formKey: _formKey,
      onBack: () => context.pop(),
      badge: 'Account recovery',
      badgeIcon: Icons.lock_reset_rounded,
      titleLine1: 'Forgot your',
      titleHighlight: 'password?',
      subtitle: 'No worries — we\'ll send an OTP to reset it.',
      floatingIcons: const [
        Icons.lock_reset_rounded,
        Icons.sms_rounded,
        Icons.key_rounded,
      ],
      sheetTitle: 'Reset password',
      sheetSubtitle: 'Enter your registered mobile number',
      children: [
        TextFormField(
          controller: _phoneController,
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
            color: const Color(0xFF111827),
          ),
          decoration: InputDecoration(
            hintText: 'Mobile number',
            counterText: '',
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 10),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '+91',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 15,
                      fontWeight: FontWeight.w800,
                      color: const Color(0xFF111827),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Container(
                    width: 1.2,
                    height: 22,
                    color: const Color(0xFFD1D5DB),
                  ),
                ],
              ),
            ),
            prefixIconConstraints:
                const BoxConstraints(minWidth: 0, minHeight: 0),
          ),
          validator: (v) => _localizedValidator(Validators.phone(v)),
        ),
        const SizedBox(height: 28),
        DsGradientButton(
          label: 'Send OTP',
          isLoading: state.isLoading,
          onPressed: state.isLoading ? null : _sendResetLink,
        ),
        const SizedBox(height: 24),
        Wrap(
          alignment: WrapAlignment.center,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            Text(
              'Remembered it? ',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF6B7280),
              ),
            ),
            GestureDetector(
              onTap: () => context.go(AppRoutes.login),
              child: Text(
                'Back to login',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFF1A56FF),
                  decoration: TextDecoration.underline,
                  decorationColor:
                      const Color(0xFF1A56FF).withValues(alpha: 0.35),
                  decorationThickness: 2,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
      ],
    );
  }
}
