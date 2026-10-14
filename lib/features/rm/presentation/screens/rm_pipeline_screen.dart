import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/series/series_catalog.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmPipelineScreen extends ConsumerStatefulWidget {
  const RmPipelineScreen({super.key});

  @override
  ConsumerState<RmPipelineScreen> createState() => _RmPipelineScreenState();
}

class _RmPipelineScreenState extends ConsumerState<RmPipelineScreen> {
  String? _seriesFilter;
  String _search = '';
  Timer? _debounce;
  final _searchController = TextEditingController();

  /// Stage whose staff are listed; null until data arrives (then the first
  /// non-empty stage is picked).
  String? _stage;

  /// Every series, paused ones marked — their staff still exist.
  Map<String, String?> get _filters => {
        'All series': null,
        for (final s in ref.watch(seriesCatalogProvider).all)
          s.active ? s.label : '${s.label} (paused)': s.short,
      };

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged(String value) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      setState(() => _search = value);
    });
  }

  @override
  Widget build(BuildContext context) {
    final params = KanbanParams(
      search: _search.isEmpty ? null : _search,
      series: _seriesFilter,
    );
    final kanban = ref.watch(rmKanbanProvider(params));
    final data = kanban.valueOrNull;
    final stages = PipelineStages.visibleStages(
      data?.columns ?? const {},
      stage25Enabled: ref.watch(seriesCatalogProvider).stage25Enabled,
    );

    // Default to the first stage with people in it.
    final stage = _stage != null && stages.contains(_stage)
        ? _stage!
        : stages.firstWhere(
            (s) => (data?.columns[s]?.isNotEmpty ?? false),
            orElse: () => stages.first,
          );

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      floatingActionButton: DsFab(
        icon: Icons.person_add_alt_1_rounded,
        label: 'Add staff',
        onPressed: () => context.push(RmRoutes.staffIntake),
      ),
      body: RefreshIndicator(
        color: RmTheme.electricBlue,
        onRefresh: () async => ref.invalidate(rmKanbanProvider(params)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _PipelineAppBar(total: data?.total),
            SliverToBoxAdapter(child: _buildSearch()),
            SliverToBoxAdapter(child: _buildSeriesChips()),
            ...kanban.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (_, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.cloud_off_rounded,
                    title: 'Could not load pipeline',
                    message: 'Pull down or tap retry.',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(rmKanbanProvider(params)),
                  ),
                ),
              ],
              data: (d) => _buildContent(d, stage, stages),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 1),
    );
  }

  List<Widget> _buildContent(KanbanResult data, String stage, List<String> stages) {
    final items = data.columns[stage] ?? const <StaffRow>[];
    return [
      SliverToBoxAdapter(
        child: _FunnelCard(
          data: data,
          stages: stages,
          onTrials: () => context.push(RmRoutes.trials),
          onDeferred: () => context.push(RmRoutes.deferred),
          onTerminal: () => context.push(RmRoutes.terminal),
        ),
      ),
      SliverToBoxAdapter(
        child: _StageTabs(
          data: data,
          stages: stages,
          selected: stage,
          onSelect: (s) {
            HapticFeedback.selectionClick();
            setState(() => _stage = s);
          },
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: _stageColor(stage),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _stageName(stage),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.3,
                    color: RmTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                '${items.length} staff',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: RmTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      if (items.isEmpty)
        SliverToBoxAdapter(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 140),
            child: _EmptyState(
              key: ValueKey('empty-$stage'),
              icon: Icons.inbox_rounded,
              title: 'No one here yet',
              message: data.total == 0
                  ? 'No staff match this filter yet.'
                  : 'Nobody is in ${_stageName(stage)} right now.',
              actionLabel: 'Add staff',
              onAction: () => context.push(RmRoutes.staffIntake),
            ),
          ),
        )
      else
        SliverPadding(
          // Room for the FAB and floating bottom nav.
          padding: const EdgeInsets.fromLTRB(20, 4, 20, 140),
          sliver: SliverList.builder(
            itemCount: items.length,
            itemBuilder: (context, i) => _StaffCard(
              key: ValueKey('${stage}_${items[i].id}'),
              staff: items[i],
              onTap: () => context.push(
                RmRoutes.staffDetail(items[i].id),
                extra: items[i],
              ),
            )
                .animate(delay: (50 * i).ms)
                .fadeIn(duration: 350.ms)
                .slideX(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
    ];
  }

  Widget _buildSearch() {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 4, 20, 12),
      child: TextField(
        controller: _searchController,
        onChanged: _onSearchChanged,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w600,
          color: RmTheme.textPrimary,
        ),
        decoration: InputDecoration(
          hintText: 'Search by name or staff code',
          fillColor: Colors.white,
          prefixIcon: const Icon(Icons.search_rounded, color: RmTheme.iconAccent),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close_rounded, size: 18),
                  onPressed: () {
                    _searchController.clear();
                    _onSearchChanged('');
                  },
                )
              : null,
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(16),
            borderSide: const BorderSide(color: RmTheme.borderSubtle),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.2, end: 0);
  }

  Widget _buildSeriesChips() {
    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        children: [
          for (final entry in _filters.entries)
            Padding(
              padding: const EdgeInsets.only(right: 8),
              child: _Pill(
                label: entry.key,
                selected: _seriesFilter == entry.value,
                onTap: () {
                  HapticFeedback.selectionClick();
                  setState(() {
                    _seriesFilter = entry.value;
                    _stage = null;
                  });
                },
              ),
            ),
        ],
      ),
    ).animate(delay: 80.ms).fadeIn(duration: 350.ms);
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

