import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../common/presentation/providers/auth_provider.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmDashboardScreen extends ConsumerWidget {
  const RmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isTablet = MediaQuery.of(context).size.width > 600;
    final stats = ref.watch(rmDashboardStatsProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(user?.name, user?.avatarUrl),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildStatsGrid(isTablet, stats),
            const SizedBox(height: 24),
            _buildPipelineDistribution(),
            const SizedBox(height: 24),
            _buildActionButtons(context),
            const SizedBox(height: 24),
            _buildRecentActivity(),
          ],
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 0),
    );
  }

  AppBar _buildAppBar(String? userName, String? avatarUrl) {
    return AppBar(
      backgroundColor: RmTheme.offWhite,
      elevation: 0,
      title: Row(
        children: [
          CircleAvatar(
            backgroundImage: avatarUrl != null 
              ? NetworkImage(avatarUrl)
              : const NetworkImage('https://images.unsplash.com/photo-1573496359142-b8d87734a5a2?w=150'),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Hello, ${userName ?? 'Priya'}', style: RmTheme.headline(null).copyWith(fontSize: 18)),
              Text('Mumbai West', style: RmTheme.body(null).copyWith(fontSize: 12)),
            ],
          ),
        ],
      ),
      actions: [
        Stack(
          alignment: Alignment.center,
          children: [
            IconButton(
              icon: const Icon(Icons.notifications_none, color: RmTheme.textPrimary),
              onPressed: () {},
            ),
            Positioned(
              right: 12,
              top: 12,
              child: Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: RmTheme.electricBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildStatsGrid(bool isTablet, Map<String, int> stats) {
    return GridView.count(
      crossAxisCount: isTablet ? 4 : 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 16,
      mainAxisSpacing: 16,
      childAspectRatio: isTablet ? 2.0 : 1.5,
      children: [
        _buildStatCard('Total Staff', '${stats['totalStaff'] ?? 0}', Icons.people_outline, RmTheme.textPrimary),
        _buildStatCard('Active Pipeline', '${stats['pipeline'] ?? 0}', Icons.trending_up, RmTheme.electricBlue),
        _buildStatCard('Alerts', '${stats['alerts'] ?? 0}', Icons.warning_amber_rounded, RmTheme.amberWarning),
        _buildStatCard('Trials Active', '${stats['trialsActive'] ?? 0}', Icons.play_circle_outline, RmTheme.textPrimary),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        gradient: LinearGradient(
          colors: [
            RmTheme.cardSurface,
            color.withOpacity(0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: color.withOpacity(0.15), width: 1.5),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: color.withOpacity(0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(icon, size: 16, color: color),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: RmTheme.label(null).copyWith(
                    color: RmTheme.textSecondary,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          Text(
            value,
            style: RmTheme.headline(null).copyWith(
              color: RmTheme.textPrimary,
              fontSize: 28,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPipelineDistribution() {
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
          Text('Current candidates across all stages', style: RmTheme.body(null)),
          const SizedBox(height: 24),
          Row(
            children: [
              _buildSegment(15, const Color(0xFFE5E7EB)),
              _buildSegment(25, const Color(0xFF6B7280)),
              _buildSegment(35, const Color(0xFFD1D5DB)),
              _buildSegment(15, RmTheme.electricBlueLight),
              _buildSegment(10, RmTheme.electricBlue, isLast: true),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              _buildLegend('S1 (15%)', const Color(0xFFE5E7EB)),
              _buildLegend('S2 (25%)', const Color(0xFF6B7280)),
              _buildLegend('S3 (35%)', const Color(0xFFD1D5DB)),
              _buildLegend('S4 (15%)', RmTheme.electricBlueLight),
              _buildLegend('S5 (10%)', RmTheme.electricBlue),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSegment(int flex, Color color, {bool isLast = false}) {
    return Expanded(
      flex: flex,
      child: Container(
        height: 12,
        decoration: BoxDecoration(
          color: color,
          borderRadius: isLast ? const BorderRadius.horizontal(right: Radius.circular(6)) : null,
        ),
      ),
    );
  }

  Widget _buildLegend(String label, Color color) {
    return Row(
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(label, style: RmTheme.label(null).copyWith(fontSize: 10, color: RmTheme.textSecondary)),
      ],
    );
  }

  Widget _buildActionButtons(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: _buildActionButton(
            'Add New\nStaff',
            Icons.person_add_alt,
            () => context.push(RmRoutes.staffIntake),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: _buildActionButton(
            'Verify\nDocs',
            Icons.fact_check_outlined,
            () {},
          ),
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
          boxShadow: [
            BoxShadow(
              color: RmTheme.electricBlue.withOpacity(0.08),
              blurRadius: 16,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(14),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    RmTheme.electricBlue.withOpacity(0.15),
                    RmTheme.electricBlue.withOpacity(0.05),
                  ],
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
              style: RmTheme.label(null).copyWith(
                fontWeight: FontWeight.w700,
                color: RmTheme.textPrimary,
                letterSpacing: 0.3,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRecentActivity() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Recent Activity', style: RmTheme.title(null).copyWith(color: RmTheme.textPrimary)),
              const Icon(Icons.history, color: RmTheme.textSecondary),
            ],
          ),
          const Divider(height: 32),
          _buildActivityItem('Rahul S.', 'moved to S3 (Training)', '10 mins ago', Icons.circle, RmTheme.electricBlue, RmTheme.electricBlueLight.withOpacity(0.2)),
          _buildActivityItem('Anita K.', 'docs verified', '1 hour ago', Icons.check, RmTheme.emeraldGreen, RmTheme.emeraldGreen.withOpacity(0.1)),
          _buildActivityItem('Background check flagged for', 'Vikram M.', '3 hours ago', Icons.priority_high, RmTheme.amberWarning, RmTheme.amberWarning.withOpacity(0.1)),
          _buildActivityItem('S4 Agreements', 'sent to 5 candidates', 'Yesterday', Icons.login, RmTheme.textSecondary, RmTheme.offWhite, isLast: true),
        ],
      ),
    );
  }

  Widget _buildActivityItem(String titlePart1, String titlePart2, String time, IconData icon, Color iconColor, Color bgColor, {bool isLast = false}) {
    return Stack(
      children: [
        if (!isLast)
          Positioned(
            left: 11,
            top: 24,
            bottom: 0,
            child: Container(
              width: 2,
              color: RmTheme.borderSubtle,
            ),
          ),
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: bgColor,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 12, color: iconColor),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  RichText(
                    text: TextSpan(
                      style: RmTheme.body(null).copyWith(color: RmTheme.textPrimary),
                      children: [
                        TextSpan(text: '$titlePart1 ', style: const TextStyle(fontWeight: FontWeight.w600)),
                        TextSpan(text: titlePart2),
                      ],
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(time, style: RmTheme.label(null).copyWith(color: RmTheme.textSecondary)),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}
