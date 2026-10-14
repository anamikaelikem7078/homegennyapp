import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';
import '../widgets/rm_stage_ui.dart';

/// Shift Review — repurposed from the former "Tasks" tab, which had no
/// backend equivalent of its own (hardcoded mock task list). Shift review
/// (`GET /rm/shifts`, `PATCH /rm/shifts/:id/review`) is a real, required RM
/// module that needed a home; this reuses the existing bottom-nav slot.
class RmTasksScreen extends ConsumerStatefulWidget {
  const RmTasksScreen({super.key});

  @override
  ConsumerState<RmTasksScreen> createState() => _RmTasksScreenState();
}

const _filters = <(String, String?)>[
  ('Pending', 'PENDING'),
  ('Approved', 'APPROVED'),
  ('Flagged', 'FLAGGED'),
  ('Rejected', 'REJECTED'),
  ('All', null),
];

Color _shiftStatusColor(String status) => switch (status) {
      'APPROVED' => RmTheme.emeraldGreen,
      'REJECTED' => RmTheme.crimsonDanger,
      'FLAGGED' => RmTheme.amberWarning,
      _ => RmTheme.electricBlue,
    };

IconData _shiftStatusIcon(String status) => switch (status) {
      'APPROVED' => Icons.check_circle_rounded,
      'REJECTED' => Icons.cancel_rounded,
      'FLAGGED' => Icons.flag_rounded,
      _ => Icons.hourglass_top_rounded,
    };

class _RmTasksScreenState extends ConsumerState<RmTasksScreen> {
  String? _statusFilter = 'PENDING';

  void _refresh() {
    ref.invalidate(rmShiftsProvider(_statusFilter));
    ref.invalidate(rmShiftsProvider('PENDING'));
  }

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(rmShiftsProvider(_statusFilter));
    final pendingAsync = ref.watch(rmShiftsProvider('PENDING'));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: RefreshIndicator(
        color: RmTheme.electricBlue,
        onRefresh: () async => _refresh(),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            _ShiftsAppBar(onRefresh: _refresh),
            SliverToBoxAdapter(
              child: _SummaryCard(
                pending: pendingAsync.valueOrNull?.length,
                shown: shiftsAsync.valueOrNull?.length,
                filterLabel: _filters.firstWhere((f) => f.$2 == _statusFilter).$1,
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _FilterHeader(
                selected: _statusFilter,
                onSelected: (v) => setState(() => _statusFilter = v),
              ),
            ),
            ...shiftsAsync.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: CircularProgressIndicator()),
                ),
              ],
              error: (e, _) => [
                SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                  sliver: SliverToBoxAdapter(
                    child: RmEmptyBlock(
                      icon: Icons.cloud_off_rounded,
                      color: RmTheme.crimsonDanger,
                      title: 'Couldn\'t load shifts',
                      message: 'Check your connection and try again.',
                      action: DsGradientButton(
                        label: 'Retry',
                        icon: Icons.refresh_rounded,
                        isExpanded: false,
                        onPressed: _refresh,
                      ),
                    ),
                  ),
                ),
              ],
              data: (shifts) => [
                if (shifts.isEmpty)
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 120),
                    sliver: SliverToBoxAdapter(
                      child: RmEmptyBlock(
                        icon: _statusFilter == 'PENDING'
                            ? Icons.task_alt_rounded
                            : Icons.event_note_rounded,
                        color: _statusFilter == 'PENDING'
                            ? RmTheme.emeraldGreen
                            : RmTheme.iconAccent,
                        title: _statusFilter == 'PENDING' ? 'All caught up' : 'No shifts here',
                        message: _statusFilter == 'PENDING'
                            ? 'There are no shifts waiting for your review.'
                            : 'No shift logs match this filter yet.',
                      ),
                    ),
                  )
                else
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 4, 20, 120),
                    sliver: SliverList.builder(
                      itemCount: shifts.length,
                      itemBuilder: (context, index) => _ShiftCard(
                        key: ValueKey(shifts[index].id),
                        shift: shifts[index],
                        filter: _statusFilter,
                        index: index,
                      ),
                    ),
                  ),
              ],
            ),
          ],
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 2),
    );
  }
}

