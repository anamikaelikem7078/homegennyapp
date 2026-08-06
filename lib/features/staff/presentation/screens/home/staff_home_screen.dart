import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/staff_scaffold.dart';
import '../../../../../common/presentation/viewmodels/biometric_viewmodel.dart';

/// Staff home dashboard tab.
class StaffHomeScreen extends ConsumerWidget {
  const StaffHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(staffDashboardProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8), // Sophisticated off-white
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        automaticallyImplyLeading: false,
        title: Text(
          'HOMEGENNY',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.2,
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 16.0),
            child: Row(
              children: [
                GestureDetector(
                  onTap: () => context.push(StaffRoutes.notifications),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      const Icon(Icons.notifications_none_rounded, color: Color(0xFF0F172A), size: 28),
                      Container(
                        width: 8,
                        height: 8,
                        margin: const EdgeInsets.only(top: 2, right: 2),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56FF),
                          shape: BoxShape.circle,
                          border: Border.all(color: const Color(0xFFFBF9F8), width: 1.5),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                const CircleAvatar(
                  radius: 16,
                  backgroundImage: NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=200'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: dashboard,
        onRetry: () => ref.invalidate(staffDashboardProvider),
        loadingMessage: context.l10n.loading,
        builder: (data) => Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 600),
            child: DsRefreshIndicator(
              onRefresh: () async => ref.invalidate(staffDashboardProvider),
              child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _WelcomeHeader(name: data.profile.name),
              const SizedBox(height: 24),
              _ProfileSpotlightCard(
                name: data.profile.name,
                role: data.profile.role,
                employeeId: data.profile.employeeId,
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
              Row(
                children: [
                  Expanded(
                    child: _AttendanceBentoCard(
                      percentage: 92,
                      onTap: () => context.push(StaffRoutes.attendance),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: _PaymentsBentoCard(
                      amount: '₹18,500',
                      onTap: () => context.push(StaffRoutes.salary),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              _OngoingTrainingWidget(),
              const SizedBox(height: 24),
              _QuickManagementGrid(),
              const SizedBox(height: 24),
              _CareShieldBanner(),
              const SizedBox(height: 100),
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
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: Colors.white,
      builder: (context) {
        return SafeArea(
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
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Select the type of request you would like to log with your Relationship Manager.',
                  style: GoogleFonts.inter(
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
                          style: GoogleFonts.inter(),
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
                          style: GoogleFonts.inter(),
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
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'OVERVIEW',
          style: GoogleFonts.inter(
            color: const Color(0xFF1A56FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Welcome back,\nPriya Sharma',
          style: GoogleFonts.libreCaslonText(
            fontSize: 32,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Your personal care ecosystem at a glance.',
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        const SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => _showNewRequestBottomSheet(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.add, size: 20),
                const SizedBox(width: 8),
                Text(
                  'New Request',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
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
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
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
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '$role · $employeeId',
                    style: GoogleFonts.inter(
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
                        style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '09:00 AM - 06:00 PM',
                              style: GoogleFonts.inter(
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
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                color: const Color(0xFF94A3B8),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Health\nMonitoring',
                              style: GoogleFonts.inter(
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
                            style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
                    style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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

class _PaymentsBentoCard extends StatelessWidget {
  const _PaymentsBentoCard({
    required this.amount,
    required this.onTap,
  });

  final String amount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: const Color(0xFF1A56FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A56FF).withOpacity(0.2),
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
                    'PAYMENTS',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: Colors.white.withOpacity(0.8),
                      letterSpacing: 1.5,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(Icons.payments_outlined, size: 14, color: Colors.white),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              amount,
              style: GoogleFonts.libreCaslonText(
                fontSize: 20,
                color: Colors.white,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                const Icon(Icons.timer_outlined, color: Colors.white, size: 12),
                const SizedBox(width: 4),
                Text(
                  '5 days left',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: Colors.white.withOpacity(0.9),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: const Color(0xFF123BB8), // Darker blue for contrast
                borderRadius: BorderRadius.circular(4), // Soft-square 4px
              ),
              child: Text(
                'Pay Now',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
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
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Hygiene & Safety v2.4',
                    style: GoogleFonts.libreCaslonText(
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
          style: GoogleFonts.libreCaslonText(
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        content: Text(
          'To request a replacement, change your current shift, or modify your assignment, please contact Concierge Support.',
          style: GoogleFonts.inter(
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
              style: GoogleFonts.inter(
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
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Contact Support',
              style: GoogleFonts.inter(
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
                style: GoogleFonts.libreCaslonText(
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
              style: GoogleFonts.inter(
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
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'You are fully covered by HomeGenny\'s Comprehensive Care Shield.',
                  style: GoogleFonts.inter(
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
                      style: GoogleFonts.inter(
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
      padding: EdgeInsets.all(AppSpacing.md),
      decoration: AppDecorations.softCard(context),
      child: Row(
        children: [
          Icon(
            task.isCompleted
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked,
            color: task.isCompleted ? AppColors.success : AppColors.primary,
          ),
          SizedBox(width: AppSpacing.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title, style: Theme.of(context).textTheme.titleSmall),
                Text(task.dueTime, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ),
          DsStatusChip(
            label: task.priority.name,
            type: task.priority == TaskPriority.high
                ? DsStatusType.error
                : DsStatusType.warning,
          ),
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

    return StaffPageScaffold(
      title: "Today's Tasks",
      body: tasks.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Error',
          onRetry: () => ref.invalidate(staffTasksProvider),
        ),
        data: (list) => list.isEmpty
            ? const DsEmptyState(title: 'No tasks', message: 'You are all caught up!')
            : ListView.builder(
                itemCount: list.length,
                itemBuilder: (_, i) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _TaskTile(task: list[i]),
                ),
              ),
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

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(StaffRoutes.home);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'Profile Completion',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF0F172A),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined, color: Color(0xFF64748B)),
            onPressed: () => context.push(StaffRoutes.settings),
          ),
        ],
      ),
      body: profile.when(
        loading: () => const DsLoadingWidget(),
        error: (e, _) => DsErrorState(
          title: 'Error',
          onRetry: () => ref.invalidate(staffProfileProvider),
        ),
        data: (p) => Column(
          children: [
            Expanded(
              child: ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  // Overall Progress Card
                  Container(
                    padding: const EdgeInsets.all(24),
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
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'STATUS',
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF94A3B8),
                                  letterSpacing: 1.5,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Overall\nProgress',
                                style: GoogleFonts.libreCaslonText(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w600,
                                  color: const Color(0xFF0F172A),
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 12),
                              Text(
                                'You\'re almost there!\nComplete the remaining\ntasks to unlock full\naccess.',
                                style: GoogleFonts.inter(
                                  fontSize: 13,
                                  color: const Color(0xFF64748B),
                                  height: 1.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                        // The custom 72% square progress indicator
                        Container(
                          width: 100,
                          height: 120,
                          decoration: BoxDecoration(
                            color: const Color(0xFF1A56FF),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: Stack(
                            alignment: Alignment.center,
                            children: [
                              // The light blue background part for uncompleted
                              Positioned(
                                top: 0,
                                left: 0,
                                bottom: 0,
                                child: Container(
                                  width: 40,
                                  decoration: const BoxDecoration(
                                    color: Color(0xFFE0E7FF), // Lighter blue for uncompleted part
                                    borderRadius: BorderRadius.only(
                                      topLeft: Radius.circular(16),
                                      bottomLeft: Radius.circular(16),
                                    ),
                                  ),
                                ),
                              ),
                              // White inner container
                              Container(
                                width: 76,
                                height: 96,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Center(
                                  child: Text(
                                    '${p.completionPercent}%',
                                    style: GoogleFonts.libreCaslonText(
                                      fontSize: 24,
                                      fontWeight: FontWeight.w600,
                                      color: const Color(0xFF1A56FF),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'REQUIRED STEPS',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF94A3B8),
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 16),
                  
                  // Step Items
                  _RequiredStepTile(
                    icon: Icons.person_outline,
                    iconBgColor: const Color(0xFFF1F5F9),
                    title: 'Personal Details',
                    subtitle: 'Completed on Oct 12',
                    onTap: () => context.push(StaffRoutes.profile),
                    statusWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFDCFCE7),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.check, color: Color(0xFF16A34A), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            'Done',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF16A34A),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  
                  _RequiredStepTile(
                    icon: Icons.description_outlined,
                    iconBgColor: const Color(0xFFEFF6FF),
                    iconColor: const Color(0xFF1A56FF),
                    title: 'Documents',
                    subtitle: 'ID verification required',
                    onTap: () => context.push(StaffRoutes.documents),
                    statusWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE0E7FF),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        '1 pending',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF3730A3), // darker blue text
                        ),
                      ),
                    ),
                  ),

                  _RequiredStepTile(
                    icon: Icons.school_outlined,
                    iconBgColor: const Color(0xFFF1F5F9),
                    title: 'Training',
                    subtitle: 'Safety & Procedures module',
                    onTap: () => context.push(StaffRoutes.training),
                    statusWidget: Text(
                      '60%',
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A56FF),
                      ),
                    ),
                    bottomWidget: Padding(
                      padding: const EdgeInsets.only(top: 12),
                      child: Stack(
                        children: [
                          Container(
                            height: 6,
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(3),
                            ),
                          ),
                          FractionallySizedBox(
                            alignment: Alignment.centerLeft,
                            widthFactor: 0.6,
                            child: Container(
                              height: 6,
                              decoration: BoxDecoration(
                                color: const Color(0xFF1A56FF),
                                borderRadius: BorderRadius.circular(3),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _RequiredStepTile(
                    icon: Icons.videocam_outlined,
                    iconBgColor: const Color(0xFFFEF2F2),
                    iconColor: const Color(0xFFDC2626),
                    title: 'Video Certification',
                    subtitle: 'Record self-introduction',
                    onTap: () => context.push(StaffRoutes.videoCertification),
                    statusWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFFEE2E2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(Icons.warning_amber_rounded, color: Color(0xFF991B1B), size: 12),
                          const SizedBox(width: 4),
                          Text(
                            '2 pending',
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF991B1B),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  _RequiredStepTile(
                    icon: Icons.draw_outlined,
                    iconBgColor: const Color(0xFFF1F5F9),
                    title: 'Agreement',
                    subtitle: 'Terms and Conditions',
                    onTap: () => context.push(StaffRoutes.agreement),
                    statusWidget: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            // Bottom Button
            Padding(
              padding: const EdgeInsets.all(24),
              child: SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push(StaffRoutes.documents),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Text(
                    'CONTINUE SETUP',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1,
                    ),
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

class _RequiredStepTile extends StatelessWidget {
  final IconData icon;
  final Color iconBgColor;
  final Color? iconColor;
  final String title;
  final String subtitle;
  final Widget statusWidget;
  final Widget? bottomWidget;
  final VoidCallback? onTap;

  const _RequiredStepTile({
    required this.icon,
    required this.iconBgColor,
    this.iconColor,
    required this.title,
    required this.subtitle,
    required this.statusWidget,
    this.bottomWidget,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: iconBgColor,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: iconColor ?? const Color(0xFF475569), size: 24),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                ),
                statusWidget,
              ],
            ),
            if (bottomWidget != null) bottomWidget!,
          ],
        ),
      ),
    );
  }
}
