import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/router/app_routes.dart';
import '../../../design_system/design_system.dart';
import '../providers/auth_provider.dart';

const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);

/// How [_OfficeLoginSheet] ended.
enum _OfficeLoginResult { signedIn, mustChangePassword }

/// Office accounts (RM, BM, Admin, HR) don't use OTP: the server answers
/// `POST /auth/otp/send` with `use_password_login: true` for them. This asks
/// for the password, signs in with `POST /auth/login`, and opens the
/// account's home — or Change password when the server requires it.
Future<void> signInOfficeAccount(BuildContext context, String phone) async {
  final router = GoRouter.of(context);
  final container = ProviderScope.containerOf(context, listen: false);
  final result = await showModalBottomSheet<_OfficeLoginResult>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _OfficeLoginSheet(phone: phone),
  );
  switch (result) {
    case _OfficeLoginResult.mustChangePassword:
      // Not marked signed-in yet: Change password is a login route, which
      // the router would otherwise leave for the dashboard.
      router.go(AppRoutes.changePassword);
    case _OfficeLoginResult.signedIn:
      final role = container.read(authProvider).user?.role;
      if (role != null) router.go(role.dashboardRoute);
    case null:
      break;
  }
}

class _OfficeLoginSheet extends ConsumerStatefulWidget {
  const _OfficeLoginSheet({required this.phone});

  final String phone;

  @override
  ConsumerState<_OfficeLoginSheet> createState() => _OfficeLoginSheetState();
}

class _OfficeLoginSheetState extends ConsumerState<_OfficeLoginSheet> {
  final _password = TextEditingController();
  bool _obscure = true;
  bool _loading = false;
  String? _error;

  @override
  void dispose() {
    _password.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_password.text.isEmpty) {
      setState(() => _error = 'Please enter your password.');
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await ref
        .read(authRepositoryProvider)
        .login(phone: widget.phone, password: _password.text);
    if (!mounted) return;
    final failure = result.failureOrNull;
    if (failure != null) {
      setState(() {
        _loading = false;
        _error = ExceptionHandler.userMessage(failure);
      });
      return;
    }
    if (result.dataOrNull?.mustChangePassword == true) {
      Navigator.of(context).pop(_OfficeLoginResult.mustChangePassword);
      return;
    }
    // Loads who this is (role, name) and marks the session signed in.
    final ok = await ref.read(authProvider.notifier).fetchProfile();
    if (!mounted) return;
    if (ok) {
      Navigator.of(context).pop(_OfficeLoginResult.signedIn);
    } else {
      setState(() {
        _loading = false;
        _error = ref.read(authProvider).errorMessage ?? 'Could not sign you in. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(24, 14, 24, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  decoration: BoxDecoration(
                    color: const Color(0xFFE5E7EB),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: const Icon(Icons.business_center_rounded, color: AppColors.primary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Office account',
                          style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: _ink),
                        ),
                        Text(
                          '+91 ${widget.phone} signs in with a password.',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13, color: _muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              TextField(
                controller: _password,
                autofocus: true,
                obscureText: _obscure,
                enabled: !_loading,
                textInputAction: TextInputAction.done,
                autofillHints: const [AutofillHints.password],
                onSubmitted: (_) => _submit(),
                style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: _ink),
                decoration: InputDecoration(
                  hintText: 'Password',
                  errorText: _error,
                  errorMaxLines: 3,
                  prefixIcon: const Icon(Icons.lock_outline_rounded),
                  suffixIcon: IconButton(
                    tooltip: _obscure ? 'Show password' : 'Hide password',
                    icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: _loading
                      ? null
                      : () {
                          // Captured first: the sheet's context is gone once
                          // it is popped.
                          final router = GoRouter.of(context);
                          Navigator.of(context).pop();
                          router.push(AppRoutes.forgotPassword);
                        },
                  child: const Text('Forgot password?'),
                ),
              ),
              const SizedBox(height: 4),
              DsGradientButton(
                label: 'Log in',
                icon: Icons.arrow_forward_rounded,
                isLoading: _loading,
                onPressed: _loading ? null : _submit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
