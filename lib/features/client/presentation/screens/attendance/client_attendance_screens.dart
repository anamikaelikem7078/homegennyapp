import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

String _pretty(String s) => s
    .toLowerCase()
    .split('_')
    .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
    .join(' ');

(Color, IconData) _statusStyle(String status) {
  final s = status.toUpperCase();
  if (s.contains('ABSENT') || s.contains('NOT')) return (AppColors.error, Icons.cancel_rounded);
  if (s.contains('LATE')) return (AppColors.warning, Icons.schedule_rounded);
  if (s.contains('LEAVE')) return (AppColors.secondary, Icons.beach_access_rounded);
  if (s.contains('PRESENT') || s.contains('CHECKED')) return (AppColors.success, Icons.check_circle_rounded);
  return (AppColors.primary, Icons.hourglass_top_rounded);
}

/// Today's attendance.
class ClientTodayAttendanceScreen extends ConsumerWidget {
  const ClientTodayAttendanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(clientTodayAttendanceProvider);

    return DsPage(
      title: 'Today\'s attendance',
      subtitle: _todayLabel(),
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(clientTodayAttendanceProvider),
      actions: [
        DsPageAction(
          icon: Icons.history_rounded,
          tooltip: 'History',
          onPressed: () => context.push(ClientRoutes.attendanceHistory),
        ),
      ],
      body: dsAsyncBody(
        today,
        onRetry: () => ref.invalidate(clientTodayAttendanceProvider),
        builder: (t) {
          if (t.staff.isNotEmpty) {
            return [
              for (var i = 0; i < t.staff.length; i++)
                _StaffTodayCard(staff: t.staff[i])
                    .animate(delay: (60 * i.clamp(0, 6)).ms)
                    .fadeIn(duration: 280.ms)
                    .slideY(begin: 0.05, end: 0),
              const DsSection('Something wrong?'),
              DsListCard(
                icon: Icons.flag_rounded,
                iconColor: AppColors.error,
                title: 'Raise an issue',
                subtitle: 'Late arrival, early leave or a missed check-in',
                onTap: () => context.push(ClientRoutes.attendanceRaiseIssue),
              ),
              DsListCard(
                icon: Icons.calendar_month_rounded,
                title: 'Attendance history',
                subtitle: 'Days worked at your home',
                onTap: () => context.push(ClientRoutes.attendanceHistory),
              ),
            ];
          }
          // Older server: one staff member in the top-level fields.
          final (color, icon) = _statusStyle(t.todayStatus);
          final present = color == AppColors.success;
          return [
            DsGradientCard(
              colors: present ? DsGradientCard.green : DsGradientCard.blue,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(3),
                        decoration: const BoxDecoration(color: Colors.white, shape: BoxShape.circle),
                        child: DsInitialsAvatar(name: t.staffName ?? 'Staff', size: 50, radius: 25),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              t.staffName ?? 'Your staff',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 19,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                            if (t.staffCode != null)
                              Text(
                                t.staffCode!,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white.withValues(alpha: 0.78),
                                ),
                              ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(20)),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(icon, size: 14, color: color),
                            const SizedBox(width: 4),
                            Text(
                              _pretty(t.todayStatus),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w800,
                                color: color,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 18),
                  Row(
                    children: [
                      Expanded(
                        child: DsGlassStat(
                          value: t.checkInTime ?? '—',
                          label: 'Check-in',
                          icon: Icons.login_rounded,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: DsGlassStat(
                          value: t.checkOutTime ?? '—',
                          label: 'Check-out',
                          icon: Icons.logout_rounded,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DsListCard(
              icon: t.gpsVerified ? Icons.gps_fixed_rounded : Icons.gps_off_rounded,
              iconColor: t.gpsVerified ? AppColors.success : AppColors.warning,
              title: t.gpsVerified ? 'Location verified' : 'Location not verified',
              subtitle: t.gpsVerified
                  ? 'Check-in was confirmed at your home via GPS'
                  : 'We could not confirm the check-in location',
              trailing: DsPill(
                t.gpsVerified ? 'GPS' : 'Pending',
                color: t.gpsVerified ? AppColors.success : AppColors.warning,
              ),
            ),
            const DsSection('Something wrong?'),
            DsListCard(
              icon: Icons.flag_rounded,
              iconColor: AppColors.error,
              title: 'Raise an issue',
              subtitle: 'Late arrival, early leave or a missed check-in',
              onTap: () => context.push(ClientRoutes.attendanceRaiseIssue),
            ),
            DsListCard(
              icon: Icons.calendar_month_rounded,
              title: 'Attendance history',
              subtitle: 'See every day this month',
              onTap: () => context.push(ClientRoutes.attendanceHistory),
            ),
          ];
        },
      ),
    );
  }

  static String _todayLabel() {
    const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
    const months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
    final n = DateTime.now();
    return '${days[n.weekday - 1]}, ${n.day} ${months[n.month - 1]}';
  }
}

/// One staff member's day: status, times and where they are now.
class _StaffTodayCard extends StatelessWidget {
  const _StaffTodayCard({required this.staff});
  final ClientStaffToday staff;

  static (String, Color) _status(String s) => switch (s) {
        'PRESENT' => ('Present', AppColors.success),
        'CHECKED_OUT' => ('Checked out', AppColors.secondary),
        _ => ('Not checked in', AppColors.warning),
      };

  @override
  Widget build(BuildContext context) {
    final (statusLabel, statusColor) = _status(staff.status);
    final last = staff.lastLocation;
    final small = GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary);
    final times = [
      if (staff.checkIn != null) 'In ${DateFormatter.time(staff.checkIn)}',
      if (staff.checkOut != null) 'Out ${DateFormatter.time(staff.checkOut)}',
    ].join('  ·  ');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
            child: Row(
              children: [
                DsInitialsAvatar(name: staff.name, size: 46, radius: 23),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staff.name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15.5,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      if (staff.seriesLabel != null) Text(staff.seriesLabel!, style: small),
                    ],
                  ),
                ),
                DsPill(statusLabel, color: statusColor),
              ],
            ),
          ),
          if (times.isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(times, style: small.copyWith(fontWeight: FontWeight.w600)),
          ],
          if (last != null && last.label != null) ...[
            const SizedBox(height: 8),
            Row(
              children: [
                Icon(
                  last.atHome == true ? Icons.home_rounded : Icons.location_on_rounded,
                  size: 16,
                  color: last.atHome == true ? AppColors.success : AppColors.error,
                ),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    last.label!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: last.atHome == true ? AppColors.success : AppColors.error,
                    ),
                  ),
                ),
              ],
            ),
          ],
          if (last != null && last.stale) ...[
            const SizedBox(height: 4),
            Text(
              'Location not updated since ${DateFormatter.time(last.at)}',
              style: small.copyWith(color: AppColors.warning),
            ),
          ],
          if (staff.status == 'PRESENT') ...[
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerLeft,
              child: TextButton.icon(
                onPressed: () => context.push(ClientRoutes.staffLiveMap(staff.staffId)),
                icon: const Icon(Icons.map_rounded, size: 18),
                label: const Text('View on map'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Attendance history.
class ClientAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const ClientAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<ClientAttendanceHistoryScreen> createState() => _ClientAttendanceHistoryScreenState();
}

class _ClientAttendanceHistoryScreenState extends ConsumerState<ClientAttendanceHistoryScreen> {
  String? _filter;
  String? _staffId;
  DateTimeRange? _range;

  static String _ymd(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  ClientHistoryFilter get _query => (
        staffId: _staffId,
        from: _range == null ? null : _ymd(_range!.start),
        to: _range == null ? null : _ymd(_range!.end),
      );

  Future<void> _pickRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 2),
      lastDate: now,
      initialDateRange: _range ?? DateTimeRange(start: now.subtract(const Duration(days: 29)), end: now),
    );
    if (picked == null || !mounted) return;
    // The server accepts at most 3 months.
    if (picked.end.difference(picked.start).inDays > 92) {
      context.showDsSnackBar('Pick at most 3 months', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _range = picked);
  }

  static const _filters = [
    ('All', null),
    ('Present', 'PRESENT'),
    ('Late', 'LATE'),
    ('Absent', 'ABSENT'),
  ];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(clientAttendanceHistoryFilteredProvider(_query));
    final staff = ref.watch(clientTodayAttendanceProvider).valueOrNull?.staff ?? const <ClientStaffToday>[];
    final range = _range;

    return DsPage(
      title: 'Attendance history',
      subtitle: range == null
          ? 'Last 30 days'
          : '${DateFormatter.date(range.start)} – ${DateFormatter.date(range.end)}',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(clientAttendanceHistoryFilteredProvider(_query)),
      actions: [
        DsPageAction(icon: Icons.date_range_rounded, tooltip: 'Date range', onPressed: _pickRange),
      ],
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(clientAttendanceHistoryFilteredProvider(_query)),
        builder: (list) {
          int count(String s) => list.where((r) => r.status.toUpperCase() == s).length;
          final present = count('PRESENT');
          final late = count('LATE');
          final absent = count('ABSENT');
          final rate = list.isEmpty ? 0.0 : (present + late) / list.length;
          final shown = _filter == null ? list : list.where((r) => r.status.toUpperCase() == _filter).toList();

          return [
            DsGradientCard(
              child: Row(
                children: [
                  SizedBox(
                    width: 88,
                    height: 88,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: rate),
                      duration: 1000.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 8,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.18),
                              color: AppColors.sunYellow,
                            ),
                          ),
                          Text(
                            '${(v * 100).round()}%',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Attendance rate',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 6,
                          runSpacing: 6,
                          children: [
                            DsGlassPill('$present PRESENT'),
                            DsGlassPill('$late LATE'),
                            DsGlassPill('$absent ABSENT'),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            if (staff.length > 1) ...[
              const SizedBox(height: 18),
              SizedBox(
                height: 42,
                child: ListView(
                  scrollDirection: Axis.horizontal,
                  clipBehavior: Clip.none,
                  children: [
                    DsChoiceChip(
                      label: 'Everyone',
                      selected: _staffId == null,
                      onTap: () => setState(() => _staffId = null),
                    ),
                    for (final s in staff) ...[
                      const SizedBox(width: 8),
                      DsChoiceChip(
                        label: s.name.split(' ').first,
                        selected: _staffId == s.staffId,
                        onTap: () => setState(() => _staffId = s.staffId),
                      ),
                    ],
                  ],
                ),
              ),
            ],
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => DsChoiceChip(
                  label: _filters[i].$1,
                  selected: _filter == _filters[i].$2,
                  onTap: () => setState(() => _filter = _filters[i].$2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              const DsEmptyBlock(
                icon: Icons.event_busy_rounded,
                title: 'No records',
                message: 'Nothing to show for this filter yet.',
              )
            else
              for (var i = 0; i < shown.length; i++)
                _RecordCard(record: shown[i], showName: staff.length > 1 && _staffId == null)
                    .animate(delay: (40 * i.clamp(0, 10)).ms)
                    .fadeIn(duration: 280.ms)
                    .slideX(begin: 0.05, end: 0),
          ];
        },
      ),
    );
  }
}

class _RecordCard extends StatelessWidget {
  const _RecordCard({required this.record, this.showName = false});
  final bool showName;
  final ClientAttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final (color, icon) = _statusStyle(record.status);
    final absent = record.status.toUpperCase() == 'ABSENT';
    final out = record.checkOut;
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Row(
        children: [
          DsIconTile(icon, color: color, size: 42),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  showName && record.staffName != null ? '${record.date}  ·  ${record.staffName}' : record.date,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  absent
                      ? 'No check-in recorded'
                      : 'In ${DateFormatter.time(record.checkIn, fallback: '—')}'
                          '${out != null && out.isNotEmpty && out != '—' ? '  ·  Out ${DateFormatter.time(out)}' : ''}'
                          '${record.worked != null ? '  ·  ${record.worked}' : ''}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DsPill(_pretty(record.status), color: color),
        ],
      ),
    );
  }
}

/// Raise attendance issue.
class ClientRaiseAttendanceIssueScreen extends ConsumerStatefulWidget {
  const ClientRaiseAttendanceIssueScreen({super.key});

  @override
  ConsumerState<ClientRaiseAttendanceIssueScreen> createState() => _ClientRaiseAttendanceIssueScreenState();
}

class _ClientRaiseAttendanceIssueScreenState extends ConsumerState<ClientRaiseAttendanceIssueScreen> {
  final _message = TextEditingController();
  bool _loading = false;

  static const _quick = ['Late arrival', 'Left early', 'Did not show up', 'Wrong check-in time'];

  @override
  void dispose() {
    _message.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_message.text.trim().isEmpty) {
      context.showDsSnackBar('Please describe the issue', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).raiseAttendanceIssue(message: _message.text);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Issue submitted', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: 'Raise an issue',
      subtitle: 'Report an attendance concern',
      onBack: () => _backOrHome(context),
      bottom: DsGradientButton(
        label: 'Submit issue',
        icon: Icons.send_rounded,
        isLoading: _loading,
        onPressed: _loading ? null : _submit,
      ),
      body: [
        DsGradientCard(
          colors: DsGradientCard.orange,
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Tell us what happened',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Your Relationship Manager reviews every attendance issue.',
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
              const DsFloatingIconTile(icon: Icons.flag_rounded),
            ],
          ),
        ),
        const DsSection('Quick pick'),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final q in _quick)
              DsChoiceChip(
                label: q,
                selected: _message.text.trim() == q,
                onTap: () => setState(() {
                  _message.text = q;
                  _message.selection = TextSelection.collapsed(offset: q.length);
                }),
              ),
          ],
        ),
        const DsSection('Details'),
        DsLabeledField(
          label: 'Describe the issue',
          controller: _message,
          icon: Icons.edit_note_rounded,
          hint: 'e.g. Late arrival, early leave…',
          maxLines: 6,
          minLines: 4,
          onChanged: (_) => setState(() {}),
          textCapitalization: TextCapitalization.sentences,
        ),
      ],
    );
  }
}
