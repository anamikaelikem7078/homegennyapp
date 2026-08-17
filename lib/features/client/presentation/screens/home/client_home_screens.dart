import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../core/presentation/async_value_widget.dart';
import '../../../../../core/extensions/context_extensions.dart';
import '../../../domain/models/client_models.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

/// Client home / dashboard tab.
class ClientHomeScreen extends ConsumerWidget {
  const ClientHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(clientDashboardProvider);
    final assignedStaff = ref.watch(clientAssignedStaffProvider);
    final history = ref.watch(clientAttendanceHistoryProvider);

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
                  onTap: () => context.push(ClientRoutes.notifications),
                  child: Stack(
                    alignment: Alignment.topRight,
                    children: [
                      Icon(Icons.notifications_none_rounded, color: const Color(0xFF0F172A), size: 28),
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
                SizedBox(width: 16),
                CircleAvatar(
                  radius: 16,
                  backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1438761681033-6461ffad8d80?auto=format&fit=crop&q=80&w=200'),
                ),
              ],
            ),
          ),
        ],
      ),
      body: AsyncValueWidget(
        value: dashboard,
        onRetry: () => ref.invalidate(clientDashboardProvider),
        loadingMessage: context.l10n.loading,
        builder: (data) => DsRefreshIndicator(
          onRefresh: () async => ref.invalidate(clientDashboardProvider),
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            children: [
              _WelcomeHeader(name: data.clientName),
              SizedBox(height: 24),
              assignedStaff.when(
                loading: () => const DsLoadingWidget(),
                error: (_, _) => const SizedBox.shrink(),
                data: (list) {
                  if (list.isEmpty) return const SizedBox.shrink();
                  final staff = list.first;
                  return _StaffSpotlightCard(
                    name: staff.fullName ?? 'Staff',
                    series: staff.series ?? '',
                    staffCode: staff.staffCode ?? '',
                    status: staff.status,
                    deploymentDate: staff.deploymentDate,
                    onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
                  );
                },
              ),
              SizedBox(height: 16),
              // IntrinsicHeight, not a bare stretch Row: this Row is a direct
              // ListView child, so it receives unbounded height. Plain
              // CrossAxisAlignment.stretch on an unbounded Row asks every
              // child for a *tight infinite* height ("BoxConstraints forces
              // an infinite height"). IntrinsicHeight measures the tallest
              // child first, giving the Row (and therefore `stretch`) a real
              // finite height to work with.
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: history.when(
                        loading: () => const DsLoadingWidget(),
                        error: (_, _) => const SizedBox.shrink(),
                        data: (list) {
                          final present = list.where((r) => r.status == 'PRESENT').length;
                          final total = list.length;
                          final percent = total == 0 ? 0 : (present / total * 100).round();
                          return _AttendanceBentoCard(
                            percentage: percent.toString(),
                            presentDays: present,
                            totalDays: total,
                            onTap: () => context.push(ClientRoutes.attendanceSummary),
                          );
                        },
                      ),
                    ),
                    SizedBox(width: 16),
                    Expanded(
                      child: _PaymentsBentoCard(
                        amount: CurrencyFormatter.inr(data.totalUnpaidAmount),
                        pendingCount: data.pendingInvoicesCount,
                        onTap: () => context.push(ClientRoutes.pendingPayment),
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),
              _QuickManagementGrid(),
              SizedBox(height: 24),
              _CareShieldBanner(),
              SizedBox(height: 100), // padding for bottom nav
            ],
          ),
        ),
      ),
    );
  }
}

