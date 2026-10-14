import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/utils/validators.dart';
import '../viewmodels/login_viewmodel.dart';

// --- Palette ---
const Color _brandBlue = Color(0xFF1A56FF);
const Color _deepNavy = Color(0xFF0B1B4D);
const Color _sunYellow = Color(0xFFFFD84D);
const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);
const Color _fieldFill = Color(0xFFF3F5FA);
const Color _error = Color(0xFFE5484D);

const double _heroHeight = 340;
const double _sheetOverlap = 36;

/// Login screen: gradient hero with floating service icons and a
/// slide-up form sheet.
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
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }
    HapticFeedback.lightImpact();

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

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _Hero(),
                  Transform.translate(
                    offset: const Offset(0, -_sheetOverlap),
                    child: _buildSheet(loginState.isLoading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Form(
        key: _formKey,
        child: Column(
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
            const SizedBox(height: 22),
            Text(
              'Login or continue',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: _ink,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Use your registered mobile number',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13.5,
                fontWeight: FontWeight.w500,
                color: _muted,
              ),
            ),
            const SizedBox(height: 22),

            _GlowField(
              child: TextFormField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                textInputAction: TextInputAction.next,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                style: _fieldTextStyle(letterSpacing: 1.2),
                decoration: _inputDecoration(
                  hint: 'Mobile number',
                  prefix: const _CountryPrefix(),
                ).copyWith(counterText: ''),
                validator: (v) => _localizedValidator(Validators.phone(v)),
              ),
            ),
            const SizedBox(height: 14),

            _GlowField(
              child: TextFormField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onFieldSubmitted: (_) => _onLogin(),
                style: _fieldTextStyle(
                  letterSpacing: _obscurePassword ? 3 : 0.2,
                ),
                decoration: _inputDecoration(
                  hint: 'Password',
                  prefix: const Padding(
                    padding: EdgeInsets.only(left: 16, right: 10),
                    child: Icon(Icons.lock_rounded, color: _muted, size: 20),
                  ),
                  suffix: IconButton(
                    splashRadius: 20,
                    onPressed: () =>
                        setState(() => _obscurePassword = !_obscurePassword),
                    icon: AnimatedSwitcher(
                      duration: 250.ms,
                      transitionBuilder: (child, anim) =>
                          RotationTransition(
                            turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                            child: FadeTransition(opacity: anim, child: child),
                          ),
                      child: Icon(
                        _obscurePassword
                            ? Icons.visibility_off_rounded
                            : Icons.visibility_rounded,
                        key: ValueKey(_obscurePassword),
                        color: _muted,
                        size: 20,
                      ),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 6),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () => context.push(AppRoutes.forgotPassword),
                style: TextButton.styleFrom(
                  foregroundColor: _brandBlue,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 4,
                    vertical: 4,
                  ),
                ),
                child: Text(
                  'Forgot password?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 14),

            _PrimaryButton(isLoading: isLoading, onPressed: _onLogin),
            const SizedBox(height: 22),

            Row(
              children: [
                const Expanded(child: Divider(color: Color(0xFFEDEFF3))),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'or',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF9CA3AF),
                    ),
                  ),
                ),
                const Expanded(child: Divider(color: Color(0xFFEDEFF3))),
              ],
            ),
            const SizedBox(height: 18),

            _BiometricButton(
              onPressed: () => context.push(AppRoutes.biometricLogin),
            ),
            const SizedBox(height: 26),
            _buildSignUpFooter(),
            const SizedBox(height: 12),
          ]
              .animate(interval: 60.ms, delay: 250.ms)
              .fadeIn(duration: 420.ms)
              .slideY(begin: 0.25, end: 0, curve: Curves.easeOutCubic),
        ),
      ),
    )
        .animate()
        .slideY(begin: 0.35, end: 0, duration: 650.ms, curve: Curves.easeOutQuart)
        .fadeIn(duration: 400.ms);
  }

  Widget _buildSignUpFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'New to HomeGenny? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
        GestureDetector(
          onTap: () => context.push(AppRoutes.register),
          child: Text(
            'Create account',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _brandBlue,
              decoration: TextDecoration.underline,
              decorationColor: _brandBlue.withValues(alpha: 0.35),
              decorationThickness: 2,
            ),
          ),
        ),
      ],
    );
  }

  TextStyle _fieldTextStyle({double letterSpacing = 0}) {
    return GoogleFonts.plusJakartaSans(
      fontSize: 16,
      color: _ink,
      fontWeight: FontWeight.w700,
      letterSpacing: letterSpacing,
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required Widget prefix,
    Widget? suffix,
  }) {
    final radius = BorderRadius.circular(16);
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: const Color(0xFF9CA3AF),
        fontSize: 15,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        color: _error,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      filled: true,
      fillColor: _fieldFill,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      border: OutlineInputBorder(borderSide: BorderSide.none, borderRadius: radius),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: radius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _brandBlue, width: 1.6),
        borderRadius: radius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _error),
        borderRadius: radius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _error, width: 1.6),
        borderRadius: radius,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero();

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      height: _heroHeight + topInset,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepNavy, Color(0xFF1238B8), _brandBlue],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          // Soft glowing blobs
          Positioned(
            top: -60,
            right: -40,
            child: _Blob(size: 220, color: _sunYellow.withValues(alpha: 0.18)),
          ),
          Positioned(
            bottom: 10,
            left: -70,
            child: _Blob(size: 200, color: Colors.white.withValues(alpha: 0.08)),
          ),

          // Floating service icons
          Positioned(
            top: topInset + 26,
            right: 28,
            child: const _FloatingIcon(
              icon: Icons.cleaning_services_rounded,
              color: _sunYellow,
              delay: 0,
            ),
          ),
          Positioned(
            top: topInset + 104,
            right: 96,
            child: const _FloatingIcon(
              icon: Icons.plumbing_rounded,
              color: Color(0xFF7CF2C9),
              delay: 400,
              size: 44,
            ),
          ),
          Positioned(
            top: topInset + 150,
            right: 20,
            child: const _FloatingIcon(
              icon: Icons.electrical_services_rounded,
              color: Color(0xFFFFA3C7),
              delay: 800,
              size: 50,
            ),
          ),

          // Copy
          Positioned(
            left: 24,
            right: 24,
            top: topInset + 28,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: _sunYellow,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: _deepNavy,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Text(
                      'HomeGenny',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        letterSpacing: -0.3,
                      ),
                    ),
                  ],
                )
                    .animate()
                    .fadeIn(duration: 500.ms)
                    .slideX(begin: -0.2, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 56),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(Icons.bolt_rounded, color: _sunYellow, size: 15),
                      const SizedBox(width: 4),
                      Text(
                        'Welcome back',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .scaleXY(begin: 0.8, end: 1, curve: Curves.easeOutBack),
                const SizedBox(height: 14),
                const _Headline(),
                const SizedBox(height: 10),
                Text(
                  'Manage your sanctuary with precision.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                )
                    .animate(delay: 450.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.4, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.1,
      letterSpacing: -1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Your home,', style: base)
            .animate(delay: 250.ms)
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
        Stack(
          clipBehavior: Clip.none,
          children: [
            // Highlighter swipe behind the word
            Positioned(
              left: -2,
              right: -4,
              bottom: 4,
              height: 12,
              child: Container(
                decoration: BoxDecoration(
                  color: _sunYellow.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(4),
                ),
              )
                  .animate(delay: 750.ms)
                  .scaleX(
                    begin: 0,
                    end: 1,
                    alignment: Alignment.centerLeft,
                    duration: 500.ms,
                    curve: Curves.easeOutCubic,
                  ),
            ),
            Text('sorted.', style: base),
          ],
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(begin: 0.9, end: 1.1, duration: 4.seconds, curve: Curves.easeInOut);
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.icon,
    required this.color,
    required this.delay,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final int delay;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    )
        .animate(delay: (300 + delay).ms)
        .fadeIn(duration: 500.ms)
        .scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack, duration: 600.ms)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: 2200.ms, curve: Curves.easeInOut)
        .rotate(begin: -0.015, end: 0.015, duration: 2200.ms);
  }
}

