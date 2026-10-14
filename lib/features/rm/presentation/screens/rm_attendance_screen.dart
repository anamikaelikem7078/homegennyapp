import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// `GET`/`PUT /rm/attendance` requires a `branchId` — this screen picks a
/// branch (from `GET /rm/locations`) plus month/year, then shows the real
/// per-staff attendance grid for confirmed placements in that branch.
class RmAttendanceScreen extends ConsumerStatefulWidget {
  const RmAttendanceScreen({super.key});

  @override
  ConsumerState<RmAttendanceScreen> createState() => _RmAttendanceScreenState();
}

const _monthNames = [
  'January', 'February', 'March', 'April', 'May', 'June',
  'July', 'August', 'September', 'October', 'November', 'December',
];

(Color, IconData, String) _statusStyle(String s) => switch (s) {
      AttendanceStatuses.present => (RmTheme.emeraldGreen, Icons.check_circle_rounded, 'Present'),
      AttendanceStatuses.absent => (RmTheme.crimsonDanger, Icons.cancel_rounded, 'Absent'),
      AttendanceStatuses.leave => (RmTheme.amberWarning, Icons.beach_access_rounded, 'Leave'),
      AttendanceStatuses.overtime => (const Color(0xFFEA580C), Icons.more_time_rounded, 'Overtime'),
      _ => (RmTheme.textSecondary, Icons.circle_outlined, rmTitleCase(s)),
    };

String _money(num v) {
  final s = v.round().toString();
  if (s.length <= 3) return '₹$s';
  final last3 = s.substring(s.length - 3);
  var rest = s.substring(0, s.length - 3);
  final parts = <String>[];
  while (rest.length > 2) {
    parts.insert(0, rest.substring(rest.length - 2));
    rest = rest.substring(0, rest.length - 2);
  }
  if (rest.isNotEmpty) parts.insert(0, rest);
  return '₹${parts.join(',')},$last3';
}

