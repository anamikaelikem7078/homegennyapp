import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../../../../core/onboarding/onboarding_providers.dart';
import '../../../../../core/onboarding/profile_gate.dart';
import '../../../../../core/series/series_catalog.dart';

String _pretty(String s) => s
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

/// `1996-05-15` / ISO → `15 May 1996`; anything else as sent.
String _dob(String raw) {
  final parsed = DateTime.tryParse(raw);
  return parsed == null ? raw : DateFormat('d MMM yyyy').format(parsed);
}

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(staffProfileProvider);
    final dashboard = ref.watch(staffDashboardProvider).valueOrNull;
    final agreement = ref.watch(staffAgreementProvider).valueOrNull;
    final videoCert = ref.watch(staffTrainingHomeProvider).valueOrNull?.videoCert;
    final completionPct = dashboard?.completionPct ?? 0;
    final l10n = context.l10n;

    final (agreementSubtitle, agreementBadge) = switch (agreement?.status) {
      AgreementStatus.signed => ('Signed', null),
      AgreementStatus.expired => ('Expired — sign again', 'Action needed'),
      AgreementStatus.pending => (l10n.signatureRequired, 'Action needed'),
      null => ('Terms and conditions', null),
    };
    final videosSubmitted = ref.watch(staffVideoCertSubmittedProvider);
    final videoSubtitle = videoCert == null || videoCert.required_ == 0
        ? 'Record your introduction'
        : videoCert.approved >= videoCert.required_
            ? 'Certified'
            : '${videosSubmitted ?? videoCert.approved} of ${videoCert.required_} submitted · ${videoCert.approved} approved';

    return Scaffold(
      body: profileAsync.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: l10n.errorLoadingProfile,
          message: e.toString().replaceFirst('Exception: ', ''),
          onRetry: () => ref.invalidate(staffProfileProvider),
        ),
        data: (profile) => RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(staffProfileProvider);
            ref.invalidate(staffDashboardProvider);
            ref.invalidate(staffAgreementProvider);
          },
          child: DsProfileView(
            title: l10n.profile,
            name: displayNameOr(profile.fullName, profile.mobile),
            role: profile.series.isEmpty ? '—' : SeriesDisplay.label(profile.series),
            idLabel: 'Staff code',
            idValue: profile.staffCode,
            tagline: 'HomeGenny Pro',
            onBack: context.canPop() ? () => context.pop() : null,
            onSettings: () => context.push(StaffRoutes.settings),
            facts: [
              if (profile.mobile.isNotEmpty)
                DsProfileFact(icon: Icons.phone_rounded, label: 'Mobile', value: profile.mobile),
              if (profile.email.isNotEmpty)
                DsProfileFact(icon: Icons.mail_rounded, label: 'Email', value: profile.email),
              if (profile.pipelineStage.isNotEmpty)
                DsProfileFact(icon: Icons.route_rounded, label: 'Stage', value: _pretty(profile.pipelineStage)),
            ],
            highlight: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                if (!profile.profileComplete) ...[
                  const ProfileIncompleteCard(compact: true),
                  const SizedBox(height: 14),
                ],
                _PersonalInfoCard(
                  profile: profile,
                  rmName: (profile.assignedRmName?.trim().isNotEmpty ?? false)
                      ? profile.assignedRmName
                      : dashboard?.assignedRmName,
                ),
                const SizedBox(height: 14),
                DsProfileProgressCard(
                  percent: completionPct,
                  title: l10n.profileCompletion,
                  subtitle: l10n.unlockPremiumFeatures,
                  onTap: () => context.push(StaffRoutes.profileCompletion),
                ),
              ],
            ),
            sections: [
              DsProfileSection(
                title: l10n.managementModules,
                items: [
                  DsProfileMenuItem(
                    icon: Icons.description_rounded,
                    title: l10n.documents,
                    subtitle: l10n.verifiedIdTaxForms,
                    onTap: () => context.push(StaffRoutes.documents),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.school_rounded,
                    title: l10n.training,
                    subtitle: 'Batches, materials and quizzes',
                    onTap: () => context.push(StaffRoutes.training),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.videocam_rounded,
                    title: l10n.videoCertification,
                    subtitle: videoSubtitle,
                    onTap: () => context.push(StaffRoutes.videoCertification),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.edit_document,
                    title: l10n.agreement,
                    subtitle: agreementSubtitle,
                    badge: agreementBadge,
                    urgent: agreementBadge != null,
                    onTap: () => context.push(StaffRoutes.agreement),
                  ),
                ],
              ),
              DsProfileSection(
                title: 'Work & pay',
                items: [
                  DsProfileMenuItem(
                    icon: Icons.location_on_rounded,
                    title: l10n.deployment,
                    subtitle: l10n.viewCurrentAssignment,
                    onTap: () => context.push(StaffRoutes.deployment),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.payments_rounded,
                    title: l10n.salary,
                    subtitle: l10n.financialOverview,
                    onTap: () => context.push(StaffRoutes.salary),
                  ),
                ],
              ),
              DsProfileSection(
                title: 'Support',
                items: [
                  DsProfileMenuItem(
                    icon: Icons.support_agent_rounded,
                    title: l10n.helpSupport,
                    subtitle: l10n.conciergeAssistance,
                    onTap: () => context.push(StaffRoutes.help),
                  ),
                  DsProfileMenuItem(
                    icon: Icons.settings_rounded,
                    title: l10n.systemSettings,
                    onTap: () => context.push(StaffRoutes.settings),
                  ),
                ],
              ),
            ],
            logoutLabel: l10n.logoutFromDevice,
            onLogout: () async {
              await ref.read(authProvider.notifier).logout();
              if (context.mounted) context.go(AppRoutes.login);
            },
          ),
        ),
      ),
    );
  }
}

