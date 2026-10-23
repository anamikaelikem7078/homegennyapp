import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../core/presentation/screens/app_settings_screens.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';

void _back(BuildContext context, [String fallback = StaffRoutes.profile]) =>
    context.canPop() ? context.pop() : context.go(fallback);

/// Staff settings.
class StaffSettingsScreen extends ConsumerWidget {
  const StaffSettingsScreen({super.key});

  Future<void> _logout(BuildContext context, WidgetRef ref) async {
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Log out?',
      message: 'You will need to sign in again on this device.',
      confirmLabel: 'Log out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok != true) return;
    await ref.read(authProvider.notifier).logout();
    if (context.mounted) context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeProvider);
    final themeMode = ref.watch(themeModeProvider);
    final user = ref.watch(authProvider).user;
    final langLabel = locale.languageCode == 'hi' ? 'Hindi' : 'English';
    final themeLabel = switch (themeMode) {
      ThemeMode.dark => 'Dark',
      ThemeMode.light => 'Light',
      ThemeMode.system => 'System',
    };

    return DsPage(
      title: 'Settings',
      subtitle: 'App preferences and security',
      onBack: () => _back(context),
      bottom: DsOutlineButton(
        label: 'Log out',
        icon: Icons.logout_rounded,
        color: AppColors.error,
        onPressed: () => _logout(context, ref),
      ),
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(colors: [AppColors.sunYellow, AppColors.secondary, AppColors.sunYellow]),
                ),
                child: Container(
                  padding: const EdgeInsets.all(2),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: DsInitialsAvatar(name: user?.name ?? 'Staff', size: 54, radius: 27),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      user?.name ?? 'Your account',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                    if (user?.phone != null && user!.phone!.isNotEmpty)
                      Text(
                        user.phone!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                    const SizedBox(height: 8),
                    const DsGlassPill('STAFF ACCOUNT', icon: Icons.verified_user_rounded),
                  ],
                ),
              ),
            ],
          ),
        ),
        const DsSection('Preferences'),
        DsListCard(
          icon: Icons.translate_rounded,
          title: context.l10n.languageSettings,
          subtitle: 'Currently $langLabel',
          onTap: () => context.push(StaffRoutes.settingsLanguage),
        ),
        DsListCard(
          icon: Icons.palette_rounded,
          title: context.l10n.themeSettings,
          subtitle: 'Currently $themeLabel',
          onTap: () => context.push(StaffRoutes.settingsTheme),
        ),
        const DsSection('Security'),
        DsListCard(
          icon: Icons.fingerprint_rounded,
          title: 'Biometric login',
          subtitle: 'Sign in with fingerprint or face',
          onTap: () => context.push(StaffRoutes.settingsBiometric),
        ),
        const DsSection('Support'),
        DsListCard(
          icon: Icons.support_agent_rounded,
          title: 'Help & support',
          subtitle: 'Chat, call or read FAQs',
          onTap: () => context.push(StaffRoutes.help),
        ),
      ],
    );
  }
}

/// Language settings.
class StaffLanguageSettingsScreen extends ConsumerStatefulWidget {
  const StaffLanguageSettingsScreen({super.key});

  @override
  ConsumerState<StaffLanguageSettingsScreen> createState() => _StaffLanguageSettingsScreenState();
}

class _StaffLanguageSettingsScreenState extends ConsumerState<StaffLanguageSettingsScreen> {
  late String _selected = ref.read(localeProvider).languageCode;
  bool _saving = false;

  static const _languages = [
    ('en', 'English', 'Default', 'A'),
    ('hi', 'Hindi', 'हिन्दी', 'अ'),
  ];

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(localeProvider.notifier).setLocale(Locale(_selected));
    if (!mounted) return;
    setState(() => _saving = false);
    context.showDsSnackBar('Language updated', type: DsSnackBarType.success);
    _back(context, StaffRoutes.settings);
  }

  @override
  Widget build(BuildContext context) {
    final current = ref.watch(localeProvider).languageCode;

    return DsPage(
      title: 'Language',
      subtitle: 'Choose your app language',
      onBack: () => _back(context, StaffRoutes.settings),
      bottom: DsGradientButton(
        label: 'Save changes',
        icon: Icons.check_rounded,
        isLoading: _saving,
        onPressed: _saving || _selected == current ? null : _save,
      ),
      body: [
        for (final (code, name, sub, glyph) in _languages)
          _LanguageCard(
            name: name,
            subtitle: sub,
            glyph: glyph,
            selected: _selected == code,
            current: current == code,
            onTap: () => setState(() => _selected = code),
          ),
        const SizedBox(height: 6),
        const DsNote(text: 'More languages are coming soon.'),
      ],
    );
  }
}

