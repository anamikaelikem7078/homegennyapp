import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/core/theme/app_fonts.dart';
import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../providers/staff_providers.dart';
import '../../../../../common/presentation/viewmodels/biometric_viewmodel.dart';
import '../../../../../core/series/series_catalog.dart';
import '../../../../care/presentation/care_providers.dart';
import '../care/staff_care_screens.dart';
import '../care/staff_client_updates_screen.dart';
import '../care/staff_cook_screens.dart';
import '../care/staff_instruction_screens.dart';

/// Staff home dashboard tab.
class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(staffDashboardProvider);
    final authState = ref.watch(authProvider);
    final userName = authState.user?.name ?? 'Staff User';

    return Scaffold(
      body: AsyncValueWidget(
        value: dashboard,
        onRetry: () => ref.invalidate(staffDashboardProvider),
        loadingMessage: context.l10n.loading,
        builder: (data) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: DsRefreshIndicator(
              onRefresh: () async {
                ref.invalidate(staffDashboardProvider);
                ref.invalidate(staffCareTodayProvider);
                ref.invalidate(cookTodayProvider);
                ref.invalidate(staffInstructionsProvider);
                ref.invalidate(clientUpdatesUnreadProvider);
              },
              child: ListView(
            padding: EdgeInsets.zero,
            children: [
              _WelcomeHeader(name: userName),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
              _ProfileSpotlightCard(
                name: data.fullName,
                role: SeriesDisplay.label(data.series),
                employeeId: data.staffCode,
                onTap: () => context.push(StaffRoutes.profileCompletion),
                onBiometricTap: () async {
                  final biometricViewModel = ref.read(biometricViewModelProvider.notifier);
                  final isAvailable = await biometricViewModel.checkBiometricAvailability();
                  if (isAvailable && context.mounted) {
                    final success = await biometricViewModel.authenticate();
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(success ? 'Biometric Authentication Successful' : 'Biometric Authentication Failed'),
                          backgroundColor: success ? Colors.green : Colors.red,
                        ),
                      );
                    }
                  } else if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Biometric authentication is not available on this device'),
                        backgroundColor: Colors.red,
                      ),
                    );
                  }
                },
              ),
              const SizedBox(height: 16),
              const StaffClientUpdatesHomeCard(),
              const StaffCareHomeCard(),
              const StaffCookHomeCard(),
              const StaffInstructionsHomeCard(),
              _AttendanceBentoCard(
                percentage: 92,
                onTap: () => context.go(StaffRoutes.attendance),
              ),
              const SizedBox(height: 16),
              _OngoingTrainingWidget(),
              const SizedBox(height: 24),
              _QuickManagementGrid(),
              const SizedBox(height: 24),
              _CareShieldBanner(),
              const SizedBox(height: 100),
                  ]
                      .animate(interval: 70.ms)
                      .fadeIn(duration: 380.ms)
                      .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  ),
);
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});
  final String name;

  void _showNewRequestBottomSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
          child: SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: const Color(0xFFE2E8F0),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Submit New Request',
                  style: AppFonts.display(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the type of request you would like to log with your Relationship Manager.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                  ),
                ),
                const SizedBox(height: 24),
                _BottomSheetActionTile(
                  icon: Icons.calendar_today_outlined,
                  title: 'Leave Request',
                  subtitle: 'Request planned time off or report absence',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Leave request logged and sent to your Relationship Manager.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _BottomSheetActionTile(
                  icon: Icons.access_time_outlined,
                  title: 'Shift Change Request',
                  subtitle: 'Request to swap or modify a scheduled shift',
                  onTap: () {
                    Navigator.pop(context);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          'Shift change request logged and sent to your RM.',
                          style: GoogleFonts.plusJakartaSans(),
                        ),
                        backgroundColor: const Color(0xFF16A34A),
                      ),
                    );
                  },
                ),
                const SizedBox(height: 12),
                _BottomSheetActionTile(
                  icon: Icons.payments_outlined,
                  title: 'Salary Advance / Query',
                  subtitle: 'Request salary advance or raise a payment query',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(StaffRoutes.salary);
                  },
                ),
                const SizedBox(height: 12),
                _BottomSheetActionTile(
                  icon: Icons.support_agent_outlined,
                  title: 'Contact Concierge Support',
                  subtitle: 'Chat directly with support specialist',
                  onTap: () {
                    Navigator.pop(context);
                    context.push(StaffRoutes.help);
                  },
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
         ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().split(RegExp(r'\s+')).first;
    return DsHeroHeader(
      leading: DsRingAvatar(
        name: name,
        onTap: () => context.go(StaffRoutes.profile),
      ),
      actions: [
        DsHeroIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Notifications',
          badgeCount: 1,
          onPressed: () => context.push(StaffRoutes.notifications),
        ),
      ],
      eyebrow: dsGreeting(),
      eyebrowIcon: Icons.wb_sunny_rounded,
      title: 'Welcome back,\n$firstName',
      subtitle: 'Your personal care ecosystem at a glance.',
      floatingIcons: const [
        Icons.cleaning_services_rounded,
        Icons.fingerprint_rounded,
        Icons.workspace_premium_rounded,
      ],
      bottom: DsHeroPillButton(
        label: 'New Request',
        icon: Icons.add_rounded,
        onPressed: () => _showNewRequestBottomSheet(context),
      ),
    );
  }
}

