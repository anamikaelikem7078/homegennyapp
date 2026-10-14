import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../../../design_system/widgets/layout/ds_hero_header.dart';
import '../widgets/rm_stage_ui.dart';
import '../navigation/rm_routes.dart';
import 'rm_account_widgets.dart';

const _supportEmail = 'support@homegenny.com';

final _appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return 'v${info.version}';
});

String _roleLabel(String? role) => switch (role) {
      'BM' => 'Branch Manager',
      'ADMIN' => 'Administrator',
      _ => 'Relationship Manager',
    };

String _deviceLabel() {
  if (kIsWeb) return 'Web browser';
  return switch (defaultTargetPlatform) {
    TargetPlatform.android => 'Android device',
    TargetPlatform.iOS => 'iOS device',
    TargetPlatform.macOS => 'Mac',
    TargetPlatform.windows => 'Windows PC',
    _ => 'This device',
  };
}

// ─────────────────────────────────────────────────────────────────────────
// Personal Information
// ─────────────────────────────────────────────────────────────────────────

class RmPersonalInfoScreen extends ConsumerWidget {
  const RmPersonalInfoScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final name = user?.name.trim() ?? '';
    final roleCode = user?.role.value ?? 'RM';

    Widget copyButton(String value) => IconButton(
          icon: const Icon(Icons.copy_rounded, size: 19, color: RmTheme.electricBlue),
          tooltip: 'Copy',
          onPressed: value.isEmpty
              ? null
              : () {
                  Clipboard.setData(ClipboardData(text: value));
                  rmToast(context, 'Copied to clipboard');
                },
        );

    return RmAccountScaffold(
      title: 'Personal info',
      subtitle: 'Your HomeGenny account details',
      hero: _AvatarHero(
        name: name.isEmpty ? _roleLabel(roleCode) : name,
        role: _roleLabel(roleCode),
        roleCode: roleCode,
        avatarUrl: user?.avatarUrl,
      ),
      children: [
        const RmSectionLabel('Basic details'),
        RmGroupCard(children: [
          RmInfoRow(icon: Icons.person_rounded, label: 'Full name', value: name),
          RmInfoRow(
            icon: Icons.mail_rounded,
            label: 'Email',
            value: user?.email ?? '',
            trailing: copyButton(user?.email ?? ''),
          ),
          RmInfoRow(
            icon: Icons.phone_rounded,
            label: 'Phone',
            value: user?.phone ?? '',
            trailing: copyButton(user?.phone ?? ''),
          ),
        ]),
        const RmSectionLabel('Work details'),
        RmGroupCard(children: [
          RmInfoRow(
            icon: Icons.badge_rounded,
            label: 'Role',
            value: _roleLabel(roleCode),
            badge: RmPill(roleCode, border: RmTheme.electricBlue.withValues(alpha: 0.2)),
          ),
          RmInfoRow(
            icon: Icons.fingerprint_rounded,
            label: 'User ID',
            value: user?.id ?? '',
            monospace: true,
            trailing: copyButton(user?.id ?? ''),
          ),
        ]),
        const SizedBox(height: 20),
        const RmNote(
          title: 'Managed by HomeGenny',
          text: 'To change your name, email or phone number, contact support.',
        ),
        const SizedBox(height: 16),
        DsOutlineButton(
          label: 'Request changes via support',
          icon: Icons.headset_mic_rounded,
          onPressed: () => context.push(RmRoutes.support),
        ),
      ],
    );
  }
}

class _AvatarHero extends StatelessWidget {
  const _AvatarHero({
    required this.name,
    required this.role,
    required this.roleCode,
    this.avatarUrl,
  });
  final String name;
  final String role;
  final String roleCode;
  final String? avatarUrl;

