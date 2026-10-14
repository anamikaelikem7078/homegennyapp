import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/exceptions/failures.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/navigation/ds_navigation.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';

/// Shared building blocks for the RM staff-detail and stage screens
/// (S2 verification, S2.5 assessment, S3 training, S4 agreements, invoice).

// ---------------------------------------------------------------------------
// Stage metadata
// ---------------------------------------------------------------------------

Color rmStageColor(String stage) => switch (stage) {
      PipelineStages.s1Intake => const Color(0xFF3B82F6),
      PipelineStages.s2Verify => const Color(0xFF0D9488),
      PipelineStages.s25Assess => const Color(0xFFD97706),
      PipelineStages.s3Train => const Color(0xFFF97316),
      PipelineStages.s4Agreements => const Color(0xFF1A56FF),
      PipelineStages.s5Deploy => const Color(0xFF10B981),
      PipelineStages.deferred => RmTheme.amberWarning,
      PipelineStages.terminal => RmTheme.crimsonDanger,
      _ => RmTheme.textSecondary,
    };

IconData rmStageIcon(String stage) => switch (stage) {
      PipelineStages.s1Intake => Icons.person_add_alt_rounded,
      PipelineStages.s2Verify => Icons.fact_check_rounded,
      PipelineStages.s25Assess => Icons.assignment_turned_in_rounded,
      PipelineStages.s3Train => Icons.school_rounded,
      PipelineStages.s4Agreements => Icons.edit_document,
      PipelineStages.s5Deploy => Icons.rocket_launch_rounded,
      PipelineStages.deferred => Icons.pause_circle_rounded,
      PipelineStages.terminal => Icons.block_rounded,
      _ => Icons.circle_rounded,
    };

/// "S2 · Verification" → "Verification".
String rmStageName(String stage) {
  final l = PipelineStages.label(stage);
  final i = l.indexOf('·');
  return i == -1 ? l : l.substring(i + 1).trim();
}

/// "S2 · Verification" → "S2".
String rmStageCode(String stage) {
  final l = PipelineStages.label(stage);
  final i = l.indexOf('·');
  return i == -1 ? '' : l.substring(0, i).trim();
}

/// Visual state of a step / track tile.
enum RmStepState { done, active, pending, warning, failed, locked }

Color rmStepColor(RmStepState s) => switch (s) {
      RmStepState.done => RmTheme.emeraldGreen,
      RmStepState.active => RmTheme.electricBlue,
      RmStepState.pending => RmTheme.iconAccent,
      RmStepState.warning => RmTheme.amberWarning,
      RmStepState.failed => RmTheme.crimsonDanger,
      RmStepState.locked => RmTheme.textSecondary,
    };

String rmTitleCase(String s) => s
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

// ---------------------------------------------------------------------------
// Scaffold
// ---------------------------------------------------------------------------

/// Light pinned app bar + scrolling body + optional sticky bottom action.
class RmStageScaffold extends StatelessWidget {
  const RmStageScaffold({
    super.key,
    required this.title,
    required this.body,
    this.stageCode,
    this.stageColor,
    this.bottom,
    this.onRefresh,
    this.actions = const [],
    this.onBack,
  });

  /// Custom back action; defaults to popping the route.
  final VoidCallback? onBack;

  final String title;

  /// Small chip next to the title (e.g. "S2").
  final String? stageCode;
  final Color? stageColor;

  /// Children of the scrolling body.
  final List<Widget> body;

  /// Sticky footer (usually the advance button).
  final Widget? bottom;
  final Future<void> Function()? onRefresh;
  final List<Widget> actions;

  @override
  Widget build(BuildContext context) {
    final color = stageColor ?? RmTheme.electricBlue;
    final scroll = CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverAppBar(
          pinned: true,
          backgroundColor: RmTheme.offWhite,
          surfaceTintColor: Colors.transparent,
          scrolledUnderElevation: 0,
          systemOverlayStyle: SystemUiOverlayStyle.dark,
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          leadingWidth: 64,
          leading: Padding(
            padding: const EdgeInsets.only(left: 20),
            child: DsBackButton(
              onPressed: onBack ?? () => Navigator.of(context).maybePop(),
            ),
          ),
          titleSpacing: 8,
          title: Row(
            children: [
              Flexible(
                child: Text(
                  title,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: RmTheme.textPrimary,
                  ),
                ),
              ),
              if (stageCode != null && stageCode!.isNotEmpty) ...[
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    stageCode!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w800,
                      color: color,
                    ),
                  ),
                ),
              ],
            ],
          ),
          actions: [...actions, const SizedBox(width: 12)],
        ),
        SliverPadding(
          padding: EdgeInsets.fromLTRB(20, 4, 20, bottom == null ? 40 : 24),
          sliver: SliverList.list(
            children: body
                .animate(interval: 60.ms)
                .fadeIn(duration: 380.ms)
                .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
          ),
        ),
      ],
    );

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: onRefresh == null
          ? scroll
          : RefreshIndicator(
              color: RmTheme.electricBlue,
              onRefresh: onRefresh!,
              child: scroll,
            ),
      bottomNavigationBar: bottom == null
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: RmTheme.navy.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: SafeArea(top: false, child: bottom!),
            )
              .animate()
              .slideY(begin: 1, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
    );
  }
}

