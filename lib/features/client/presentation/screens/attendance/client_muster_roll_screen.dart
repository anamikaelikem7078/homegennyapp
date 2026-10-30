import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/attendance_approval_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/attendance_approval_providers.dart';
import '../../providers/client_providers.dart';

/// Mark colours on the grid.
Color _markColor(String m) => switch (m) {
      'P' => AppColors.success,
      '½' => AppColors.warning,
      'A' => AppColors.error,
      'L' => AppColors.secondary,
      'WO' => AppColors.primary,
      _ => AppColors.lightTextSecondary,
    };

String _fmt(num? v) {
  if (v == null) return '—';
  return v == v.roundToDouble() ? '${v.toInt()}' : v.toStringAsFixed(1);
}

/// "Monthly attendance sheet" — the Form XVI muster roll for one month:
/// one card per staff member with the month's marks, then Sign. Signing
/// also confirms every day of that month still waiting.
class ClientMusterRollScreen extends ConsumerStatefulWidget {
  const ClientMusterRollScreen({super.key});

  @override
  ConsumerState<ClientMusterRollScreen> createState() => _ClientMusterRollScreenState();
}

class _ClientMusterRollScreenState extends ConsumerState<ClientMusterRollScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _signing = false;
  bool _printing = false;

  ({int month, int year}) get _key => (month: _month.month, year: _month.year);

  bool get _isCurrentMonth {
    final now = DateTime.now();
    return _month.year == now.year && _month.month == now.month;
  }

  void _shiftMonth(int by) => setState(() => _month = DateTime(_month.year, _month.month + by));

  String get _label => DateFormat('MMMM yyyy').format(_month);

  Future<void> _print() async {
    setState(() => _printing = true);
    final result = await ref.read(attendanceApprovalApiProvider).musterRollHtml(_key.month, _key.year);
    if (!mounted) return;
    setState(() => _printing = false);
    switch (result) {
      case Success(data: final html):
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/muster-roll-${_key.year}-${_key.month.toString().padLeft(2, '0')}.html');
        await file.writeAsString(html);
        await SharePlus.instance.share(ShareParams(files: [XFile(file.path)], text: 'Attendance sheet — $_label'));
      case Error(failure: final f):
        context.showDsSnackBar(f.message, type: DsSnackBarType.error);
    }
  }

  Future<void> _sign(MusterRoll roll) async {
    final name = await _askSignature(
      context,
      monthLabel: roll.monthLabel ?? _label,
      initialName: ref.read(clientProfileProvider).valueOrNull?.name ?? '',
    );
    if (name == null || !mounted) return;
    setState(() => _signing = true);
    final result = await ref.read(attendanceApprovalApiProvider).sign(_key.month, _key.year, name: name);
    if (!mounted) return;
    setState(() => _signing = false);
    result.fold(
      onSuccess: (r) {
        context.showDsSnackBar(
          r.daysConfirmed > 0
              ? 'Signed. ${r.daysConfirmed == 1 ? '1 waiting day' : '${r.daysConfirmed} waiting days'} confirmed.'
              : 'Attendance sheet signed',
          type: DsSnackBarType.success,
        );
        ref
          ..invalidate(clientMusterRollProvider(_key))
          ..invalidate(clientPendingApprovalsProvider);
      },
      // e.g. "locked with an approved invoice".
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final roll = ref.watch(clientMusterRollProvider(_key));

    return DsPage(
      title: 'Monthly attendance sheet',
      subtitle: _label,
      onBack: () => context.canPop() ? context.pop() : context.go(ClientRoutes.profile),
      onRefresh: () async => ref.invalidate(clientMusterRollProvider(_key)),
      actions: [
        DsPageAction(
          icon: _printing ? Icons.hourglass_top_rounded : Icons.ios_share_rounded,
          tooltip: 'Print / share',
          onPressed: _printing ? () {} : _print,
        ),
      ],
      bottom: switch (roll.valueOrNull) {
        final r? when r.needsSignature && r.rows.isNotEmpty => DsGradientButton(
            label: r.signed == null ? 'Sign' : 'Sign again',
            icon: Icons.draw_rounded,
            isLoading: _signing,
            onPressed: _signing ? null : () => _sign(r),
          ),
        _ => null,
      },
      body: [
        _MonthPicker(
          label: _label,
          onPrev: () => _shiftMonth(-1),
          onNext: _isCurrentMonth ? null : () => _shiftMonth(1),
        ),
        const SizedBox(height: 14),
        ...dsAsyncBody(
          roll,
          onRetry: () => ref.invalidate(clientMusterRollProvider(_key)),
          builder: (r) => [
            _SignatureStatus(roll: r),
            const SizedBox(height: 14),
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(child: DsGlassStat(value: _fmt(r.totalPresent), label: 'Present', icon: Icons.check_circle_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: _fmt(r.totalWeeklyOff), label: 'Weekly off', icon: Icons.weekend_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: _fmt(r.totalMandays), label: 'Man-days', icon: Icons.groups_rounded)),
                ],
              ),
            ),
            if (r.disputedDays > 0) ...[
              const SizedBox(height: 12),
              DsNote(
                tone: DsNoteTone.warning,
                text: '${r.disputedDays == 1 ? '1 day is' : '${r.disputedDays} days are'} under review and left blank '
                    'until your RM resolves ${r.disputedDays == 1 ? 'it' : 'them'}.',
              ),
            ],
            const DsSection('Staff'),
            if (r.rows.isEmpty)
              const DsEmptyBlock(
                icon: Icons.event_busy_rounded,
                title: 'No attendance this month',
                message: 'Days appear here once your staff have worked them.',
              )
            else ...[
              for (var i = 0; i < r.rows.length; i++)
                _StaffMonthCard(row: r.rows[i], daysInMonth: r.daysInMonth, month: _month)
                    .animate(delay: (50 * i.clamp(0, 8)).ms)
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.05, end: 0),
              const _Legend(),
            ],
            if (r.versions.isNotEmpty) ...[
              const DsSection('Earlier signatures'),
              for (final v in r.versions)
                DsListCard(
                  icon: v.onPaper ? Icons.description_rounded : Icons.draw_rounded,
                  iconColor: AppColors.lightTextSecondary,
                  title: 'Version ${v.version ?? '—'}${v.signedName == null ? '' : ' · ${v.signedName}'}',
                  subtitle: [
                    if (v.signedAt != null) DateFormatter.timestamp(v.signedAt),
                    if (v.onPaper) 'Paper',
                  ].join('  ·  '),
                ),
            ],
          ],
        ),
      ],
    );
  }
}

