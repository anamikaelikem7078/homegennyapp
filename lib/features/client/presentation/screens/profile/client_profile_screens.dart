import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../core/onboarding/city_fields.dart';
import '../../../../../core/onboarding/onboarding_providers.dart';
import '../../../../../design_system/design_system.dart';
import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/router/app_routes.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/map_pin_picker.dart';
import '../../../../../core/theme/theme_provider.dart';
import '../../../../../core/utils/validators.dart';

/// Profile tab.
class ClientProfileTabScreen extends ConsumerWidget {
  const ClientProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientProfileProvider);
    final l10n = context.l10n;

    return Scaffold(
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => DsErrorState(title: l10n.error),
        data: (p) {
          final digits = p.phone.replaceAll(RegExp(r'\D'), '');
          final idValue = digits.length >= 4
              ? 'HG-C-${digits.substring(digits.length - 4)}'
              : 'HG-CLIENT';
          final location = [p.city, p.pincode]
              .where((s) => s.trim().isNotEmpty)
              .join(' · ');

          return DsProfileView(
            title: l10n.profile,
            name: p.name,
            role: l10n.premiumMember,
            idLabel: 'Member ID',
            idValue: idValue,
            tagline: l10n.memberSince,
            onBack: context.canPop() ? () => context.pop() : null,
            onSettings: () => context.push(ClientRoutes.settings),
            facts: [
              if (p.phone.isNotEmpty)
                DsProfileFact(
                  icon: Icons.phone_rounded,
                  label: 'Mobile',
                  value: p.phone,
                ),
              if (p.email.isNotEmpty)
                DsProfileFact(
                  icon: Icons.mail_rounded,
                  label: 'Email',
                  value: p.email,
                ),
              if (location.isNotEmpty)
                DsProfileFact(
                  icon: Icons.location_on_rounded,
                  label: 'Location',
                  value: location,
                ),
              DsProfileFact(
                icon: Icons.support_agent_rounded,
                label: 'Relationship manager',
                value: (p.assignedRmName?.trim().isNotEmpty ?? false)
                    ? p.assignedRmName!.trim()
                    : 'Not assigned yet',
              ),
            ],
            stats: [
              DsProfileStat(
                label: l10n.services,
                value: 12,
                icon: Icons.cleaning_services_rounded,
              ),
              DsProfileStat(
                label: l10n.rating,
                value: 4.9,
                decimals: 1,
                icon: Icons.star_rounded,
              ),
              DsProfileStat(
                label: l10n.credits,
                value: 150,
                icon: Icons.account_balance_wallet_rounded,
              ),
            ],
            sections: [
              DsProfileSection(
                title: l10n.accountSettings,
                items: [
                  DsProfileMenuItem(
                    icon: Icons.person_rounded,
                    title: l10n.personalDetails,
                    onTap: () => context.push(ClientRoutes.personalDetails),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.location_on_rounded,
                    title: l10n.addressBook,
                    subtitle: location.isEmpty ? null : location,
                    onTap: () => context.push(ClientRoutes.address),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.credit_card_rounded,
                    title: l10n.paymentMethods,
                    onTap: () => context.push(ClientRoutes.paymentDetails),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.table_chart_rounded,
                    title: 'Monthly attendance sheet',
                    subtitle: 'View, print and sign',
                    onTap: () => context.push(ClientRoutes.musterRoll),
                  ),
                ],
              ),
              DsProfileSection(
                title: l10n.supportSafety,
                items: [
                  DsProfileMenuItem(
                    icon: Icons.report_problem_rounded,
                    title: l10n.complaints,
                    onTap: () => context.push(ClientRoutes.complaintHistory),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.support_agent_rounded,
                    title: l10n.helpCenter,
                    onTap: () {},
                  ),
                  DsProfileMenuItem(
                    icon: Icons.privacy_tip_rounded,
                    title: l10n.privacyPolicy,
                    onTap: () {},
                  ),
                ],
              ),
            ],
            logoutLabel: l10n.logOut,
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          );
        },
      ),
    );
  }
}

/// Personal details.
class ClientPersonalDetailsScreen extends ConsumerStatefulWidget {
  const ClientPersonalDetailsScreen({super.key});

  @override
  ConsumerState<ClientPersonalDetailsScreen> createState() => _ClientPersonalDetailsScreenState();
}