class _WelcomeHeader extends StatelessWidget {
  const _WelcomeHeader({required this.name});
  final String name;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          context.l10n.overview,
          style: GoogleFonts.inter(
            color: const Color(0xFF1A56FF),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        SizedBox(height: 8),
        Text(
          context.l10n.welcomeBack(name),
          style: GoogleFonts.libreCaslonText(
            fontSize: 32,
            color: const Color(0xFF0F172A),
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        SizedBox(height: 8),
        Text(
          context.l10n.personalCareEcosystem,
          style: GoogleFonts.inter(
            color: const Color(0xFF64748B),
            fontSize: 13,
            fontWeight: FontWeight.w400,
          ),
        ),
        SizedBox(height: 20),
        SizedBox(
          width: double.infinity,
          height: 48,
          child: ElevatedButton(
            onPressed: () => context.push(ClientRoutes.replacementRequest),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF1A56FF),
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(4), // Soft-square 4px
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.add, size: 20),
                SizedBox(width: 8),
                Text(
                  context.l10n.newRequest,
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

class _StaffSpotlightCard extends StatelessWidget {
  const _StaffSpotlightCard({
    required this.name,
    required this.series,
    required this.staffCode,
    required this.status,
    required this.deploymentDate,
    required this.onTap,
  });

  final String name;
  final String series;
  final String staffCode;
  final String status;
  final String deploymentDate;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          children: [
            Stack(
              alignment: Alignment.bottomCenter,
              clipBehavior: Clip.none,
              children: [
                Container(
                  height: 124,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                ),
                Positioned(
                  top: -16,
                  child: Container(
                    width: 140,
                    height: 140,
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F4FF),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.1),
                          blurRadius: 12,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        name.isNotEmpty ? name[0].toUpperCase() : '?',
                        style: GoogleFonts.libreCaslonText(
                          color: const Color(0xFF1A56FF),
                          fontSize: 48,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ),
                Positioned(
                  bottom: -12,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
                    decoration: BoxDecoration(
                      color: status == 'ACTIVE_DEPLOYED' ? const Color(0xFF1A56FF) : const Color(0xFF94A3B8),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 6,
                          height: 6,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6),
                        Text(
                          status == 'ACTIVE_DEPLOYED' ? 'DEPLOYED' : 'ON TRIAL',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                children: [
                  Text(
                    name,
                    style: GoogleFonts.libreCaslonText(
                      color: const Color(0xFF0F172A),
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    [series, staffCode].where((s) => s.isNotEmpty).join(' · '),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF64748B),
                      fontSize: 12,
                      fontWeight: FontWeight.w400,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _MinimalistCommunicationBtn(
                        icon: Icons.chat_bubble_outline_rounded,
                        onTap: () => context.push(
                          '${AppRoutes.chat}?recipientName=$name&recipientRole=${Uri.encodeComponent(series)}',
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Divider(color: Colors.grey.shade200),
                  SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'DEPLOYED SINCE',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            _formatDate(deploymentDate),
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'STATUS',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF94A3B8),
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              letterSpacing: 1.0,
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            status == 'ACTIVE_DEPLOYED' ? 'Active' : 'On Trial',
                            style: GoogleFonts.inter(
                              color: const Color(0xFF0F172A),
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  SizedBox(height: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

String _formatDate(String isoDate) {
  final parsed = DateTime.tryParse(isoDate);
  if (parsed == null) return isoDate;
  const months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];
  return '${months[parsed.month - 1]} ${parsed.day}, ${parsed.year}';
}

class _MinimalistCommunicationBtn extends StatelessWidget {
  const _MinimalistCommunicationBtn({required this.icon, this.onTap});
  final IconData icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: const Color(0xFFF8FAFC),
          shape: BoxShape.circle,
          border: Border.all(color: Colors.grey.shade200, width: 1),
        ),
        child: Icon(icon, color: const Color(0xFF1A56FF), size: 20),
      ),
    );
  }
}

class _AttendanceBentoCard extends StatelessWidget {
  const _AttendanceBentoCard({
    required this.percentage,
    required this.presentDays,
    required this.totalDays,
    required this.onTap,
  });
  final String percentage;
  final int presentDays;
  final int totalDays;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 24,
              offset: const Offset(0, 12),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.attendanceCap,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(Icons.insert_chart_outlined, color: const Color(0xFF1A56FF), size: 16),
              ],
            ),
            SizedBox(height: 20),
            Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 64,
                    height: 64,
                    child: CircularProgressIndicator(
                      value: (double.tryParse(percentage) ?? 0) / 100,
                      backgroundColor: Colors.grey.shade100,
                      color: const Color(0xFF1A56FF),
                      strokeWidth: 4,
                    ),
                  ),
                  Text(
                    context.l10n.percentageValue(percentage),
                    style: GoogleFonts.inter(
                      color: const Color(0xFF0F172A),
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 16),
            Center(
              child: Text(
                context.l10n.daysPresent(presentDays.toString(), totalDays.toString()),
                style: GoogleFonts.libreCaslonText(
                  color: const Color(0xFF1A56FF),
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
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
    required this.pendingCount,
    required this.onTap,
  });
  final String amount;
  final int pendingCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: const Color(0xFF1A56FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A56FF).withValues(alpha: 0.3),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  context.l10n.paymentsCap,
                  style: GoogleFonts.inter(
                    color: Colors.white.withValues(alpha: 0.8),
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
                Icon(Icons.account_balance_wallet_outlined, color: Colors.white, size: 16),
              ],
            ),
            SizedBox(height: 20),
            Text(
              amount,
              style: GoogleFonts.libreCaslonText(
                color: Colors.white,
                fontSize: 22,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.timer_outlined, color: Colors.white, size: 12),
                SizedBox(width: 4),
                Text(
                  pendingCount == 1 ? '1 invoice pending' : '$pendingCount invoices pending',
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontSize: 11,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
            SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 36,
              child: ElevatedButton(
                onPressed: onTap,
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1142D3),
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                child: Text(
                  context.l10n.payNow,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
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

class _QuickManagementGrid extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              context.l10n.quickManagement,
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF0F172A),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
            Row(
              children: [
                _NavArrow(icon: Icons.chevron_left),
                SizedBox(width: 8),
                _NavArrow(icon: Icons.chevron_right),
              ],
            ),
          ],
        ),
        SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _QuickActionTile(icon: Icons.people_outline_rounded, label: context.l10n.myStaff, onTap: () => context.go(ClientRoutes.staff)),
            _QuickActionTile(icon: Icons.receipt_long_outlined, label: context.l10n.logs, onTap: () => context.push(ClientRoutes.attendanceHistory)),
            _QuickActionTile(icon: Icons.report_problem_outlined, label: context.l10n.complain, onTap: () => context.push(ClientRoutes.complaintRaise)),
          ],
        ),
      ],
    );
  }
}

class _NavArrow extends StatelessWidget {
  const _NavArrow({required this.icon});
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: Colors.grey.shade200, width: 1),
      ),
      child: Icon(icon, color: const Color(0xFF0F172A), size: 16),
    );
  }
}

