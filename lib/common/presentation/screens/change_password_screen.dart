import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/design_system/widgets/buttons/ds_buttons.dart';
import '../widgets/auth_hero_scaffold.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/change_password_viewmodel.dart';

// --- Premium Palette ---
const Color _textColor = Color(0xFF1A1C1E);

class ChangePasswordScreen extends ConsumerStatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  ConsumerState<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends ConsumerState<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _otpController = TextEditingController();
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

    return AuthHeroScaffold(
      formKey: _formKey,
      badge: 'Security check',
      badgeIcon: Icons.shield_rounded,
      titleLine1: 'Update your',
      titleHighlight: 'password.',
      subtitle: 'You must change your password before continuing.',
      floatingIcons: const [
        Icons.lock_reset_rounded,
        Icons.password_rounded,
        Icons.verified_user_rounded,
      ],
      children: [
        _label('OTP code'),
        TextFormField(
          controller: _otpController,
          keyboardType: TextInputType.number,
          textInputAction: TextInputAction.next,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          style: _fieldStyle(letterSpacing: 4),
          decoration: const InputDecoration(
            hintText: 'Enter 6-digit OTP',
            prefixIcon: Icon(Icons.sms_outlined),
            counterText: '',
          ),
          validator: (v) {
            final err = Validators.otp(v);
            if (err == 'otpRequired') return context.l10n.otpRequired;
            if (err == 'otpInvalid') return context.l10n.otpInvalid;
            return err;
          },
        ),
        const SizedBox(height: 18),
        _label('New password'),
        TextFormField(
          controller: _passwordController,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _submit(),
          style: _fieldStyle(letterSpacing: _obscurePassword ? 3 : 0.2),
          decoration: InputDecoration(
            hintText: 'Create a strong password',
            prefixIcon: const Icon(Icons.lock_outline_rounded),
            suffixIcon: IconButton(
              icon: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
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
        const SizedBox(height: 30),
        DsGradientButton(
          label: 'Update password',
          isLoading: state.isLoading,
          onPressed: state.isLoading ? null : _submit,
        ),
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _label(String text) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: _textColor,
          ),
        ),
      );

  TextStyle _fieldStyle({double letterSpacing = 0}) =>
      GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w700,
        color: _textColor,
        letterSpacing: letterSpacing,
      );
}
