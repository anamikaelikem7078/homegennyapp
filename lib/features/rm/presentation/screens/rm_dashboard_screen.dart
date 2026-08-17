import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/async_value_widget.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmDashboardScreen extends ConsumerWidget {
  const RmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final dashboard = ref.watch(rmDashboardProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(user?.name),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmDashboardProvider),
        child: AsyncValueWidget<RmDashboard>(
          value: dashboard,
          onRetry: () => ref.invalidate(rmDashboardProvider),
          errorTitle: 'Could not load dashboard',
          builder: (data) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildStatsGrid(isTablet, data.kpis),
                const SizedBox(height: 24),
                _buildPipelineDistribution(data.funnel),
                const SizedBox(height: 24),
                _buildActionButtons(context),
                const SizedBox(height: 16),
                _buildToolsRow(context),
                const SizedBox(height: 24),
                if (data.seriesDistribution.isNotEmpty) _buildSeriesBreakdown(data.seriesDistribution),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 0),
    );
  }

  AppBar _buildAppBar(String? userName) {
    return AppBar(
      backgroundColor: RmTheme.offWhite,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundColor: RmTheme.electricBlue.withOpacity(0.1),
            child: Text(
              (userName?.trim().isNotEmpty ?? false) ? userName!.trim()[0].toUpperCase() : 'R',
              style: const TextStyle(color: RmTheme.electricBlue, fontWeight: FontWeight.w700),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${userName ?? 'RM'}', style: RmTheme.headline(null).copyWith(fontSize: 18)),
              Text('RM Dashboard', style: RmTheme.body(null).copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatsGrid(bool isTablet, RmDashboardKpis kpis) {
    return GridView.count(
      crossAxisCount: isTablet ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 2.0 : 1.5,
      children: [
        _buildStatCard('Total Staff', '${kpis.totalStaff}', Icons.people_outline, RmTheme.textPrimary),
        _buildStatCard('Active Pipeline', '${kpis.activePipeline}', Icons.trending_up, RmTheme.electricBlue),
        _buildStatCard('Pending Verification', '${kpis.pendingVerification}', Icons.fact_check_outlined, RmTheme.amberWarning),
        _buildStatCard('Trials Active', '${kpis.trialPlacements}', Icons.play_circle_outline, RmTheme.emeraldGreen),
        _buildStatCard('Deployed', '${kpis.activePlacements}', Icons.check_circle_outline, RmTheme.emeraldGreen),
        _buildStatCard('Training Queue', '${kpis.trainingQueue}', Icons.school_outlined, RmTheme.electricBlueLight),
        _buildStatCard('Deployment Ready', '${kpis.deploymentQueue}', Icons.local_shipping_outlined, RmTheme.electricBlue),
        _buildStatCard('Deferred', '${kpis.deferredCases}', Icons.pause_circle_outline, RmTheme.textSecondary),
        _buildStatCard('Open Incidents', '${kpis.openIncidents}', Icons.report_problem_outlined, RmTheme.crimsonDanger),
        _buildStatCard('Pending Shifts', '${kpis.pendingShifts}', Icons.pending_actions, RmTheme.amberWarning),
        _buildStatCard('Pending Video', '${kpis.pendingVideo}', Icons.videocam_outlined, RmTheme.electricBlueLight),
        _buildStatCard('Monthly Placements', '${kpis.monthlyPlacements}', Icons.insights_outlined, RmTheme.textPrimary),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        gradient: LinearGradient(
          colors: [RmTheme.cardSurface, color.withOpacity(0.05)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: color.withOpacity(0.1), blurRadius: 12, offset: const Offset(0, 4))],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: RmTheme.label(null).copyWith(color: RmTheme.textSecondary, fontWeight: FontWeight.w600),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(value, style: RmTheme.headline(null).copyWith(color: RmTheme.textPrimary, fontSize: 28)),
        ],
      ),
    );
  }

  Widget _buildPipelineDistribution(List<PipelineFunnelEntry> funnel) {
    final total = funnel.fold<int>(0, (sum, e) => sum + e.count);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Pipeline Distribution', style: RmTheme.title(null).copyWith(color: RmTheme.textPrimary)),
          const SizedBox(height: 4),
          Text('Current staff across all stages', style: RmTheme.body(null)),
          const SizedBox(height: 24),
          if (total == 0)
            Text('No staff in the pipeline yet.', style: RmTheme.body(null).copyWith(color: RmTheme.textSecondary))
          else ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Row(
                children: [
                  for (final entry in funnel)
                    if (entry.count > 0)
                      Expanded(
                        flex: entry.count,
                        child: Container(height: 12, color: _stageColor(entry.stage)),
                      ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: [
                for (final entry in funnel)
                  _buildLegend('${_shortStage(entry.stage)} (${entry.count})', _stageColor(entry.stage)),
              ],
            ),
          ],
        ],
      ),
    );
  }

  String _shortStage(String stage) {
    const labels = {
      'S1_INTAKE': 'S1', 'S2_VERIFY': 'S2', 'S2_5_ASSESS': 'S2.5',
      'S3_TRAIN': 'S3', 'S4_AGREEMENTS': 'S4', 'S5_DEPLOY': 'S5',
      'DEFERRED': 'Deferred', 'TERMINAL': 'Terminal',
    };
    return labels[stage] ?? stage;
  }

  Color _stageColor(String stage) {
    const colors = {
      'S1_INTAKE': Color(0xFFE5E7EB), 'S2_VERIFY': Color(0xFF9CA3AF),
      'S2_5_ASSESS': Color(0xFF6B7280), 'S3_TRAIN': Color(0xFFD1D5DB),
      'S4_AGREEMENTS': RmTheme.electricBlueLight, 'S5_DEPLOY': RmTheme.electricBlue,
      'DEFERRED': RmTheme.amberWarning, 'TERMINAL': RmTheme.crimsonDanger,
    };
    return colors[stage] ?? RmTheme.textSecondary;
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label, style: RmTheme.label(null).copyWith(fontSize: 10, color: RmTheme.textSecondary)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton('Add New\nStaff', Icons.person_add_alt, () => context.push(RmRoutes.staffIntake)),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton('View\nPipeline', Icons.view_kanban_outlined, () => context.push(RmRoutes.pipeline)),
        ),
      ],
    );
  }

  Widget _buildActionButton(String label, IconData icon, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 24),
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          border: Border.all(color: RmTheme.electricBlue.withOpacity(0.15), width: 1.5),
          borderRadius: BorderRadius.circular(20),
          boxShadow: [BoxShadow(color: RmTheme.electricBlue.withOpacity(0.08), blurRadius: 16, offset: const Offset(0, 4))],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [RmTheme.electricBlue.withOpacity(0.15), RmTheme.electricBlue.withOpacity(0.05)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: RmTheme.electricBlue, size: 28),
            ),
            const SizedBox(height: 16),
            Text(
              label,
              textAlign: TextAlign.center,
              style: RmTheme.label(null).copyWith(fontWeight: FontWeight.w700, color: RmTheme.textPrimary, letterSpacing: 0.3),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildToolsRow(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: [
          _buildToolChip(context, 'Attendance', Icons.event_available_outlined, () => context.push(RmRoutes.attendance)),
          const SizedBox(width: 8),
          _buildToolChip(context, 'Locations', Icons.place_outlined, () => context.push(RmRoutes.locations)),
          const SizedBox(width: 8),
          _buildToolChip(context, 'Upgrades', Icons.trending_up, () => context.push(RmRoutes.upgrades)),
        ],
      ),
    );
  }

  Widget _buildToolChip(BuildContext context, String label, IconData icon, VoidCallback onTap) {
    return ActionChip(
      avatar: Icon(icon, size: 16, color: RmTheme.electricBlue),
      label: Text(label),
      onPressed: onTap,
      backgroundColor: RmTheme.cardSurface,
      side: BorderSide(color: RmTheme.electricBlue.withOpacity(0.2)),
    );
  }

  Widget _buildSeriesBreakdown(List<SeriesDistributionEntry> series) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Series Breakdown', style: RmTheme.title(null).copyWith(color: RmTheme.textPrimary)),
          const SizedBox(height: 16),
          Wrap(
            spacing: 12,
            runSpacing: 12,
            children: [
              for (final s in series)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                  decoration: BoxDecoration(
                    color: RmTheme.offWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RmTheme.borderSubtle),
                  ),
                  child: Text('${s.series}: ${s.count}', style: RmTheme.label(null).copyWith(fontWeight: FontWeight.w600)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
