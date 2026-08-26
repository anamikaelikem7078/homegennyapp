import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/login_viewmodel.dart';
import '../../data/repositories/auth_repository_impl.dart';
import '../../domain/models/user_role.dart';

// --- Premium Palette ---
const Color _electricBlue = Color(0xFF1A56FF);
const Color _offWhite = Color(0xFFFBF9F8);
const Color _obsidianError = Color(0xFFD32F2F);
const Color _textColor = Color(0xFF1A1C1E);

/// Premium Login Screen
class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _phoneController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _localizedValidator(String? key) {
    if (key == null) return null;
    return switch (key) {
      'emailRequired' || 'phoneRequired' => 'Mobile number is required',
      'emailInvalid' || 'phoneInvalid' => 'Enter a valid mobile number',
      'passwordRequired' => context.l10n.passwordRequired,
      'passwordTooShort' => context.l10n.passwordTooShort,
      _ => key,
    };
  }

  Future<void> _onLogin() async {
    if (!_formKey.currentState!.validate()) return;

    final phone = _phoneController.text.trim();
    final success = await ref
        .read(loginViewModelProvider.notifier)
        .login(phone: phone, password: _passwordController.text);

    if (!mounted || !success) return;

    final loginState = ref.read(loginViewModelProvider);
    if (loginState.mustChangePassword) {
      context.go(AppRoutes.changePassword);
    } else {
      context.go(
        Uri(path: AppRoutes.otp, queryParameters: {'phone': phone}).toString(),
      );
    }
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
      backgroundColor: _offWhite,
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
                  // SizedBox(height: 48),
                  // _buildFooter(),
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
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            color: _electricBlue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(Icons.eco_outlined, color: _electricBlue, size: 32),
        ),
        SizedBox(height: 24),
        Text(
          'Sign in to\nHomeGenny',
          textAlign: TextAlign.center,
          style: GoogleFonts.libreCaslonText(
            fontSize: 36,
            fontWeight: FontWeight.w600,
            color: _electricBlue,
            height: 1.1,
          ),
        ),
        SizedBox(height: 12),
        Text(
          'Manage your sanctuary with\nprecision.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF6B7280),
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildForm(bool isLoading) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Mobile Number Field
          Text(
            'MOBILE NUMBER',
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
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              textInputAction: TextInputAction.next,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              style: GoogleFonts.inter(
                fontSize: 16,
                color: _textColor,
                fontWeight: FontWeight.w500,
              ),
              decoration: _inputDecoration(
                hint: '9876543210',
                prefixIcon: Icons.phone_android_rounded,
              ).copyWith(counterText: ''),
              validator: (v) => _localizedValidator(Validators.phone(v)),
            ),
          ),
          SizedBox(height: 24),

          // Password Field
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'PASSWORD',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: _textColor,
                  letterSpacing: 1.0,
                ),
              ),
              InkWell(
                onTap: () => context.push(AppRoutes.forgotPassword),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF6B7280),
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 8),
          Container(
            decoration: _inputCardDecoration(),
            child: TextFormField(
              controller: _passwordController,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onLogin(),
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
              validator: (v) => _localizedValidator(Validators.password(v)),
            ),
          ),
          SizedBox(height: 32),

          // Primary Sign In Button
          SizedBox(
            width: double.infinity,
            height: 52,
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
                          'SIGN IN',
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.2,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 20),
                      ],
                    ),
            ),
          ),
          SizedBox(height: 32),

          // OR Divider
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE5E7EB)),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Text(
                  'OR',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: const Color(0xFF9CA3AF),
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: const Color(0xFFE5E7EB)),
              ),
            ],
          ),
          SizedBox(height: 32),

          // Secondary Biometric Button
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: () => context.push(AppRoutes.biometricLogin),
              style: OutlinedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: _textColor,
                side: BorderSide(color: _textColor),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.fingerprint, color: _textColor),
                  SizedBox(width: 12),
                  Text(
                    'BIOMETRIC LOGIN',
                    style: GoogleFonts.inter(
                      fontSize: 13,
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

  // Widget _buildFooter() {
  //   return Column(
  //     children: [
  //       Row(
  //         mainAxisAlignment: MainAxisAlignment.center,
  //         children: [
  //           Text(
  //             "Don't have an account? ",
  //             style: GoogleFonts.inter(
  //               fontSize: 14,
  //               fontWeight: FontWeight.w500,
  //               color: const Color(0xFF6B7280),
  //             ),
  //           ),
  //           InkWell(
  //             onTap: () {},
  //             child: Text(
  //               'Request\nAccess',
  //               textAlign: TextAlign.center,
  //               style: GoogleFonts.inter(
  //                 fontSize: 14,
  //                 fontWeight: FontWeight.w600,
  //                 color: _electricBlue,
  //               ),
  //             ),
  //           ),
  //         ],
  //       ),
  //       SizedBox(height: 32),
  //       // Demo shortcuts at the bottom
  //       // Row(
  //       //   mainAxisAlignment: MainAxisAlignment.center,
  //       //   children: [
  //       //     _buildDemoShortcut('Client Demo', '9800000004'),
  //       //     SizedBox(width: 16),
  //       //     _buildDemoShortcut('Staff Demo', '9800000002'),
  //       //     SizedBox(width: 16),
  //       //     _buildDemoShortcut('RM Demo', '9800000001'),
  //       //   ],
  //       // ),
  //     ],
  //   ); 
  // }

  // Widget _buildDemoShortcut(String label, String phone) {
  //   return InkWell(
  //     onTap: () {
  //       _phoneController.text = phone;
  //       _passwordController.text = 'HomeGenny@2024';
  //     },
  //     child: Text(
  //       label,
  //       style: GoogleFonts.inter(
  //         fontSize: 12,
  //         fontWeight: FontWeight.w500,
  //         color: const Color(0xFF9CA3AF),
  //         decoration: TextDecoration.underline,
  //       ),
  //     ),
  //   );
  // }
}
