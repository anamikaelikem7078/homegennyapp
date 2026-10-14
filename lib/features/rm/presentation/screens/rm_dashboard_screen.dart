import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/series/series_catalog.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/layout/ds_hero_header.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmDashboardScreen extends ConsumerWidget {
  const RmDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final dashboard = ref.watch(rmDashboardProvider);
    final user = ref.watch(authProvider).user;

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: RefreshIndicator(
        color: RmTheme.electricBlue,
        onRefresh: () async => ref.invalidate(rmDashboardProvider),
        child: AsyncValueWidget<RmDashboard>(
          value: dashboard,
          onRetry: () => ref.invalidate(rmDashboardProvider),
          errorTitle: 'Could not load dashboard',
          builder: (data) => SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildHero(context, user?.name, data.kpis),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 22, 20, 0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      const _SectionTitle(
                        title: 'At a glance',
                        subtitle: 'Your key numbers today',
                      ),
                      _FocusGrid(kpis: data.kpis),
                      const SizedBox(height: 12),
                      _MetricStrip(kpis: data.kpis),
                      const SizedBox(height: 26),
                      const _SectionTitle(
                        title: 'Quick actions',
                        subtitle: 'Jump straight into work',
                      ),
                      const _QuickActions(),
                      const SizedBox(height: 26),
                      _SectionTitle(
                        title: 'Pipeline funnel',
                        subtitle: 'Staff at each stage',
                        actionLabel: 'Open',
                        onAction: () => context.go(RmRoutes.pipeline),
                      ),
                      _FunnelCard(funnel: data.funnel),
                      if (data.seriesDistribution.isNotEmpty) ...[
                        const SizedBox(height: 26),
                        const _SectionTitle(
                          title: 'Series mix',
                          subtitle: 'Who is in your pool',
                        ),
                        _SeriesCard(series: data.seriesDistribution),
                      ],
                    ]
                        .animate(interval: 60.ms)
                        .fadeIn(duration: 380.ms)
                        .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 0),
    );
  }

  Widget _buildHero(
    BuildContext context,
    String? userName,
    RmDashboardKpis kpis,
  ) {
    final name =
        (userName?.trim().isNotEmpty ?? false) ? userName!.trim() : 'RM';
    return DsHeroHeader(
      leading: DsRingAvatar(
        name: name,
        onTap: () => context.go(RmRoutes.profile),
      ),
      actions: [
        DsHeroIconButton(
          icon: Icons.notifications_none_rounded,
          tooltip: 'Incidents',
          badgeCount: kpis.openIncidents,
          onPressed: () => context.go(RmRoutes.alerts),
        ),
      ],
      eyebrow: dsGreeting(),
      eyebrowIcon: Icons.wb_sunny_rounded,
      title: 'Hello, ${name.split(' ').first}',
      subtitle: "Here's your placement pipeline today.",
      floatingIcons: const [
        Icons.groups_rounded,
        Icons.trending_up_rounded,
        Icons.verified_user_rounded,
      ],
      bottom: Row(
        children: [
          Expanded(
            child: DsHeroStat(
              label: 'Active pipeline',
              value: '${kpis.activePipeline}',
              icon: Icons.view_kanban_rounded,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DsHeroStat(
              label: 'Deployed',
              value: '${kpis.activePlacements}',
              icon: Icons.check_circle_rounded,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared bits
// ---------------------------------------------------------------------------

const _stageOrder = [
  'S1_INTAKE',
  'S2_VERIFY',
  'S2_5_ASSESS',
  'S3_TRAIN',
  'S4_AGREEMENTS',
  'S5_DEPLOY',
  'DEFERRED',
  'TERMINAL',
];

(String, String, Color, IconData) _stageInfo(String stage) => switch (stage) {
      'S1_INTAKE' => ('S1', 'Intake', const Color(0xFF6366F1), Icons.person_add_alt_rounded),
      'S2_VERIFY' => ('S2', 'Verification', const Color(0xFF0D9488), Icons.fact_check_rounded),
      'S2_5_ASSESS' => ('S2.5', 'Assessment', const Color(0xFFD97706), Icons.assignment_turned_in_rounded),
      'S3_TRAIN' => ('S3', 'Training', const Color(0xFF8B5CF6), Icons.school_rounded),
      'S4_AGREEMENTS' => ('S4', 'Agreements', const Color(0xFF1A56FF), Icons.edit_document),
      'S5_DEPLOY' => ('S5', 'Deploy', const Color(0xFF10B981), Icons.rocket_launch_rounded),
      'DEFERRED' => ('—', 'Deferred', RmTheme.amberWarning, Icons.pause_circle_rounded),
      'TERMINAL' => ('—', 'Exited', RmTheme.crimsonDanger, Icons.block_rounded),
      _ => ('', stage, RmTheme.textSecondary, Icons.circle_rounded),
    };

BoxDecoration _card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
      boxShadow: RmTheme.subtleShadow,
    );

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({
    required this.title,
    required this.subtitle,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Container(
            width: 4,
            height: 34,
            decoration: BoxDecoration(
              color: RmTheme.iconAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  subtitle,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.electricBlue,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_rounded,
                      size: 14,
                      color: RmTheme.electricBlue,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Count-up integer text.
class _CountUp extends StatelessWidget {
  const _CountUp({required this.value, required this.style});
  final int value;
  final TextStyle style;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value.toDouble()),
      duration: 900.ms,
      curve: Curves.easeOutCubic,
      builder: (_, v, _) => Text('${v.round()}', style: style),
    );
  }
}

/// Press-to-shrink wrapper.
class _Pressable extends StatefulWidget {
  const _Pressable({required this.onTap, required this.child});
  final VoidCallback onTap;
  final Widget child;

  @override
  State<_Pressable> createState() => _PressableState();
}

class _PressableState extends State<_Pressable> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapUp: (_) => setState(() => _down = false),
      onTapCancel: () => setState(() => _down = false),
      onTap: () {
        HapticFeedback.lightImpact();
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.96 : 1,
        duration: 120.ms,
        child: widget.child,
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// At a glance
// ---------------------------------------------------------------------------

class _FocusGrid extends StatelessWidget {
  const _FocusGrid({required this.kpis});
  final RmDashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final tiles = [
      _FocusTile(
        label: 'Total staff',
        value: kpis.totalStaff,
        icon: Icons.groups_rounded,
        hint: 'In your pool',
        onTap: () => context.go(RmRoutes.pipeline),
      ),
      _FocusTile(
        label: 'To verify',
        value: kpis.pendingVerification,
        icon: Icons.fact_check_rounded,
        hint: 'Awaiting checks',
        alert: kpis.pendingVerification > 0,
        onTap: () => context.go(RmRoutes.pipeline),
      ),
      _FocusTile(
        label: 'Active pipeline',
        value: kpis.activePipeline,
        icon: Icons.trending_up_rounded,
        hint: 'Moving forward',
        onTap: () => context.go(RmRoutes.pipeline),
      ),
      _FocusTile(
        label: 'Trials live',
        value: kpis.trialPlacements,
        icon: Icons.play_circle_rounded,
        hint: 'With clients now',
        onTap: () => context.push(RmRoutes.trials),
      ),
    ];

    return Column(
      children: [
        Row(
          children: [
            Expanded(child: tiles[0]),
            const SizedBox(width: 12),
            Expanded(child: tiles[1]),
          ],
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            Expanded(child: tiles[2]),
            const SizedBox(width: 12),
            Expanded(child: tiles[3]),
          ],
        ),
      ],
    );
  }
}

class _FocusTile extends StatelessWidget {
  const _FocusTile({
    required this.label,
    required this.value,
    required this.icon,
    required this.hint,
    required this.onTap,
    this.alert = false,
  });

  final String label;
  final int value;
  final IconData icon;
  final String hint;
  final VoidCallback onTap;
  final bool alert;

  @override
  Widget build(BuildContext context) {
    return _Pressable(
      onTap: onTap,
      child: Container(
        height: 140,
        padding: const EdgeInsets.all(14),
        decoration: _card(),
        clipBehavior: Clip.antiAlias,
        child: Stack(
          children: [
            // Oversized watermark icon.
            Positioned(
              right: -18,
              bottom: -18,
              child: Icon(
                icon,
                size: 86,
                color: RmTheme.iconAccent.withValues(alpha: 0.07),
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: RmTheme.iconAccentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(icon, size: 20, color: RmTheme.iconAccent),
                    ),
                    const Spacer(),
                    if (alert)
                      Container(
                        width: 9,
                        height: 9,
                        decoration: const BoxDecoration(
                          color: RmTheme.crimsonDanger,
                          shape: BoxShape.circle,
                        ),
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .scaleXY(begin: 0.8, end: 1.3, duration: 700.ms),
                  ],
                ),
                const Spacer(),
                _CountUp(
                  value: value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.8,
                    height: 1,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  hint,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Horizontally scrolling compact metrics for the remaining KPIs.
class _MetricStrip extends StatelessWidget {
  const _MetricStrip({required this.kpis});
  final RmDashboardKpis kpis;

  @override
  Widget build(BuildContext context) {
    final items = <(String, int, IconData, Color)>[
      ('Training', kpis.trainingQueue, Icons.school_rounded, const Color(0xFF8B5CF6)),
      ('Deploy ready', kpis.deploymentQueue, Icons.rocket_launch_rounded, const Color(0xFF10B981)),
      ('Pending video', kpis.pendingVideo, Icons.videocam_rounded, const Color(0xFF0D9488)),
      ('Pending shifts', kpis.pendingShifts, Icons.pending_actions_rounded, RmTheme.amberWarning),
      ('Incidents', kpis.openIncidents, Icons.report_rounded, RmTheme.crimsonDanger),
      ('Deferred', kpis.deferredCases, Icons.pause_circle_rounded, RmTheme.amberWarning),
      ('This month', kpis.monthlyPlacements, Icons.insights_rounded, RmTheme.electricBlue),
    ];

    return SizedBox(
      height: 64,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 10),
        itemBuilder: (context, i) {
          final (label, value, icon, color) = items[i];
          return Container(
            padding: const EdgeInsets.fromLTRB(8, 8, 14, 8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
            ),
            child: Row(
              children: [
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const SizedBox(width: 10),
                Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CountUp(
                      value: value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        height: 1.1,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate(delay: (50 * i).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Quick actions
// ---------------------------------------------------------------------------

class _QuickActions extends StatelessWidget {
  const _QuickActions();

  @override
  Widget build(BuildContext context) {
    final tools = <(String, IconData, VoidCallback)>[
      ('Pipeline', Icons.view_kanban_rounded, () => context.go(RmRoutes.pipeline)),
      ('Attendance', Icons.event_available_rounded, () => context.push(RmRoutes.attendance)),
      ('Locations', Icons.place_rounded, () => context.push(RmRoutes.locations)),
      ('Upgrades', Icons.trending_up_rounded, () => context.push(RmRoutes.upgrades)),
    ];

    return Column(
      children: [
        // Primary action banner.
        _Pressable(
          onTap: () => context.push(RmRoutes.staffIntake),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
              ),
              borderRadius: BorderRadius.circular(22),
              boxShadow: [
                BoxShadow(
                  color: RmTheme.electricBlue.withValues(alpha: 0.3),
                  blurRadius: 22,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            clipBehavior: Clip.antiAlias,
            child: Stack(
              clipBehavior: Clip.none,
              children: [
                Positioned(
                  right: -40,
                  top: -50,
                  child: Container(
                    width: 130,
                    height: 130,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: const Color(0xFFFFD84D).withValues(alpha: 0.15),
                    ),
                  ),
                ),
                Row(
                  children: [
                    Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.person_add_alt_1_rounded,
                        color: RmTheme.iconAccent,
                        size: 26,
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Add new staff',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                          Text(
                            'Start an intake in under 2 minutes',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w500,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.18),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 19,
                      ),
                    )
                        .animate(onPlay: (c) => c.repeat(reverse: true))
                        .moveX(begin: 0, end: 4, duration: 700.ms),
                  ],
                ),
              ],
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(
                delay: 2500.ms,
                duration: 1500.ms,
                color: Colors.white.withValues(alpha: 0.18),
              ),
        ),
        const SizedBox(height: 12),
        Row(
          children: [
            for (var i = 0; i < tools.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _Pressable(
                  onTap: tools[i].$3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    decoration: _card(),
                    child: Column(
                      children: [
                        Container(
                          width: 42,
                          height: 42,
                          decoration: BoxDecoration(
                            color: RmTheme.iconAccentSoft,
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Icon(
                            tools[i].$2,
                            size: 21,
                            color: RmTheme.iconAccent,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          tools[i].$1,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w700,
                            color: RmTheme.textPrimary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ],
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Funnel
// ---------------------------------------------------------------------------

class _FunnelCard extends StatelessWidget {
  const _FunnelCard({required this.funnel});
  final List<PipelineFunnelEntry> funnel;

  @override
  Widget build(BuildContext context) {
    final counts = {for (final e in funnel) e.stage: e.count};
    // S2.5 is switched off — show its chip only if someone is still in it.
    final stages = _stageOrder
        .where(counts.containsKey)
        .where((s) => s != 'S2_5_ASSESS' || (counts[s] ?? 0) > 0)
        .toList();
    final total = counts.values.fold<int>(0, (a, b) => a + b);
    final max = counts.values.fold<int>(0, (a, b) => b > a ? b : a);

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _card(),
      child: total == 0
          ? Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(
                'No staff in the pipeline yet.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: RmTheme.textSecondary,
                ),
              ),
            )
          : Column(
              children: [
                // Overview bar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 12,
                    child: Row(
                      children: [
                        for (final s in stages)
                          if (counts[s]! > 0)
                            Expanded(
                              flex: counts[s]!,
                              child: Container(
                                margin: const EdgeInsets.only(right: 2),
                                color: _stageInfo(s).$3,
                              ),
                            ),
                      ],
                    ),
                  ),
                )
                    .animate()
                    .scaleX(
                      begin: 0,
                      end: 1,
                      alignment: Alignment.centerLeft,
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                    ),
                const SizedBox(height: 14),
                for (var i = 0; i < stages.length; i++)
                  _FunnelRow(
                    stage: stages[i],
                    count: counts[stages[i]]!,
                    max: max,
                    total: total,
                    index: i,
                  ),
              ],
            ),
    );
  }
}

class _FunnelRow extends StatelessWidget {
  const _FunnelRow({
    required this.stage,
    required this.count,
    required this.max,
    required this.total,
    required this.index,
  });

  final String stage;
  final int count;
  final int max;
  final int total;
  final int index;

  @override
  Widget build(BuildContext context) {
    final (code, name, color, icon) = _stageInfo(stage);
    final frac = max == 0 ? 0.0 : count / max;
    final pct = total == 0 ? 0 : (count / total * 100).round();

    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, size: 17, color: color),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    if (code != '—') ...[
                      Text(
                        code,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: color,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    Expanded(
                      child: Text(
                        name,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      '$count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    const SizedBox(width: 6),
                    SizedBox(
                      width: 34,
                      child: Text(
                        '$pct%',
                        textAlign: TextAlign.right,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                ClipRRect(
                  borderRadius: BorderRadius.circular(4),
                  child: Stack(
                    children: [
                      Container(height: 6, color: RmTheme.surfaceSecondary),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: frac),
                        duration: Duration(milliseconds: 700 + index * 80),
                        curve: Curves.easeOutCubic,
                        builder: (_, v, _) => FractionallySizedBox(
                          widthFactor: v,
                          child: Container(height: 6, color: color),
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
    );
  }
}

// ---------------------------------------------------------------------------
// Series mix
// ---------------------------------------------------------------------------

(String, IconData, Color) _seriesInfo(String raw) {
  // Exact match on either series form (UC / UNSKILLED_CARE …), incl. CK.
  if (SeriesCatalog.fallback.find(raw) != null) {
    return (SeriesDisplay.label(raw), SeriesDisplay.icon(raw), SeriesDisplay.color(raw));
  }
  final pretty = raw.toUpperCase().replaceAll('_', ' ').toLowerCase();
  return (
    pretty.isEmpty ? raw : pretty[0].toUpperCase() + pretty.substring(1),
    Icons.person_rounded,
    RmTheme.textSecondary,
  );
}

class _SeriesCard extends StatelessWidget {
  const _SeriesCard({required this.series});
  final List<SeriesDistributionEntry> series;

  @override
  Widget build(BuildContext context) {
    final total = series.fold<int>(0, (a, b) => a + b.count);
    final sorted = [...series]..sort((a, b) => b.count.compareTo(a.count));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Row(
        children: [
          // Donut ring of the mix.
          SizedBox(
            width: 104,
            height: 104,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: 1000.ms,
              curve: Curves.easeOutCubic,
              builder: (_, t, _) => CustomPaint(
                painter: _DonutPainter(
                  values: [for (final s in sorted) s.count.toDouble()],
                  colors: [for (final s in sorted) _seriesInfo(s.series).$3],
                  progress: t,
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '$total',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          height: 1,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'staff',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              children: [
                for (final s in sorted)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 5),
                    child: Row(
                      children: [
                        Container(
                          width: 28,
                          height: 28,
                          decoration: BoxDecoration(
                            color: _seriesInfo(s.series).$3.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(9),
                          ),
                          child: Icon(
                            _seriesInfo(s.series).$2,
                            size: 15,
                            color: _seriesInfo(s.series).$3,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            _seriesInfo(s.series).$1,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: RmTheme.textPrimary,
                            ),
                          ),
                        ),
                        Text(
                          '${s.count}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
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
    );
  }
}

class _DonutPainter extends CustomPainter {
  _DonutPainter({
    required this.values,
    required this.colors,
    required this.progress,
  });

  final List<double> values;
  final List<Color> colors;
  final double progress;

  @override
  void paint(Canvas canvas, Size size) {
    const stroke = 13.0;
    final rect = Offset.zero & size;
    final arcRect = rect.deflate(stroke / 2);
    final total = values.fold<double>(0, (a, b) => a + b);

    canvas.drawArc(
      arcRect,
      0,
      6.2832,
      false,
      Paint()
        ..style = PaintingStyle.stroke
        ..strokeWidth = stroke
        ..color = RmTheme.surfaceSecondary,
    );
    if (total == 0) return;

    var start = -1.5708; // 12 o'clock
    final sweepTotal = 6.2832 * progress;
    const gap = 0.06;
    for (var i = 0; i < values.length; i++) {
      final sweep = values[i] / total * sweepTotal;
      if (sweep > gap) {
        canvas.drawArc(
          arcRect,
          start,
          sweep - gap,
          false,
          Paint()
            ..style = PaintingStyle.stroke
            ..strokeWidth = stroke
            ..strokeCap = StrokeCap.round
            ..color = colors[i],
        );
      }
      start += sweep;
    }
  }

  @override
  bool shouldRepaint(_DonutPainter old) =>
      old.progress != progress || old.values != values;
}
