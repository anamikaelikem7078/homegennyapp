import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/localization/locale_provider.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// Profile tab.
class RmProfileTabScreen extends ConsumerWidget {
  const RmProfileTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(rmDashboardProvider);

    return Scaffold(
      appBar: const DsAppBar(title: 'Profile', subtitle: 'Account & settings'),
      body: dashboard.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (data) => ListView(
          padding: AppBreakpoints.pagePadding(context),
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 48,
                    backgroundColor: AppColors.primary,
                    child: Icon(Icons.manage_accounts, color: context.theme.cardColor, size: 48),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(data.rmName, style: Theme.of(context).textTheme.headlineSmall),
                  Text('Relationship Manager'),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            RmMenuTile(icon: Icons.notifications_outlined, title: 'Notifications', onTap: () => context.push(RmRoutes.notifications)),
            RmMenuTile(icon: Icons.settings_outlined, title: 'Settings', onTap: () => context.push(RmRoutes.settings)),
            RmMenuTile(icon: Icons.verified_user_outlined, title: 'Verification', onTap: () => context.push(RmRoutes.verificationPending)),
            RmMenuTile(icon: Icons.school_outlined, title: 'Training', onTap: () => context.push(RmRoutes.trainingAssign)),
            RmMenuTile(icon: Icons.videocam_outlined, title: 'Video Review', onTap: () => context.push(RmRoutes.videosPending)),
            RmMenuTile(icon: Icons.location_on_outlined, title: 'Deployment', onTap: () => context.push(RmRoutes.deployment)),
            SizedBox(height: AppSpacing.xl),
            DsOutlineButton(
              label: 'Sign Out',
              onPressed: () => context.go('/login'),
              color: AppColors.error,
            ),
          ],
        ),
      ),
    );
  }
}

/// Notifications screen.
class RmNotificationsScreen extends ConsumerWidget {
  const RmNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(rmNotificationsProvider);

    return RmPageScaffold(
      title: 'Notifications',
      body: notifications.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final n = list[i];
            return Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.softCard(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(
                    n.isRead ? Icons.notifications_none : Icons.notifications_active,
                    color: n.isRead ? AppColors.lightTextHint : AppColors.primary,
                  ),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(n.title, style: Theme.of(context).textTheme.titleSmall),
                        Text(n.message),
                        Text(n.time, style: Theme.of(context).textTheme.bodySmall),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

/// Settings screen.
class RmSettingsScreen extends ConsumerStatefulWidget {
  const RmSettingsScreen({super.key});

  @override
  ConsumerState<RmSettingsScreen> createState() => _RmSettingsScreenState();
}

class _RmSettingsScreenState extends ConsumerState<RmSettingsScreen> {
  bool _pushEnabled = true;
  bool _emailEnabled = false;

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return RmPageScaffold(
      title: 'Settings',
      body: ListView(
        children: [
          RmSectionHeader(title: 'Preferences'),
          RmMenuTile(
            icon: Icons.language_rounded,
            title: context.l10n.languageSettings,
            subtitle: locale.languageCode == 'hi' ? 'Hindi' : 'English',
            onTap: () => context.push('${RmRoutes.settings}/language'),
          ),
          RmMenuTile(
            icon: Icons.palette_outlined,
            title: context.l10n.themeSettings,
            onTap: () => context.push('${RmRoutes.settings}/theme'),
          ),
          SizedBox(height: AppSpacing.lg),
          RmSectionHeader(title: 'Notifications'),
          SwitchListTile(
            title: Text('Push Notifications'),
            value: _pushEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _pushEnabled = v),
          ),
          SwitchListTile(
            title: Text('Email Alerts'),
            value: _emailEnabled,
            activeColor: AppColors.primary,
            onChanged: (v) => setState(() => _emailEnabled = v),
          ),
          SizedBox(height: AppSpacing.lg),
          RmSectionHeader(title: 'Quick Links'),
          RmMenuTile(icon: Icons.school_outlined, title: 'Training Progress', onTap: () => context.push(RmRoutes.trainingProgress)),
          RmMenuTile(icon: Icons.workspace_premium_outlined, title: 'Certificates', onTap: () => context.push(RmRoutes.trainingCertificates)),
          RmMenuTile(icon: Icons.privacy_tip_outlined, title: 'Privacy Policy', onTap: () {}),
          RmMenuTile(icon: Icons.help_outline, title: 'Help & Support', onTap: () {}),
        ],
      ),
    );
  }
}
