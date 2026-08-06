import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// Report kind for routing to the correct provider.
enum RmReportKind { daily, weekly, monthly, attendance, pipeline, deployment }

/// Reports tab.
class RmReportsTabScreen extends ConsumerWidget {
  const RmReportsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(rmDashboardProvider);

    return Scaffold(
      appBar: const DsAppBar(title: 'Reports', subtitle: 'Analytics & insights'),
      body: dashboard.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (summary) => ListView(
          padding: AppBreakpoints.pagePadding(context),
          children: [
            Row(
              children: [
                Expanded(
                  child: RmKpiCard(
                    label: 'Total Staff',
                    value: '${summary.totalStaff}',
                    icon: Icons.people_rounded,
                  ),
                ),
                SizedBox(width: AppSpacing.sm),
                Expanded(
                  child: RmKpiCard(
                    label: 'Total Clients',
                    value: '${summary.totalClients}',
                    icon: Icons.home_work_rounded,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.lg),
            RmSectionHeader(title: 'Report Types'),
            RmMenuTile(
              icon: Icons.today_outlined,
              title: 'Daily Report',
              onTap: () => context.push(RmRoutes.reportDaily),
            ),
            RmMenuTile(
              icon: Icons.date_range_outlined,
              title: 'Weekly Report',
              onTap: () => context.push(RmRoutes.reportWeekly),
            ),
            RmMenuTile(
              icon: Icons.calendar_month_outlined,
              title: 'Monthly Report',
              onTap: () => context.push(RmRoutes.reportMonthly),
            ),
            RmMenuTile(
              icon: Icons.fact_check_outlined,
              title: 'Attendance Report',
              onTap: () => context.push(RmRoutes.reportAttendance),
            ),
            RmMenuTile(
              icon: Icons.account_tree_outlined,
              title: 'Pipeline Report',
              onTap: () => context.push(RmRoutes.reportPipeline),
            ),
            RmMenuTile(
              icon: Icons.location_on_outlined,
              title: 'Deployment Report',
              onTap: () => context.push(RmRoutes.reportDeployment),
            ),
          ],
        ),
      ),
    );
  }
}

/// Generic report detail screen.
class RmReportDetailScreen extends ConsumerWidget {
  const RmReportDetailScreen({
    super.key,
    required this.title,
    required this.kind,
  });

  final String title;
  final RmReportKind kind;

  AsyncValue<RmReportSummary> _watchReport(WidgetRef ref) {
    return switch (kind) {
      RmReportKind.daily => ref.watch(rmReportProvider(RmReportPeriod.daily)),
      RmReportKind.weekly => ref.watch(rmReportProvider(RmReportPeriod.weekly)),
      RmReportKind.monthly => ref.watch(rmReportProvider(RmReportPeriod.monthly)),
      RmReportKind.attendance => ref.watch(rmAttendanceReportProvider),
      RmReportKind.pipeline => ref.watch(rmPipelineReportProvider),
      RmReportKind.deployment => ref.watch(rmDeploymentReportProvider),
    };
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = _watchReport(ref);

    return RmPageScaffold(
      title: title,
      body: report.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (data) => ListView(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.xl),
              decoration: AppDecorations.softCard(context),
              child: Column(
                children: [
                  Text(data.title, style: Theme.of(context).textTheme.titleMedium),
                  SizedBox(height: AppSpacing.sm),
                  Text(data.period, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            RmSectionHeader(title: 'Metrics'),
            ...data.metrics.map(
              (m) => Padding(
                padding: EdgeInsets.only(bottom: AppSpacing.sm),
                child: Container(
                  padding: EdgeInsets.all(AppSpacing.lg),
                  decoration: AppDecorations.softCard(context),
                  child: Row(
                    children: [
                      Expanded(child: Text(m.label)),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(m.value, style: Theme.of(context).textTheme.titleSmall),
                          Text(
                            m.change,
                            style: TextStyle(
                              color: m.isPositive ? AppColors.success : AppColors.error,
                              fontSize: 12,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
