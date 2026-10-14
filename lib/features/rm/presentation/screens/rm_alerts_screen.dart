import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../design_system/design_system.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

/// Incidents — repurposed from the former "Alerts" tab, which had no
/// backend equivalent (hardcoded mock notification list). Incidents
/// (`GET`/`POST /rm/incidents`) is a real, required RM module needing a
/// home; this reuses the existing bottom-nav slot.
class RmAlertsScreen extends ConsumerStatefulWidget {
  const RmAlertsScreen({super.key});

  @override
  ConsumerState<RmAlertsScreen> createState() => _RmAlertsScreenState();
}

class _RmAlertsScreenState extends ConsumerState<RmAlertsScreen> {
  /// Selected status filter; null = all.
  String? _status;

  void _showCreateSheet() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => _CreateIncidentSheet(ref: ref),
    );
  }

  void _showDetails(IncidentRow incident) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _IncidentDetailSheet(incident: incident),
    );
  }

  @override
  Widget build(BuildContext context) {
    final incidentsAsync = ref.watch(rmIncidentsProvider(null));
    final all = incidentsAsync.valueOrNull ?? const <IncidentRow>[];
    final open = all.where((i) => _isOpen(i.status)).length;
    final resolved = all.length - open;

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      floatingActionButton: Padding(
        padding: const EdgeInsets.only(bottom: 4),
        child: DsFab(
          icon: Icons.add_rounded,
          label: 'New incident',
          onPressed: _showCreateSheet,
        ),
      ),
      body: RefreshIndicator(
        color: RmTheme.electricBlue,
        onRefresh: () async => ref.invalidate(rmIncidentsProvider(null)),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _IncidentsAppBar(
              onAdd: _showCreateSheet,
              onRefresh: () => ref.invalidate(rmIncidentsProvider(null)),
            ),
            SliverToBoxAdapter(
              child: _SummaryCard(
                loaded: incidentsAsync.hasValue,
                open: open,
                resolved: resolved,
              ),
            ),
            ...incidentsAsync.when(
              loading: () => [
                const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyState(
                    icon: Icons.cloud_off_rounded,
                    color: RmTheme.crimsonDanger,
                    title: 'Couldn\'t load incidents',
                    message: 'Check your connection and try again.',
                    actionLabel: 'Retry',
                    onAction: () => ref.invalidate(rmIncidentsProvider(null)),
                  ),
                ),
              ],
              data: (incidents) => _buildList(incidents),
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 3),
    );
  }

  List<Widget> _buildList(List<IncidentRow> incidents) {
    if (incidents.isEmpty) {
      return [
        SliverFillRemaining(
          hasScrollBody: false,
          child: _EmptyState(
            icon: Icons.verified_user_rounded,
            color: RmTheme.emeraldGreen,
            title: 'All clear!',
            message: 'No incidents on file. Everything is running smoothly.',
            actionLabel: 'File an incident',
            onAction: _showCreateSheet,
          ),
        ),
      ];
    }

    final statuses = <String>{
      for (final i in incidents) i.status.toUpperCase(),
    }.toList()
      ..sort();
    final visible = _status == null
        ? incidents
        : incidents.where((i) => i.status.toUpperCase() == _status).toList();

    return [
      SliverToBoxAdapter(
        child: SizedBox(
          height: 64,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 8),
            children: [
              _FilterChip(
                label: 'All',
                count: incidents.length,
                selected: _status == null,
                onTap: () => setState(() => _status = null),
              ),
              for (final s in statuses)
                _FilterChip(
                  label: _titleCase(s),
                  count: incidents
                      .where((i) => i.status.toUpperCase() == s)
                      .length,
                  selected: _status == s,
                  onTap: () => setState(() => _status = s),
                ),
            ],
          ),
        ),
      ),
      SliverPadding(
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 4),
        sliver: SliverToBoxAdapter(
          child: Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: RmTheme.iconAccent,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Recent incidents',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.3,
                  color: RmTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${visible.length}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: RmTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
      SliverPadding(
        // Leaves room for the FAB and the floating bottom nav.
        padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
        sliver: SliverList.builder(
          itemCount: visible.length,
          itemBuilder: (context, index) {
            final incident = visible[index];
            return _IncidentCard(
              key: ValueKey(incident.id),
              incident: incident,
              onTap: () => _showDetails(incident),
            )
                .animate(delay: (60 * index).ms)
                .fadeIn(duration: 380.ms)
                .slideY(begin: 0.15, end: 0, curve: Curves.easeOutCubic);
          },
        ),
      ),
    ];
  }
}

