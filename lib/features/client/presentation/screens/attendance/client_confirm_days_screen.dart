import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/attendance_approval_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/attendance_approval_providers.dart';

/// Tag for a day's `client_status`.
(String, Color, IconData) clientDayStatusStyle(String s) => switch (s) {
      ClientDayStatus.pending => ('Waiting', AppColors.warning, Icons.hourglass_top_rounded),
      ClientDayStatus.approved => ('Confirmed', AppColors.success, Icons.check_circle_rounded),
      ClientDayStatus.deemed => ('Auto-confirmed', AppColors.success, Icons.check_circle_outline_rounded),
      ClientDayStatus.approvedPaper => ('Confirmed on paper', AppColors.success, Icons.description_rounded),
      ClientDayStatus.disputed => ('Under review', AppColors.error, Icons.report_rounded),
      _ => ('No action needed', AppColors.lightTextSecondary, Icons.remove_circle_outline_rounded),
    };

/// "Confirm days": the days staff marked from the app, grouped by staff
/// member, each with Confirm / Not right. A waiting day auto-confirms 48
/// hours after it was marked.
class ClientConfirmDaysScreen extends ConsumerStatefulWidget {
  const ClientConfirmDaysScreen({super.key, this.initialStatus = ClientDayStatus.pending});

  final String initialStatus;

  @override
  ConsumerState<ClientConfirmDaysScreen> createState() => _ClientConfirmDaysScreenState();
}

class _ClientConfirmDaysScreenState extends ConsumerState<ClientConfirmDaysScreen> {
  late String _status = widget.initialStatus;

  /// Day ids with a request in flight.
  final Set<String> _busy = {};
  bool _confirmingAll = false;

  static const _filters = [
    ('Waiting', ClientDayStatus.pending),
    ('Under review', ClientDayStatus.disputed),
    ('Confirmed', ClientDayStatus.approved),
    ('Auto-confirmed', ClientDayStatus.deemed),
    ('On paper', ClientDayStatus.approvedPaper),
    ('All', ClientDayStatus.all),
  ];

  void _refresh() {
    ref
      ..invalidate(clientApprovalsProvider)
      ..invalidate(clientPendingApprovalsProvider);
  }

  Future<void> _approve(List<ApprovalDay> days, {bool all = false}) async {
    if (days.isEmpty) return;
    if (all) {
      final ok = await DsConfirmationDialog.show(
        context: context,
        title: 'Confirm ${days.length == 1 ? '1 day' : '${days.length} days'}?',
        message: 'You confirm these staff worked the days and times shown.',
        confirmLabel: 'Confirm all',
        icon: Icons.fact_check_rounded,
      );
      if (ok != true || !mounted) return;
    }
    setState(() {
      _busy.addAll(days.map((d) => d.id));
      if (all) _confirmingAll = true;
    });
    final result = await ref.read(attendanceApprovalApiProvider).approve(days.map((d) => d.id).toList());
    if (!mounted) return;
    setState(() {
      _busy.removeAll(days.map((d) => d.id));
      _confirmingAll = false;
    });
    result.fold(
      onSuccess: (n) {
        context.showDsSnackBar(n == 1 ? 'Day confirmed' : '$n days confirmed', type: DsSnackBarType.success);
        _refresh();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _dispute(ApprovalDay day) async {
    final input = await _askDispute(context, day);
    if (input == null || !mounted) return;
    setState(() => _busy.add(day.id));
    final result = await ref
        .read(attendanceApprovalApiProvider)
        .dispute(day.id, reason: input.reason, actual: input.actual);
    if (!mounted) return;
    setState(() => _busy.remove(day.id));
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Sent to your RM for review', type: DsSnackBarType.success);
        _refresh();
      },
      // e.g. "raise it with your RM" for a day the office entered.
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final approvals = ref.watch(clientApprovalsProvider(_status));

    return DsPage(
      title: 'Confirm days',
      subtitle: 'Last 30 days',
      onBack: () => context.canPop() ? context.pop() : context.go(ClientRoutes.dashboard),
      onRefresh: () async => _refresh(),
      actions: [
        DsPageAction(
          icon: Icons.table_chart_rounded,
          tooltip: 'Monthly attendance sheet',
          onPressed: () => context.push(ClientRoutes.musterRoll),
        ),
      ],
      bottom: switch (approvals.valueOrNull) {
        final list? when _status == ClientDayStatus.pending && list.items.any((d) => d.isPending) => DsGradientButton(
            label: 'Confirm all',
            icon: Icons.done_all_rounded,
            isLoading: _confirmingAll,
            onPressed: _busy.isNotEmpty ? null : () => _approve(list.items.where((d) => d.isPending).toList(), all: true),
          ),
        _ => null,
      },
      body: [
        SizedBox(
          height: 42,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            clipBehavior: Clip.none,
            itemCount: _filters.length,
            separatorBuilder: (_, _) => const SizedBox(width: 8),
            itemBuilder: (_, i) => DsChoiceChip(
              label: _filters[i].$1,
              selected: _status == _filters[i].$2,
              onTap: () => setState(() => _status = _filters[i].$2),
            ),
          ),
        ),
        const SizedBox(height: 16),
        ...dsAsyncBody(
          approvals,
          onRetry: () => ref.invalidate(clientApprovalsProvider(_status)),
          builder: (list) {
            if (list.items.isEmpty) {
              return [
                DsEmptyBlock(
                  icon: Icons.task_alt_rounded,
                  color: AppColors.success,
                  title: _status == ClientDayStatus.pending ? 'Nothing to confirm' : 'No days',
                  message: _status == ClientDayStatus.pending
                      ? 'You are all caught up. New days appear here after your staff check in.'
                      : 'No days with this status in the last 30 days.',
                ),
              ];
            }
            // Group by staff member, keeping the server's order.
            final groups = <String, List<ApprovalDay>>{};
            for (final d in list.items) {
              groups.putIfAbsent(d.staffId, () => []).add(d);
            }
            return [
              if (_status == ClientDayStatus.pending) ...[
                const DsNote(
                  text: 'Check each day your staff marked in the app. A day you don\'t answer within 48 hours '
                      'counts as confirmed. Tap "Not right" if a day is wrong; it is not billed until your RM resolves it.',
                ),
                const SizedBox(height: 16),
              ],
              for (final days in groups.values) ...[
                _StaffHeader(day: days.first, count: days.length),
                for (var i = 0; i < days.length; i++)
                  _DayCard(
                    day: days[i],
                    busy: _busy.contains(days[i].id),
                    onConfirm: _busy.isEmpty ? () => _approve([days[i]]) : null,
                    onDispute: _busy.isEmpty ? () => _dispute(days[i]) : null,
                  ).animate(delay: (40 * i.clamp(0, 10)).ms).fadeIn(duration: 280.ms).slideX(begin: 0.05, end: 0),
                const SizedBox(height: 8),
              ],
            ];
          },
        ),
      ],
    );
  }
}

class _StaffHeader extends StatelessWidget {
  const _StaffHeader({required this.day, required this.count});
  final ApprovalDay day;
  final int count;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 10, top: 4),
        child: Row(
          children: [
            DsInitialsAvatar(name: day.staffName, size: 36, radius: 18),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                day.staffCode == null ? day.staffName : '${day.staffName}  ·  ${day.staffCode}',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            DsPill(count == 1 ? '1 day' : '$count days'),
          ],
        ),
      );
}