class _BottomSheetActionTile extends StatelessWidget {
  const _BottomSheetActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFEEF2FF),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1A56FF), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

class _ProfileSpotlightCard extends StatelessWidget {
  const _ProfileSpotlightCard({
    required this.name,
    required this.role,
    required this.employeeId,
    required this.onTap,
    required this.onBiometricTap,
  });

  final String name;
  final String role;
  final String employeeId;
  final VoidCallback onTap;
  final VoidCallback onBiometricTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(top: 60),
        child: Stack(
          clipBehavior: Clip.none,
          alignment: Alignment.topCenter,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.only(top: 76, bottom: 24, left: 24, right: 24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.04),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    name,
                    style: AppFonts.display(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$role · $employeeId',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: List.generate(5, (index) {
                          return Icon(
                            index == 4 ? Icons.star_border : Icons.star,
                            color: const Color(0xFF1A56FF),
                            size: 16,
                          );
                        }),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '4.8 Rating',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      GestureDetector(
                        onTap: () => context.push(
                          '${AppRoutes.chat}?recipientName=HG Concierge&recipientRole=Support Specialist',
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Soft grey background
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.chat_bubble_outline, color: Color(0xFF1A56FF), size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: () => CommunicationHelper.makePhoneCall(
                          context,
                          '+18005550199',
                          recipientName: 'HG Concierge Support',
                        ),
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Soft grey background
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.phone_outlined, color: Color(0xFF1A56FF), size: 20),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      GestureDetector(
                        onTap: onBiometricTap,
                        child: Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: const Color(0xFFF1F5F9), // Soft grey background
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: const Center(
                            child: Icon(Icons.fingerprint, color: Color(0xFF1A56FF), size: 20),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  const Divider(color: Color(0xFFF1F5F9)),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'TODAY\'S SHIFT',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '09:00 AM - 06:00 PM',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'CURRENT TASK',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Health\nMonitoring',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            Positioned(
              top: -60,
              child: Stack(
                alignment: Alignment.bottomCenter,
                clipBehavior: Clip.none,
                children: [
                  Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 16,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                  ),
                  Positioned(
                    bottom: -12,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFF1A56FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: const BoxDecoration(
                              color: Colors.white,
                              shape: BoxShape.circle,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            'ACTIVE NOW',
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AttendanceBentoCard extends StatelessWidget {
  const _AttendanceBentoCard({
    required this.percentage,
    required this.onTap,
  });

  final int percentage;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      'ATTENDANCE',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF64748B),
                        letterSpacing: 1.5,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.insert_chart_outlined, size: 14, color: Color(0xFF1A56FF)),
                ],
              ),
            const SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 72,
                    height: 72,
                    child: CircularProgressIndicator(
                      value: percentage / 100,
                      strokeWidth: 4,
                      backgroundColor: const Color(0xFFF1F5F9),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF1A56FF)),
                    ),
                  ),
                  Text(
                    '$percentage%',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Center(
              child: Text(
                '22/24 days',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  color: const Color(0xFF1A56FF),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _OngoingTrainingWidget extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(StaffRoutes.training),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56FF).withOpacity(0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Icon(Icons.school, color: Color(0xFF1A56FF), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'ONGOING TRAINING',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hygiene & Safety v2.4',
                    style: AppFonts.display(
                      fontSize: 15,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    height: 4,
                    width: 120,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(2),
                    ),
                    child: FractionallySizedBox(
                      alignment: Alignment.centerLeft,
                      widthFactor: 0.6,
                      child: Container(
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56FF),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.play_circle_outline, color: Color(0xFF1A56FF), size: 28),
          ],
        ),
      ),
    );
  }
}