// ---------------------------------------------------------------------------
// Helpers
// ---------------------------------------------------------------------------

bool _isOpen(String status) {
  final s = status.toUpperCase();
  return !(s == 'RESOLVED' || s == 'CLOSED' || s == 'DISMISSED');
}

String _titleCase(String s) {
  final words = s.replaceAll('_', ' ').toLowerCase().split(' ');
  return words
      .where((w) => w.isNotEmpty)
      .map((w) => w[0].toUpperCase() + w.substring(1))
      .join(' ');
}

String _sentenceCase(String s) =>
    s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

String? _formatDate(String? iso) {
  if (iso == null) return null;
  final dt = DateTime.tryParse(iso)?.toLocal();
  if (dt == null) return null;
  final now = DateTime.now();
  final diff = now.difference(dt);
  if (diff.inMinutes < 1) return 'Just now';
  if (diff.inHours < 1) return '${diff.inMinutes}m ago';
  if (diff.inDays < 1) return '${diff.inHours}h ago';
  if (diff.inDays < 7) return '${diff.inDays}d ago';
  return DateFormat('d MMM yyyy').format(dt);
}

IconData _iconFor(String type) => switch (type) {
      IncidentTypes.clientComplaint => Icons.sentiment_dissatisfied_rounded,
      IncidentTypes.staffMisconduct => Icons.person_off_rounded,
      IncidentTypes.safetyIssue => Icons.warning_amber_rounded,
      IncidentTypes.attendanceFraud => Icons.gpp_bad_rounded,
      IncidentTypes.drivingViolation => Icons.car_crash_rounded,
      IncidentTypes.lateExit => Icons.exit_to_app_rounded,
      _ => Icons.report_problem_rounded,
    };

/// (background, foreground) for a status pill.
(Color, Color) _statusColors(String status) {
  return switch (status.toUpperCase()) {
    'OPEN' => (const Color(0xFFFEE2E2), RmTheme.crimsonDanger),
    'IN_PROGRESS' || 'INVESTIGATING' || 'UNDER_REVIEW' => (
        const Color(0xFFFEF3C7),
        const Color(0xFFB45309),
      ),
    'RESOLVED' || 'CLOSED' => (const Color(0xFFDCFCE7), const Color(0xFF15803D)),
    _ => (const Color(0xFFE8EEFF), RmTheme.electricBlue),
  };
}

// ---------------------------------------------------------------------------
// Widgets
// ---------------------------------------------------------------------------

/// Pinned, light app bar: orange icon tile + bold title, refresh and add.
class _IncidentsAppBar extends StatelessWidget {
  const _IncidentsAppBar({required this.onAdd, required this.onRefresh});

  final VoidCallback onAdd;
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return SliverAppBar(
      pinned: true,
      automaticallyImplyLeading: false,
      backgroundColor: RmTheme.offWhite,
      surfaceTintColor: Colors.transparent,
      scrolledUnderElevation: 0,
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      toolbarHeight: 76,
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
              Icons.shield_rounded,
              color: RmTheme.iconAccent,
              size: 24,
            ),
          )
              .animate()
              .scaleXY(begin: 0.5, end: 1, duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Incidents',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  'Safety desk · Track & resolve',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            )
                .animate()
                .fadeIn(duration: 350.ms)
                .slideX(begin: -0.08, end: 0, curve: Curves.easeOutCubic),
          ),
        ],
      ),
      actions: [
        _RefreshButton(onPressed: onRefresh),
        const SizedBox(width: 10),
        _RoundButton(
          onTap: onAdd,
          gradient: const LinearGradient(
            colors: [Color(0xFF2F6BFF), Color(0xFF1238B8)],
          ),
          shadow: RmTheme.electricBlue.withValues(alpha: 0.35),
          child: const Icon(Icons.add_rounded, color: Colors.white, size: 24),
        ),
        const SizedBox(width: 20),
      ],
    );
  }
}