const _genderLabels = {'FEMALE': 'Female', 'MALE': 'Male', 'OTHER': 'Other'};

/// Everything `GET /staff/profile` returns, always visible. A blank is shown
/// as "Not added", never a placeholder. "Edit" opens the profile wizard;
/// fields locked after Submit carry a lock and "Ask your RM to change this".
class _PersonalInfoCard extends StatelessWidget {
  const _PersonalInfoCard({required this.profile, this.rmName});

  final StaffProfile profile;
  final String? rmName;

  @override
  Widget build(BuildContext context) {
    final city = [profile.city, profile.area].where((s) => s != null && s.trim().isNotEmpty).join(' · ');
    final emergency = [profile.emergencyContactName, profile.emergencyContactMobile]
        .where((s) => s != null && s.trim().isNotEmpty)
        .join(' · ');
    // (icon, label, value, text shown when the value is empty, server field)
    final rows = <(IconData, String, String?, String, String?)>[
      (Icons.person_rounded, 'Full name', profile.fullName, 'Not added', 'full_name'),
      (Icons.phone_rounded, 'Mobile', profile.mobile, 'Not added', null),
      (Icons.mail_rounded, 'Email', profile.email, 'Not added', null),
      (
        Icons.cake_rounded,
        'Date of birth',
        profile.dateOfBirth == null ? null : _dob(profile.dateOfBirth!),
        'Not added',
        'date_of_birth',
      ),
      (Icons.wc_rounded, 'Gender', _genderLabels[profile.gender?.toUpperCase()], 'Not added', 'gender'),
      (Icons.family_restroom_rounded, "Father's / husband's name", profile.fatherOrHusbandName, 'Not added', null),
      (
        Icons.work_rounded,
        'Work category',
        profile.series.isEmpty ? null : SeriesDisplay.label(profile.series),
        'Not added',
        'series',
      ),
      (Icons.location_city_rounded, 'City', city, 'Not added', null),
      (Icons.home_rounded, 'Address', profile.address, 'Not added', null),
      (Icons.pin_drop_rounded, 'Pincode', profile.pincode, 'Not added', null),
      (Icons.contact_emergency_rounded, 'Emergency contact', emergency, 'Not added', null),
      (
        Icons.translate_rounded,
        'Languages',
        profile.languages.isEmpty ? null : profile.languages.join(', '),
        'Not added',
        null,
      ),
      (Icons.badge_rounded, 'Staff code', profile.staffCode, 'Not added', null),
      (
        Icons.route_rounded,
        'Stage',
        profile.pipelineStage.isEmpty ? null : _pretty(profile.pipelineStage),
        'Not added',
        null,
      ),
      (Icons.support_agent_rounded, 'Relationship manager', rmName, 'RM not assigned yet', null),
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 8, 8),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Personal information',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              TextButton.icon(
                onPressed: () => context.push('${AppRoutes.staffCompleteProfile}?step=0'),
                icon: const Icon(Icons.edit_rounded, size: 16),
                label: const Text('Edit'),
              ),
            ],
          ),
          for (final (icon, label, value, emptyText, field) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 10, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(icon, size: 18, color: AppColors.primary),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, color: AppColors.lightTextSecondary),
                        ),
                        Text(
                          value == null || value.trim().isEmpty ? emptyText : value.trim(),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: value == null || value.trim().isEmpty
                                ? AppColors.lightTextHint
                                : AppColors.lightTextPrimary,
                          ),
                        ),
                        if (field != null && profile.isLocked(field))
                          Text(
                            'Ask your RM to change this',
                            style: GoogleFonts.plusJakartaSans(fontSize: 11, color: AppColors.lightTextSecondary),
                          ),
                      ],
                    ),
                  ),
                  if (field != null && profile.isLocked(field))
                    const Padding(
                      padding: EdgeInsets.only(top: 4),
                      child: Icon(Icons.lock_rounded, size: 16, color: AppColors.lightTextSecondary),
                    )
                  else if (label == 'Email')
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => _EditEmailSheet.show(context, profile),
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(Icons.edit_rounded, size: 16, color: AppColors.primary),
                      ),
                    ),
                ],
              ),
            ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }
}

/// Email isn't part of the profile wizard; it is edited on its own.
class _EditEmailSheet extends ConsumerStatefulWidget {
  const _EditEmailSheet({required this.profile});
  final StaffProfile profile;

  static Future<void> show(BuildContext context, StaffProfile profile) => DsBottomSheet.show<void>(
        context: context,
        title: 'Edit email',
        child: _EditEmailSheet(profile: profile),
      );

  @override
  ConsumerState<_EditEmailSheet> createState() => _EditEmailSheetState();
}

class _EditEmailSheetState extends ConsumerState<_EditEmailSheet> {
  late final _email = TextEditingController(text: widget.profile.email);
  bool _saving = false;

  @override
  void dispose() {
    _email.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final email = _email.text.trim();
    if (email.isEmpty || !RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      context.showDsSnackBar('Enter a valid email', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(staffRepositoryProvider).updateProfile({'email': email});
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffProfileProvider);
        Navigator.pop(context);
        context.showDsSnackBar('Profile updated', type: DsSnackBarType.success);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsLabeledField(
          label: 'Email',
          controller: _email,
          icon: Icons.mail_rounded,
          keyboardType: TextInputType.emailAddress,
        ),
        const SizedBox(height: 16),
        DsGradientButton(
          label: 'Save',
          icon: Icons.check_rounded,
          isLoading: _saving,
          onPressed: _saving ? null : _save,
        ),
      ],
    );
  }
}