class _LanguageCard extends StatelessWidget {
  const _LanguageCard({
    required this.name,
    required this.subtitle,
    required this.glyph,
    required this.selected,
    required this.current,
    required this.onTap,
  });

  final String name;
  final String subtitle;
  final String glyph;
  final bool selected;
  final bool current;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 220.ms,
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: dsCardDecoration(
          color: selected ? AppColors.primary.withValues(alpha: 0.05) : Colors.white,
          border: selected ? AppColors.primary : null,
        ),
        child: Row(
          children: [
            Container(
              width: 52,
              height: 52,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: selected
                    ? const LinearGradient(colors: [AppColors.primaryLight, AppColors.primaryDark])
                    : null,
                color: selected ? null : AppColors.iconAccentSoft,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                glyph,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: selected ? Colors.white : AppColors.iconAccent,
                ),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    name,
                    style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                  ),
                  Text(subtitle, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary)),
                ],
              ),
            ),
            if (current) ...[const DsPill('Current'), const SizedBox(width: 8)],
            AnimatedContainer(
              duration: 220.ms,
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: selected ? AppColors.primary : AppColors.lightBorder, width: selected ? 7 : 2),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Theme settings.
class StaffThemeSettingsScreen extends StatelessWidget {
  const StaffThemeSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) => const AppThemeSettingsScreen();
}

/// Biometric settings.
class StaffBiometricSettingsScreen extends ConsumerStatefulWidget {
  const StaffBiometricSettingsScreen({super.key});

  @override
  ConsumerState<StaffBiometricSettingsScreen> createState() => _StaffBiometricSettingsScreenState();
}

class _StaffBiometricSettingsScreenState extends ConsumerState<StaffBiometricSettingsScreen> {
  bool _enabled = false;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final enabled = await ref.read(authRepositoryProvider).isBiometricEnabled();
    if (mounted) {
      setState(() {
        _enabled = enabled;
        _loading = false;
      });
    }
  }

  Future<void> _toggle(bool value) async {
    HapticFeedback.mediumImpact();
    await ref.read(authRepositoryProvider).setBiometricEnabled(value);
    if (!mounted) return;
    setState(() => _enabled = value);
    context.showDsSnackBar(value ? 'Biometric login enabled' : 'Biometric login disabled', type: DsSnackBarType.success);
  }

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: 'Biometric login',
      subtitle: 'Faster, secure sign-in',
      onBack: () => _back(context, StaffRoutes.settings),
      bottom: _loading
          ? null
          : DsGradientButton(
              label: 'Done',
              icon: Icons.check_rounded,
              onPressed: () => _back(context, StaffRoutes.settings),
            ),
      body: _loading
          ? const [
              Padding(
                padding: EdgeInsets.symmetric(vertical: 80),
                child: Center(child: CircularProgressIndicator()),
              ),
            ]
          : [
              const SizedBox(height: 12),
              Center(
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    for (final (size, alpha) in [(190.0, 0.05), (150.0, 0.08)])
                      Container(
                        width: size,
                        height: size,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: (_enabled ? AppColors.success : AppColors.primary).withValues(alpha: alpha),
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.94, end: 1.06, duration: 1500.ms, curve: Curves.easeInOut),
                    AnimatedContainer(
                      duration: 300.ms,
                      width: 108,
                      height: 108,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: _enabled
                              ? const [Color(0xFF34D399), Color(0xFF059669)]
                              : const [AppColors.primaryLight, AppColors.primaryDark],
                        ),
                        borderRadius: BorderRadius.circular(34),
                        boxShadow: [
                          BoxShadow(
                            color: (_enabled ? AppColors.success : AppColors.primary).withValues(alpha: 0.35),
                            blurRadius: 24,
                            offset: const Offset(0, 10),
                          ),
                        ],
                      ),
                      child: Icon(
                        _enabled ? Icons.verified_user_rounded : Icons.fingerprint_rounded,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              Text(
                _enabled ? 'Biometric login is on' : 'Sign in with a touch',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
              ),
              const SizedBox(height: 4),
              Text(
                'Use your fingerprint or face instead of typing your password.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45, color: AppColors.lightTextSecondary),
              ),
              const SizedBox(height: 22),
              Material(
                color: Colors.white,
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: () => _toggle(!_enabled),
                  child: Ink(
                    padding: const EdgeInsets.all(14),
                    decoration: dsCardDecoration(),
                    child: Row(
                      children: [
                        const DsIconTile(Icons.fingerprint_rounded),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Enable biometric login',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.lightTextPrimary,
                                ),
                              ),
                              Text(
                                'Fingerprint or face recognition',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                              ),
                            ],
                          ),
                        ),
                        Switch(
                          value: _enabled,
                          activeThumbColor: Colors.white,
                          activeTrackColor: AppColors.primary,
                          inactiveThumbColor: Colors.white,
                          inactiveTrackColor: AppColors.lightBorder,
                          trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
                          onChanged: _toggle,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 14),
              const DsNote(
                tone: DsNoteTone.success,
                text: 'Your biometric data never leaves your device.',
              ),
            ],
    );
  }
}