class _ClientPersonalDetailsScreenState extends ConsumerState<ClientPersonalDetailsScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final name = _name.text.trim();
    final email = _email.text.trim();
    if (name.length < 2) {
      context.showDsSnackBar('Enter your name', type: DsSnackBarType.error);
      return;
    }
    if (email.isNotEmpty && Validators.email(email) != null) {
      context.showDsSnackBar('Enter a valid email', type: DsSnackBarType.error);
      return;
    }

    setState(() => _loading = true);
    // The phone is the login: it can't be changed, so it is never sent.
    final result = await ref.read(clientRepositoryProvider).updateProfile({
      'full_name': name,
      if (email.isNotEmpty) 'email': email,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(clientProfileProvider);
        ref.invalidate(onboardingProvider);
        context.showDsSnackBar('Profile updated', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(clientProfileProvider);
    final l10n = context.l10n;

    return DsPage(
      title: l10n.personalDetails,
      subtitle: l10n.profileManagement,
      onBack: () => context.pop(),
      bottom: profile.hasValue
          ? DsGradientButton(
              label: l10n.saveChanges,
              icon: Icons.check_rounded,
              isLoading: _loading,
              onPressed: _loading ? null : _save,
            )
          : null,
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientProfileProvider),
        builder: (p) {
          if (!_initialized) {
            _name.text = p.name;
            _email.text = p.email;
            _phone.text = p.phone;
            _initialized = true;
          }
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: SweepGradient(
                        colors: [AppColors.sunYellow, AppColors.secondary, AppColors.sunYellow],
                      ),
                    ),
                    child: Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                      child: DsInitialsAvatar(name: p.name, size: 60, radius: 30),
                    ),
                  ).animate().scaleXY(begin: 0.6, end: 1, duration: 600.ms, curve: Curves.elasticOut),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.refineIdentity,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            height: 1.2,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.personalInfoDesc,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const DsSection('Your details'),
            DsLabeledField(
              label: l10n.fullName,
              controller: _name,
              icon: Icons.person_rounded,
              hint: 'Add your name',
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            DsLabeledField(
              label: l10n.emailAddress,
              controller: _email,
              icon: Icons.mail_rounded,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DsLabeledField(
              label: l10n.phoneNumber,
              controller: _phone,
              icon: Icons.phone_rounded,
              enabled: false,
              suffix: const Icon(Icons.lock_rounded, size: 18),
            ),
            const Padding(
              padding: EdgeInsets.only(left: 4, top: 6),
              child: Text(
                'Your mobile number is your login and can\'t be changed here.',
                style: TextStyle(fontSize: 12, color: AppColors.lightTextSecondary),
              ),
            ),
            const SizedBox(height: 20),
            DsNote(tone: DsNoteTone.success, title: l10n.privacyAssured, text: l10n.privacyDesc),
          ];
        },
      ),
    );
  }
}

/// Address details.
class ClientAddressScreen extends ConsumerStatefulWidget {
  const ClientAddressScreen({super.key});

  @override
  ConsumerState<ClientAddressScreen> createState() => _ClientAddressScreenState();
}