class _QuickManagementGrid extends StatelessWidget {
  void _showReplacementDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        title: Text(
          'Deployment Replacement',
          style: AppFonts.display(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'To request a replacement, change your current shift, or modify your assignment, please contact Concierge Support.',
          style: GoogleFonts.plusJakartaSans(
            color: const Color(0xFF64748B),
            fontSize: 14,
            height: 1.5,
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: Text(
              'Cancel',
              style: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF64748B),
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              context.push(StaffRoutes.help);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56FF),
              elevation: 0,
              shape: const StadiumBorder(),
            ),
            child: Text(
              'Contact Support',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                'Quick Management',
                style: AppFonts.display(
                  fontSize: 18,
                  color: const Color(0xFF0F172A),
                  fontWeight: FontWeight.w600,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const Row(
              children: [
                _NavButton(icon: Icons.chevron_left),
                SizedBox(width: 8),
                _NavButton(icon: Icons.chevron_right),
              ],
            ),
          ],
        ),
        const SizedBox(height: 16),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _QuickActionCard(
                  icon: Icons.people_outline,
                  label: 'Assigned staff',
                  onTap: () => context.push(StaffRoutes.deployment),
                ),
                const SizedBox(width: 12),
                _QuickActionCard(
                  icon: Icons.assignment_outlined,
                  label: 'Attendance summary',
                  onTap: () => context.push(StaffRoutes.monthlyAttendance),
                ),
                const SizedBox(width: 12),
                _QuickActionCard(
                  icon: Icons.warning_amber_outlined,
                  label: 'Raise complaints',
                  onTap: () => context.push(StaffRoutes.help),
                ),
                const SizedBox(width: 12),
                _QuickActionCard(
                  icon: Icons.autorenew,
                  label: 'Request replacement',
                  onTap: () => _showReplacementDialog(context),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: const Color(0xFFE2E8F0)),
      ),
      child: Icon(icon, size: 16, color: const Color(0xFF64748B)),
    );
  }
}

class _QuickActionCard extends StatelessWidget {
  const _QuickActionCard({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 140,
        height: 120,
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1A56FF), size: 28),
            const SizedBox(height: 12),
            Text(
              label,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w500,
                color: const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CareShieldBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F5F9), // Soft-grey
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF1A56FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.shield_outlined, color: Colors.white, size: 28),
          ),
          const SizedBox(width: 20),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Premium Insurance Active',
                  style: AppFonts.display(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are fully covered by HomeGenny\'s Comprehensive Care Shield.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: const Color(0xFF64748B),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Text(
                      'View Policy Details',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF1A56FF),
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(width: 4),
                    const Icon(Icons.open_in_new, size: 14, color: Color(0xFF1A56FF)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _TaskTile extends StatelessWidget {
  const _TaskTile({required this.task});
  final StaffTask task;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20, color: task.done ? const Color(0xFFF0FDF4) : Colors.white),
      child: Row(
        children: [
          AnimatedContainer(
            duration: 250.ms,
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: task.done ? AppColors.success : Colors.white,
              shape: BoxShape.circle,
              border: Border.all(color: task.done ? AppColors.success : AppColors.lightBorder, width: 2),
            ),
            child: task.done ? const Icon(Icons.check_rounded, size: 17, color: Colors.white) : null,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              task.title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14.5,
                fontWeight: FontWeight.w700,
                color: task.done ? AppColors.lightTextSecondary : AppColors.lightTextPrimary,
                decoration: task.done ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
          if (task.done) const DsPill('Done', color: AppColors.success),
        ],
      ),
    );
  }
}