class _RoundButton extends StatelessWidget {
  const _RoundButton({
    required this.onTap,
    required this.child,
    this.gradient,
    this.shadow,
  });

  final VoidCallback onTap;
  final Widget child;
  final Gradient? gradient;
  final Color? shadow;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        onTap();
      },
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: gradient,
          color: gradient == null ? Colors.white : null,
          border: gradient == null
              ? Border.all(color: RmTheme.borderSubtle)
              : null,
          boxShadow: [
            BoxShadow(
              color: shadow ?? const Color(0x0F0F172A),
              blurRadius: 14,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        alignment: Alignment.center,
        child: child,
      ),
    );
  }
}

/// Refresh button whose icon spins once per tap.
class _RefreshButton extends StatefulWidget {
  const _RefreshButton({required this.onPressed});
  final VoidCallback onPressed;

  @override
  State<_RefreshButton> createState() => _RefreshButtonState();
}

class _RefreshButtonState extends State<_RefreshButton> {
  double _turns = 0;

  @override
  Widget build(BuildContext context) {
    return _RoundButton(
      onTap: () {
        setState(() => _turns += 1);
        widget.onPressed();
      },
      child: AnimatedRotation(
        turns: _turns,
        duration: 600.ms,
        curve: Curves.easeOutCubic,
        child: const Icon(
          Icons.refresh_rounded,
          color: RmTheme.textPrimary,
          size: 22,
        ),
      ),
    );
  }
}

/// Gradient summary card: resolution-rate ring + open / resolved / total.
class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.loaded,
    required this.open,
    required this.resolved,
  });

  final bool loaded;
  final int open;
  final int resolved;

  @override
  Widget build(BuildContext context) {
    final total = open + resolved;
    final rate = total == 0 ? 0.0 : resolved / total;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 0),
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
          // Decorative glow circles.
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
          Positioned(
            bottom: -60,
            left: -40,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.06),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(18),
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
                            'Resolution rate',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                          const SizedBox(height: 2),
                          TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: loaded ? rate : 0),
                            duration: 1100.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => Text(
                              loaded ? '${(v * 100).round()}%' : '—',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -1,
                                color: Colors.white,
                              ),
                            ),
                          ),
                          Text(
                            loaded
                                ? '$resolved of $total incidents closed'
                                : 'Loading…',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.75),
                            ),
                          ),
                        ],
                      ),
                    ),
                    _RateRing(value: loaded ? rate : 0),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: _MiniStat(
                        label: 'Open',
                        value: loaded ? open : null,
                        dot: const Color(0xFFFF8A8A),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Resolved',
                        value: loaded ? resolved : null,
                        dot: const Color(0xFF4ADE80),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _MiniStat(
                        label: 'Total',
                        value: loaded ? total : null,
                        dot: const Color(0xFFFFD84D),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 450.ms)
        .slideY(begin: 0.12, end: 0, curve: Curves.easeOutCubic);
  }
}