  @override
  Widget build(BuildContext context) {
    final initials = name
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Container(
                width: 72,
                height: 72,
                padding: const EdgeInsets.all(3),
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: SweepGradient(
                    colors: [Color(0xFFFFD84D), RmTheme.iconAccent, Color(0xFFFFD84D)],
                  ),
                ),
                child: Container(
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  padding: const EdgeInsets.all(3),
                  child: ClipOval(
                    child: avatarUrl != null
                        ? Image.network(avatarUrl!, fit: BoxFit.cover)
                        : Container(
                            alignment: Alignment.center,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                                colors: [RmTheme.electricBlue, RmTheme.navy],
                              ),
                            ),
                            child: Text(
                              initials.isEmpty ? 'R' : initials,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 24,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ),
                  ),
                ),
              ).animate().scaleXY(begin: 0.6, end: 1, duration: 600.ms, curve: Curves.elasticOut),
              Positioned(
                right: -2,
                bottom: -2,
                child: Container(
                  padding: const EdgeInsets.all(3),
                  decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                  child: const Icon(Icons.verified_rounded, size: 18, color: RmTheme.iconAccent),
                ),
              ),
            ],
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 6,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        roleCode,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: RmTheme.electricBlue,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                      decoration: BoxDecoration(
                        color: RmTheme.emeraldGreen.withValues(alpha: 0.25),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Color(0xFF6EE7B7),
                              shape: BoxShape.circle,
                            ),
                          )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fade(begin: 0.4, end: 1, duration: 900.ms),
                          const SizedBox(width: 5),
                          Text(
                            'Active',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  role,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Security & Privacy
// ─────────────────────────────────────────────────────────────────────────

class RmSecurityScreen extends ConsumerWidget {
  const RmSecurityScreen({super.key});

  void _showDataPolicy(BuildContext context) {
    showDialog<void>(
      context: context,
      builder: (ctx) => DsDialogCard(
        children: [
          const DsDialogIcon(icon: Icons.shield_rounded, color: RmTheme.iconAccent),
          const SizedBox(height: 16),
          Text(
            'How we use your data',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: RmAccountStyle.ink,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Staff documents and verification records you handle are visible only to authorised '
            'HomeGenny team members and are used only to run placements and compliance checks. '
            'They are never shared for marketing.\n\nFor data requests, contact $_supportEmail.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.5, color: RmAccountStyle.body),
          ),
          const SizedBox(height: 22),
          DsPrimaryButton(label: 'Got it', onPressed: () => Navigator.pop(ctx)),
        ],
      ),
    );
  }

  Future<void> _confirmSignOut(BuildContext context, WidgetRef ref) async {
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Sign out?',
      message: 'You will need to log in again on this device.',
      confirmLabel: 'Sign out',
      isDestructive: true,
      icon: Icons.logout_rounded,
    );
    if (ok != true) return;
    await ref.read(authProvider.notifier).logout();
    if (!context.mounted) return;
    context.go(AppRoutes.login);
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(_appVersionProvider).valueOrNull;

    return RmAccountScaffold(
      title: 'Security & privacy',
      subtitle: 'Keep your account safe',
      actions: [
        DsHeroIconButton(
          tooltip: 'Help',
          icon: Icons.help_outline_rounded,
          onPressed: () => context.push(RmRoutes.support),
        ),
      ],
      hero: Row(
        children: [
          Expanded(
            child: RmHeroGlassTile(
              icon: Icons.verified_user_rounded,
              label: 'Protection',
              value: 'OTP verified',
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: RmHeroGlassTile(
              icon: Icons.devices_rounded,
              label: 'Signed in on',
              value: _deviceLabel(),
            ),
          ),
        ],
      ),
      children: [
        const RmNote(
          tone: RmNoteTone.success,
          title: 'Account protection is on',
          text: 'Password changes are verified with a one-time code sent to your registered phone.',
        ),
        const RmSectionLabel('Password'),
        RmGroupCard(children: [
          RmActionRow(
            icon: Icons.lock_reset_rounded,
            title: 'Change password',
            subtitle: 'Verify with an OTP sent to your phone',
            onTap: () => showModalBottomSheet<void>(
              context: context,
              isScrollControlled: true,
              backgroundColor: Colors.transparent,
              barrierColor: Colors.black.withValues(alpha: 0.45),
              builder: (_) => const _ChangePasswordSheet(),
            ),
          ),
        ]),
        RmSectionLabel('Privacy', trailing: RmSectionMeta('Policy', onTap: () => _showDataPolicy(context))),
        RmGroupCard(children: [
          RmActionRow(
            icon: Icons.shield_outlined,
            title: 'How we use your data',
            subtitle: 'Your data is used only to run placements and compliance checks',
            onTap: () => _showDataPolicy(context),
          ),
        ]),
        RmSectionLabel('Session', trailing: RmSectionMeta(_deviceLabel())),
        RmGroupCard(children: [
          RmActionRow(
            icon: Icons.logout_rounded,
            title: 'Sign out of this device',
            subtitle: 'You will need to log in again',
            color: RmAccountStyle.coral,
            chipColor: RmAccountStyle.coralChip,
            onTap: () => _confirmSignOut(context, ref),
          ),
        ]),
        const SizedBox(height: 32),
        if (version != null)
          Text(
            'HomeGenny $version',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: RmTheme.textSecondary),
          ),
      ],
    );
  }
}