Color _stageColor(String stage) => switch (stage) {
      PipelineStages.s1Intake => const Color(0xFF6366F1),
      PipelineStages.s2Verify => const Color(0xFF0D9488),
      PipelineStages.s25Assess => const Color(0xFFD97706),
      PipelineStages.s3Train => const Color(0xFF8B5CF6),
      PipelineStages.s4Agreements => const Color(0xFF1A56FF),
      PipelineStages.s5Deploy => const Color(0xFF10B981),
      _ => RmTheme.textSecondary,
    };

IconData _stageIcon(String stage) => switch (stage) {
      PipelineStages.s1Intake => Icons.person_add_alt_rounded,
      PipelineStages.s2Verify => Icons.fact_check_rounded,
      PipelineStages.s25Assess => Icons.assignment_turned_in_rounded,
      PipelineStages.s3Train => Icons.school_rounded,
      PipelineStages.s4Agreements => Icons.edit_document,
      PipelineStages.s5Deploy => Icons.rocket_launch_rounded,
      _ => Icons.circle_rounded,
    };

/// "S2 · Verification" → "Verification".
String _stageName(String stage) {
  final l = PipelineStages.label(stage);
  final i = l.indexOf('·');
  return i == -1 ? l : l.substring(i + 1).trim();
}

/// "S2 · Verification" → "S2".
String _stageCode(String stage) {
  final l = PipelineStages.label(stage);
  final i = l.indexOf('·');
  return i == -1 ? '' : l.substring(0, i).trim();
}

String _seriesName(String s) => SeriesDisplay.label(s);

(String, Color) _pv(String? status) => switch (status) {
      'CLEAR' => ('Verified', RmTheme.emeraldGreen),
      'IN_PROGRESS' => ('Verifying', RmTheme.amberWarning),
      'ADVERSE' => ('Adverse', RmTheme.crimsonDanger),
      'EXPIRED' => ('Expired', RmTheme.crimsonDanger),
      'NOT_INITIATED' => ('Not started', RmTheme.textSecondary),
      _ => ('Unknown', RmTheme.textSecondary),
    };

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

class _PipelineAppBar extends StatelessWidget {
  const _PipelineAppBar({required this.total});
  final int? total;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: RmTheme.offWhite,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarHeight: 74,
      titleSpacing: 20,
      title: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: RmTheme.iconAccentSoft,
              borderRadius: BorderRadius.circular(15),
            ),
            child: const Icon(
              Icons.view_kanban_rounded,
              color: RmTheme.iconAccent,
              size: 24,
            ),
          ).animate().scaleXY(
                begin: 0.5,
                end: 1,
                duration: 500.ms,
                curve: Curves.elasticOut,
              ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Pipeline',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  total == null
                      ? 'Loading staff…'
                      : '$total staff across ${PipelineStages.order.length} stages',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ).animate().fadeIn(duration: 350.ms).slideX(begin: -0.08, end: 0),
          ),
        ],
      ),
    );
  }
}