class _RateRing extends StatelessWidget {
  const _RateRing({required this.value});
  final double value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 84,
      height: 84,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: value),
        duration: 1100.ms,
        curve: Curves.easeOutCubic,
        builder: (_, v, _) => Stack(
          alignment: Alignment.center,
          children: [
            SizedBox.expand(
              child: CircularProgressIndicator(
                value: v,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                color: const Color(0xFFFFD84D),
                backgroundColor: Colors.white.withValues(alpha: 0.15),
              ),
            ),
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(15),
              ),
              child: const Icon(
                Icons.verified_user_rounded,
                color: RmTheme.iconAccent,
                size: 24,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  const _MiniStat({required this.label, required this.value, required this.dot});

  final String label;
  final int? value;
  final Color dot;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 7,
                height: 7,
                decoration: BoxDecoration(color: dot, shape: BoxShape.circle),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.75),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: (value ?? 0).toDouble()),
            duration: 900.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              value == null ? '—' : '${v.round()}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.status});
  final String status;

  @override
  Widget build(BuildContext context) {
    final (bg, fg) = _statusColors(status);
    final open = _isOpen(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: fg, shape: BoxShape.circle),
          )
              .animate(
                onPlay: (c) => open ? c.repeat(reverse: true) : c.stop(),
              )
              .fadeOut(duration: 700.ms, begin: 1),
          const SizedBox(width: 5),
          Text(
            _titleCase(status),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: fg,
            ),
          ),
        ],
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.count,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final int count;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: 220.ms,
          curve: Curves.easeOut,
          padding: const EdgeInsets.symmetric(horizontal: 14),
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
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: selected ? Colors.white : RmTheme.textPrimary,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                decoration: BoxDecoration(
                  color: selected
                      ? Colors.white.withValues(alpha: 0.22)
                      : RmTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '$count',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w800,
                    color: selected ? Colors.white : RmTheme.textSecondary,
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

class _IncidentCard extends StatefulWidget {
  const _IncidentCard({super.key, required this.incident, required this.onTap});

  final IncidentRow incident;
  final VoidCallback onTap;

  @override
  State<_IncidentCard> createState() => _IncidentCardState();
}

class _IncidentCardState extends State<_IncidentCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final i = widget.incident;
    final when = _formatDate(i.createdAt);
    final open = _isOpen(i.status);

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
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
              boxShadow: RmTheme.subtleShadow,
            ),
            clipBehavior: Clip.antiAlias,
            child: IntrinsicHeight(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // Severity strip: red while open, green once resolved.
                  Container(
                    width: 5,
                    color: open ? RmTheme.crimsonDanger : RmTheme.emeraldGreen,
                  ),
                  Expanded(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: RmTheme.iconAccentSoft,
                                  borderRadius: BorderRadius.circular(14),
                                ),
                                child: Icon(
                                  _iconFor(i.type),
                                  color: RmTheme.iconAccent,
                                  size: 22,
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _sentenceCase(i.title),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontWeight: FontWeight.w800,
                                        fontSize: 15.5,
                                        letterSpacing: -0.2,
                                        color: RmTheme.textPrimary,
                                      ),
                                    ),
                                    const SizedBox(height: 3),
                                    Text(
                                      IncidentTypes.label(i.type),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 12.5,
                                        fontWeight: FontWeight.w600,
                                        color: RmTheme.textSecondary,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(width: 8),
                              _StatusPill(status: i.status),
                            ],
                          ),
                          if (i.description?.trim().isNotEmpty ?? false) ...[
                            const SizedBox(height: 10),
                            Text(
                              i.description!.trim(),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                height: 1.4,
                                fontWeight: FontWeight.w500,
                                color: RmTheme.textSecondary,
                              ),
                            ),
                          ],
                          const SizedBox(height: 12),
                          Container(height: 1, color: RmTheme.surfaceSecondary),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              if (i.staff != null) ...[
                                _MetaChip(
                                  icon: Icons.person_rounded,
                                  label: i.staff!.fullName,
                                ),
                                const SizedBox(width: 8),
                              ],
                              if (when != null)
                                _MetaChip(
                                  icon: Icons.schedule_rounded,
                                  label: when,
                                  flexible: false,
                                ),
                              const Spacer(),
                              Text(
                                'Details',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w800,
                                  color: RmTheme.electricBlue,
                                ),
                              ),
                              const Icon(
                                Icons.chevron_right_rounded,
                                size: 18,
                                color: RmTheme.electricBlue,
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _MetaChip extends StatelessWidget {
  const _MetaChip({
    required this.icon,
    required this.label,
    this.flexible = true,
  });
  final IconData icon;
  final String label;

  /// Whether the chip may shrink (and ellipsize) to fit.
  final bool flexible;

  @override
  Widget build(BuildContext context) {
    final chip = Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(
          color: RmTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: RmTheme.iconAccent),
            const SizedBox(width: 4),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: RmTheme.textPrimary,
                ),
              ),
            ),
          ],
        ),
      );
    return flexible ? Flexible(child: chip) : chip;
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({
    required this.icon,
    required this.color,
    required this.title,
    required this.message,
    required this.actionLabel,
    required this.onAction,
  });

  final IconData icon;
  final Color color;
  final String title;
  final String message;
  final String actionLabel;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(32, 32, 32, 120),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 150,
            height: 150,
            child: Stack(
              alignment: Alignment.center,
              children: [
                Container(
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withValues(alpha: 0.25),
                      width: 2,
                    ),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 0.6, end: 1, duration: 1800.ms)
                    .fadeOut(duration: 1800.ms),
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 48, color: color),
                )
                    .animate()
                    .scaleXY(
                      begin: 0.5,
                      end: 1,
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 18),
          Text(
            title,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            message,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: RmTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 20),
          DsOutlineButton(
            label: actionLabel,
            icon: Icons.add_rounded,
            isExpanded: false,
            onPressed: onAction,
          ),
        ]
            .animate(interval: 80.ms)
            .fadeIn(duration: 400.ms)
            .slideY(begin: 0.2, end: 0),
      ),
    );
  }
}

