import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/foundations/rm_theme.dart';
import '../../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../../../rm/domain/models/pipeline_stage.dart';
import '../../../../rm/presentation/navigation/rm_routes.dart';
import '../../../../rm/presentation/widgets/rm_stage_ui.dart';

/// Demo of the staff-side S5 "active placement" view (trial countdown,
/// client and today's shift with check-out).
class StaffActivePlacementScreen extends StatefulWidget {
  const StaffActivePlacementScreen({super.key});

  @override
  State<StaffActivePlacementScreen> createState() => _StaffActivePlacementScreenState();
}

class _StaffActivePlacementScreenState extends State<StaffActivePlacementScreen> {
  static const _trialDays = 7;
  static const _daysLeft = 4;

  bool _isCheckedOut = false;
  String _checkOutTime = '';

  void _checkOut() {
    HapticFeedback.mediumImpact();
    setState(() {
      _isCheckedOut = true;
      _checkOutTime = TimeOfDay.now().format(context);
    });
    DsSnackBar.show(context, message: 'Checked out successfully', type: DsSnackBarType.success);
    Future.delayed(const Duration(seconds: 1), () {
      if (mounted) context.go(RmRoutes.dashboard);
    });
  }

  @override
  Widget build(BuildContext context) {
    final stageColor = rmStageColor(PipelineStages.s5Deploy);

    return RmStageScaffold(
      title: 'Active placement',
      stageCode: 'S5',
      stageColor: stageColor,
      onBack: () => context.pop(),
      bottom: _isCheckedOut
          ? RmHint(text: 'Checked out at $_checkOutTime', done: true)
          : DsGradientButton(
              label: 'Check out now',
              icon: Icons.logout_rounded,
              onPressed: _checkOut,
            ),
      body: [
        _StageHero(color: stageColor),
        const SizedBox(height: 14),
        _TrialCard(daysLeft: _daysLeft, totalDays: _trialDays),
        const RmSectionTitle(title: 'Client'),
        const _InfoCard(
          icon: Icons.home_work_rounded,
          title: 'Sharma Household',
          subtitle: 'Bandra West, Mumbai',
          trailing: RmStatusPill(label: 'Trial', color: RmTheme.amberWarning),
        ),
        const RmSectionTitle(title: 'Today\'s shift'),
        _InfoCard(
          icon: _isCheckedOut ? Icons.logout_rounded : Icons.login_rounded,
          title: _isCheckedOut ? 'Checked out' : 'Checked in',
          subtitle: _isCheckedOut ? 'At $_checkOutTime' : 'At 7:42 AM · shift in progress',
          trailing: _LiveDot(active: !_isCheckedOut),
        ),
      ],
    );
  }
}

class _StageHero extends StatelessWidget {
  const _StageHero({required this.color});
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 24, offset: const Offset(0, 12)),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.18),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    'S5 · DEPLOYMENT',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: Colors.white,
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Trial, confirmation & payroll',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    height: 1.2,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'The active employment phase. Starts with a series-specific trial period. '
                  'All exits are logged.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(17)),
            child: const Icon(Icons.rocket_launch_rounded, color: RmTheme.iconAccent, size: 26),
          )
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .moveY(begin: -3, end: 3, duration: 1400.ms, curve: Curves.easeInOut),
        ],
      ),
    );
  }
}

class _TrialCard extends StatelessWidget {
  const _TrialCard({required this.daysLeft, required this.totalDays});
  final int daysLeft;
  final int totalDays;

  @override
  Widget build(BuildContext context) {
    final progress = (totalDays - daysLeft) / totalDays;
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 92,
            height: 92,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: progress),
              duration: 1100.ms,
              curve: Curves.easeOutCubic,
              builder: (context, v, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 8,
                      strokeCap: StrokeCap.round,
                      backgroundColor: RmTheme.amberWarning.withValues(alpha: 0.12),
                      color: RmTheme.amberWarning,
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$daysLeft',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 28,
                          height: 1,
                          fontWeight: FontWeight.w800,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'of $totalDays days',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w700,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const RmStatusPill(label: 'Trial period', color: RmTheme.amberWarning),
                const SizedBox(height: 10),
                Text(
                  '$daysLeft days remaining',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '$totalDays-day trial',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    for (var i = 0; i < totalDays; i++) ...[
                      if (i > 0) const SizedBox(width: 4),
                      Expanded(
                        child: Container(
                          height: 6,
                          decoration: BoxDecoration(
                            color: i < totalDays - daysLeft
                                ? RmTheme.amberWarning
                                : RmTheme.amberWarning.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(3),
                          ),
                        ).animate(delay: (80 * i).ms).fadeIn().scaleX(begin: 0, end: 1),
                      ),
                    ],
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

class _InfoCard extends StatelessWidget {
  const _InfoCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    this.trailing,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Widget? trailing;

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
            child: Icon(icon, color: RmTheme.iconAccent),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (trailing != null) ...[const SizedBox(width: 8), trailing!],
        ],
      ),
    );
  }
}

class _LiveDot extends StatelessWidget {
  const _LiveDot({required this.active});
  final bool active;

  @override
  Widget build(BuildContext context) {
    final color = active ? RmTheme.emeraldGreen : RmTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          )
              .animate(onPlay: (c) => active ? c.repeat(reverse: true) : null)
              .fade(begin: 0.3, end: 1, duration: 800.ms),
          const SizedBox(width: 6),
          Text(
            active ? 'Live' : 'Done',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