class _Pill extends StatelessWidget {
  const _Pill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOut,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          gradient: selected
              ? const LinearGradient(
                  colors: [Color(0xFF2F6BFF), Color(0xFF1238B8)],
                )
              : null,
          color: selected ? null : Colors.white,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? Colors.transparent : RmTheme.borderSubtle,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: RmTheme.electricBlue.withValues(alpha: 0.3),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ]
              : null,
        ),
        child: Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: selected ? Colors.white : RmTheme.textPrimary,
          ),
        ),
      ),
    );
  }
}

/// Gradient funnel overview: total, stage-proportion bar, exception queues.
class _FunnelCard extends StatelessWidget {
  const _FunnelCard({
    required this.data,
    required this.stages,
    required this.onTrials,
    required this.onDeferred,
    required this.onTerminal,
  });

  final KanbanResult data;
  final List<String> stages;
  final VoidCallback onTrials;
  final VoidCallback onDeferred;
  final VoidCallback onTerminal;

  @override
  Widget build(BuildContext context) {
    final counts = {
      for (final s in stages) s: data.columns[s]?.length ?? 0,
    };
    final active = counts.values.fold<int>(0, (a, b) => a + b);
    final deployReady = counts[PipelineStages.s5Deploy] ?? 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 16, 20, 4),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withValues(alpha: 0.28),
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(
            top: -50,
            right: -30,
            child: Container(
              width: 150,
              height: 150,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD84D).withValues(alpha: 0.14),
              ),
            )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scaleXY(begin: 0.9, end: 1.1, duration: 4.seconds),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'In pipeline',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: active.toDouble()),
                            duration: 900.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Text(
                              '${v.round()}',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.rocket_launch_rounded,
                            size: 14,
                            color: Color(0xFFFFD84D),
                          ),
                          const SizedBox(width: 5),
                          Text(
                            '$deployReady ready to deploy',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                // Stacked stage-proportion bar.
                ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: SizedBox(
                    height: 10,
                    child: active == 0
                        ? Container(color: Colors.white.withValues(alpha: 0.15))
                        : Row(
                            children: [
                              for (final s in stages)
                                if ((counts[s] ?? 0) > 0)
                                  Expanded(
                                    flex: counts[s]!,
                                    child: Container(
                                      margin: const EdgeInsets.only(right: 2),
                                      color: _stageColor(s),
                                    ),
                                  ),
                            ],
                          )
                            .animate()
                            .scaleX(
                              begin: 0,
                              end: 1,
                              alignment: Alignment.centerLeft,
                              duration: 900.ms,
                              curve: Curves.easeOutCubic,
                            ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _QueueLink(
                        icon: Icons.play_arrow_rounded,
                        label: 'Trials',
                        dot: const Color(0xFF4ADE80),
                        onTap: onTrials,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QueueLink(
                        icon: Icons.pause_rounded,
                        label: 'Deferred',
                        dot: const Color(0xFFFFD84D),
                        onTap: onDeferred,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _QueueLink(
                        icon: Icons.block_rounded,
                        label: 'Exited',
                        dot: const Color(0xFFFF8A8A),
                        onTap: onTerminal,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 450.ms).slideY(begin: 0.1, end: 0);
  }
}

class _QueueLink extends StatelessWidget {
  const _QueueLink({
    required this.icon,
    required this.label,
    required this.dot,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color dot;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.12),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.18)),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () {
          HapticFeedback.lightImpact();
          onTap();
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 16, color: dot),
              const SizedBox(width: 4),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Horizontal stage tracker: icon, code, name, count — linked by a rail.
class _StageTabs extends StatelessWidget {
  const _StageTabs({
    required this.data,
    required this.stages,
    required this.selected,
    required this.onSelect,
  });

  final KanbanResult data;
  final List<String> stages;
  final String selected;
  final ValueChanged<String> onSelect;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
        itemCount: stages.length,
        separatorBuilder: (_, i) => Center(
          child: Container(
            width: 14,
            height: 2,
            color: RmTheme.borderSubtle,
          ),
        ),
        itemBuilder: (context, i) {
          final s = stages[i];
          final count = data.columns[s]?.length ?? 0;
          final isSel = s == selected;
          final color = _stageColor(s);

          return GestureDetector(
            onTap: () => onSelect(s),
            child: AnimatedContainer(
              duration: 250.ms,
              curve: Curves.easeOutCubic,
              width: 104,
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSel ? null : Colors.white,
                gradient: isSel
                    ? const LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [Color(0xFF2F6BFF), Color(0xFF1238B8)],
                      )
                    : null,
                borderRadius: BorderRadius.circular(18),
                border: Border.all(
                  color: isSel ? Colors.transparent : RmTheme.borderSubtle,
                ),
                boxShadow: isSel
                    ? [
                        BoxShadow(
                          color: RmTheme.electricBlue.withValues(alpha: 0.3),
                          blurRadius: 14,
                          offset: const Offset(0, 6),
                        ),
                      ]
                    : null,
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 26,
                        height: 26,
                        decoration: BoxDecoration(
                          color: isSel
                              ? Colors.white
                              : color.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(_stageIcon(s), size: 15, color: color),
                      ),
                      const Spacer(),
                      Text(
                        '$count',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: isSel ? Colors.white : RmTheme.textPrimary,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    _stageCode(s),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.6,
                      color: isSel
                          ? Colors.white.withValues(alpha: 0.75)
                          : RmTheme.textSecondary,
                    ),
                  ),
                  Text(
                    _stageName(s),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: isSel ? Colors.white : RmTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          )
              .animate(delay: (40 * i).ms)
              .fadeIn(duration: 300.ms)
              .slideX(begin: 0.2, end: 0);
        },
      ),
    );
  }
}