class _ClientAddressScreenState extends ConsumerState<ClientAddressScreen> {
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  // City is a dropdown from `GET /meta/cities` — never free text.
  String? _city;
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _address.dispose();
    _pincode.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final address = _address.text.trim();
    final pincode = _pincode.text.trim();
    if (address.length < 5) {
      context.showDsSnackBar('Enter your full address', type: DsSnackBarType.error);
      return;
    }
    if (_city == null) {
      context.showDsSnackBar('Choose your city', type: DsSnackBarType.error);
      return;
    }
    if (!RegExp(r'^[1-9][0-9]{5}$').hasMatch(pincode)) {
      context.showDsSnackBar('Enter a valid 6-digit pincode', type: DsSnackBarType.error);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).updateProfile({
      'address': address,
      'city': _city,
      'pincode': pincode,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(clientProfileProvider);
        ref.invalidate(onboardingProvider);
        context.showDsSnackBar('Address updated', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  /// `PUT /client/home-location` — the pin staff check-ins and the live map
  /// measure "at home" against.
  Future<void> _pinHome() async {
    final pin = await pickMapPin(context);
    if (pin == null || !mounted) return;
    final result = await ref
        .read(clientRepositoryProvider)
        .setHomeLocation(lat: pin.latitude, lng: pin.longitude);
    if (!mounted) return;
    result.fold(
      onSuccess: (_) => context.showDsSnackBar('Home location saved', type: DsSnackBarType.success),
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(clientProfileProvider);
    final l10n = context.l10n;

    return DsPage(
      title: l10n.address,
      subtitle: l10n.primaryResidence,
      onBack: () => context.pop(),
      bottom: profile.hasValue
          ? Row(
              children: [
                Expanded(
                  flex: 2,
                  child: DsOutlineButton(label: 'Discard', onPressed: () => context.pop()),
                ),
                const SizedBox(width: 12),
                Expanded(
                  flex: 3,
                  child: DsGradientButton(
                    label: 'Save address',
                    icon: Icons.check_rounded,
                    isLoading: _loading,
                    onPressed: _loading ? null : _save,
                  ),
                ),
              ],
            )
          : null,
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientProfileProvider),
        builder: (p) {
          if (!_initialized) {
            _address.text = p.address;
            _city = p.city.isEmpty ? null : p.city;
            _pincode.text = p.pincode;
            _initialized = true;
          }
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsGlassPill(l10n.profileDetails.toUpperCase(), icon: Icons.home_rounded),
                        const SizedBox(height: 12),
                        Text(
                          [p.city, p.pincode].where((s) => s.trim().isNotEmpty).join(' · ').ifEmpty(l10n.primaryResidence),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          l10n.addressUpdateDesc,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const DsFloatingIconTile(icon: Icons.location_on_rounded),
                ],
              ),
            ),
            const DsSection('Address'),
            DsLabeledField(
              label: l10n.streetAddress,
              controller: _address,
              icon: Icons.home_rounded,
              maxLines: 2,
              minLines: 1,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 16),
            ref.watch(citiesProvider).when(
                  loading: () => const DsLoadingWidget(),
                  error: (e, _) => DsNote(
                    tone: DsNoteTone.danger,
                    text: 'Could not load the city list. Pull down to try again.',
                  ),
                  data: (cities) => CityDropdown(
                    cities: cities,
                    value: _city,
                    onChanged: (c) => setState(() => _city = c),
                  ),
                ),
            const SizedBox(height: 16),
            DsLabeledField(
              label: l10n.pincode,
              controller: _pincode,
              icon: Icons.pin_drop_rounded,
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
            ),
            const DsSection('My home on the map'),
            DsListCard(
              icon: Icons.add_home_rounded,
              title: 'Pin your home',
              subtitle: 'Used to show whether your staff are at home during their shift',
              onTap: _pinHome,
            ),
            const SizedBox(height: 20),
            DsNote(text: '${l10n.locateOnMap}: your staff use this address for GPS check-in.'),
          ];
        },
      ),
    );
  }
}

extension on String {
  String ifEmpty(String fallback) => trim().isEmpty ? fallback : this;
}

/// Payment details.
class ClientPaymentDetailsScreen extends ConsumerWidget {
  const ClientPaymentDetailsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(clientProfileProvider);