/// Read-only detail sheet for one incident.
class _IncidentDetailSheet extends StatelessWidget {
  const _IncidentDetailSheet({required this.incident});
  final IncidentRow incident;

  @override
  Widget build(BuildContext context) {
    final i = incident;
    final when = _formatDate(i.createdAt);

    Widget section(String label, String value, IconData icon) => Container(
          width: double.infinity,
          margin: const EdgeInsets.only(bottom: 10),
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: RmTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, size: 18, color: RmTheme.iconAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        height: 1.45,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.85,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RmTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Row(
              children: [
                Container(
                  width: 52,
                  height: 52,
                  decoration: BoxDecoration(
                    color: RmTheme.iconAccentSoft,
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Icon(
                    _iconFor(i.type),
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
                        _sentenceCase(i.title),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        IncidentTypes.label(i.type),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
                _StatusPill(status: i.status),
              ],
            ),
            const SizedBox(height: 20),
            if (i.staff != null)
              section(
                'Staff',
                '${i.staff!.fullName} · ${i.staff!.staffCode}',
                Icons.person_rounded,
              ),
            if (when != null) section('Reported', when, Icons.schedule_rounded),
            section(
              'Description',
              (i.description?.trim().isNotEmpty ?? false)
                  ? i.description!.trim()
                  : 'No description provided.',
              Icons.notes_rounded,
            ),
            if (i.resolution?.trim().isNotEmpty ?? false)
              section('Resolution', i.resolution!.trim(), Icons.task_alt_rounded),
            if (i.evidenceUrls.isNotEmpty)
              section(
                'Evidence',
                '${i.evidenceUrls.length} file${i.evidenceUrls.length == 1 ? '' : 's'} attached',
                Icons.attach_file_rounded,
              ),
            const SizedBox(height: 8),
            DsOutlineButton(
              label: 'Close',
              onPressed: () => Navigator.of(context).pop(),
            ),
          ]
              .animate(interval: 50.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0),
        ),
      ),
    );
  }
}

class _CreateIncidentSheet extends StatefulWidget {
  const _CreateIncidentSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateIncidentSheet> createState() => _CreateIncidentSheetState();
}