class _ChangePasswordSheet extends ConsumerStatefulWidget {
  const _ChangePasswordSheet();

  @override
  ConsumerState<_ChangePasswordSheet> createState() => _ChangePasswordSheetState();
}

class _ChangePasswordSheetState extends ConsumerState<_ChangePasswordSheet> {
  final _otp = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();
  bool _otpSent = false;
  bool _busy = false;
  bool _obscure = true;
  String? _error;

  @override
  void dispose() {
    _otp.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    final phone = ref.read(authProvider).user?.phone;
    if (phone == null || phone.isEmpty) {
      setState(() => _error = 'No phone number on your account. Contact support.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).forgotPassword(phone: phone);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) => setState(() {
        _busy = false;
        _otpSent = true;
      }),
      onError: (f) => setState(() {
        _busy = false;
        _error = f.message;
      }),
    );
  }

  Future<void> _submit() async {
    final pw = _password.text;
    if (_otp.text.trim().isEmpty) {
      setState(() => _error = 'Enter the OTP you received.');
      return;
    }
    if (pw.length < 8 || pw.length > 72) {
      setState(() => _error = 'Password must be 8–72 characters.');
      return;
    }
    if (pw != _confirm.text) {
      setState(() => _error = 'Passwords do not match.');
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await ref.read(authRepositoryProvider).changePassword(otp: _otp.text.trim(), newPassword: pw);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) {
        DsSnackBar.show(context, message: 'Password updated', type: DsSnackBarType.success);
        Navigator.pop(context);
      },
      onError: (f) => setState(() {
        _busy = false;
        _error = f.message;
      }),
    );
  }

  InputDecoration _decoration(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      prefixIcon: Icon(icon, color: RmTheme.iconAccent, size: 21),
      suffixIcon: suffix,
    );
  }

  Widget _phonePill(String phone) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        decoration: BoxDecoration(
          color: RmTheme.electricBlue.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Text(
          phone,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w800,
            color: RmTheme.electricBlue,
          ),
        ),
      );

  Widget _step(int index, String label) {
    final active = (_otpSent ? 1 : 0) >= index;
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          AnimatedContainer(
            duration: 350.ms,
            height: 5,
            decoration: BoxDecoration(
              color: active ? RmTheme.electricBlue : RmTheme.borderSubtle,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(height: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: active ? RmTheme.electricBlue : RmTheme.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final phone = ref.watch(authProvider).user?.phone ?? '';
    final bodyStyle = GoogleFonts.plusJakartaSans(fontSize: 14, color: RmAccountStyle.body, height: 1.6);

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        boxShadow: [BoxShadow(color: Color(0x33000000), blurRadius: 40, offset: Offset(0, -8))],
      ),
      padding: EdgeInsets.fromLTRB(24, 12, 24, 16 + MediaQuery.of(context).viewInsets.bottom),
      child: SafeArea(
        top: false,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(color: RmTheme.borderSubtle, borderRadius: BorderRadius.circular(3)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  const RmIconBadge(Icons.lock_reset_rounded, size: 52)
                      .animate()
                      .scaleXY(begin: 0.5, end: 1, duration: 550.ms, curve: Curves.elasticOut),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        AnimatedSwitcher(
                          duration: 250.ms,
                          child: Text(
                            _otpSent ? 'Set new password' : 'Change password',
                            key: ValueKey(_otpSent),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 21,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: RmAccountStyle.ink,
                            ),
                          ),
                        ),
                        Text(
                          _otpSent ? 'Step 2 of 2' : 'Step 1 of 2',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: RmTheme.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Material(
                    color: RmTheme.offWhite,
                    shape: const CircleBorder(),
                    child: InkWell(
                      customBorder: const CircleBorder(),
                      onTap: () => Navigator.pop(context),
                      child: const Padding(
                        padding: EdgeInsets.all(9),
                        child: Icon(Icons.close_rounded, size: 20, color: RmAccountStyle.ink),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  _step(0, 'Verify phone'),
                  const SizedBox(width: 8),
                  _step(1, 'New password'),
                ],
              ),
              const SizedBox(height: 18),
              Text.rich(
                TextSpan(
                  style: bodyStyle,
                  children: [
                    TextSpan(text: _otpSent ? 'Enter the code sent to ' : 'We will send a one-time code to '),
                    if (phone.isEmpty)
                      const TextSpan(text: 'your phone')
                    else
                      WidgetSpan(alignment: PlaceholderAlignment.middle, child: _phonePill(phone)),
                    TextSpan(text: _otpSent ? ' and choose a new password.' : ' to verify it is you.'),
                  ],
                ),
              ),
              const SizedBox(height: 18),
              AnimatedSwitcher(
                duration: 300.ms,
                transitionBuilder: (child, anim) => FadeTransition(
                  opacity: anim,
                  child: SlideTransition(
                    position: Tween(begin: const Offset(0.08, 0), end: Offset.zero).animate(anim),
                    child: child,
                  ),
                ),
                child: !_otpSent
                    ? Container(
                        key: const ValueKey('sms'),
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: RmTheme.offWhite,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          children: [
                            const RmIconBadge(Icons.sms_rounded, background: Colors.white, size: 44),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'SMS verification',
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: RmAccountStyle.ink,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Standard carrier SMS rates apply',
                                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: RmTheme.textSecondary),
                                  ),
                                ],
                              ),
                            ),
                            const RmPill('Primary', uppercase: true),
                          ],
                        ),
                      )
                    : Column(
                        key: const ValueKey('form'),
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _otp,
                            keyboardType: TextInputType.number,
                            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              letterSpacing: 6,
                              fontWeight: FontWeight.w800,
                            ),
                            decoration: _decoration('One-time code', Icons.pin_rounded),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _password,
                            obscureText: _obscure,
                            decoration: _decoration(
                              'New password',
                              Icons.lock_rounded,
                              suffix: IconButton(
                                icon: Icon(
                                  _obscure ? Icons.visibility_off_rounded : Icons.visibility_rounded,
                                  color: RmTheme.textSecondary,
                                ),
                                onPressed: () => setState(() => _obscure = !_obscure),
                              ),
                            ),
                          ),
                          const SizedBox(height: 12),
                          TextField(
                            controller: _confirm,
                            obscureText: _obscure,
                            decoration: _decoration('Confirm new password', Icons.lock_outline_rounded),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.info_outline_rounded, size: 14, color: RmTheme.textSecondary),
                              const SizedBox(width: 6),
                              Text(
                                'Use 8–72 characters.',
                                style: GoogleFonts.plusJakartaSans(fontSize: 12, color: RmTheme.textSecondary),
                              ),
                            ],
                          ),
                        ],
                      ),
              ),
              if (_error != null) ...[
                const SizedBox(height: 14),
                RmNote(tone: RmNoteTone.danger, text: _error!).animate().shake(duration: 400.ms),
              ],
              const SizedBox(height: 22),
              RmPrimaryButton(
                label: _otpSent ? 'Update password' : 'Send OTP',
                trailingIcon: _otpSent ? Icons.check_rounded : Icons.arrow_forward_rounded,
                busy: _busy,
                onPressed: _otpSent ? _submit : _sendOtp,
              ),
              const SizedBox(height: 6),
              TextButton(
                onPressed: _busy ? null : (_otpSent ? _sendOtp : () => Navigator.pop(context)),
                child: Text(
                  _otpSent ? 'Resend code' : 'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: _otpSent ? RmTheme.electricBlue : RmAccountStyle.body,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────
// Notifications
// ─────────────────────────────────────────────────────────────────────────

const _prefsKey = 'rm_notification_prefs';

class RmNotificationPrefsNotifier extends StateNotifier<Map<String, bool>> {
  RmNotificationPrefsNotifier(this._ref) : super(defaults) {
    final stored = _ref.read(hiveServiceProvider).getCache<Map<dynamic, dynamic>>(_prefsKey);
    if (stored != null) {
      state = {
        ...defaults,
        for (final e in stored.entries)
          if (e.value is bool) e.key.toString(): e.value as bool,
      };
    }
  }

  static const defaults = {
    'push': true,
    'incidents': true,
    'verification': true,
    'trials': true,
    'attendance': false,
    'email': false,
  };

  final Ref _ref;

  void set(String key, bool value) {
    state = {...state, key: value};
    _ref.read(hiveServiceProvider).saveCache(_prefsKey, state);
  }

  void reset() {
    state = defaults;
    _ref.read(hiveServiceProvider).saveCache(_prefsKey, state);
  }
}

final rmNotificationPrefsProvider =
    StateNotifierProvider<RmNotificationPrefsNotifier, Map<String, bool>>((ref) => RmNotificationPrefsNotifier(ref));

class RmNotificationSettingsScreen extends ConsumerWidget {
  const RmNotificationSettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final prefs = ref.watch(rmNotificationPrefsProvider);
    final notifier = ref.read(rmNotificationPrefsProvider.notifier);
    final version = ref.watch(_appVersionProvider).valueOrNull;
    final pushOn = prefs['push'] ?? true;
    final activeAlerts = ['incidents', 'verification', 'trials', 'attendance'].where((k) => prefs[k] ?? false).length;

    Widget row(String key, IconData icon, String title, String subtitle, {bool needsPush = true}) => RmSwitchRow(
          icon: icon,
          title: title,
          subtitle: subtitle,
          value: (prefs[key] ?? false) && (!needsPush || pushOn),
          onChanged: needsPush && !pushOn ? null : (v) => notifier.set(key, v),
        );

    return RmAccountScaffold(
      title: 'Notifications',
      subtitle: 'Choose what you want to hear about',
      actions: [
        RmHeroTextButton(
          label: 'Reset',
          icon: Icons.restart_alt_rounded,
          onPressed: () {
            notifier.reset();
            rmToast(context, 'Notification preferences reset');
          },
        ),
      ],
      hero: _AlertsHeroCard(pushOn: pushOn, active: activeAlerts, version: version),
      children: [
        const RmSectionLabel('Channels'),
        RmGroupCard(children: [
          RmSwitchRow(
            icon: Icons.notifications_active_rounded,
            title: 'Push notifications',
            subtitle: 'Master switch for alerts on this device',
            value: pushOn,
            onChanged: (v) => notifier.set('push', v),
          ),
          row('email', Icons.mail_rounded, 'Email updates', 'Daily summary to your inbox', needsPush: false),
        ]),
        RmSectionLabel('Alert types', trailing: RmSectionMeta(pushOn ? '$activeAlerts of 4 on' : 'Push is off')),
        RmGroupCard(children: [
          row('incidents', Icons.report_rounded, 'Staff incidents', 'When an incident is raised on your staff'),
          row('verification', Icons.fact_check_rounded, 'Verification updates', 'Track results and pending reviews'),
          row('trials', Icons.play_circle_rounded, 'Trial placements', 'Trial starts, endings and feedback'),
          row('attendance', Icons.event_available_rounded, 'Attendance', 'Missed check-ins and late arrivals'),
        ]),
        const SizedBox(height: 28),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.devices_rounded, size: 16, color: RmTheme.textSecondary),
            const SizedBox(width: 8),
            Flexible(child: Text(
              'Preferences are saved on this device.',
              style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: RmTheme.textSecondary),
            )),
          ],
        ),
      ],
    );
  }
}