// ---------------------------------------------------------------------------
// Staff banner
// ---------------------------------------------------------------------------

/// Gradient staff card: avatar, name, code · series, stage pill and an
/// optional six-step stage tracker.
class RmStaffBanner extends StatelessWidget {
  const RmStaffBanner({
    super.key,
    required this.staff,
    this.showTracker = true,
    this.extra,
  });

  final StaffRow staff;
  final bool showTracker;

  /// Optional row under the name (e.g. mobile number chips).
  final Widget? extra;

  @override
  Widget build(BuildContext context) {
    final stage = staff.pipelineStage;
    final flow = PipelineStages.flowFor(stage);
    final current = flow.indexOf(stage);

    return Container(
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
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      padding: const EdgeInsets.all(2.5),
                      decoration: const BoxDecoration(
                        shape: BoxShape.circle,
                        gradient: SweepGradient(
                          colors: [
                            Color(0xFFFFD84D),
                            RmTheme.iconAccent,
                            Color(0xFFFFD84D),
                          ],
                        ),
                      ),
                      child: Container(
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        alignment: Alignment.center,
                        child: Text(
                          staff.initials,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 21,
                            fontWeight: FontWeight.w800,
                            color: RmTheme.electricBlue,
                          ),
                        ),
                      ),
                    ).animate().scaleXY(
                          begin: 0.6,
                          end: 1,
                          duration: 550.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            staff.fullName,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.4,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            '${staff.staffCode} · ${StaffSeries.label(staff.series)}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w600,
                              color: Colors.white.withValues(alpha: 0.78),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (extra != null) ...[
                  const SizedBox(height: 12),
                  extra!,
                ],
                const SizedBox(height: 14),
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(rmStageIcon(stage), size: 14, color: rmStageColor(stage)),
                          const SizedBox(width: 5),
                          Text(
                            PipelineStages.label(stage),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w800,
                              color: rmStageColor(stage),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    if (current >= 0)
                      Text(
                        'Step ${current + 1} of ${flow.length}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.8),
                        ),
                      ),
                  ],
                ),
                if (showTracker && current >= 0) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      for (var i = 0; i < flow.length; i++) ...[
                        Expanded(
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: Stack(
                              children: [
                                Container(
                                  height: 6,
                                  color: Colors.white.withValues(alpha: 0.18),
                                ),
                                if (i <= current)
                                  Container(
                                    height: 6,
                                    color: i == current
                                        ? const Color(0xFFFFD84D)
                                        : Colors.white,
                                  )
                                      .animate(delay: (120 * i).ms)
                                      .scaleX(
                                        begin: 0,
                                        end: 1,
                                        alignment: Alignment.centerLeft,
                                        duration: 400.ms,
                                      ),
                              ],
                            ),
                          ),
                        ),
                        if (i < flow.length - 1)
                          const SizedBox(width: 5),
                      ],
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Translucent info chip for the banner's [RmStaffBanner.extra] slot.
class RmBannerChip extends StatelessWidget {
  const RmBannerChip({super.key, required this.icon, required this.label});
  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: const Color(0xFFFFD84D)),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11.5,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Section title / notes / tiles
// ---------------------------------------------------------------------------

class RmSectionTitle extends StatelessWidget {
  const RmSectionTitle({super.key, required this.title, this.trailing});
  final String title;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 22, bottom: 12),
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
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: RmTheme.textPrimary,
              ),
            ),
          ),
          if (trailing != null) trailing!,
        ],
      ),
    );
  }
}

enum RmNoteTone { info, warning, success, danger }

/// Soft tinted note with an icon.
class RmNote extends StatelessWidget {
  const RmNote({
    super.key,
    required this.text,
    this.title,
    this.tone = RmNoteTone.info,
  });

