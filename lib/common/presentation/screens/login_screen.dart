import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/login_viewmodel.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_role.dart';

// --- Ethereal Luxe Palette ---

const Color _electricBlue = Color(0xFF1A56FF);
const Color _obsidianError = Color(0xFFD32F2F);

/// Ethereal Obsidian Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _localizedValidator(String? key) {
    if (key == null) return null;
    return switch (key) {
      'emailRequired' => context.l10n.emailRequired,
      'emailInvalid' => context.l10n.emailInvalid,
      'passwordRequired' => context.l10n.passwordRequired,
      'passwordTooShort' => context.l10n.passwordTooShort,
      _ => key,
    };
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final success = await ref
        .read(loginViewModelProvider.notifier)
        .login(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );

    if (!mounted || !success) return;

    final email = _emailController.text.trim();
    if (AuthRepositoryImpl.isDemoCredentials(email, _passwordController.text)) {
      final profileOk = await ref.read(authProvider.notifier).fetchProfile();
      if (!mounted || !profileOk) return;

      final role = ref.read(authProvider).user?.role ?? UserRole.client;
      context.go(role.dashboardRoute);
      return;
    }

    // Commented out OTP navigation as per request to bypass it
    // context.go('${AppRoutes.otp}?phone=${Uri.encodeComponent(email)}');

    // Directly show home page
    final profileOk = await ref.read(authProvider.notifier).fetchProfile();
    if (!mounted || !profileOk) return;

    final role = ref.read(authProvider).user?.role ?? UserRole.client;
    context.go(role.dashboardRoute);
  }

  @override
  Widget build(BuildContext context) {
    final loginState = ref.watch(loginViewModelProvider);

    ref.listen(loginViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: ResponsiveLayout(
            maxWidth: 500,
            padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  SizedBox(height: 24),
                  _buildHeader(),
                  SizedBox(height: 48),
                  _buildForm(loginState.isLoading),
                  SizedBox(height: 48),
                  _buildFooter(),
                  SizedBox(height: 16),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        SizedBox(height: 32),
        Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            fontSize: 42,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
            letterSpacing: -1.0,
          ),
        ),
        SizedBox(height: 8),
        Text(
          'EXQUISITE ESTATE MANAGEMENT',
          style: GoogleFonts.inter(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurfaceVariant,
            letterSpacing: 2.0,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: context.theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            spreadRadius: 0,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Email Field
            Text(
              'EMAIL ADDRESS',
              style: GoogleFonts.inter(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
                letterSpacing: 0.5,
              ),
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.colors.onSurface,
                fontWeight: FontWeight.w500,
              ),
              decoration: _minimalInputDecoration(hint: 'name@estate.com'),
              validator: (v) => _localizedValidator(Validators.email(v)),
            ),
            SizedBox(height: 20),

            // Password Field
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'PASSWORD',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: context.colors.onSurface,
                    letterSpacing: 0.5,
                  ),
                ),
                InkWell(
                  onTap: () => context.push(AppRoutes.forgotPassword),
                  child: Text(
                    'Forgot?',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: _electricBlue,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 8),
            TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLogin(),
              style: GoogleFonts.inter(
                fontSize: 15,
                color: context.colors.onSurface,
                fontWeight: FontWeight.bold,
                letterSpacing: 2.0,
              ),
              decoration: _minimalInputDecoration(hint: '••••••••'),
              validator: (v) => _localizedValidator(Validators.password(v)),
            ),
            SizedBox(height: 32),

            // Primary Sign In Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                onPressed: isLoading ? null : _onLogin,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _electricBlue,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: isLoading
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: context.theme.cardColor,
                        ),
                      )
                    : Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Text(
                            'SIGN IN',
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.2,
                            ),
                          ),
                          SizedBox(width: 8),
                          Icon(Icons.arrow_forward, size: 16),
                        ],
                      ),
              ),
            ),
            SizedBox(height: 24),

            // OR Divider
            Row(
              children: [
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.theme.dividerColor,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Text(
                    'OR',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ),
                Expanded(
                  child: Container(
                    height: 1,
                    color: context.theme.dividerColor,
                  ),
                ),
              ],
            ),
            SizedBox(height: 24),

            // Secondary Biometric Button
            SizedBox(
              width: double.infinity,
              height: 48,
              child: OutlinedButton(
                onPressed: () => context.push(AppRoutes.biometricLogin),
                style: OutlinedButton.styleFrom(
                  foregroundColor: context.colors.onSurface,
                  side: BorderSide(color: context.theme.dividerColor),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.fingerprint, color: context.colors.onSurface),
                    SizedBox(width: 8),
                    Text(
                      'BIOMETRIC LOGIN',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        Text(
          'EXPLORE PREVIEW MODES',
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: context.colors.onSurface,
            letterSpacing: 1.0,
          ),
        ),
        SizedBox(height: 24),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _buildDemoSquare(
              'Client',
              Icons.person_outline,
              'client@homegenny.com',
            ),
            SizedBox(width: 16),
            _buildDemoSquare(
              'Staff',
              Icons.badge_outlined,
              'staff@homegenny.com',
            ),
            SizedBox(width: 16),
            // _buildDemoSquare('RM', Icons.account_balance_outlined, 'rm@homegenny.com'),
          ],
        ),
      ],
    );
  }

  Widget _buildDemoSquare(String label, IconData icon, String email) {
    return InkWell(
      onTap: () {
        _emailController.text = email;
        _passwordController.text = 'demo1234';
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        width: 100,
        height: 115,
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          border: Border.all(
            color: _electricBlue.withOpacity(0.15),
            width: 1.5,
          ),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _electricBlue.withOpacity(0.12),
              blurRadius: 15,
              spreadRadius: 1,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                color: _electricBlue.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 28, color: _electricBlue),
            ),
            SizedBox(height: 14),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _minimalInputDecoration({required String hint}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.inter(
        color: context.colors.onSurfaceVariant.withOpacity(0.8),
        fontSize: 14,
        letterSpacing: 0,
      ),
      filled: false,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      border: OutlineInputBorder(
        borderSide: BorderSide(color: context.theme.dividerColor),
        borderRadius: BorderRadius.circular(4),
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: context.theme.dividerColor),
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
