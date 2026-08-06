import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Redesigned premium Attendance History Screen matching visual identity.
class StaffAttendanceHistoryScreen extends ConsumerWidget {
  const StaffAttendanceHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(staffAttendanceHistoryProvider);
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
    final successColor = const Color(0xFF10B981);
    final errorColor = const Color(0xFFEF4444);
    final warningColor = const Color(0xFFF59E0B);
    final leaveColor = const Color(0xFF6366F1);

    final tactileCardShadows = [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.04),
        blurRadius: 16,
        spreadRadius: 0,
        offset: const Offset(0, 8),
      ),
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.02),
        blurRadius: 4,
        spreadRadius: 0,
        offset: const Offset(0, 2),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF), size: 20),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Attendance History',
          style: GoogleFonts.libreCaslonText(
            color: primaryColor,
            fontSize: 26,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: Color(0xFF0F172A), size: 20),
            onPressed: () => context.push(StaffRoutes.monthlyAttendance),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: SafeArea(
        child: history.when(
          loading: () => const Center(child: DsLoadingWidget(message: 'Loading history...')),
          error: (e, _) => DsErrorState(
            title: 'Failed to load history',
            message: e.toString(),
            onRetry: () => ref.invalidate(staffAttendanceHistoryProvider),
          ),
          data: (records) {
            // Dynamically calculate PRESENT and LATE totals
            final presentCount = records.where((r) => r.status == AttendanceDayStatus.present).length;
            final lateCount = records.where((r) => r.status == AttendanceDayStatus.late).length;

            return Column(
              children: [
                Expanded(
                  child: DsRefreshIndicator(
                    onRefresh: () async => ref.invalidate(staffAttendanceHistoryProvider),
                    child: ListView(
                      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      children: [
                        // Summary Cards (Two side-by-side metric cards)
                        Row(
                          children: [
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: tactileCardShadows,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'PRESENT',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$presentCount',
                                      style: GoogleFonts.libreCaslonText(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Expanded(
                              child: Container(
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: tactileCardShadows,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'LATE',
                                      style: GoogleFonts.inter(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w700,
                                        color: textGrey,
                                        letterSpacing: 0.5,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      '$lateCount',
                                      style: GoogleFonts.libreCaslonText(
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                        color: primaryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 24),

                        // Daily Log List (Stack of tactile cards)
                        if (records.isEmpty)
                          const DsEmptyState(
                            title: 'No attendance records',
                            message: 'Your attendance history will appear here.',
                            icon: Icons.history_rounded,
                          )
                        else
                          ListView.separated(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: records.length,
                            separatorBuilder: (_, index) => const SizedBox(height: 16),
                            itemBuilder: (_, index) {
                              final record = records[index];
                              final statusType = record.status;
                              
                              String badgeLabel = 'PRESENT';
                              Color badgeColor = successColor;
                              switch (statusType) {
                                case AttendanceDayStatus.present:
                                  badgeLabel = 'PRESENT';
                                  badgeColor = successColor;
                                  break;
                                case AttendanceDayStatus.late:
                                  badgeLabel = 'LATE';
                                  badgeColor = warningColor;
                                  break;
                                case AttendanceDayStatus.absent:
                                  badgeLabel = 'ABSENT';
                                  badgeColor = errorColor;
                                  break;
                                case AttendanceDayStatus.leave:
                                  badgeLabel = 'LEAVE';
                                  badgeColor = leaveColor;
                                  break;
                              }

                              return Container(
                                padding: const EdgeInsets.all(20),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(16),
                                  boxShadow: tactileCardShadows,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          record.date, // e.g. "Today, 25 Jul 2024" or similar
                                          style: GoogleFonts.inter(
                                            fontSize: 14,
                                            fontWeight: FontWeight.w600,
                                            color: textDark,
                                          ),
                                        ),
                                        // Status badge
                                        Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                          decoration: BoxDecoration(
                                            color: badgeColor.withValues(alpha: 0.12),
                                            borderRadius: BorderRadius.circular(12),
                                          ),
                                          child: Text(
                                            badgeLabel,
                                            style: GoogleFonts.inter(
                                              fontSize: 10,
                                              fontWeight: FontWeight.w700,
                                              color: badgeColor,
                                              letterSpacing: 0.5,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(
                                      color: Color(0xFFF1F5F9),
                                      height: 24,
                                      thickness: 1,
                                    ),
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        // In Time detail
                                        Row(
                                          children: [
                                            Icon(Icons.login_rounded, color: textGrey, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'In: ${record.checkIn ?? '--:--'}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: textDark,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                        // Out Time detail
                                        Row(
                                          children: [
                                            Icon(Icons.logout_rounded, color: textGrey, size: 16),
                                            const SizedBox(width: 8),
                                            Text(
                                              'Out: ${record.checkOut ?? '--:--'}',
                                              style: GoogleFonts.inter(
                                                fontSize: 13,
                                                color: textDark,
                                                fontWeight: FontWeight.w500,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                        const SizedBox(height: 16),
                      ],
                    ),
                  ),
                ),
                // Custom Bottom Navigation Bar
                _buildBottomNavigationBar(context),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildBottomNavigationBar(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
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
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBottomNavItem(
            context: context,
            icon: Icons.home_outlined,
            label: 'HOME',
            isActive: false,
            onTap: () => context.go(StaffRoutes.home),
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.people,
            label: 'STAFF',
            isActive: true,
            onTap: () {},
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.payments_outlined,
            label: 'PAYMENTS',
            isActive: false,
            onTap: () => context.go(StaffRoutes.salary),
          ),
          _buildBottomNavItem(
            context: context,
            icon: Icons.person_outline_rounded,
            label: 'PROFILE',
            isActive: false,
            onTap: () => context.go(StaffRoutes.profile),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNavItem({
    required BuildContext context,
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    final activeColor = const Color(0xFF1A56FF);
    final inactiveColor = const Color(0xFF64748B);

    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
              decoration: BoxDecoration(
                color: isActive ? activeColor.withValues(alpha: 0.12) : Colors.transparent,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                icon,
                color: isActive ? activeColor : inactiveColor,
                size: 24,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                color: isActive ? activeColor : inactiveColor,
                letterSpacing: 0.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
