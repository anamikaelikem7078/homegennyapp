import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Monthly attendance summary.
class StaffMonthlyAttendanceScreen extends ConsumerWidget {
  const StaffMonthlyAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final monthly = ref.watch(staffMonthlyAttendanceProvider);

    return DsPage(
      title: 'Monthly attendance',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.attendance),
      onRefresh: () async => ref.invalidate(staffMonthlyAttendanceProvider),
      actions: [
        DsPageAction(
          icon: Icons.history_rounded,
          tooltip: 'Daily history',
          onPressed: () => context.push(StaffRoutes.attendanceHistory),
        ),
      ],
      body: dsAsyncBody(
        monthly,
        onRetry: () => ref.invalidate(staffMonthlyAttendanceProvider),
        builder: (s) {
          final total = s.present + s.absent + s.late + s.leave;
          final rate = total > 0 ? s.present / total : 0.0;
          final parts = [
            ('Present', s.present, AppColors.success, Icons.check_circle_rounded),
            ('Late', s.late, AppColors.warning, Icons.schedule_rounded),
            ('Leave', s.leave, const Color(0xFF3B82F6), Icons.beach_access_rounded),
            ('Absent', s.absent, AppColors.error, Icons.cancel_rounded),
          ];

          return [
            DsGradientCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 104,
                    height: 104,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: rate),
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
                          Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                '${(v * 100).round()}%',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 24,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                              Text(
                                'RATE',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w800,
                                  letterSpacing: 1,
                                  color: Colors.white.withValues(alpha: 0.75),
                                ),
                              ),
                            ],
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
                        const DsGlassPill('THIS MONTH', icon: Icons.calendar_month_rounded),
                        const SizedBox(height: 10),
                        Text(
                          s.month,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '$total working days tracked',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const DsSection('Breakdown'),
            // Stacked split bar.
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(),
              child: Column(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: SizedBox(
                      height: 12,
                      child: total == 0
                          ? Container(color: AppColors.lightBorder)
                          : Row(
                              children: [
                                for (final (_, n, c, _) in parts)
                                  if (n > 0) Expanded(flex: n, child: Container(color: c)),
                              ],
                            ),
                    ),
                  ).animate().scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft, duration: 800.ms, curve: Curves.easeOutCubic),
                  const SizedBox(height: 14),
                  LayoutBuilder(
                    builder: (context, c) {
                      final cols = c.maxWidth > 420 ? 4 : 2;
                      final w = (c.maxWidth - 10 * (cols - 1)) / cols;
                      return Wrap(
                        spacing: 10,
                        runSpacing: 10,
                        children: [
                          for (final (label, n, color, icon) in parts)
                            SizedBox(
                              width: w,
                              child: Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: color.withValues(alpha: 0.07),
                                  borderRadius: BorderRadius.circular(16),
                                ),
                                child: Row(
                                  children: [
                                    Icon(icon, color: color, size: 22),
                                    const SizedBox(width: 10),
                                    Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          '$n',
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 19,
                                            height: 1.1,
                                            fontWeight: FontWeight.w800,
                                            color: AppColors.lightTextPrimary,
                                          ),
                                        ),
                                        Text(
                                          label,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 11.5,
                                            fontWeight: FontWeight.w600,
                                            color: AppColors.lightTextSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              ),
                            ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DsNote(
              tone: rate >= 0.9 ? DsNoteTone.success : (rate >= 0.75 ? DsNoteTone.info : DsNoteTone.warning),
              title: rate >= 0.9 ? 'Great consistency!' : 'Keep it up',
              text: rate >= 0.9
                  ? 'Your attendance this month is excellent.'
                  : 'Regular attendance helps you qualify for series upgrades.',
            ),
          ];
        },
      ),
    );
  }
}