class _MonthPicker extends StatelessWidget {
  const _MonthPicker({required this.label, required this.onPrev, this.onNext});
  final String label;
  final VoidCallback onPrev;
  final VoidCallback? onNext;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: dsCardDecoration(radius: 20),
        child: Row(
          children: [
            IconButton(onPressed: onPrev, icon: const Icon(Icons.chevron_left_rounded), tooltip: 'Previous month'),
            Expanded(
              child: Text(
                label,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            IconButton(onPressed: onNext, icon: const Icon(Icons.chevron_right_rounded), tooltip: 'Next month'),
          ],
        ),
      );
}

class _SignatureStatus extends StatelessWidget {
  const _SignatureStatus({required this.roll});
  final MusterRoll roll;

  @override
  Widget build(BuildContext context) {
    final s = roll.signed;
    if (s == null) {
      return const DsNote(
        title: 'Not signed yet',
        text: 'Check the month below and tap Sign. Signing also confirms any days still waiting.',
      );
    }
    final by = [
      if (s.signedName != null) s.signedName!,
      if (s.signedAt != null) DateFormatter.timestamp(s.signedAt),
      if (s.onPaper) 'on paper',
    ].join(' · ');
    if (roll.changedSinceSigned.isNotEmpty && !s.locked) {
      return DsNote(
        tone: DsNoteTone.warning,
        title: 'Changed since you signed — please sign again',
        text: 'Signed $by. Attendance changed afterwards.',
      );
    }
    return DsNote(
      tone: DsNoteTone.success,
      title: s.locked ? 'Signed and locked' : 'Signed',
      text: s.locked ? '$by. The invoice for this month is approved, so it can no longer be signed.' : by,
    );
  }
}

/// One staff member's month: a cell per day with its mark, then totals.
class _StaffMonthCard extends StatelessWidget {
  const _StaffMonthCard({required this.row, required this.daysInMonth, required this.month});
  final MusterRow row;
  final int daysInMonth;
  final DateTime month;

