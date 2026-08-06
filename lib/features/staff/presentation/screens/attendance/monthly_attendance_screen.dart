import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Redesigned premium Monthly Attendance Screen matching visual identity.
class StaffMonthlyAttendanceScreen extends ConsumerWidget {
  const StaffMonthlyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(staffMonthlyAttendanceProvider);
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);
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
      ),
      body: SafeArea(
        child: monthly.when(
          loading: () => const Center(child: DsLoadingWidget(message: 'Loading summary...')),
          error: (e, _) => DsErrorState(
            title: 'Failed to load summary',
            message: e.toString(),
            onRetry: () => ref.invalidate(staffMonthlyAttendanceProvider),
          ),
          data: (summary) {
            final total = summary.present + summary.absent + summary.late + summary.leave;
            final progress = total > 0 ? summary.present / total : 0.0;

            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                    children: [
                      // Headline
                      Text(
                        'Monthly\nAttendance',
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 36,
                          fontWeight: FontWeight.w700,
                          color: primaryColor,
                          height: 1.1,
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Hero Module: Gradient "glass" card
                      Container(
                        width: double.infinity,
                        height: 140,
                        decoration: BoxDecoration(
                          gradient: const LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [Color(0xFF1A56FF), Color(0xFF4F46E5)],
                          ),
                          borderRadius: BorderRadius.circular(24),
                          boxShadow: [
                            BoxShadow(
                              color: primaryColor.withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 10),
                            ),
                          ],
                        ),
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(24),
                          child: Stack(
                            children: [
                              // Text Content
                              Padding(
                                padding: const EdgeInsets.all(24),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Text(
                                      summary.month, // e.g. "July 2024"
                                      style: GoogleFonts.libreCaslonText(
                                        color: Colors.white,
                                        fontSize: 36,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const SizedBox(height: 6),
                                    Text(
                                      '$total working days tracked',
                                      style: GoogleFonts.inter(
                                        color: Colors.white.withValues(alpha: 0.85),
                                        fontSize: 14,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              // Abstract dot-pattern graphic for texture on the right
                              Positioned(
                                right: 24,
                                top: 0,
                                bottom: 0,
                                child: Center(
                                  child: Container(
                                    width: 80,
                                    height: 80,
                                    decoration: BoxDecoration(
                                      color: Colors.white.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(16),
                                    ),
                                    child: Column(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: [
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: List.generate(3, (_) => Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white60,
                                              shape: BoxShape.circle,
                                            ),
                                          )),
                                        ),
                                        const SizedBox(height: 12),
                                        Row(
                                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                                          children: List.generate(3, (_) => Container(
                                            width: 8,
                                            height: 8,
                                            decoration: const BoxDecoration(
                                              color: Colors.white60,
                                              shape: BoxShape.circle,
                                            ),
                                          )),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Metric Grid 2x2
                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 16,
                        mainAxisSpacing: 16,
                        childAspectRatio: 1.15,
                        children: [
                          _buildMetricCard(
                            icon: Icons.check_circle_outline_rounded,
                            iconColor: primaryColor,
                            bgColor: primaryColor.withValues(alpha: 0.1),
                            count: '${summary.present}',
                            label: 'PRESENT',
                            shadows: tactileCardShadows,
                            textDark: textDark,
                            textGrey: textGrey,
                          ),
                          _buildMetricCard(
                            icon: Icons.cancel_outlined,
                            iconColor: errorColor,
                            bgColor: errorColor.withValues(alpha: 0.1),
                            count: '${summary.absent}',
                            label: 'ABSENT',
                            shadows: tactileCardShadows,
                            textDark: textDark,
                            textGrey: textGrey,
                          ),
                          _buildMetricCard(
                            icon: Icons.schedule_rounded,
                            iconColor: warningColor,
                            bgColor: warningColor.withValues(alpha: 0.1),
                            count: '${summary.late}',
                            label: 'LATE',
                            shadows: tactileCardShadows,
                            textDark: textDark,
                            textGrey: textGrey,
                          ),
                          _buildMetricCard(
                            icon: Icons.flight_takeoff_rounded,
                            iconColor: leaveColor,
                            bgColor: leaveColor.withValues(alpha: 0.1),
                            count: '${summary.leave}',
                            label: 'LEAVE',
                            shadows: tactileCardShadows,
                            textDark: textDark,
                            textGrey: textGrey,
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Attendance Rate Card
                      Container(
                        padding: const EdgeInsets.all(24),
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
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Attendance rate',
                                      style: GoogleFonts.libreCaslonText(
                                        fontSize: 20,
                                        fontWeight: FontWeight.w600,
                                        color: textDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Overall monthly performance',
                                      style: GoogleFonts.inter(
                                        fontSize: 12,
                                        color: textGrey,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ],
                                ),
                                Text(
                                  '${(progress * 100).toInt()}%',
                                  style: GoogleFonts.libreCaslonText(
                                    fontSize: 32,
                                    fontWeight: FontWeight.w700,
                                    color: primaryColor,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 20),
                            // Thick, rounded blue progress bar
                            Container(
                              height: 10,
                              width: double.infinity,
                              decoration: BoxDecoration(
                                color: const Color(0xFFF1F5F9),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: FractionallySizedBox(
                                alignment: Alignment.centerLeft,
                                widthFactor: progress,
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: primaryColor,
                                    borderRadius: BorderRadius.circular(5),
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 16),
                    ],
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

  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required Color bgColor,
    required String count,
    required String label,
    required List<BoxShadow> shadows,
    required Color textDark,
    required Color textGrey,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(4), // Exactly 4px rounded corners
        boxShadow: shadows,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Minimalist icon in soft colored container
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: iconColor,
              size: 20,
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                count,
                style: GoogleFonts.inter(
                  fontSize: 28,
                  fontWeight: FontWeight.w700,
                  color: textDark,
                  height: 1.1,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: textGrey,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ],
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