class _CreateIncidentSheetState extends State<_CreateIncidentSheet> {
  String _type = IncidentTypes.clientComplaint;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _staffIdController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      HapticFeedback.mediumImpact();
      DsSnackBar.show(
        context,
        message: 'Title is required',
        type: DsSnackBarType.warning,
      );
      return;
    }
    setState(() => _submitting = true);
    final result = await widget.ref.read(rmRepositoryProvider).createIncident({
      'type': _type,
      'title': _titleController.text.trim(),
      if (_descController.text.trim().isNotEmpty) 'description': _descController.text.trim(),
      if (_staffIdController.text.trim().isNotEmpty) 'staff_id': _staffIdController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (_) {
        widget.ref.invalidate(rmIncidentsProvider(null));
        widget.ref.invalidate(rmDashboardProvider);
        DsSnackBar.show(
          context,
          message: 'Incident filed',
          type: DsSnackBarType.success,
        );
        Navigator.of(context).pop();
      },
      onError: (f) => DsSnackBar.show(
        context,
        message: f.message,
        type: DsSnackBarType.error,
      ),
    );
  }

  Widget _label(String text, {bool optional = false}) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Row(
          children: [
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: RmTheme.textPrimary,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: RmTheme.electricBlue,
                  ),
                ),
              ),
            ],
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final fieldStyle = GoogleFonts.plusJakartaSans(
      fontSize: 15,
      fontWeight: FontWeight.w600,
      color: RmTheme.textPrimary,
    );

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.sizeOf(context).height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: EdgeInsets.only(
        left: 20,
        right: 20,
        top: 14,
        bottom: MediaQuery.of(context).viewInsets.bottom + 20,
      ),
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: RmTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 18),

            // ── Header ──
            Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: RmTheme.iconAccentSoft,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.report_rounded,
                    color: RmTheme.iconAccent,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'New incident',
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          fontSize: 20,
                          letterSpacing: -0.3,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      Text(
                        'Log an issue for follow-up',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 22),

            // ── Type chips ──
            _label('What happened?'),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in IncidentTypes.all)
                  _TypeChip(
                    label: IncidentTypes.label(t),
                    icon: _iconFor(t),
                    selected: _type == t,
                    onTap: () {
                      HapticFeedback.selectionClick();
                      setState(() => _type = t);
                    },
                  ),
              ],
            ),
            const SizedBox(height: 18),

            _label('Title'),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              style: fieldStyle,
              decoration: const InputDecoration(
                hintText: 'Short summary of the incident',
                prefixIcon: Icon(Icons.title_rounded),
              ),
            ),
            const SizedBox(height: 14),

            _label('Description', optional: true),
            TextFormField(
              controller: _descController,
              maxLines: 3,
              textCapitalization: TextCapitalization.sentences,
              style: fieldStyle,
              decoration: const InputDecoration(
                hintText: 'What happened, when and where?',
              ),
            ),
            const SizedBox(height: 14),

            _label('Staff ID', optional: true),
            TextFormField(
              controller: _staffIdController,
              style: fieldStyle,
              decoration: const InputDecoration(
                hintText: 'e.g. HG-STF-0012',
                prefixIcon: Icon(Icons.badge_outlined),
              ),
            ),
            const SizedBox(height: 24),

            DsGradientButton(
              label: 'File incident',
              isLoading: _submitting,
              onPressed: _submitting ? null : _submit,
            ),
          ]
              .animate(interval: 40.ms)
              .fadeIn(duration: 300.ms)
              .slideY(begin: 0.15, end: 0),
        ),
      ),
    );
  }
}

class _TypeChip extends StatelessWidget {
  const _TypeChip({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFE8EEFF) : RmTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(
            color: selected ? RmTheme.electricBlue : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 16, color: RmTheme.iconAccent),
            const SizedBox(width: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontWeight: FontWeight.w700,
                color: selected ? RmTheme.electricBlue : RmTheme.textPrimary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