// ---------------------------------------------------------------------------
// Form pieces
// ---------------------------------------------------------------------------

/// Wraps a field and adds a soft brand-colored glow while it has focus.
class _GlowField extends StatefulWidget {
  const _GlowField({required this.child});

  final Widget child;

  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: _brandBlue.withValues(alpha: _focused ? 0.16 : 0),
              blurRadius: _focused ? 18 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedScale(
          scale: _focused ? 1.012 : 1,
          duration: 220.ms,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+91',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1.2, height: 22, color: const Color(0xFFD1D5DB)),
        ],
      ),
    );
  }
}

/// Pill-shaped primary CTA with press-scale and an idle shimmer sweep.
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading;

    Widget label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Continue',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.2),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.white,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: 0, end: 4, duration: 700.ms, curve: Curves.easeInOut),
      ],
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: 120.ms,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: 250.ms,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [Color(0xFF2F6BFF), _brandBlue, Color(0xFF1238B8)],
            ),
            boxShadow: [
              BoxShadow(
                color: _brandBlue.withValues(alpha: _pressed ? 0.25 : 0.4),
                blurRadius: _pressed ? 10 : 22,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: AnimatedSwitcher(
              duration: 250.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : KeyedSubtree(key: const ValueKey('label'), child: label),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              delay: 1800.ms,
              duration: 1400.ms,
              color: Colors.white.withValues(alpha: 0.28),
            ),
      ),
    );
  }
}

class _BiometricButton extends StatelessWidget {
  const _BiometricButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: const Color(0xFFF7F8FB),
      borderRadius: BorderRadius.circular(30),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(30),
        child: Container(
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: const Color(0xFFE5E7EB)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: _brandBlue.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.fingerprint_rounded,
                  color: _brandBlue,
                  size: 20,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(
                    begin: 1,
                    end: 1.12,
                    duration: 1100.ms,
                    curve: Curves.easeInOut,
                  ),
              const SizedBox(width: 12),
              Text(
                'Login with biometrics',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