class _AlertsHeroCard extends StatelessWidget {
  const _AlertsHeroCard({required this.pushOn, required this.active, this.version});
  final bool pushOn;
  final int active;
  final String? version;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          AnimatedContainer(
            duration: 300.ms,
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(17),
            ),
            child: Icon(
              pushOn ? Icons.notifications_active_rounded : Icons.notifications_off_rounded,
              color: pushOn ? RmTheme.iconAccent : RmTheme.textSecondary,
              size: 27,
            ),
          )
              .animate(key: ValueKey(pushOn), onPlay: (c) => pushOn ? c.repeat(reverse: true) : null)
              .rotate(begin: pushOn ? -0.025 : 0, end: pushOn ? 0.025 : 0, duration: 600.ms),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  pushOn ? 'Alerts are on' : 'Alerts are paused',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16.5,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  pushOn
                      ? '$active of 4 alert types enabled'
                      : 'Turn on push to receive alerts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          SizedBox(
            width: 46,
            height: 46,
            child: TweenAnimationBuilder<double>(
              tween: Tween(end: pushOn ? active / 4 : 0),
              duration: 500.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 4,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.18),
                      color: const Color(0xFFFFD84D),
                    ),
                  ),
                  Text(
                    pushOn ? '$active/4' : 'Off',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
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
}

