import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

String _currentMonthYear() {
  const months = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];
  final now = DateTime.now();
  return '${months[now.month - 1]} ${now.year}';
}

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

/// Attendance history.
class ClientAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const ClientAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<ClientAttendanceHistoryScreen> createState() => _ClientAttendanceHistoryScreenState();
}

class _ClientAttendanceHistoryScreenState extends ConsumerState<ClientAttendanceHistoryScreen> {
  String? _filter;

  static const _filters = [
    ('All', null),
    ('Present', 'PRESENT'),
    ('Late', 'LATE'),
    ('Absent', 'ABSENT'),
  ];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(clientAttendanceHistoryProvider);

    return DsPage(
      title: 'Attendance history',
      subtitle: _currentMonthYear(),
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(clientAttendanceHistoryProvider),
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(clientAttendanceHistoryProvider),
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
                _RecordCard(record: shown[i])
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
  const _RecordCard({required this.record});
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
                  record.date,
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
                      : 'In ${record.checkIn ?? '—'}'
                          '${out != null && out.isNotEmpty && out != '—' ? '  ·  Out $out' : ''}',
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