class _DayCard extends StatelessWidget {
  const _DayCard({required this.day, required this.busy, this.onConfirm, this.onDispute});
  final ApprovalDay day;
  final bool busy;
  final VoidCallback? onConfirm;
  final VoidCallback? onDispute;

  static String _hours(num h) => h == h.roundToDouble() ? '${h.toInt()} h' : '${h.toStringAsFixed(1)} h';

  @override
  Widget build(BuildContext context) {
    final (label, color, icon) = clientDayStatusStyle(day.clientStatus);
    final small = GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary);
    final times = [
      'In ${day.checkInIst ?? DateFormatter.since(day.checkIn, fallback: '—')}',
      if (day.checkOutIst != null || day.checkOut != null)
        'Out ${day.checkOutIst ?? DateFormatter.since(day.checkOut)}',
      if (day.hoursWorked != null && day.hoursWorked! > 0) _hours(day.hoursWorked!),
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  DateFormatter.day(day.date),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              DsPill(label, color: color, icon: icon),
            ],
          ),
          const SizedBox(height: 4),
          Text(times, style: small.copyWith(fontWeight: FontWeight.w600)),
          if (day.isPending && day.deemedAt != null) ...[
            const SizedBox(height: 4),
            Text('Auto-confirms on ${DateFormatter.timestamp(day.deemedAt)}', style: small),
          ],
          if (day.clientNote != null) ...[
            const SizedBox(height: 6),
            Text('Your note: ${day.clientNote}', style: small),
          ],
          if (day.resolutionNote != null) ...[
            const SizedBox(height: 6),
            Text(
              'RM: ${day.resolutionNote}',
              style: small.copyWith(color: AppColors.success, fontWeight: FontWeight.w600),
            ),
          ],
          if (day.isPending) ...[
            const SizedBox(height: 12),
            if (busy)
              const Center(
                child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)),
              )
            else
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: onDispute,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.error,
                        side: BorderSide(color: AppColors.error.withValues(alpha: 0.4)),
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.close_rounded, size: 18),
                      label: const Text('Not right'),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: onConfirm,
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.success,
                        shape: const StadiumBorder(),
                      ),
                      icon: const Icon(Icons.check_rounded, size: 18),
                      label: const Text('Confirm'),
                    ),
                  ),
                ],
              ),
          ],
        ],
      ),
    );
  }
}

/// Asks why a day is wrong: a reason (5+ characters) and, optionally, what
/// really happened.
Future<({String reason, String? actual})?> _askDispute(BuildContext context, ApprovalDay day) {
  final controller = TextEditingController();
  String? actual;
  return showModalBottomSheet<({String reason, String? actual})>(
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
            builder: (context, setSheetState) {
              final reason = controller.text.trim();
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'What is wrong with ${DateFormatter.day(day.date)}?',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${day.staffName}. Your RM will check and get back to you.',
                    style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.lightTextSecondary),
                  ),
                  const SizedBox(height: 14),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: [
                      for (final (value, label) in DisputeActual.options)
                        DsChoiceChip(
                          label: label,
                          selected: actual == value,
                          onTap: () => setSheetState(() => actual = actual == value ? null : value),
                        ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  DsLabeledField(
                    label: 'Reason',
                    controller: controller,
                    icon: Icons.edit_note_rounded,
                    hint: 'e.g. She left at 2 pm, not 8 pm',
                    maxLines: 4,
                    minLines: 3,
                    textCapitalization: TextCapitalization.sentences,
                    onChanged: (_) => setSheetState(() {}),
                  ),
                  if (reason.isNotEmpty && reason.length < 5) ...[
                    const SizedBox(height: 6),
                    Text(
                      'At least 5 characters',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.error),
                    ),
                  ],
                  const SizedBox(height: 16),
                  DsGradientButton(
                    label: 'Send to RM',
                    icon: Icons.send_rounded,
                    onPressed: reason.length < 5
                        ? null
                        : () => Navigator.of(sheetContext).pop((reason: reason, actual: actual)),
                  ),
                ],
              );
            },
          ),
        ),
      ),
    ),
  );
}
