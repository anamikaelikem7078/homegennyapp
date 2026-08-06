import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/constants/app_constants.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../../domain/models/user_role.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/otp_viewmodel.dart';
import '../widgets/app_button.dart';

/// OTP verification screen.
class OtpScreen extends ConsumerStatefulWidget {
  const OtpScreen({super.key, required this.phone});

  final String phone;

  @override
  ConsumerState<OtpScreen> createState() => _OtpScreenState();
}

class _OtpScreenState extends ConsumerState<OtpScreen> {
  final _otpController = TextEditingController();

  @override
  void dispose() {
    _otpController.dispose();
    super.dispose();
  }

  String? _localizedValidator(String? key) {
    if (key == null) return null;
    return switch (key) {
      'otpRequired' => context.l10n.otpRequired,
      'otpInvalid' => context.l10n.otpInvalid,
      _ => key,
    };
  }

  Future<void> _verify() async {
    final otp = _otpController.text.trim();
    final error = Validators.otp(otp, length: AppConstants.otpLength);
    if (error != null) {
      context.showAppSnackBar(_localizedValidator(error)!, isError: true);
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
    final l10n = context.l10n;
    final displayPhone = widget.phone.isNotEmpty ? widget.phone : 'your phone';

    ref.listen(otpViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios_new_rounded),
          onPressed: () => context.go(AppRoutes.login),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SizedBox(height: 16),
              Text(
                l10n.otpTitle,
                style: context.textTheme.headlineMedium,
              ),
              SizedBox(height: 12),
              Text(
                l10n.otpSubtitle(displayPhone),
                style: context.textTheme.bodyLarge,
              ),
              SizedBox(height: 40),
              TextFormField(
                controller: _otpController,
                keyboardType: TextInputType.number,
                textAlign: TextAlign.center,
                maxLength: AppConstants.otpLength,
                style: context.textTheme.headlineMedium?.copyWith(
                  letterSpacing: 12,
                  fontWeight: FontWeight.w700,
                ),
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                decoration: const InputDecoration(
                  hintText: '• • • • • •',
                  counterText: '',
                ),
              ),
              SizedBox(height: 32),
              AppButton(
                label: l10n.verifyOtp,
                isLoading: otpState.isLoading,
                onPressed: _verify,
                icon: Icons.verified_user_outlined,
              ),
              SizedBox(height: 24),
              Center(
                child: otpState.canResend
                    ? TextButton(
                        onPressed: () {
                          ref.read(otpViewModelProvider.notifier).resendOtp();
                          context.showAppSnackBar('OTP resent successfully');
                        },
                        child: Text(l10n.resendOtp),
                      )
                    : Text(
                        l10n.resendOtpIn(otpState.resendSeconds),
                        style: context.textTheme.bodyMedium,
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