class _RmAttendanceScreenState extends ConsumerState<RmAttendanceScreen> {
  String? _branchId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  Future<void> _pickBranch(List<BranchInfo> branches) async {
    final picked = await DsBottomSheet.show<String>(
      context: context,
      title: 'Choose branch',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.sizeOf(context).height * 0.6),
        child: ListView.separated(
          shrinkWrap: true,
          itemCount: branches.length,
          separatorBuilder: (_, _) => const SizedBox(height: 8),
          itemBuilder: (context, i) {
            final b = branches[i];
            final selected = b.id == _branchId;
            return Material(
              color: selected ? RmTheme.electricBlue.withValues(alpha: 0.08) : RmTheme.offWhite,
              borderRadius: BorderRadius.circular(18),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () => Navigator.of(context).pop(b.id),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(13),
                        ),
                        child: const Icon(Icons.apartment_rounded, color: RmTheme.iconAccent, size: 21),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              b.name,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: FontWeight.w800,
                                color: RmTheme.textPrimary,
                              ),
                            ),
                            Text(
                              b.city,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                color: RmTheme.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                      if (selected) const Icon(Icons.check_circle_rounded, color: RmTheme.electricBlue),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
    if (picked != null && mounted) setState(() => _branchId = picked);
  }

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(rmLocationsProvider);
    final branches = locationsAsync.valueOrNull?.branches ?? const <BranchInfo>[];
    final branchId = _branchId ?? (branches.isNotEmpty ? branches.first.id : null);
    final params = branchId == null
        ? null
        : AttendanceParams(branchId: branchId, month: _month.month, year: _month.year);
    final attendanceAsync = params == null ? null : ref.watch(rmAttendanceProvider(params));

    return RmStageScaffold(
      title: 'Attendance',
      onBack: () => context.pop(),
      onRefresh: () async {
        ref.invalidate(rmLocationsProvider);
        if (params != null) ref.invalidate(rmAttendanceProvider(params));
      },
      body: rmAsyncBody<LocationsData>(
        locationsAsync,
        onRetry: () => ref.invalidate(rmLocationsProvider),
        builder: (locations) {
          if (locations.branches.isEmpty || params == null) {
            return const [
              RmEmptyBlock(
                icon: Icons.apartment_rounded,
                title: 'No branches yet',
                message: 'Attendance is tracked per branch. No branches are configured.',
              ),
            ];
          }
          final branch = locations.branches.firstWhere(
            (b) => b.id == branchId,
            orElse: () => locations.branches.first,
          );

          return [
            _PeriodCard(
              branch: branch,
              month: _month,
              canPickBranch: locations.branches.length > 1,
              canGoForward: !_isCurrentMonth,
              onPickBranch: () => _pickBranch(locations.branches),
              onPrev: () => _shiftMonth(-1),
              onNext: () => _shiftMonth(1),
            ),
            ...rmAsyncBody<AttendanceMonthResult>(
              attendanceAsync!,
              onRetry: () => ref.invalidate(rmAttendanceProvider(params)),
              builder: (data) {
                if (data.staff.isEmpty) {
                  return const [
                    SizedBox(height: 16),
                    RmEmptyBlock(
                      icon: Icons.event_busy_rounded,
                      title: 'No one placed here',
                      message: 'There are no confirmed placements in this branch for this month.',
                    ),
                  ];
                }
                return [
                  const SizedBox(height: 14),
                  _TotalsRow(rows: data.staff),
                  RmSectionTitle(
                    title: 'Staff',
                    trailing: RmStatusPill(label: '${data.staff.length}', color: RmTheme.electricBlue),
                  ),
                  for (final row in data.staff)
                    _StaffAttendanceCard(
                      key: ValueKey(row.staffId),
                      row: row,
                      params: params,
                      canMarkToday: _isCurrentMonth,
                    ),
                ];
              },
            ),
          ];
        },
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Period selector
// ---------------------------------------------------------------------------

class _PeriodCard extends StatelessWidget {
  const _PeriodCard({
    required this.branch,
    required this.month,
    required this.canPickBranch,
    required this.canGoForward,
    required this.onPickBranch,
    required this.onPrev,
    required this.onNext,
  });

  final BranchInfo branch;
  final DateTime month;
  final bool canPickBranch;
  final bool canGoForward;
  final VoidCallback onPickBranch;
  final VoidCallback onPrev;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    Widget arrow(IconData icon, VoidCallback? onTap) => Material(
          color: Colors.white.withValues(alpha: onTap == null ? 0.06 : 0.16),
          shape: const CircleBorder(),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: SizedBox(
              width: 42,
              height: 42,
              child: Icon(
                icon,
                color: Colors.white.withValues(alpha: onTap == null ? 0.35 : 1),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
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
        children: [
          Material(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: canPickBranch ? onPickBranch : null,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: RmTheme.iconAccentSoft,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.apartment_rounded, color: RmTheme.iconAccent, size: 20),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Branch',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: RmTheme.textSecondary,
                            ),
                          ),
                          Text(
                            '${branch.name} · ${branch.city}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: RmTheme.textPrimary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    if (canPickBranch)
                      const Icon(Icons.unfold_more_rounded, color: RmTheme.electricBlue),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              arrow(Icons.chevron_left_rounded, onPrev),
              Expanded(
                child: AnimatedSwitcher(
                  duration: 250.ms,
                  transitionBuilder: (child, anim) => FadeTransition(
                    opacity: anim,
                    child: ScaleTransition(scale: Tween(begin: 0.9, end: 1.0).animate(anim), child: child),
                  ),
                  child: Column(
                    key: ValueKey(month),
                    children: [
                      Text(
                        _monthNames[month.month - 1],
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.5,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        '${month.year}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: Colors.white.withValues(alpha: 0.75),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              arrow(Icons.chevron_right_rounded, canGoForward ? onNext : null),
            ],
          ),
        ],
      ),
    );
  }
}

class _TotalsRow extends StatelessWidget {
  const _TotalsRow({required this.rows});
  final List<StaffAttendanceRow> rows;

  @override
  Widget build(BuildContext context) {
    int sum(int Function(StaffAttendanceRow r) f) => rows.fold(0, (a, r) => a + f(r));
    final gross = rows.fold<num>(0, (a, r) => a + r.proratedGross);

    Widget tile(String status, int value) {
      final (color, icon, label) = _statusStyle(status);
      return Expanded(
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(height: 4),
              Text(
                '$value',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.textPrimary,
                ),
              ),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        Row(
          children: [
            tile(AttendanceStatuses.present, sum((r) => r.presentDays)),
            const SizedBox(width: 8),
            tile(AttendanceStatuses.absent, sum((r) => r.absentDays)),
            const SizedBox(width: 8),
            tile(AttendanceStatuses.leave, sum((r) => r.leaveDays)),
            const SizedBox(width: 8),
            tile(AttendanceStatuses.overtime, sum((r) => r.overtimeDays)),
          ],
        ),
        const SizedBox(height: 10),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: RmTheme.emeraldGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(18),
          ),
          child: Row(
            children: [
              const Icon(Icons.payments_rounded, color: RmTheme.iconAccent),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Prorated gross this month',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textPrimary,
                  ),
                ),
              ),
              Text(
                _money(gross),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.emeraldGreen,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Staff card
// ---------------------------------------------------------------------------

class _StaffAttendanceCard extends ConsumerStatefulWidget {
  const _StaffAttendanceCard({
    super.key,
    required this.row,
    required this.params,
    required this.canMarkToday,
  });
  final StaffAttendanceRow row;
  final AttendanceParams params;
  final bool canMarkToday;

  @override
  ConsumerState<_StaffAttendanceCard> createState() => _StaffAttendanceCardState();
}

class _StaffAttendanceCardState extends ConsumerState<_StaffAttendanceCard> {
  String? _busyStatus;

  String get _today => DateTime.now().toIso8601String().substring(0, 10);

  Future<void> _markToday(String status) async {
    HapticFeedback.mediumImpact();
    setState(() => _busyStatus = status);
    final result = await ref.read(rmRepositoryProvider).markAttendance(
          staffId: widget.row.staffId,
          date: _today,
          status: status,
          branchId: widget.params.branchId,
        );
    if (!mounted) return;
    setState(() => _busyStatus = null);
    result.fold(
      onSuccess: (_) {
        DsSnackBar.show(
          context,
          message: '${widget.row.fullName} marked ${_statusStyle(status).$3.toLowerCase()} today',
          type: DsSnackBarType.success,
        );
        ref.invalidate(rmAttendanceProvider(widget.params));
      },
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final today = _today;
    final todayStatus = row.dailyRecords
        .where((d) => d.date.startsWith(today))
        .map((d) => d.status)
        .firstOrNull;
    final days = row.daysInMonth == 0 ? 1 : row.daysInMonth;
    final initials = row.fullName
        .trim()
        .split(RegExp(r'\s+'))
        .where((p) => p.isNotEmpty)
        .take(2)
        .map((p) => p[0].toUpperCase())
        .join();

    final segments = [
      (row.presentDays, RmTheme.emeraldGreen),
      (row.overtimeDays, const Color(0xFFEA580C)),
      (row.leaveDays, RmTheme.amberWarning),
      (row.absentDays, RmTheme.crimsonDanger),
    ];

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
                      row.fullName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      '${row.staffCode} · ${row.billableDays}/${row.daysInMonth} billable days',
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
              Material(
                color: RmTheme.electricBlue.withValues(alpha: 0.08),
                shape: const StadiumBorder(),
                child: InkWell(
                  customBorder: const StadiumBorder(),
                  onTap: () => context.push(RmRoutes.staffInvoicePreview(row.staffId)),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.receipt_long_rounded, size: 15, color: RmTheme.iconAccent),
                        const SizedBox(width: 5),
                        Text(
                          'Invoice',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w800,
                            color: RmTheme.electricBlue,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          // Month split bar.
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 10,
              child: LayoutBuilder(
                builder: (context, c) => Stack(
                  children: [
                    Container(color: RmTheme.offWhite),
                    Row(
                      children: [
                        for (final (count, color) in segments)
                          if (count > 0)
                            Container(
                              width: c.maxWidth * (count / days).clamp(0, 1),
                              color: color,
                            )
                                .animate()
                                .scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft, duration: 700.ms, curve: Curves.easeOutCubic),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 12,
            runSpacing: 6,
            children: [
              for (final (status, count) in [
                (AttendanceStatuses.present, row.presentDays),
                (AttendanceStatuses.overtime, row.overtimeDays),
                (AttendanceStatuses.leave, row.leaveDays),
                (AttendanceStatuses.absent, row.absentDays),
              ])
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: _statusStyle(status).$1,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${_statusStyle(status).$3} $count',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Text(
                'Prorated gross',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w600,
                  color: RmTheme.textSecondary,
                ),
              ),
              const Spacer(),
              Text(
                _money(row.proratedGross),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.textPrimary,
                ),
              ),
            ],
          ),
          if (widget.canMarkToday) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RmTheme.offWhite,
                borderRadius: BorderRadius.circular(18),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.today_rounded, size: 16, color: RmTheme.iconAccent),
                      const SizedBox(width: 6),
                      Text(
                        'Mark today',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w800,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      if (todayStatus != null)
                        RmStatusPill(
                          label: _statusStyle(todayStatus).$3,
                          color: _statusStyle(todayStatus).$1,
                        ),
                    ],
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      for (var i = 0; i < AttendanceStatuses.all.length; i++) ...[
                        if (i > 0) const SizedBox(width: 6),
                        Expanded(
                          child: _MarkButton(
                            status: AttendanceStatuses.all[i],
                            selected: todayStatus == AttendanceStatuses.all[i],
                            loading: _busyStatus == AttendanceStatuses.all[i],
                            onTap: _busyStatus != null ? null : () => _markToday(AttendanceStatuses.all[i]),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _MarkButton extends StatelessWidget {
  const _MarkButton({
    required this.status,
    required this.selected,
    required this.loading,
    required this.onTap,
  });

  final String status;
  final bool selected;
  final bool loading;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = _statusStyle(status);
    return AnimatedContainer(
      duration: 220.ms,
      decoration: BoxDecoration(
        color: selected ? color : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: selected ? color : color.withValues(alpha: 0.25)),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: SizedBox(
            height: 54,
            child: Center(
              child: loading
                  ? SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.2,
                        color: selected ? Colors.white : color,
                      ),
                    )
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(icon, size: 18, color: selected ? Colors.white : color),
                        const SizedBox(height: 3),
                        FittedBox(
                          fit: BoxFit.scaleDown,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4),
                            child: Text(
                              label,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w800,
                                color: selected ? Colors.white : RmTheme.textPrimary,
                              ),
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