// ---------------------------------------------------------------------------
// Header pieces
// ---------------------------------------------------------------------------

class _ShiftsAppBar extends StatelessWidget {
  const _ShiftsAppBar({required this.onRefresh});
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
            child: const Icon(Icons.fact_check_rounded, color: RmTheme.iconAccent, size: 24),
          ).animate().scaleXY(begin: 0.5, end: 1, duration: 500.ms, curve: Curves.elasticOut),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Shift review',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 21,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  'Approve, flag or reject staff shifts',
                  maxLines: 1,
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
        ],
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 20),
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(),
            elevation: 0,
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                onRefresh();
              },
              child: Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(color: RmTheme.borderSubtle),
                ),
                child: const Icon(Icons.refresh_rounded, color: RmTheme.textPrimary, size: 22),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.pending,
    required this.shown,
    required this.filterLabel,
  });

  final int? pending;
  final int? shown;
  final String filterLabel;

  @override
  Widget build(BuildContext context) {
    final p = pending;
    final clear = p == 0;

    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
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
            blurRadius: 26,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(
            right: -30,
            top: -40,
            child: Container(
              width: 130,
              height: 130,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFFFFD84D).withValues(alpha: 0.14),
              ),
            ),
          ),
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.16),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        clear ? 'ALL CLEAR' : 'NEEDS REVIEW',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10.5,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.8,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            p == null ? '—' : '$p',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 40,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -1.2,
                              color: Colors.white,
                            ),
                          ),
                          const SizedBox(width: 8),
                          Padding(
                            padding: const EdgeInsets.only(bottom: 5),
                            child: Text(
                              p == 1 ? 'shift pending' : 'shifts pending',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                                color: Colors.white.withValues(alpha: 0.85),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      shown == null
                          ? 'Loading $filterLabel shifts…'
                          : 'Showing $shown ${filterLabel.toLowerCase()} '
                              '${shown == 1 ? 'shift' : 'shifts'}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Icon(
                  clear ? Icons.task_alt_rounded : Icons.pending_actions_rounded,
                  color: RmTheme.iconAccent,
                  size: 32,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -3, end: 3, duration: 1600.ms, curve: Curves.easeInOut),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic);
  }
}

class _FilterHeader extends SliverPersistentHeaderDelegate {
  _FilterHeader({required this.selected, required this.onSelected});

  final String? selected;
  final ValueChanged<String?> onSelected;

