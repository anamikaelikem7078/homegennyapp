import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../../../../common/domain/models/staff_entity.dart';

class RmStaffDetailScreen extends ConsumerStatefulWidget {
  final String staffId;
  const RmStaffDetailScreen({super.key, required this.staffId});

  @override
  ConsumerState<RmStaffDetailScreen> createState() =>
      _RmStaffDetailScreenState();
}

class _RmStaffDetailScreenState extends ConsumerState<RmStaffDetailScreen> {
  int _activeTabIndex =
      2; // 0: Overview, 1: Documents, 2: Verify (Verify is active in mockup)

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(rmStaffDetailProvider(widget.staffId));

    if (staff == null) {
      return Scaffold(
        appBar: AppBar(),
        body: const Center(child: Text('Staff not found')),
      );
    }

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RmTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Staff Details',
          style: RmTheme.headline(
            context,
          ).copyWith(fontSize: 18, color: RmTheme.textPrimary),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.more_vert, color: RmTheme.textPrimary),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildProfileSummary(staff),
            const SizedBox(height: 16),
            _buildOnboardingJourney(staff),
            const SizedBox(height: 24),
            _buildTabs(),
            const SizedBox(height: 16),
            _buildTabContent(staff),
          ],
        ),
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [_buildFooterActions(staff), _buildBottomNav(context)],
      ),
    );
  }

  Widget _buildProfileSummary(StaffEntity staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(16),
            child: Image.network(
              staff.profileImage ??
                  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=300',
              width: 80,
              height: 80,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            staff.name,
            style: RmTheme.headline(
              context,
            ).copyWith(color: RmTheme.electricBlue, fontSize: 18),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: RmTheme.textSecondary.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  staff.staffCode,
                  style: RmTheme.label(
                    context,
                  ).copyWith(color: RmTheme.electricBlue, fontSize: 12),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                staff.phone,
                style: RmTheme.body(context).copyWith(fontSize: 12),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RmTheme.cardSurface,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: RmTheme.amberWarning.withOpacity(0.3)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 6,
                  height: 6,
                  decoration: const BoxDecoration(
                    color: RmTheme.amberWarning,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  '${staff.status} - ${staff.pipelineStage}',
                  style: RmTheme.label(context).copyWith(
                    color: RmTheme.amberWarning,
                    fontSize: 10,
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

  Widget _buildOnboardingJourney(StaffEntity staff) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Onboarding Progress',
            style: RmTheme.headline(context).copyWith(fontSize: 18),
          ),
          const SizedBox(height: 24),
          _buildTimelineItem('Intake', 'Completed Jan 12', true),
          _buildTimelineItem('Verification', 'Completed Jan 14', true),
          _buildTimelineItem('Training', 'Completed Jan 15', true),
          _buildTimelineActiveItem('Agreements'),
        ],
      ),
    );
  }

  Widget _buildTimelineItem(String title, String time, bool isCompleted) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: const BoxDecoration(
                color: RmTheme.electricBlue,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.check, size: 16, color: Colors.white),
            ),
            Container(width: 1, height: 36, color: RmTheme.borderSubtle),
          ],
        ),
        const SizedBox(width: 16),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: RmTheme.label(
                context,
              ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
            ),
            const SizedBox(height: 2),
            Text(time, style: RmTheme.body(context).copyWith(fontSize: 12)),
          ],
        ),
      ],
    );
  }

  Widget _buildTimelineActiveItem(String title) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Column(
          children: [
            Container(
              width: 24,
              height: 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(color: RmTheme.electricBlue, width: 2),
              ),
              padding: const EdgeInsets.all(4),
              child: Container(
                decoration: const BoxDecoration(
                  color: RmTheme.electricBlue,
                  shape: BoxShape.circle,
                ),
              ),
            ),
          ],
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: RmTheme.label(context).copyWith(
                  color: RmTheme.electricBlue,
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RmTheme.electricBlue.withOpacity(0.05),
                  border: Border.all(
                    color: RmTheme.electricBlue.withOpacity(0.1),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(
                      Icons.info_outline,
                      size: 16,
                      color: RmTheme.electricBlue,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'ACTION REQUIRED',
                            style: RmTheme.label(context).copyWith(
                              color: RmTheme.electricBlue,
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Review and approve final contractor agreements.',
                            style: RmTheme.body(context).copyWith(
                              fontSize: 12,
                              color: RmTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTabs() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: RmTheme.borderSubtle)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildTab('Overview', 0),
          _buildTab('Documents', 1),
          _buildTab('Verify', 2),
        ],
      ),
    );
  }

  Widget _buildTab(String label, int index) {
    final isActive = _activeTabIndex == index;
    return GestureDetector(
      onTap: () => setState(() => _activeTabIndex = index),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Text(
              label,
              style: RmTheme.label(context).copyWith(
                color: isActive ? RmTheme.electricBlue : RmTheme.textPrimary,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
                fontSize: 14,
              ),
            ),
          ),
          Container(
            height: 2,
            width: 60,
            color: isActive ? RmTheme.electricBlue : Colors.transparent,
          ),
        ],
      ),
    );
  }

  Widget _buildTabContent(StaffEntity staff) {
    if (_activeTabIndex == 0) {
      // Overview
      return Column(
        children: [
          _buildSummaryRow('Email', staff.email ?? 'Not Provided'),
          const SizedBox(height: 12),
          _buildSummaryRow('Address', staff.address ?? 'Not Provided'),
          const SizedBox(height: 12),
          _buildSummaryRow('Joined', staff.createdAt.toString().split(' ')[0]),
        ],
      );
    } else if (_activeTabIndex == 1 || _activeTabIndex == 2) {
      // Documents / Verify
      return Column(
        children: [
          _buildDocumentCard(
            'Aadhaar Card',
            'Uploaded Jan 12',
            Icons.assignment_ind_outlined,
          ),
          const SizedBox(height: 12),
          _buildDocumentCard(
            'PAN Card',
            'Uploaded Jan 12',
            Icons.credit_card_outlined,
          ),
          const SizedBox(height: 12),
          _buildDocumentCard(
            'Driving License',
            'Uploaded Jan 13',
            Icons.drive_eta_outlined,
          ),
        ],
      );
    }
    return const Center(child: Text('Content Placeholder'));
  }

  Widget _buildSummaryRow(String label, String value) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: RmTheme.textSecondary,
            ),
          ),
          Text(
            value,
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RmTheme.textPrimary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDocumentCard(String title, String date, IconData icon) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RmTheme.borderSubtle.withOpacity(0.3),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: RmTheme.textPrimary, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: RmTheme.label(
                    context,
                  ).copyWith(fontWeight: FontWeight.w500, fontSize: 14),
                ),
                const SizedBox(height: 4),
                Text(date, style: RmTheme.body(context).copyWith(fontSize: 12)),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: RmTheme.emeraldGreen.withOpacity(0.05),
              border: Border.all(color: RmTheme.emeraldGreen.withOpacity(0.3)),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.check_circle_outline,
                  size: 12,
                  color: RmTheme.emeraldGreen,
                ),
                const SizedBox(width: 4),
                Text(
                  'APPROVED',
                  style: RmTheme.label(context).copyWith(
                    color: RmTheme.emeraldGreen,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFooterActions(StaffEntity staff) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(color: RmTheme.offWhite),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Row(
          children: [
            Expanded(
              flex: 1,
              child: OutlinedButton(
                onPressed: () {},
                style: OutlinedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  side: const BorderSide(color: RmTheme.textPrimary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  backgroundColor: RmTheme.cardSurface,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.upload_file_outlined,
                      size: 18,
                      color: RmTheme.textPrimary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Upload Files',
                      style: RmTheme.label(
                        context,
                      ).copyWith(fontWeight: FontWeight.w500),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 1,
              child: ElevatedButton(
                onPressed: () {
                  _onApproveStage(staff);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RmTheme.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(Icons.check, size: 18),
                    const SizedBox(width: 8),
                    Text(
                      'Approve Stage',
                      style: RmTheme.label(context).copyWith(
                        color: Colors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        border: const Border(top: BorderSide(color: RmTheme.borderSubtle)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(
                Icons.dashboard_outlined,
                'Dashboard',
                false,
                onTap: () => context.pushReplacement(RmRoutes.dashboard),
              ),
              _buildNavItem(
                Icons.view_kanban,
                'Pipeline',
                true,
                onTap: () => context.pushReplacement(RmRoutes.pipeline),
              ),
              _buildNavItem(Icons.check_circle_outline, 'Tasks', false),
              _buildNavItem(Icons.notifications_outlined, 'Alerts', false),
              _buildNavItem(Icons.person_outline, 'Profile', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(
    IconData icon,
    String label,
    bool isActive, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: RmTheme.electricBlue,
                borderRadius: BorderRadius.circular(8),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              icon,
              color: isActive ? Colors.white : RmTheme.textPrimary,
              size: 20,
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: RmTheme.label(context).copyWith(
                color: isActive ? Colors.white : RmTheme.textPrimary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w500 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _onApproveStage(StaffEntity staff) async {
    final stages = [
      'REGISTRATION',
      'VERIFICATION',
      'TRAINING',
      'VIDEO_CERTIFICATION',
      'AGREEMENT',
      'DEPLOYMENT',
      'TRIAL',
      'ACTIVE_PLACEMENT',
    ];

    final currentIndex = stages.indexOf(staff.pipelineStage);
    if (currentIndex >= 0 && currentIndex < stages.length - 1) {
      final nextStage = stages[currentIndex + 1];
      final updatedStaff = staff.copyWith(pipelineStage: nextStage);
      await ref.read(rmRepositoryProvider).updateStaff(updatedStaff);

      // Invalidate specific staff provider to refresh details
      ref.invalidate(rmStaffDetailProvider(staff.id));
      // Invalidate pipeline provider to reflect changes in dashboard/pipeline
      ref.invalidate(rmPipelineProvider);
      ref.invalidate(rmDashboardStatsProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Staff stage approved and advanced to $nextStage'),
          ),
        );

        // Navigate to the next stage's screen for pipeline testing
        switch (nextStage) {
          case 'VERIFICATION':
            context.push(RmRoutes.verificationDashboard(staff.id));
            break;
          case 'TRAINING':
            context.push(RmRoutes.stage3Training(staff.id));
            break;
          case 'VIDEO_CERTIFICATION':
            context.push(RmRoutes.stage3VideoReview(staff.id));
            break;
          case 'AGREEMENT':
            context.push(RmRoutes.stage4Hub(staff.id));
            break;
          case 'TRIAL':
            context.push(RmRoutes.stage5TrialCheckin(staff.id));
            break;
          case 'ACTIVE_PLACEMENT':
            context.push(RmRoutes.staffActivePlacement(staff.id));
            break;
        }
      }
    } else {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Staff is already in the final stage.')),
        );
      }
    }
  }
}
