import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../../../../core/series/series_catalog.dart';

class StaffProfileScreen extends ConsumerWidget {
  const StaffProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(staffProfileProvider);
    final completionPct =
        ref.watch(staffDashboardProvider).valueOrNull?.completionPct ?? 0;
    final l10n = context.l10n;

    return Scaffold(
      body: profileAsync.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: l10n.errorLoadingProfile,
          onRetry: () => ref.invalidate(staffProfileProvider),
        ),
        data: (profile) => DsProfileView(
          title: l10n.profile,
          name: profile.fullName,
          role: SeriesDisplay.label(profile.series),
          idLabel: 'Staff code',
          idValue: profile.staffCode,
          tagline: 'HomeGenny Pro',
          onBack: context.canPop() ? () => context.pop() : null,
          onSettings: () => context.push(StaffRoutes.settings),
          facts: [
            if (profile.mobile.isNotEmpty)
              DsProfileFact(
                icon: Icons.phone_rounded,
                label: 'Mobile',
                value: profile.mobile,
              ),
            if (profile.email.isNotEmpty)
              DsProfileFact(
                icon: Icons.mail_rounded,
                label: 'Email',
                value: profile.email,
              ),
            DsProfileFact(
              icon: Icons.route_rounded,
              label: 'Stage',
              value: profile.pipelineStage
                  .replaceAll('_', ' ')
                  .toLowerCase()
                  .split(' ')
                  .where((w) => w.isNotEmpty)
                  .map((w) => w[0].toUpperCase() + w.substring(1))
                  .join(' '),
            ),
          ],
          highlight: DsProfileProgressCard(
            percent: completionPct,
            title: l10n.profileCompletion,
            subtitle: l10n.unlockPremiumFeatures,
            onTap: () => context.push(StaffRoutes.profileCompletion),
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
                  subtitle: l10n.modulesInProgress,
                  onTap: () => context.push(StaffRoutes.training),
                ),
                DsProfileMenuItem(
                  icon: Icons.videocam_rounded,
                  title: l10n.videoCertification,
                  subtitle: l10n.awaitingSubmission,
                  onTap: () => context.push(StaffRoutes.videoCertification),
                ),
                DsProfileMenuItem(
                  icon: Icons.edit_document,
                  title: l10n.agreement,
                  subtitle: l10n.signatureRequired,
                  badge: 'Action needed',
                  urgent: true,
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
    );
  }
}