  @override
  Widget build(BuildContext context) {
    final small = GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary);
    final subtitle = [
      if (row.code != null) row.code!,
      if (row.rank != null) row.rank!,
      if (row.fatherOrHusbandName != null) 'F/H: ${row.fatherOrHusbandName}',
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsInitialsAvatar(name: row.name, size: 40, radius: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      row.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    if (subtitle.isNotEmpty) Text(subtitle, maxLines: 1, overflow: TextOverflow.ellipsis, style: small),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          LayoutBuilder(
            builder: (context, c) {
              const gap = 4.0;
              final cell = (c.maxWidth - gap * 6) / 7;
              return Wrap(
                spacing: gap,
                runSpacing: gap,
                children: [
                  for (var d = 1; d <= daysInMonth; d++)
                    _DayCell(
                      day: d,
                      weekday: DateFormat('E').format(DateTime(month.year, month.month, d)).substring(0, 1),
                      mark: d - 1 < row.days.length ? row.days[d - 1] : '',
                      size: cell,
                    ),
                ],
              );
            },
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              DsPill('${_fmt(row.daysPresent)} present', color: AppColors.success),
              DsPill('${_fmt(row.weeklyOff)} weekly off', color: AppColors.primary),
              if ((row.additionalHours ?? 0) > 0) DsPill('${_fmt(row.additionalHours)} extra h', color: AppColors.secondary),
              DsPill('Total ${_fmt(row.total)}', color: AppColors.lightTextPrimary),
            ],
          ),
          if (row.remarks != null) ...[
            const SizedBox(height: 8),
            Text(row.remarks!, style: small),
          ],
        ],
      ),
    );
  }
}

class _DayCell extends StatelessWidget {
  const _DayCell({required this.day, required this.weekday, required this.mark, required this.size});
  final int day;
  final String weekday;
  final String mark;
  final double size;

  @override
  Widget build(BuildContext context) {
    final color = _markColor(mark);
    final empty = mark.isEmpty;
    return Container(
      width: size,
      height: size * 0.95,
      decoration: BoxDecoration(
        color: empty ? AppColors.lightSurfaceVariant : color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            '$day $weekday',
            style: GoogleFonts.plusJakartaSans(fontSize: 9.5, color: AppColors.lightTextSecondary),
          ),
          Text(
            empty ? '–' : mark,
            style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _Legend extends StatelessWidget {
  const _Legend();

  @override
  Widget build(BuildContext context) {
    const items = [
      ('P', 'Present'),
      ('½', 'Half day'),
      ('A', 'Absent'),
      ('L', 'Leave'),
      ('WO', 'Weekly off'),
      ('', 'Not recorded / under review'),
    ];
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Wrap(
        spacing: 12,
        runSpacing: 6,
        children: [
          for (final (m, label) in items)
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: m.isEmpty ? '–  ' : '$m  ',
                    style: TextStyle(fontWeight: FontWeight.w800, color: _markColor(m)),
                  ),
                  TextSpan(text: label),
                ],
              ),
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
            ),
        ],
      ),
    );
  }
}

/// Asks for the signer's name and shows the declaration. Returns the name.
Future<String?> _askSignature(BuildContext context, {required String monthLabel, required String initialName}) {
  final controller = TextEditingController(text: initialName);
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'Sign attendance sheet',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                DsNote(text: 'I confirm the attendance above is correct for $monthLabel.'),
                const SizedBox(height: 14),
                DsLabeledField(
                  label: 'Name of the person signing',
                  controller: controller,
                  icon: Icons.person_rounded,
                  textCapitalization: TextCapitalization.words,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 16),
                DsGradientButton(
                  label: 'I confirm — sign',
                  icon: Icons.draw_rounded,
                  onPressed: controller.text.trim().length < 2
                      ? null
                      : () => Navigator.of(sheetContext).pop(controller.text.trim()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}