class _QuickActionTile extends StatelessWidget {
  const _QuickActionTile({required this.icon, required this.label, required this.onTap});
  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 100,
        height: 100,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16), // White square
          border: Border.all(color: Colors.grey.shade100, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 10,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: const Color(0xFF1A56FF), size: 28),
            SizedBox(height: 12),
            Text(
              label,
              style: GoogleFonts.inter(
                color: const Color(0xFF0F172A),
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
        borderRadius: BorderRadius.circular(16),
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
            child: Icon(Icons.shield_outlined, color: Colors.white, size: 24),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  context.l10n.premiumInsuranceActive,
                  style: GoogleFonts.libreCaslonText(
                    color: const Color(0xFF0F172A),
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  context.l10n.insuranceCoverDesc,
                  style: GoogleFonts.inter(
                    color: const Color(0xFF64748B),
                    fontSize: 12,
                    height: 1.5,
                  ),
                ),
                SizedBox(height: 12),
                Row(
                  children: [
                    Text(
                      context.l10n.viewPolicyDetails,
                      style: GoogleFonts.inter(
                        color: const Color(0xFF1A56FF),
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    SizedBox(width: 4),
                    Icon(Icons.open_in_new, color: const Color(0xFF1A56FF), size: 14),
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


/// Attendance summary from dashboard.
class ClientAttendanceSummaryScreen extends ConsumerWidget {
  const ClientAttendanceSummaryScreen({super.key});

  Widget _buildBottomNavigationBar(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final inactiveColor = const Color(0xFF94A3B8);
    
    Widget buildItem({required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: isActive
              ? BoxDecoration(
                  color: const Color(0xFFEFF6FF),
                  borderRadius: BorderRadius.circular(20),
                )
              : null,
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: isActive ? primaryColor : inactiveColor, size: 20),
              if (isActive) ...[
                const SizedBox(width: 8),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: primaryColor,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
              ],
            ],
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            buildItem(
              icon: Icons.home_outlined,
              label: context.l10n.homeCap,
              isActive: false,
              onTap: () => context.go(ClientRoutes.dashboard),
            ),
            buildItem(
              icon: Icons.people_outline,
              label: context.l10n.staffCap,
              isActive: true,
              onTap: () => context.go(ClientRoutes.staff),
            ),
            buildItem(
              icon: Icons.payments_outlined,
              label: context.l10n.paymentsCap,
              isActive: false,
              onTap: () => context.go(ClientRoutes.payments),
            ),
            buildItem(
              icon: Icons.person_outline_rounded,
              label: context.l10n.profileCap,
              isActive: false,
              onTap: () => context.go(ClientRoutes.profile),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientAttendanceHistoryProvider);
    final today = ref.watch(clientTodayAttendanceProvider);

    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    final offWhite = const Color(0xFFFBF9F8);

    final tactileCardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 24,
        offset: const Offset(0, 12),
      ),
      BoxShadow(
        color: primaryColor.withValues(alpha: 0.02),
        blurRadius: 16,
        offset: const Offset(0, 4),
      ),
    ];

    Widget buildNavItem({
      required IconData icon,
      required String title,
      required VoidCallback onTap,
    }) {
      return Container(
        margin: const EdgeInsets.only(bottom: 16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: tactileCardShadows,
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: textDark, size: 20),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Text(
                      title,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                  ),
                  Icon(Icons.info_outline, color: textGrey.withValues(alpha: 0.7), size: 20),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Scaffold(
      backgroundColor: offWhite,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
      ),
      bottomNavigationBar: _buildBottomNavigationBar(context),
      body: history.when(
        loading: () => const Center(child: DsLoadingWidget()),
        error: (_, __) => DsErrorState(title: context.l10n.error),
        data: (records) {
          final present = records.where((r) => r.status == 'PRESENT').length;
          final total = records.length;
          final percent = total == 0 ? 0.0 : present / total * 100;
          final summary = ClientAttendanceSummary(
            presentDays: present,
            totalDays: total,
            attendancePercent: percent,
          );
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
            children: [
              // Headline
              Text(
                context.l10n.attendanceSummary,
                style: GoogleFonts.libreCaslonText(
                  fontSize: 36,
                  fontWeight: FontWeight.w700,
                  color: primaryColor,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 24),

              // Metric Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                  boxShadow: tactileCardShadows,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          context.l10n.thisMonth,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: textGrey,
                            letterSpacing: 1.5,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: const Color(0xFFEFF6FF),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(Icons.calendar_month_outlined, color: primaryColor, size: 20),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      context.l10n.percentageValue(summary.attendancePercent.round().toString()),
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 48,
                        fontWeight: FontWeight.w700,
                        color: primaryColor,
                        height: 1.0,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      context.l10n.daysPresentDesc(summary.presentDays.toString(), summary.totalDays.toString()),
                      style: GoogleFonts.inter(
                        fontSize: 14,
                        color: const Color(0xFF475569),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Status Card
              today.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (_, __) => const SizedBox.shrink(),
                data: (t) => Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: tactileCardShadows,
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: const BoxDecoration(
                          color: Color(0xFFEFF6FF),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(Icons.check_circle_outline, color: primaryColor, size: 22),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              context.l10n.today,
                              style: GoogleFonts.inter(
                                fontSize: 15,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              t.checkInTime != null ? context.l10n.checkInTime(t.checkInTime!) : context.l10n.noRecordsYet,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: textGrey,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFDCFCE7),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.l10n.presentCap,
                          style: GoogleFonts.inter(
                            color: const Color(0xFF16A34A),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Navigation List
              buildNavItem(
                icon: Icons.today_outlined,
                title: context.l10n.todaysAttendance,
                onTap: () => context.push(ClientRoutes.attendanceToday),
              ),
              buildNavItem(
                icon: Icons.history_rounded,
                title: context.l10n.attendanceHistory,
                onTap: () => context.push(ClientRoutes.attendanceHistory),
              ),
              buildNavItem(
                icon: Icons.flag_outlined,
                title: context.l10n.raiseIssue,
                onTap: () => context.push(ClientRoutes.attendanceRaiseIssue),
              ),
              const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

/// Pending payment from dashboard.
class ClientPendingPaymentScreen extends ConsumerWidget {
  const ClientPendingPaymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(clientInvoicesProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(ClientRoutes.dashboard);
            }
          },
        ),
        centerTitle: true,
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.help_outline, color: Color(0xFF1A56FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: invoices.when(
        loading: () => Center(child: CircularProgressIndicator(color: Color(0xFF1A56FF))),
        error: (_, __) => Center(child: Text(context.l10n.error)),
        data: (list) {
          if (list.isEmpty) {
            return const DsEmptyState(
              title: 'No invoices yet',
              message:
                  'Invoices appear after your Relationship Manager approves shifts and Finance runs payroll.',
              icon: Icons.receipt_long_outlined,
            );
          }
          final inv = list.first;
          return SafeArea(
          child: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  child: Column(
                    children: [
                      Text(
                        context.l10n.paymentRequired,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF1A56FF),
                          letterSpacing: 1.5,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        CurrencyFormatter.inr(inv.totalAmount),
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 48,
                          color: context.colors.onSurface,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        context.l10n.dueBy(inv.dueDate),
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          color: context.colors.onSurfaceVariant,
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // Service Placeholder Banner
                      Container(
                        width: double.infinity,
                        height: 180,
                        decoration: BoxDecoration(
                          color: context.theme.dividerColor.withOpacity(0.5),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        alignment: Alignment.center,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                          decoration: BoxDecoration(
                            color: context.theme.cardColor,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            context.l10n.serviceSetup,
                            style: GoogleFonts.inter(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: context.colors.onSurface,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 32),
                      
                      // View Invoice Card
                      _buildActionCard(
                        context: context,
                        icon: Icons.description_outlined,
                        title: context.l10n.viewInvoice,
                        subtitle: context.l10n.invoicePdfDesc(inv.id),
                        onTap: () => context.push(ClientRoutes.invoice),
                      ),
                      SizedBox(height: 16),
                      
                      // Payment Status Card
                      _buildActionCard(
                        context: context,
                        icon: Icons.bar_chart_outlined,
                        title: context.l10n.paymentStatus,
                        subtitle: context.l10n.pendingAuthorization,
                        onTap: () => context.push(ClientRoutes.paymentStatus),
                      ),
                      
                      SizedBox(height: 32),
                      
                      // Bottom Image Placeholder
                      Container(
                        width: double.infinity,
                        height: 160,
                        decoration: BoxDecoration(
                          color: context.theme.dividerColor,
                          borderRadius: BorderRadius.circular(12),
                          image: const DecorationImage(
                            image: NetworkImage('https://images.unsplash.com/photo-1600210492486-724fe5c67fb0?auto=format&fit=crop&w=800&q=80'),
                            fit: BoxFit.cover,
                          ),
                        ),
                        alignment: Alignment.topRight,
                        padding: const EdgeInsets.all(12),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          color: context.colors.onSurface,
                          child: Text(
                            context.l10n.confirmBooking,
                            style: GoogleFonts.inter(
                              color: context.theme.cardColor,
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 1.0,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
              
              // Bottom Fixed Button
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                child: SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: ElevatedButton(
                    onPressed: () => context.push(ClientRoutes.paymentGateway),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          context.l10n.payNow,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(width: 8),
                        Icon(Icons.arrow_forward, size: 18),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          );
        },
      ),
    );
  }

  Widget _buildActionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: context.theme.dividerColor),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: context.colors.onSurface, size: 20),
            ),
            SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurface,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Icon(Icons.person, color: context.colors.onSurfaceVariant, size: 24),
          ],
        ),
      ),
    );
  }
}

/// Assigned staff overview from dashboard.
class ClientAssignedStaffScreen extends ConsumerWidget {
  const ClientAssignedStaffScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final assignedStaff = ref.watch(clientAssignedStaffProvider);

    return ClientPageScaffold(
      title: context.l10n.assignedStaff,
      body: assignedStaff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => DsErrorState(title: context.l10n.error),
        data: (list) {
          if (list.isEmpty) {
            return const DsEmptyState(
              title: 'No staff assigned yet',
              message: 'Your assigned staff will appear here once deployed.',
              icon: Icons.people_outline,
            );
          }
          final staff = list.first;
          return ListView(
            children: [
              ClientStaffHeroCard(
                name: staff.fullName ?? 'Staff',
                series: staff.series ?? '',
                staffCode: staff.staffCode ?? '',
                isOnDuty: staff.status == 'ACTIVE_DEPLOYED',
                onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
              ),
              SizedBox(height: AppSpacing.lg),
              ClientMenuTile(
                icon: Icons.badge_outlined,
                title: context.l10n.staffProfile,
                onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
              ),
              ClientMenuTile(
                icon: Icons.work_history_outlined,
                title: context.l10n.experience,
                onTap: () => context.push(ClientRoutes.staffExperience(staff.staffId)),
              ),
              ClientMenuTile(
                icon: Icons.psychology_outlined,
                title: context.l10n.skills,
                onTap: () => context.push(ClientRoutes.staffSkills(staff.staffId)),
              ),
              ClientMenuTile(
                icon: Icons.schedule_outlined,
                title: context.l10n.attendance,
                onTap: () => context.push(ClientRoutes.staffAttendance(staff.staffId)),
              ),
              ClientMenuTile(
                icon: Icons.trending_up_rounded,
                title: context.l10n.performance,
                onTap: () => context.push(ClientRoutes.staffPerformance(staff.staffId)),
              ),
            ],
          );
        },
      ),
    );
  }
}