class _StaffCard extends StatefulWidget {
  const _StaffCard({super.key, required this.staff, required this.onTap});

  final StaffRow staff;
  final VoidCallback onTap;

  @override
  State<_StaffCard> createState() => _StaffCardState();
}

class _StaffCardState extends State<_StaffCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final s = widget.staff;
    final stageColor = _stageColor(s.pipelineStage);
    final (pvLabel, pvColor) = _pv(s.pvStatus);

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: (_) => setState(() => _pressed = true),
        onTapUp: (_) => setState(() => _pressed = false),
        onTapCancel: () => setState(() => _pressed = false),
        onTap: widget.onTap,
        child: AnimatedScale(
          scale: _pressed ? 0.98 : 1,
          duration: 120.ms,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
              boxShadow: RmTheme.subtleShadow,
            ),
            child: Column(
              children: [
                Row(
                  children: [
                    // Avatar with a ring in the stage colour.
                    Container(
                      width: 48,
                      height: 48,
                      padding: const EdgeInsets.all(2),
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: stageColor, width: 2),
                      ),
                      child: Container(
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: stageColor.withValues(alpha: 0.12),
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          s.initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: stageColor,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.2,
                              color: RmTheme.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            s.staffCode,
                            style: GoogleFonts.robotoMono(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: RmTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      width: 32,
                      height: 32,
                      decoration: const BoxDecoration(
                        color: RmTheme.surfaceSecondary,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        size: 20,
                        color: RmTheme.electricBlue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _Tag(
                      icon: SeriesDisplay.icon(s.series),
                      label: _seriesName(s.series),
                      color: RmTheme.iconAccent,
                    ),
                    const SizedBox(width: 6),
                    _Tag(
                      icon: Icons.shield_rounded,
                      label: pvLabel,
                      color: pvColor,
                    ),
                    if (s.restrictedListFlag) ...[
                      const SizedBox(width: 6),
                      const _Tag(
                        icon: Icons.flag_rounded,
                        label: 'Flagged',
                        color: RmTheme.crimsonDanger,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _Tag extends StatelessWidget {
  const _Tag({required this.icon, required this.label, required this.color});

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Flexible(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: color),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: 110,
            height: 110,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: RmTheme.iconAccent.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 0.6, end: 1, duration: 1800.ms)
                    .fadeOut(duration: 1800.ms),
                Container(
                  width: 72,
                  height: 72,
                  decoration: const BoxDecoration(
                    color: RmTheme.iconAccentSoft,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: RmTheme.iconAccent),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 16),
          DsOutlineButton(
            label: actionLabel,
            icon: Icons.person_add_alt_1_rounded,
            isExpanded: false,
            onPressed: onAction,
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.96, end: 1);
  }
}
