import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// RM Dashboard tab — enterprise overview.
class RmDashboardHomeScreen extends ConsumerWidget {
  const RmDashboardHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(rmDashboardProvider);

    return Scaffold(
      appBar: DsAppBar(
        title: 'RM Dashboard',
        subtitle: 'Relationship Manager',
        useGradient: true,
        actions: [
          IconButton(
            icon: Icon(Icons.check, color: context.theme.cardColor),
            onPressed: () => context.push(RmRoutes.notifications),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: dashboard,
        onRetry: () => ref.invalidate(rmDashboardProvider),
        loadingMessage: context.l10n.loading,
        builder: (data) => DsRefreshIndicator(
          onRefresh: () async => ref.invalidate(rmDashboardProvider),
          child: ListView(
            padding: AppBreakpoints.pagePadding(context),
            children: [
              _WelcomeBanner(name: data.rmName),
              SizedBox(height: AppSpacing.lg),
              Row(
                children: [
                  Expanded(
                    child: RmKpiCard(
                      label: 'Total Staff',
                      value: '${data.totalStaff}',
                      icon: Icons.people_rounded,
                      onTap: () => context.go(RmRoutes.staff),
                    ),
                  ),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: RmKpiCard(
                      label: 'Total Clients',
                      value: '${data.totalClients}',
                      icon: Icons.home_work_rounded,
                      color: AppColors.primary,
                      onTap: () => context.go(RmRoutes.clients),
                    ),
                  ),
                ],
              ),
              SizedBox(height: AppSpacing.lg),
              RmSectionHeader(
                title: 'Pending Actions',
                actionLabel: 'View all',
                onAction: () => context.push(RmRoutes.pendingVerification),
              ),
              _PendingGrid(data: data),
              SizedBox(height: AppSpacing.lg),
              RmSectionHeader(
                title: "Today's Follow-ups",
                actionLabel: 'See all',
                onAction: () => context.push(RmRoutes.followUpsToday),
              ),
              ...data.followUpsToday.take(3).map(
                    (f) => Padding(
                      padding: EdgeInsets.only(bottom: AppSpacing.sm),
                      child: _FollowUpTile(followUp: f),
                    ),
                  ),
              SizedBox(height: AppSpacing.lg),
              RmMenuTile(
                icon: Icons.support_agent_rounded,
                title: 'Client Requests',
                subtitle: '${data.clientRequests} pending',
                badge: '${data.clientRequests}',
                onTap: () => context.push(RmRoutes.clientRequests),
              ),
              RmMenuTile(
                icon: Icons.location_on_outlined,
                title: 'Deployment Management',
                onTap: () => context.push(RmRoutes.deployment),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeBanner extends StatelessWidget {
  const _WelcomeBanner({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.xl),
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadius.lgAll,
        boxShadow: AppShadows.button(),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: Colors.white24,
            child: Icon(Icons.manage_accounts, color: context.theme.cardColor, size: 32),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Good morning,', style: TextStyle(color: context.theme.cardColor.withValues(alpha: 0.85))),
                Text(
                  name,
                  style: TextStyle(color: context.theme.cardColor,
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
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

class _PendingGrid extends StatelessWidget {
  const _PendingGrid({required this.data});
  final RmDashboardData data;

  @override
  Widget build(BuildContext context) {
    final items = [
      ('Verification', data.pendingVerification, RmRoutes.pendingVerification, Icons.verified_user_outlined),
      ('Training', data.pendingTraining, RmRoutes.pendingTraining, Icons.school_outlined),
      ('Agreement', data.pendingAgreement, RmRoutes.pendingAgreement, Icons.description_outlined),
      ('Deployment', data.pendingDeployment, RmRoutes.pendingDeployment, Icons.rocket_launch_outlined),
    ];

    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: items
          .map(
            (item) => SizedBox(
              width: (MediaQuery.sizeOf(context).width - 44) / 2,
              child: GestureDetector(
                onTap: () => context.push(item.$3),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.md),
                  decoration: AppDecorations.softCard(context),
                  child: Row(
                    children: [
                      Icon(item.$4, color: AppColors.secondary, size: 20),
                      SizedBox(width: AppSpacing.sm),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('${item.$2}', style: Theme.of(context).textTheme.titleLarge),
                            Text(item.$1, style: Theme.of(context).textTheme.bodySmall),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class _FollowUpTile extends StatelessWidget {
  const _FollowUpTile({required this.followUp});
  final RmFollowUp followUp;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.softCard(context),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 40,
            decoration: BoxDecoration(
              color: AppColors.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(followUp.title, style: Theme.of(context).textTheme.titleSmall),
                Text(followUp.subtitle, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          Text(followUp.time, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}

/// Today's follow-ups list.
class RmFollowUpsTodayScreen extends ConsumerWidget {
  const RmFollowUpsTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUps = ref.watch(rmFollowUpsProvider);
    return RmPageScaffold(
      title: "Today's Follow-ups",
      body: followUps.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.builder(
          itemCount: list.length,
          itemBuilder: (_, i) => Padding(
            padding: EdgeInsets.only(bottom: AppSpacing.sm),
            child: _FollowUpTile(followUp: list[i]),
          ),
        ),
      ),
    );
  }
}

/// Generic pending list screen.
class RmPendingListScreen extends ConsumerWidget {
  const RmPendingListScreen({
    super.key,
    required this.title,
    required this.type,
  });

  final String title;
  final RmPendingType type;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUps = ref.watch(rmFollowUpsProvider);
    return RmPageScaffold(
      title: title,
      body: followUps.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final filtered = list.where((f) => f.type == type).toList();
          if (filtered.isEmpty) {
            return const DsEmptyState(title: 'All clear', message: 'No pending items');
          }
          return ListView.builder(
            itemCount: filtered.length,
            itemBuilder: (_, i) => Padding(
              padding: EdgeInsets.only(bottom: AppSpacing.sm),
              child: _FollowUpTile(followUp: filtered[i]),
            ),
          );
        },
      ),
    );
  }
}

/// Client requests screen.
class RmClientRequestsScreen extends ConsumerWidget {
  const RmClientRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(rmClientRequestsProvider);
    return RmPageScaffold(
      title: 'Client Requests',
      body: requests.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) {
            final r = list[i];
            return Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.softCard(context),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(r.clientName, style: Theme.of(context).textTheme.titleSmall),
                      ),
                      if (r.isUrgent)
                        const DsStatusChip(label: 'Urgent', type: DsStatusType.error),
                    ],
                  ),
                  Text(r.requestType, style: Theme.of(context).textTheme.bodySmall),
                  SizedBox(height: AppSpacing.xs),
                  Text(r.message),
                  Text(r.time, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