/// Today's tasks screen.
class StaffTodaysTasksScreen extends ConsumerWidget {
  const StaffTodaysTasksScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tasks = ref.watch(staffTasksProvider);

    return DsPage(
      title: 'Today\'s tasks',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffTasksProvider),
      body: dsAsyncBody(
        tasks,
        onRetry: () => ref.invalidate(staffTasksProvider),
        builder: (list) {
          final done = list.where((t) => t.done).length;
          return [
            DsGradientCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 80,
                    height: 80,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: list.isEmpty ? 1 : done / list.length),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: AppColors.sunYellow,
                            ),
                          ),
                          Text(
                            '$done/${list.length}',
                            style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: Colors.white),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      list.isEmpty || done == list.length ? 'All caught up for today!' : '${list.length - done} tasks left today',
                      style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const DsEmptyBlock(
                icon: Icons.task_alt_rounded,
                color: AppColors.success,
                title: 'No tasks',
                message: 'You are all caught up!',
              )
            else
              for (final t in list) _TaskTile(task: t),
          ];
        },
      ),
    );
  }
}

/// Profile completion screen.
class StaffProfileCompletionScreen extends ConsumerWidget {
  const StaffProfileCompletionScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profile = ref.watch(staffProfileProvider);
    final completionPct = ref.watch(staffDashboardProvider).valueOrNull?.completionPct ?? 0;
    final documents = ref.watch(staffDocumentsProvider).valueOrNull ?? const <StaffDocument>[];
    final pendingDocuments = documents.where((d) => d.status == DocumentApprovalStatus.pending).length;
    final rejectedDocuments = documents.where((d) => d.status == DocumentApprovalStatus.rejected).length;
    final agreement = ref.watch(staffAgreementProvider).valueOrNull;
    final videoCert = ref.watch(staffTrainingHomeProvider).valueOrNull?.videoCert;

    final steps = <_CompletionStep>[
      _CompletionStep(
        icon: Icons.person_rounded,
        title: 'Personal details',
        subtitle: 'Your basic profile',
        status: ('Done', AppColors.success),
        onTap: () => context.canPop() ? context.pop() : context.go(StaffRoutes.profile),
      ),
      _CompletionStep(
        icon: Icons.folder_rounded,
        title: 'Documents',
        subtitle: 'ID verification',
        status: rejectedDocuments > 0
            ? ('$rejectedDocuments to fix', AppColors.error)
            : pendingDocuments > 0
                ? ('$pendingDocuments pending', AppColors.warning)
                : documents.isEmpty
                    ? ('Not started', AppColors.lightTextSecondary)
                    : ('All clear', AppColors.success),
        onTap: () => context.push(StaffRoutes.documents),
      ),
      _CompletionStep(
        icon: Icons.school_rounded,
        title: 'Training',
        subtitle: 'Safety & procedures',
        status: ('Open', AppColors.primary),
        onTap: () => context.push(StaffRoutes.training),
      ),
      _CompletionStep(
        icon: Icons.videocam_rounded,
        title: 'Video certification',
        subtitle: 'Record your introduction',
        status: videoCert == null
            ? ('Open', AppColors.primary)
            : videoCert.approved >= videoCert.required_
                ? ('Done', AppColors.success)
                : ('${videoCert.approved}/${videoCert.required_}', AppColors.warning),
        progress: videoCert == null || videoCert.required_ == 0 ? null : videoCert.approved / videoCert.required_,
        onTap: () => context.push(StaffRoutes.videoCertification),
      ),
      _CompletionStep(
        icon: Icons.draw_rounded,
        title: 'Agreement',
        subtitle: 'Terms and conditions',
        status: switch (agreement?.status) {
          AgreementStatus.signed => ('Signed', AppColors.success),
          AgreementStatus.expired => ('Expired', AppColors.error),
          AgreementStatus.pending => ('Sign now', AppColors.warning),
          null => ('Pending', AppColors.lightTextSecondary),
        },
        onTap: () => context.push(StaffRoutes.agreement),
      ),
    ];