  final String? title;
  final String text;
  final RmNoteTone tone;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = switch (tone) {
      RmNoteTone.info => (RmTheme.electricBlue, Icons.info_rounded),
      RmNoteTone.warning => (RmTheme.amberWarning, Icons.lightbulb_rounded),
      RmNoteTone.success => (RmTheme.emeraldGreen, Icons.check_circle_rounded),
      RmNoteTone.danger => (RmTheme.crimsonDanger, Icons.error_rounded),
    };
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, size: 18, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (title != null)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 2),
                    child: Text(
                      title!,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                  ),
                Text(
                  text,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
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

/// Status pill used on tiles.
class RmStatusPill extends StatelessWidget {
  const RmStatusPill({super.key, required this.label, required this.color});
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 6,
            height: 6,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

/// Tappable step / track tile: icon tile, title, subtitle, status pill.
class RmStepTile extends StatefulWidget {
  const RmStepTile({
    super.key,
    required this.icon,
    required this.title,
    required this.state,
    this.subtitle,
    this.statusLabel,
    this.onTap,
    this.code,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final String? statusLabel;
  final RmStepState state;
  final VoidCallback? onTap;

  /// Small code shown before the title (e.g. "S2").
  final String? code;

  @override
  State<RmStepTile> createState() => _RmStepTileState();
}

class _RmStepTileState extends State<RmStepTile> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final color = rmStepColor(widget.state);
    final done = widget.state == RmStepState.done;
    final locked = widget.onTap == null || widget.state == RmStepState.locked;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GestureDetector(
        onTapDown: locked ? null : (_) => setState(() => _down = true),
        onTapUp: locked ? null : (_) => setState(() => _down = false),
        onTapCancel: locked ? null : () => setState(() => _down = false),
        onTap: locked
            ? null
            : () {
                HapticFeedback.selectionClick();
                widget.onTap!();
              },
        child: AnimatedScale(
          scale: _down ? 0.98 : 1,
          duration: 120.ms,
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: done ? RmTheme.emeraldGreen.withValues(alpha: 0.05) : Colors.white,
              borderRadius: BorderRadius.circular(22),
              border: Border.all(
                color: done
                    ? RmTheme.emeraldGreen.withValues(alpha: 0.35)
                    : widget.state == RmStepState.active
                        ? RmTheme.electricBlue.withValues(alpha: 0.4)
                        : RmTheme.borderSubtle.withValues(alpha: 0.7),
                width: widget.state == RmStepState.active ? 1.5 : 1,
              ),
              boxShadow: RmTheme.subtleShadow,
            ),
            child: Row(
              children: [
                Container(
                  width: 46,
                  height: 46,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    done ? Icons.check_rounded : widget.icon,
                    color: color,
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          if (widget.code != null) ...[
                            Text(
                              widget.code!,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                            const SizedBox(width: 6),
                          ],
                          Flexible(
                            child: Text(
                              widget.title,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                fontWeight: FontWeight.w800,
                                letterSpacing: -0.2,
                                color: RmTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                      if (widget.subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          widget.subtitle!,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            height: 1.35,
                            fontWeight: FontWeight.w500,
                            color: RmTheme.textSecondary,
                          ),
                        ),
                      ],
                      if (widget.statusLabel != null) ...[
                        const SizedBox(height: 8),
                        RmStatusPill(label: widget.statusLabel!, color: color),
                      ],
                    ],
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  width: 30,
                  height: 30,
                  decoration: const BoxDecoration(
                    color: RmTheme.surfaceSecondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    locked ? Icons.lock_rounded : Icons.chevron_right_rounded,
                    size: locked ? 15 : 20,
                    color: locked ? RmTheme.textSecondary : RmTheme.electricBlue,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Animated empty / error block with a pulsing halo.
class RmEmptyBlock extends StatelessWidget {
  const RmEmptyBlock({
    super.key,
    required this.icon,
    required this.title,
    required this.message,
    this.color = RmTheme.iconAccent,
    this.action,
  });

  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Widget? action;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 26, 20, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
      ),
      child: Column(
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
                    border: Border.all(color: color.withValues(alpha: 0.25), width: 2),
                  ),
                )
                    .animate(onPlay: (c) => c.repeat())
                    .scaleXY(begin: 0.6, end: 1, duration: 1800.ms)
                    .fadeOut(duration: 1800.ms),
                Container(
                  width: 72,
                  height: 72,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(icon, size: 34, color: color),
                ).animate().scaleXY(
                      begin: 0.5,
                      end: 1,
                      duration: 600.ms,
                      curve: Curves.elasticOut,
                    ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Text(
            title,
            textAlign: TextAlign.center,
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
              height: 1.45,
              fontWeight: FontWeight.w500,
              color: RmTheme.textSecondary,
            ),
          ),
          if (action != null) ...[
            const SizedBox(height: 18),
            action!,
          ],
        ],
      ),
    );
  }
}

/// Footer hint under an advance button.
class RmHint extends StatelessWidget {
  const RmHint({super.key, required this.text, this.done = false});
  final String text;
  final bool done;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            done ? Icons.check_circle_rounded : Icons.lock_rounded,
            size: 14,
            color: done ? RmTheme.emeraldGreen : RmTheme.textSecondary,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              text,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: done ? RmTheme.emeraldGreen : RmTheme.textSecondary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Turns an [AsyncValue] into body widgets for [RmStageScaffold]: spinner
/// while loading, a friendly error block with retry, or [builder]'s output.
List<Widget> rmAsyncBody<T>(
  AsyncValue<T> value, {
  required VoidCallback onRetry,
  required List<Widget> Function(T data) builder,
}) {
  return value.when(
    loading: () => const [
      Padding(
        padding: EdgeInsets.symmetric(vertical: 60),
        child: Center(child: CircularProgressIndicator()),
      ),
    ],
    error: (e, _) => [
      RmEmptyBlock(
        icon: Icons.cloud_off_rounded,
        color: RmTheme.crimsonDanger,
        title: 'Something went wrong',
        message: e is Failure ? e.message : 'Please try again.',
        action: DsGradientButton(
          label: 'Retry',
          icon: Icons.refresh_rounded,
          isExpanded: false,
          onPressed: onRetry,
        ),
      ),
    ],
    data: builder,
  );
}