  @override
  double get minExtent => 60;
  @override
  double get maxExtent => 60;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return Container(
      color: RmTheme.offWhite,
      alignment: Alignment.center,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        itemCount: _filters.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final (label, value) = _filters[i];
          final active = selected == value;
          final color = value == null ? RmTheme.electricBlue : _shiftStatusColor(value);
          return GestureDetector(
            onTap: () {
              HapticFeedback.selectionClick();
              onSelected(value);
            },
            child: AnimatedContainer(
              duration: 220.ms,
              curve: Curves.easeOutCubic,
              padding: const EdgeInsets.symmetric(horizontal: 16),
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: active ? RmTheme.electricBlue : Colors.white,
                borderRadius: BorderRadius.circular(30),
                border: Border.all(
                  color: active ? RmTheme.electricBlue : RmTheme.borderSubtle,
                ),
                boxShadow: active
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
                  if (value != null) ...[
                    Container(
                      width: 7,
                      height: 7,
                      decoration: BoxDecoration(
                        color: active ? Colors.white : color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 7),
                  ],
                  Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: active ? Colors.white : RmTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _FilterHeader old) => old.selected != selected;
}

// ---------------------------------------------------------------------------
// Shift card
// ---------------------------------------------------------------------------

class _ShiftCard extends ConsumerStatefulWidget {
  const _ShiftCard({
    super.key,
    required this.shift,
    required this.filter,
    required this.index,
  });
  final ShiftLogRow shift;
  final String? filter;
  final int index;

  @override
  ConsumerState<_ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends ConsumerState<_ShiftCard> {
  String? _busyAction;

  Future<String?> _askNotes(String action) {
    final controller = TextEditingController();
    final flag = action == 'FLAGGED';
    final color = flag ? RmTheme.amberWarning : RmTheme.crimsonDanger;
    return showDialog<String>(
      context: context,
      builder: (dialogContext) => DsDialogCard(
        children: [
          DsDialogIcon(icon: flag ? Icons.flag_rounded : Icons.block_rounded, color: color),
          const SizedBox(height: 16),
          Text(
            flag ? 'Flag this shift?' : 'Reject this shift?',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            'Add a short note so the staff member knows why.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              height: 1.4,
              color: RmTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            maxLines: 3,
            minLines: 2,
            textCapitalization: TextCapitalization.sentences,
            style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w600),
            decoration: const InputDecoration(hintText: 'Notes (optional)'),
          ),
          const SizedBox(height: 18),
          DsButtonBase(
            label: flag ? 'Flag shift' : 'Reject shift',
            onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()),
            decoration: BoxDecoration(
              color: color,
              boxShadow: [
                BoxShadow(
                  color: color.withValues(alpha: 0.35),
                  blurRadius: 16,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Text(
              flag ? 'Flag shift' : 'Reject shift',
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontWeight: FontWeight.w800,
                fontSize: 15.5,
              ),
            ),
          ),
          const SizedBox(height: 10),
          DsOutlineButton(
            label: 'Cancel',
            onPressed: () => Navigator.of(dialogContext).pop(),
          ),
        ],
      ),
    );
  }

  Future<void> _review(String action) async {
    String? notes;
    if (action == 'FLAGGED' || action == 'REJECTED') {
      notes = await _askNotes(action);
      if (notes == null) return;
    }
    HapticFeedback.mediumImpact();

    setState(() => _busyAction = action);
    final result = await ref.read(rmRepositoryProvider).reviewShift(
          widget.shift.id,
          action,
          notes: notes?.isEmpty ?? true ? null : notes,
        );
    if (!mounted) return;
    setState(() => _busyAction = null);
    result.fold(
      onSuccess: (_) {
        DsSnackBar.show(
          context,
          message: switch (action) {
            'APPROVED' => 'Shift approved',
            'FLAGGED' => 'Shift flagged',
            _ => 'Shift rejected',
          },
          type: action == 'APPROVED' ? DsSnackBarType.success : DsSnackBarType.warning,
        );
        ref.invalidate(rmShiftsProvider(widget.filter));
        ref.invalidate(rmShiftsProvider('PENDING'));
        ref.invalidate(rmDashboardProvider);
      },
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    final staffName = shift.staff?.fullName ?? shift.staffId;
    final initials = staffName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();
    final statusColor = _shiftStatusColor(shift.status);
    final pending = shift.status == 'PENDING';
    final duration = _duration(shift.checkInAt, shift.checkOutAt);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: statusColor),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(14, 16, 16, 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            alignment: Alignment.center,
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [RmTheme.electricBlue, RmTheme.navy],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Text(
                              initials.isEmpty ? '?' : initials,
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  staffName,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w800,
                                    fontSize: 15.5,
                                    color: RmTheme.textPrimary,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  [
                                    if (shift.staff?.staffCode != null) shift.staff!.staffCode,
                                    if (shift.staff?.series != null) shift.staff!.series!,
                                  ].join(' · '),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    color: RmTheme.textSecondary,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
                            decoration: BoxDecoration(
                              color: statusColor.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(_shiftStatusIcon(shift.status), size: 13, color: statusColor),
                                const SizedBox(width: 4),
                                Text(
                                  rmTitleCase(shift.status),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    color: statusColor,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 14),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: RmTheme.offWhite,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: _TimeCell(
                                icon: Icons.calendar_today_rounded,
                                label: 'Date',
                                value: _fmtDate(shift.shiftDate),
                              ),
                            ),
                            _divider(),
                            Expanded(
                              child: _TimeCell(
                                icon: Icons.login_rounded,
                                label: 'In',
                                value: _fmtTime(shift.checkInAt),
                              ),
                            ),
                            _divider(),
                            Expanded(
                              child: _TimeCell(
                                icon: Icons.logout_rounded,
                                label: 'Out',
                                value: _fmtTime(shift.checkOutAt),
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (duration != null || (shift.notes?.isNotEmpty ?? false)) ...[
                        const SizedBox(height: 10),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: [
                            if (duration != null)
                              RmStatusPill(label: 'Worked $duration', color: RmTheme.electricBlue),
                            if (shift.notes?.isNotEmpty ?? false)
                              Text(
                                '“${shift.notes}”',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontStyle: FontStyle.italic,
                                  color: RmTheme.textSecondary,
                                ),
                              ),
                          ],
                        ),
                      ],
                      if (pending) ...[
                        const SizedBox(height: 14),
                        Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: _ActionButton(
                                label: 'Approve',
                                icon: Icons.check_rounded,
                                color: RmTheme.emeraldGreen,
                                filled: true,
                                loading: _busyAction == 'APPROVED',
                                onTap: _busyAction != null ? null : () => _review('APPROVED'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: _ActionButton(
                                label: 'Flag',
                                icon: Icons.flag_rounded,
                                color: RmTheme.amberWarning,
                                loading: _busyAction == 'FLAGGED',
                                onTap: _busyAction != null ? null : () => _review('FLAGGED'),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Expanded(
                              flex: 4,
                              child: _ActionButton(
                                label: 'Reject',
                                icon: Icons.close_rounded,
                                color: RmTheme.crimsonDanger,
                                loading: _busyAction == 'REJECTED',
                                onTap: _busyAction != null ? null : () => _review('REJECTED'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: (60 * widget.index.clamp(0, 8)).ms)
        .fadeIn(duration: 380.ms)
        .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic);
  }

  Widget _divider() => Container(
        width: 1,
        height: 30,
        margin: const EdgeInsets.symmetric(horizontal: 8),
        color: RmTheme.borderSubtle,
      );

  static String _fmtTime(String? iso) {
    if (iso == null || iso.isEmpty) return '—';
    final d = DateTime.tryParse(iso)?.toLocal();
    if (d == null) return iso;
    final h = d.hour % 12 == 0 ? 12 : d.hour % 12;
    final m = d.minute.toString().padLeft(2, '0');
    return '$h:$m ${d.hour < 12 ? 'AM' : 'PM'}';
  }

  static String _fmtDate(String raw) {
    final d = DateTime.tryParse(raw);
    if (d == null) return raw;
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    return '${d.day} ${months[d.month - 1]}';
  }

  static String? _duration(String? inIso, String? outIso) {
    final a = inIso == null ? null : DateTime.tryParse(inIso);
    final b = outIso == null ? null : DateTime.tryParse(outIso);
    if (a == null || b == null || b.isBefore(a)) return null;
    final diff = b.difference(a);
    final h = diff.inHours;
    final m = diff.inMinutes % 60;
    return h > 0 ? '${h}h ${m}m' : '${m}m';
  }
}

class _TimeCell extends StatelessWidget {
  const _TimeCell({required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, size: 13, color: RmTheme.iconAccent),
            const SizedBox(width: 4),
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
        const SizedBox(height: 3),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13.5,
              fontWeight: FontWeight.w800,
              color: RmTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.icon,
    required this.color,
    required this.onTap,
    this.filled = false,
    this.loading = false,
  });

  final String label;
  final IconData icon;
  final Color color;
  final VoidCallback? onTap;
  final bool filled;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final fg = filled ? Colors.white : color;
    return Material(
      color: filled ? color : color.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: SizedBox(
          height: 42,
          child: Center(
            child: loading
                ? SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2.2, color: fg),
                  )
                : FittedBox(
                    fit: BoxFit.scaleDown,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(icon, size: 17, color: fg),
                          const SizedBox(width: 5),
                          Text(
                            label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: fg,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}