// ─────────────────────────────────────────────────────────────────────────
// Support (Help Center)
// ─────────────────────────────────────────────────────────────────────────

class RmSupportScreen extends ConsumerWidget {
  const RmSupportScreen({super.key});

  static const _faqs = [
    (Icons.person_add_alt_rounded, 'How do I onboard a new staff member?', 'Open Pipeline, tap the add button and complete the intake form. The staff member then moves through the verification tracks.'),
    (Icons.fact_check_rounded, 'Where can I see pending verifications?', 'The Dashboard shows a Pending Verify count. Tap it, or open a staff profile to see each verification track.'),
    (Icons.report_rounded, 'How do I report an incident?', 'Open the Incidents tab, or a staff member\'s profile, and choose to add a new incident.'),
    (Icons.sms_failed_rounded, 'I did not receive my OTP', 'Wait a minute and request again. If it still does not arrive, check your phone number with support.'),
  ];

  Future<void> _email(BuildContext context) async {
    final ok = await launchUrl(
      Uri(scheme: 'mailto', path: _supportEmail, queryParameters: {'subject': 'RM support request'}),
    );
    if (!ok && context.mounted) {
      await Clipboard.setData(const ClipboardData(text: _supportEmail));
      if (context.mounted) rmToast(context, 'Email copied: $_supportEmail');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final version = ref.watch(_appVersionProvider).valueOrNull;

    return RmAccountScaffold(
      title: 'How can we help?',
      eyebrow: 'Help center',
      eyebrowIcon: Icons.support_agent_rounded,
      subtitle: 'Browse common questions or reach the HomeGenny team.',
      floatingIcons: const [Icons.headset_mic_rounded, Icons.chat_bubble_rounded, Icons.lightbulb_rounded],
      hero: DsHeroPillButton(
        label: 'Email support',
        icon: Icons.mail_rounded,
        onPressed: () => _email(context),
      ),
      children: [
        const RmSectionLabel('Contact us'),
        RmGroupCard(children: [
          RmActionRow(
            icon: Icons.mail_rounded,
            title: 'Email support',
            subtitle: _supportEmail,
            onTap: () => _email(context),
          ),
          RmActionRow(
            icon: Icons.copy_rounded,
            title: 'Copy email address',
            subtitle: 'Paste it into any mail app',
            onTap: () {
              Clipboard.setData(const ClipboardData(text: _supportEmail));
              rmToast(context, 'Email copied');
            },
          ),
        ]),
        RmSectionLabel('Frequently asked', trailing: RmSectionMeta('${_faqs.length} topics')),
        for (final (icon, q, a) in _faqs) _FaqCard(icon: icon, question: q, answer: a),
        const SizedBox(height: 24),
        if (version != null)
          Text(
            'HomeGenny $version',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: RmTheme.textSecondary),
          ),
      ],
    );
  }
}

