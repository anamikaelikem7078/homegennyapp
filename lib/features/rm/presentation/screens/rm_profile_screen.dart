import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../core/router/app_routes.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmProfileScreen extends ConsumerWidget {
  const RmProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;
    final kpis = ref.watch(rmDashboardProvider).maybeWhen(
          data: (d) => d.kpis,
          orElse: () => const RmDashboardKpis(),
        );
    final name =
        (user?.name.trim().isNotEmpty ?? false) ? user!.name.trim() : 'RM';
    final compactId = (user?.id ?? '').replaceAll('-', '').toUpperCase();
    final idValue = compactId.isEmpty
        ? 'RM-0000'
        : 'RM-${compactId.substring(0, compactId.length < 6 ? compactId.length : 6)}';

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: DsProfileView(
        name: name,
        role: 'Relationship Manager',
        idLabel: 'RM ID',
        idValue: idValue,
        tagline: 'HomeGenny Partner',
        onSettings: () => context.push(RmRoutes.security),
        facts: [
          if (user?.email.isNotEmpty ?? false)
            DsProfileFact(
              icon: Icons.mail_rounded,
              label: 'Email',
              value: user!.email,
            ),
          if (user?.phone?.isNotEmpty ?? false)
            DsProfileFact(
              icon: Icons.phone_rounded,
              label: 'Mobile',
              value: user!.phone!,
            ),
          const DsProfileFact(
            icon: Icons.workspace_premium_rounded,
            label: 'Access',
            value: 'Relationship Manager',
          ),
        ],
        stats: [
          DsProfileStat(
            label: 'Total staff',
            value: kpis.totalStaff,
            icon: Icons.groups_rounded,
          ),
          DsProfileStat(
            label: 'Active trials',
            value: kpis.trialPlacements,
            icon: Icons.play_circle_rounded,
          ),
          DsProfileStat(
            label: 'To verify',
            value: kpis.pendingVerification,
            icon: Icons.fact_check_rounded,
          ),
        ],
        sections: [
          DsProfileSection(
            title: 'Account settings',
            items: [
              DsProfileMenuItem(
                icon: Icons.person_rounded,
                title: 'Personal information',
                subtitle: 'View your details',
                onTap: () => context.push(RmRoutes.personalInfo),
              ),
              DsProfileMenuItem(
                icon: Icons.shield_rounded,
                title: 'Security & privacy',
                subtitle: 'Password and authentication',
                onTap: () => context.push(RmRoutes.security),
              ),
              DsProfileMenuItem(
                icon: Icons.notifications_rounded,
                title: 'Notifications',
                subtitle: 'Manage alert preferences',
                onTap: () => context.push(RmRoutes.notificationSettings),
              ),
            ],
          ),
          DsProfileSection(
            title: 'Support',
            items: [
              DsProfileMenuItem(
                icon: Icons.support_agent_rounded,
                title: 'Help center',
                subtitle: 'FAQs and contact support',
                onTap: () => context.push(RmRoutes.support),
              ),
              DsProfileMenuItem(
                icon: Icons.info_rounded,
                title: 'About HomeGenny',
                subtitle: 'Version 1.0.0',
                onTap: () => DsSuccessDialog.show(
                  context: context,
                  title: 'HomeGenny',
                  message: 'Version 1.0.0\n\n'
                      'The premium domestic staff management platform.',
                  buttonLabel: 'Close',
                ),
              ),
            ],
          ),
        ],
        // Must await logout (clears tokens + calls the real /auth/logout)
        // before navigating — firing context.go immediately let the login
        // screen render while the app still had a valid session, and if the
        // async logout failed it would fail out of sight, unobserved.
        onLogout: () async {
          await ref.read(authProvider.notifier).logout();
          if (!context.mounted) return;
          context.go(AppRoutes.login);
        },
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 4),
    );
  }
}
