import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/foundations/rm_theme.dart';
import '../../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../rm/presentation/navigation/rm_routes.dart';
import '../../../../rm/presentation/widgets/rm_stage_ui.dart';

/// Demo of the staff daily shift log: check-in with GPS verification,
/// check-out and this week's attendance strip.
class StaffDailyShiftScreen extends StatelessWidget {
  const StaffDailyShiftScreen({super.key});

  static const _week = [
    ('Mon', DayStatus.completed),
    ('Tue', DayStatus.completed),
    ('Wed', DayStatus.current),
    ('Thu', DayStatus.future),
    ('Fri', DayStatus.future),
    ('Sat', DayStatus.off),
    ('Sun', DayStatus.off),
  ];

  @override
  Widget build(BuildContext context) {
    return RmStageScaffold(
      title: 'Daily shift log',
      onBack: () => context.pop(),
      bottom: DsGradientButton(
        label: 'Tap to check out',
        icon: Icons.logout_rounded,
        onPressed: () => context.push(RmRoutes.staffPayslip('demo')),
      ),
      body: [
        const _CheckInHero(),
        const RmSectionTitle(title: 'Check-out'),
        const _PendingCheckOut(),
        RmSectionTitle(
          title: 'This week',
          trailing: RmStatusPill(label: '2 of 5 days', color: RmTheme.emeraldGreen),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(10, 16, 10, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
            border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
            boxShadow: RmTheme.subtleShadow,
          ),
          child: Row(
            children: [
              for (var i = 0; i < _week.length; i++)
                Expanded(
                  child: _DayColumn(label: _week[i].$1, status: _week[i].$2)
                      .animate(delay: (70 * i).ms)
                      .fadeIn(duration: 300.ms)
                      .slideY(begin: 0.3, end: 0, curve: Curves.easeOutBack),
                ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        Wrap(
          spacing: 14,
          runSpacing: 8,
          children: [
            for (final s in DayStatus.values)
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 9,
                    height: 9,
                    decoration: BoxDecoration(color: _dayColor(s), shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _dayLabel(s),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: RmTheme.textSecondary,
                    ),
                  ),
                ],
              ),
          ],
        ),
      ],
    );
  }
}

Color _dayColor(DayStatus s) => switch (s) {
      DayStatus.completed => RmTheme.emeraldGreen,
      DayStatus.current => RmTheme.electricBlue,
      DayStatus.future => RmTheme.borderSubtle,
      DayStatus.off => RmTheme.amberWarning,
    };

String _dayLabel(DayStatus s) => switch (s) {
      DayStatus.completed => 'Worked',
      DayStatus.current => 'Today',
      DayStatus.future => 'Upcoming',
      DayStatus.off => 'Off',
    };

class _CheckInHero extends StatelessWidget {
  const _CheckInHero();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withValues(alpha: 0.28),
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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'CHECKED IN',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '07:42 AM',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 36,
                        height: 1.1,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(18)),
                child: const Icon(Icons.login_rounded, color: RmTheme.iconAccent, size: 28),
              ).animate().scaleXY(begin: 0.5, end: 1, duration: 600.ms, curve: Curves.elasticOut),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                Container(
                  width: 26,
                  height: 26,
                  decoration: const BoxDecoration(color: Color(0xFF34D399), shape: BoxShape.circle),
                  child: const Icon(Icons.gps_fixed_rounded, size: 15, color: Colors.white),
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scaleXY(begin: 1, end: 1.12, duration: 900.ms),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'GPS verified · Bandra West, Mumbai',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ),
                const Icon(Icons.verified_rounded, size: 18, color: Color(0xFF6EE7B7)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _PendingCheckOut extends StatelessWidget {
  const _PendingCheckOut();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: RmTheme.iconAccentSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(Icons.schedule_rounded, color: RmTheme.iconAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Not checked out yet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  'Check out when today\'s shift ends',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const RmStatusPill(label: 'In progress', color: RmTheme.electricBlue),
        ],
      ),
    );
  }
}

class _DayColumn extends StatelessWidget {
  const _DayColumn({required this.label, required this.status});
  final String label;
  final DayStatus status;

  @override
  Widget build(BuildContext context) {
    final color = _dayColor(status);
    final current = status == DayStatus.current;
    final icon = switch (status) {
      DayStatus.completed => Icons.check_rounded,
      DayStatus.current => Icons.circle,
      DayStatus.future => null,
      DayStatus.off => Icons.bedtime_rounded,
    };

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11.5,
            fontWeight: current ? FontWeight.w800 : FontWeight.w600,
            color: current ? RmTheme.electricBlue : RmTheme.textSecondary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: status == DayStatus.future ? RmTheme.offWhite : color.withValues(alpha: current ? 1 : 0.14),
            shape: BoxShape.circle,
            border: status == DayStatus.future ? Border.all(color: RmTheme.borderSubtle, width: 1.5) : null,
            boxShadow: current
                ? [BoxShadow(color: color.withValues(alpha: 0.4), blurRadius: 10, offset: const Offset(0, 4))]
                : null,
          ),
          child: icon == null
              ? null
              : Icon(
                  icon,
                  size: current ? 10 : 17,
                  color: current ? Colors.white : color,
                ),
        ),
      ],
    );
  }
}

enum DayStatus { completed, current, future, off }