/// Change password screen.
class StaffChangePasswordScreen extends ConsumerStatefulWidget {
  const StaffChangePasswordScreen({super.key});

  @override
  ConsumerState<StaffChangePasswordScreen> createState() => _StaffChangePasswordScreenState();
}

class _StaffChangePasswordScreenState extends ConsumerState<StaffChangePasswordScreen> {
  final _currentController = TextEditingController();
  final _newController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _obscureCurrent = true;
  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _loading = false;

  @override
  void dispose() {
    _currentController.dispose();
    _newController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_newController.text.isEmpty) {
      context.showDsSnackBar('Please enter a new password', type: DsSnackBarType.error);
      return;
    }
    if (_newController.text != _confirmController.text) {
      context.showDsSnackBar('Passwords do not match', type: DsSnackBarType.error);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(staffRepositoryProvider).updatePassword(
          _currentController.text,
          _newController.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Password updated successfully', type: DsSnackBarType.success);
        _back(context, StaffRoutes.settings);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  /// 0..4 strength score with a label and colour.
  (int, String, Color) get _strength {
    final p = _newController.text;
    if (p.isEmpty) return (0, 'Enter a password', AppColors.lightTextHint);
    var score = 0;
    if (p.length >= 8) score++;
    if (RegExp(r'[A-Z]').hasMatch(p) && RegExp(r'[a-z]').hasMatch(p)) score++;
    if (RegExp(r'\d').hasMatch(p)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(p)) score++;
    return switch (score) {
      <= 1 => (1, 'Weak', AppColors.error),
      2 => (2, 'Fair', AppColors.warning),
      3 => (3, 'Good', AppColors.primary),
      _ => (4, 'Strong', AppColors.success),
    };
  }

  Widget _eye(bool obscure, VoidCallback toggle) => IconButton(
        icon: Icon(obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded, color: AppColors.lightTextSecondary),
        onPressed: toggle,
      );

  @override
  Widget build(BuildContext context) {
    final (score, label, color) = _strength;
    final matches = _confirmController.text.isNotEmpty && _confirmController.text == _newController.text;

    return DsPage(
      title: 'Change password',
      subtitle: 'Keep your account secure',
      onBack: () => _back(context, StaffRoutes.settings),
      bottom: DsGradientButton(
        label: 'Update password',
        icon: Icons.lock_rounded,
        isLoading: _loading,
        onPressed: _loading ? null : _submit,
      ),
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Use a long password with letters, numbers and symbols.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    height: 1.4,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              const DsFloatingIconTile(icon: Icons.lock_reset_rounded),
            ],
          ),
        ),
        const SizedBox(height: 18),
        DsLabeledField(
          label: 'Current password',
          controller: _currentController,
          icon: Icons.lock_outline_rounded,
          hint: 'Enter current password',
          obscureText: _obscureCurrent,
          suffix: _eye(_obscureCurrent, () => setState(() => _obscureCurrent = !_obscureCurrent)),
        ),
        const SizedBox(height: 16),
        DsLabeledField(
          label: 'New password',
          controller: _newController,
          icon: Icons.lock_rounded,
          hint: 'Create new password',
          obscureText: _obscureNew,
          onChanged: (_) => setState(() {}),
          suffix: _eye(_obscureNew, () => setState(() => _obscureNew = !_obscureNew)),
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            for (var i = 1; i <= 4; i++) ...[
              if (i > 1) const SizedBox(width: 6),
              Expanded(
                child: AnimatedContainer(
                  duration: 250.ms,
                  height: 6,
                  decoration: BoxDecoration(
                    color: i <= score ? color : AppColors.lightBorder,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
              ),
            ],
            const SizedBox(width: 10),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
        const SizedBox(height: 16),
        DsLabeledField(
          label: 'Confirm password',
          controller: _confirmController,
          icon: Icons.lock_rounded,
          hint: 'Confirm new password',
          obscureText: _obscureConfirm,
          onChanged: (_) => setState(() {}),
          suffix: _eye(_obscureConfirm, () => setState(() => _obscureConfirm = !_obscureConfirm)),
        ),
        if (_confirmController.text.isNotEmpty) ...[
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(
                matches ? Icons.check_circle_rounded : Icons.error_rounded,
                size: 16,
                color: matches ? AppColors.success : AppColors.error,
              ),
              const SizedBox(width: 6),
              Text(
                matches ? 'Passwords match' : 'Passwords do not match',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w700,
                  color: matches ? AppColors.success : AppColors.error,
                ),
              ),
            ],
          ),
        ],
      ],
    );
  }
}