class _FaqCard extends StatefulWidget {
  const _FaqCard({required this.icon, required this.question, required this.answer});
  final IconData icon;
  final String question;
  final String answer;

  @override
  State<_FaqCard> createState() => _FaqCardState();
}

class _FaqCardState extends State<_FaqCard> {
  bool _open = false;

  @override
  Widget build(BuildContext context) {
    return AnimatedContainer(
      duration: 250.ms,
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _open ? RmTheme.electricBlue.withValues(alpha: 0.35) : RmAccountStyle.cardBorder,
        ),
        boxShadow: RmAccountStyle.cardShadow,
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            HapticFeedback.selectionClick();
            setState(() => _open = !_open);
          },
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    RmIconBadge(widget.icon, size: 40),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        widget.question,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w700,
                          color: RmAccountStyle.ink,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    AnimatedRotation(
                      turns: _open ? 0.125 : 0,
                      duration: 250.ms,
                      child: Container(
                        width: 28,
                        height: 28,
                        decoration: BoxDecoration(
                          color: _open ? RmTheme.electricBlue : RmTheme.offWhite,
                          shape: BoxShape.circle,
                        ),
                        child: Icon(
                          Icons.add_rounded,
                          size: 18,
                          color: _open ? Colors.white : RmTheme.electricBlue,
                        ),
                      ),
                    ),
                  ],
                ),
                AnimatedSize(
                  duration: 250.ms,
                  curve: Curves.easeOutCubic,
                  alignment: Alignment.topCenter,
                  child: !_open
                      ? const SizedBox(width: double.infinity)
                      : Padding(
                          padding: const EdgeInsets.fromLTRB(52, 10, 4, 2),
                          child: Text(
                            widget.answer,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13.5,
                              color: RmAccountStyle.body,
                              height: 1.55,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