    return DsPage(
      title: context.l10n.paymentDetails,
      subtitle: 'Secure your transactions',
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(clientProfileProvider),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(clientProfileProvider),
        builder: (p) => [
          // Card-style primary method.
          AspectRatio(
            aspectRatio: 1.75,
            child: DsGradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const DsGlassPill('PRIMARY METHOD', icon: Icons.star_rounded),
                      const Spacer(),
                      Icon(Icons.contactless_rounded, color: Colors.white.withValues(alpha: 0.85), size: 28),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      p.accountLast4 != null ? '••••  ••••  ••••  ${p.accountLast4}' : '••••  ••••  ••••  ••••',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          p.name.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Text(
                        p.paymentMethod ?? 'Not set',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          color: AppColors.sunYellow,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const DsSection('Details'),
          Container(
            decoration: dsCardDecoration(),
            child: Column(
              children: [
                _DetailLine(icon: Icons.payments_rounded, label: 'Payment method', value: p.paymentMethod ?? 'Not set'),
                const Divider(height: 1, indent: 66, endIndent: 16, color: AppColors.lightBorder),
                _DetailLine(
                  icon: Icons.qr_code_rounded,
                  label: 'UPI ID',
                  value: p.upiId ?? 'Not set',
                  onCopy: p.upiId == null
                      ? null
                      : () {
                          Clipboard.setData(ClipboardData(text: p.upiId!));
                          context.showDsSnackBar('UPI ID copied', type: DsSnackBarType.success);
                        },
                ),
                const Divider(height: 1, indent: 66, endIndent: 16, color: AppColors.lightBorder),
                _DetailLine(
                  icon: Icons.account_balance_rounded,
                  label: 'Linked account',
                  value: p.accountLast4 != null ? '•••• ${p.accountLast4}' : 'Not set',
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                flex: 3,
                child: DsGradientButton(
                  label: 'Update details',
                  icon: Icons.edit_rounded,
                  onPressed: () => context.showDsSnackBar(
                    'Payment details updated successfully',
                    type: DsSnackBarType.success,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                flex: 2,
                child: DsOutlineButton(
                  label: 'Remove',
                  color: AppColors.error,
                  onPressed: () async {
                    final ok = await DsConfirmationDialog.show(
                      context: context,
                      title: 'Remove payment method?',
                      message: 'You can add a new one any time.',
                      confirmLabel: 'Remove',
                      isDestructive: true,
                      icon: Icons.credit_card_off_rounded,
                    );
                    if (ok == true && context.mounted) {
                      context.showDsSnackBar('Payment method removed', type: DsSnackBarType.success);
                    }
                  },
                ),
              ),
            ],
          ),
          const DsSection('More'),
          DsListCard(
            icon: Icons.history_rounded,
            title: context.l10n.paymentHistory,
            subtitle: 'View all recent transactions',
            onTap: () => context.push(ClientRoutes.paymentHistory),
          ),
          const DsNote(
            tone: DsNoteTone.success,
            title: 'Trust is our currency',
            text: 'Your payment credentials are encrypted and never shared with staff.',
          ),
        ],
      ),
    );
  }
}

class _DetailLine extends StatelessWidget {
  const _DetailLine({required this.icon, required this.label, required this.value, this.onCopy});
  final IconData icon;
  final String label;
  final String value;
  final VoidCallback? onCopy;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      child: Row(
        children: [
          DsIconTile(icon, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                Text(
                  value,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (onCopy != null)
            IconButton(
              tooltip: 'Copy',
              onPressed: onCopy,
              icon: const Icon(Icons.copy_rounded, size: 19, color: AppColors.primary),
            ),
        ],
      ),
    );
  }
}

/// Settings screen (tab).
class ClientSettingsScreen extends ConsumerStatefulWidget {
  const ClientSettingsScreen({super.key});

  @override
  ConsumerState<ClientSettingsScreen> createState() => _ClientSettingsScreenState();
}

class _ClientSettingsScreenState extends ConsumerState<ClientSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;
  bool _attendanceAlerts = true;

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final themeMode = ref.watch(themeModeProvider);
    final isHindi = ref.watch(localeProvider).languageCode == 'hi';
    final enabled = [_pushEnabled, _emailEnabled, _attendanceAlerts].where((v) => v).length;

    return DsPage(
      title: l10n.accountSettings,
      subtitle: 'Preferences and notifications',
      showBack: context.canPop(),
      onBack: () => context.pop(),
      extraBottomPadding: 90,
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Expanded(child: DsGlassStat(value: isHindi ? 'हिंदी' : 'English', label: l10n.language, icon: Icons.translate_rounded)),
              const SizedBox(width: 10),
              Expanded(
                child: DsGlassStat(
                  value: themeMode == ThemeMode.dark ? l10n.dark : (themeMode == ThemeMode.light ? l10n.light : 'Auto'),
                  label: l10n.appearance,
                  icon: Icons.palette_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(child: DsGlassStat(value: '$enabled/3', label: 'Alerts', icon: Icons.notifications_active_rounded)),
            ],
          ),
        ),
        DsSection(l10n.preferences),
        _SettingsGroup(
          children: [
            _SettingRow(
              icon: Icons.translate_rounded,
              title: l10n.language,
              subtitle: l10n.languageDesc,
              onTap: () => context.push('${ClientRoutes.settings}/language'),
              trailing: DsPill(isHindi ? 'Hindi' : 'English'),
            ),
            _SettingRow(
              icon: Icons.palette_rounded,
              title: l10n.appearance,
              subtitle: l10n.appearanceDesc,
              trailing: _ThemeToggle(
                mode: themeMode,
                lightLabel: l10n.light,
                darkLabel: l10n.dark,
                onChanged: (m) => ref.read(themeModeProvider.notifier).setThemeMode(m),
              ),
            ),
          ],
        ),
        DsSection(l10n.notifications),
        _SettingsGroup(
          children: [
            _SwitchRow(
              icon: Icons.notifications_active_rounded,
              title: l10n.pushNotifications,
              subtitle: l10n.pushNotificationsDesc,
              value: _pushEnabled,
              onChanged: (v) => setState(() => _pushEnabled = v),
            ),
            _SwitchRow(
              icon: Icons.mail_rounded,
              title: l10n.emailSummaries,
              subtitle: l10n.emailSummariesDesc,
              value: _emailEnabled,
              onChanged: (v) => setState(() => _emailEnabled = v),
            ),
            _SwitchRow(
              icon: Icons.event_available_rounded,
              title: l10n.attendanceAlerts,
              subtitle: l10n.attendanceAlertsDesc,
              value: _attendanceAlerts,
              onChanged: (v) => setState(() => _attendanceAlerts = v),
            ),
          ],
        ),
        DsSection(l10n.legalPrivacy),
        _SettingsGroup(
          children: [
            _SettingRow(icon: Icons.privacy_tip_rounded, title: l10n.privacyPolicy, subtitle: l10n.privacyPolicyDesc, onTap: () {}),
            _SettingRow(icon: Icons.gavel_rounded, title: l10n.termsOfService, subtitle: l10n.termsOfServiceDesc, onTap: () {}),
            _SettingRow(icon: Icons.cookie_rounded, title: l10n.cookiePolicy, subtitle: l10n.cookiePolicyDesc, onTap: () {}),
            _SettingRow(icon: Icons.description_rounded, title: l10n.licenses, subtitle: l10n.licensesDesc, onTap: () {}),
          ],
        ),
        const SizedBox(height: 22),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppColors.error.withValues(alpha: 0.05),
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: AppColors.error.withValues(alpha: 0.2)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const DsIconTile(Icons.warning_amber_rounded, color: AppColors.error, size: 40),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          l10n.deleteAccount,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.error,
                          ),
                        ),
                        Text(
                          l10n.deleteAccountWarning,
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              DsOutlineButton(
                label: l10n.deactivateAccount,
                color: AppColors.error,
                icon: Icons.person_off_rounded,
                onPressed: () => DsConfirmationDialog.show(
                  context: context,
                  title: l10n.deleteAccount,
                  message: l10n.deleteAccountWarning,
                  confirmLabel: l10n.deactivateAccount,
                  isDestructive: true,
                  icon: Icons.person_off_rounded,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SettingsGroup extends StatelessWidget {
  const _SettingsGroup({required this.children});
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: dsCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: Column(
          children: [
            for (var i = 0; i < children.length; i++) ...[
              if (i > 0) const Divider(height: 1, indent: 70, endIndent: 16, color: AppColors.lightBorder),
              children[i],
            ],
          ],
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  const _SettingRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Row(
          children: [
            DsIconTile(icon),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  Text(
                    subtitle,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            trailing ?? const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ],
        ),
      ),
    );
  }
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return _SettingRow(
      icon: icon,
      title: title,
      subtitle: subtitle,
      onTap: () {
        HapticFeedback.selectionClick();
        onChanged(!value);
      },
      trailing: Switch(
        value: value,
        activeThumbColor: Colors.white,
        activeTrackColor: AppColors.primary,
        inactiveThumbColor: Colors.white,
        inactiveTrackColor: AppColors.lightBorder,
        trackOutlineColor: WidgetStateProperty.all(Colors.transparent),
        onChanged: (v) {
          HapticFeedback.selectionClick();
          onChanged(v);
        },
      ),
    );
  }
}

class _ThemeToggle extends StatelessWidget {
  const _ThemeToggle({
    required this.mode,
    required this.lightLabel,
    required this.darkLabel,
    required this.onChanged,
  });

  final ThemeMode mode;
  final String lightLabel;
  final String darkLabel;
  final ValueChanged<ThemeMode> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(ThemeMode m, IconData icon, String label) {
      final on = mode == m;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(m);
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: on ? AppColors.primary : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Tooltip(
            message: label,
            child: Icon(icon, size: 17, color: on ? Colors.white : AppColors.lightTextSecondary),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: AppColors.lightSurfaceVariant,
        borderRadius: BorderRadius.circular(22),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          seg(ThemeMode.light, Icons.light_mode_rounded, lightLabel),
          seg(ThemeMode.dark, Icons.dark_mode_rounded, darkLabel),
        ],
      ),
    );
  }
}