    return DsPage(
      title: 'Profile completion',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async {
        ref.invalidate(staffProfileProvider);
        ref.invalidate(staffDashboardProvider);
        ref.invalidate(staffDocumentsProvider);
        ref.invalidate(staffAgreementProvider);
      },
      actions: [
        DsPageAction(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          onPressed: () => context.push(StaffRoutes.settings),
        ),
      ],
      bottom: DsGradientButton(
        label: 'Continue setup',
        icon: Icons.arrow_forward_rounded,
        onPressed: () => context.push(StaffRoutes.documents),
      ),
      body: dsAsyncBody(
        profile,
        onRetry: () => ref.invalidate(staffProfileProvider),
        builder: (p) => [
          DsGradientCard(
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  height: 100,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: completionPct / 100),
                    duration: 1100.ms,
                    curve: Curves.easeOutCubic,
                    builder: (_, v, _) => Stack(
                      alignment: Alignment.center,
                      children: [
                        SizedBox.expand(
                          child: CircularProgressIndicator(
                            value: v,
                            strokeWidth: 9,
                            strokeCap: StrokeCap.round,
                            backgroundColor: Colors.white.withValues(alpha: 0.2),
                            color: AppColors.sunYellow,
                          ),
                        ),
                        Text(
                          '${(v * 100).round()}%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const DsGlassPill('OVERALL PROGRESS', icon: Icons.trending_up_rounded),
                      const SizedBox(height: 10),
                      Text(
                        completionPct >= 100 ? 'Profile complete!' : 'You\'re almost there',
                        style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Finish the steps below to unlock full access.',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.82),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const DsSection('Required steps'),
          for (var i = 0; i < steps.length; i++)
            _CompletionTile(step: steps[i])
                .animate(delay: (60 * i).ms)
                .fadeIn(duration: 300.ms)
                .slideX(begin: 0.05, end: 0),
        ],
      ),
    );
  }
}

class _CompletionStep {
  const _CompletionStep({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.status,
    required this.onTap,
    this.progress,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final (String, Color) status;
  final VoidCallback onTap;
  final double? progress;
}

class _CompletionTile extends StatelessWidget {
  const _CompletionTile({required this.step});
  final _CompletionStep step;

  @override
  Widget build(BuildContext context) {
    final (label, color) = step.status;
    final done = color == AppColors.success;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: step.onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    Stack(
                      clipBehavior: Clip.none,
                      children: [
                        DsIconTile(step.icon, size: 46),
                        if (done)
                          Positioned(
                            right: -4,
                            bottom: -4,
                            child: Container(
                              padding: const EdgeInsets.all(2),
                              decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                              child: const Icon(Icons.check_circle_rounded, size: 16, color: AppColors.success),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            step.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          Text(
                            step.subtitle,
                            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    DsPill(label, color: color),
                  ],
                ),
                if (step.progress != null) ...[
                  const SizedBox(height: 12),
                  ClipRRect(
                    borderRadius: BorderRadius.circular(4),
                    child: LinearProgressIndicator(
                      value: step.progress!.clamp(0, 1).toDouble(),
                      minHeight: 6,
                      backgroundColor: AppColors.lightSurfaceVariant,
                      color: color,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
