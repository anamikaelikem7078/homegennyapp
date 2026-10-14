import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// Series/role upgrade requests — read-only. No approval endpoint is
/// exposed by the backend, so none is fabricated here (§30).
class RmUpgradesScreen extends ConsumerWidget {
  const RmUpgradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradesAsync = ref.watch(rmUpgradesProvider);

    return RmStageScaffold(
      title: 'Upgrades',
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(rmUpgradesProvider),
      body: rmAsyncBody<List<UpgradeRequestRow>>(
        upgradesAsync,
        onRetry: () => ref.invalidate(rmUpgradesProvider),
        builder: (rows) {
          final pending = rows.where((r) => _isPending(r.status)).length;
          return [
            _UpgradesHero(total: rows.length, pending: pending),
            const SizedBox(height: 14),
            const RmNote(
              text: 'Upgrade requests are view-only here. Approvals happen in the admin console.',
            ),
            RmSectionTitle(
              title: 'Requests',
              trailing: RmStatusPill(label: '${rows.length}', color: RmTheme.electricBlue),
            ),
            if (rows.isEmpty)
              const RmEmptyBlock(
                icon: Icons.trending_up_rounded,
                title: 'No upgrade requests',
                message: 'When staff become eligible for a higher series, their requests show up here.',
              )
            else
              for (final u in rows) _UpgradeCard(row: u),
          ];
        },
      ),
    );
  }
}

bool _isPending(String s) {
  final v = s.toUpperCase();
  return v == 'PENDING' || v == 'REQUESTED' || v == 'UNDER_REVIEW' || v == 'OPEN';
}

Color _statusColor(String s) {
  final v = s.toUpperCase();
  if (v.contains('APPROV') || v == 'COMPLETED' || v == 'DONE') return RmTheme.emeraldGreen;
  if (v.contains('REJECT') || v.contains('DECLIN') || v == 'CANCELLED') return RmTheme.crimsonDanger;
  return RmTheme.amberWarning;
}

class _UpgradesHero extends StatelessWidget {
  const _UpgradesHero({required this.total, required this.pending});
  final int total;
  final int pending;

  @override
  Widget build(BuildContext context) {
    Widget stat(String value, String label) => Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.14),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                ),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
        );

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
                      'Career growth',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Staff moving up to a higher series',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(Icons.trending_up_rounded, color: RmTheme.iconAccent, size: 30),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -3, end: 3, duration: 1500.ms, curve: Curves.easeInOut),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              stat('$total', 'Total requests'),
              const SizedBox(width: 10),
              stat('$pending', 'Awaiting review'),
            ],
          ),
        ],
      ),
    );
  }
}

class _UpgradeCard extends StatelessWidget {
  const _UpgradeCard({required this.row});
  final UpgradeRequestRow row;

  @override
  Widget build(BuildContext context) {
    final name = row.staff?.fullName ?? row.staffId;
    final color = _statusColor(row.status);
    final score = row.eligibilityScore;
    final created = row.createdAt == null ? null : DateTime.tryParse(row.createdAt!);

    Widget seriesChip(String s, {required bool target}) => Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: target ? RmTheme.electricBlue : RmTheme.offWhite,
            borderRadius: BorderRadius.circular(14),
          ),
          child: Text(
            s,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: target ? Colors.white : RmTheme.textPrimary,
            ),
          ),
        );

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(Icons.workspace_premium_rounded, color: RmTheme.iconAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      [
                        if (row.staff?.staffCode != null) row.staff!.staffCode,
                        if (created != null) 'Requested ${created.day}/${created.month}/${created.year}',
                      ].join(' · '),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              RmStatusPill(label: rmTitleCase(row.status), color: color),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              seriesChip(row.fromSeries, target: false),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Row(
                    children: [
                      Expanded(
                        child: Container(
                          height: 2,
                          decoration: BoxDecoration(
                            gradient: LinearGradient(
                              colors: [
                                RmTheme.borderSubtle,
                                RmTheme.electricBlue.withValues(alpha: 0.6),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Icon(Icons.arrow_forward_rounded, size: 18, color: RmTheme.electricBlue)
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .moveX(begin: -2, end: 2, duration: 900.ms),
                    ],
                  ),
                ),
              ),
              seriesChip(row.toSeries, target: true),
              if (score != null) ...[
                const SizedBox(width: 12),
                _ScoreRing(score: score),
              ],
            ],
          ),
          if (row.rmRecommendation?.isNotEmpty ?? false) ...[
            const SizedBox(height: 12),
            Text(
              'RM note: ${row.rmRecommendation}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.4,
                color: RmTheme.textSecondary,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ScoreRing extends StatelessWidget {
  const _ScoreRing({required this.score});
  final num score;

  @override
  Widget build(BuildContext context) {
    final pct = (score > 1 ? score / 100 : score).clamp(0, 1).toDouble();
    final color = pct >= 0.7
        ? RmTheme.emeraldGreen
        : pct >= 0.4
            ? RmTheme.amberWarning
            : RmTheme.crimsonDanger;
    return SizedBox(
      width: 46,
      height: 46,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: pct),
        duration: 900.ms,
        curve: Curves.easeOutCubic,
        builder: (context, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 4,
                strokeCap: StrokeCap.round,
                backgroundColor: color.withValues(alpha: 0.12),
                color: color,
              ),
            ),
            Text(
              score is int || score == score.roundToDouble()
                  ? '${score.round()}'
                  : score.toStringAsFixed(1),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: RmTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
