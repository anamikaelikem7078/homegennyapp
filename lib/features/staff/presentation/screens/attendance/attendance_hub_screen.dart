import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import 'attendance_history_screen.dart';

/// Attendance tab.
class StaffAttendanceHubScreen extends ConsumerWidget {
  const StaffAttendanceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(staffTodayAttendanceProvider);
    final placementsToday = ref.watch(staffPlacementsTodayProvider);
    final history = ref.watch(staffAttendanceHistoryProvider);
    final records = history.valueOrNull ?? const <AttendanceRecord>[];
    // Attendance can be marked at any house listed for today (trial,
    // confirmed, or a one-time visit on its date). Treat a still-loading/
    // errored list as "nothing to check in at" rather than letting the toggle
    // through optimistically.
    final placementConfirmed = placementsToday.valueOrNull?.placements.isNotEmpty ?? false;
    // The staff record's name, not the login account's (they can differ).
    final staffName = ref.watch(staffDashboardProvider).valueOrNull?.fullName.trim() ?? '';
    final userName = staffName.isNotEmpty ? staffName : ref.watch(authProvider).user?.name ?? 'You';
    // An open shift on the server wins over history, which can lag and keeps
    // the old check-out time when a shift is reopened after lunch.
    final shiftOpen = placementsToday.valueOrNull?.isCheckedIn ?? false;

    final worked = records.where((r) => r.status != 'absent').length;
    final consistency = records.isEmpty ? null : worked / records.length;

    return DsPage(
      title: 'Attendance',
      subtitle: 'Track your daily presence',
      showBack: false,
      extraBottomPadding: 90,
      onRefresh: () async {
        ref.invalidate(staffTodayAttendanceProvider);
        ref.invalidate(staffAttendanceHistoryProvider);
        ref.invalidate(staffDeploymentProvider);
        ref.invalidate(staffPlacementsTodayProvider);
      },
      actions: [
        DsPageAction(
          icon: Icons.calendar_month_rounded,
          tooltip: 'Monthly view',
          onPressed: () => context.push(StaffRoutes.monthlyAttendance),
        ),
      ],
      body: [
        _ConsistencyCard(consistency: consistency, days: records.length),
        const SizedBox(height: 16),
        ...dsAsyncBody(
          today,
          onRetry: () => ref.invalidate(staffTodayAttendanceProvider),
          builder: (record) => [
            _TodayCard(
              userName: userName,
              record: record,
              placementConfirmed: placementConfirmed,
              shiftOpen: shiftOpen,
              onCheckInAgain: () => context.push(StaffRoutes.checkIn),
              onTrigger: () {
                if (shiftOpen || (record != null && record.checkIn != null && record.checkOut == null)) {
                  context.push(StaffRoutes.checkOut);
                } else if (!placementConfirmed) {
                  context.showDsSnackBar(
                    'No active placement — you can check in once your RM has placed you.',
                    type: DsSnackBarType.warning,
                  );
                } else {
                  context.push(StaffRoutes.checkIn);
                }
              },
            ),
          ],
        ),
        if (records.isNotEmpty) ...[
          const DsSection('Recent days'),
          _RecentStrip(records: records.take(7).toList().reversed.toList()),
        ],
        DsSection(
          'History',
          trailing: TextButton(
            onPressed: () => context.push(StaffRoutes.attendanceHistory),
            child: Text('See all', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800)),
          ),
        ),
        if (history.isLoading && records.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 24),
            child: Center(child: CircularProgressIndicator()),
          )
        else if (records.isEmpty)
          const DsEmptyBlock(
            icon: Icons.history_rounded,
            title: 'No history yet',
            message: 'Your check-ins will show up here.',
          )
        else
          for (final r in records.take(3)) StaffAttendanceTile(record: r),
      ],
    );
  }
}

class _ConsistencyCard extends StatelessWidget {
  const _ConsistencyCard({required this.consistency, required this.days});
  final double? consistency;
  final int days;

  @override
  Widget build(BuildContext context) {
    final c = consistency;
    final label = c == null
        ? 'Start your first shift'
        : c >= 0.9
            ? 'Exceptional consistency'
            : c >= 0.75
                ? 'Good consistency'
                : 'Room to improve';
    return DsGradientCard(
      child: Row(
        children: [
          SizedBox(
            width: 96,
            height: 96,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: c ?? 0),
              duration: 1100.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 9,
                      strokeCap: StrokeCap.round,
                      backgroundColor: Colors.white.withValues(alpha: 0.2),
                      color: AppColors.sunYellow,
                    ),
                  ),
                  Text(
                    c == null ? '—' : '${(v * 100).round()}%',
                    style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
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
                const DsGlassPill('CONSISTENCY', icon: Icons.insights_rounded),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: Colors.white),
                ),
                Text(
                  days == 0 ? 'No days tracked yet' : 'Across your last $days tracked days',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.8),
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

class _RecentStrip extends StatelessWidget {
  const _RecentStrip({required this.records});
  final List<AttendanceRecord> records;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 14),
      decoration: dsCardDecoration(),
      child: Row(
        children: [
          for (var i = 0; i < records.length; i++)
            Expanded(
              child: Builder(builder: (context) {
                final (color, icon, _) = staffAttendanceStyle(records[i].status);
                final d = DateTime.tryParse(records[i].date);
                const days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
                return Column(
                  children: [
                    Text(
                      d == null ? '${i + 1}' : days[d.weekday - 1],
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.14), shape: BoxShape.circle),
                      child: Icon(icon, size: 18, color: color),
                    ).animate(delay: (60 * i).ms).scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack),
                  ],
                );
              }),
            ),
        ],
      ),
    );
  }
}

class _TodayCard extends StatefulWidget {
  const _TodayCard({
    required this.userName,
    required this.record,
    required this.placementConfirmed,
    required this.onTrigger,
    required this.onCheckInAgain,
    this.shiftOpen = false,
  });

  final String userName;
  final AttendanceRecord? record;
  final bool placementConfirmed;
  final VoidCallback onTrigger;

  /// Checking in again at the same house the same day reopens the shift.
  final VoidCallback onCheckInAgain;

  /// The server shows an open shift right now.
  final bool shiftOpen;

  @override
  State<_TodayCard> createState() => _TodayCardState();
}

class _TodayCardState extends State<_TodayCard> {
  double _drag = 0; // 0..1
  bool _triggered = false;

  @override
  void didUpdateWidget(covariant _TodayCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record != widget.record) _reset();
  }

  void _reset() => setState(() {
        _drag = 0;
        _triggered = false;
      });

  void _fire() {
    HapticFeedback.mediumImpact();
    setState(() {
      _drag = 1;
      _triggered = true;
    });
    widget.onTrigger();
    // Slide back if the user returns without finishing.
    Future.delayed(const Duration(milliseconds: 900), () {
      if (mounted) _reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final record = widget.record;
    final checkedIn = widget.shiftOpen || (record != null && record.checkIn != null);
    final checkedOut = !widget.shiftOpen && record != null && record.checkOut != null;
    final locked = !checkedIn && !checkedOut && !widget.placementConfirmed;

    final (statusText, statusColor, prompt, actionIcon) = locked
        ? ('Placement pending', AppColors.lightTextSecondary, 'Unlocks once placement is confirmed', Icons.lock_rounded)
        : checkedOut
            ? ('Shift completed', AppColors.success, 'Work completed', Icons.check_rounded)
            : checkedIn
                ? ('Checked in', AppColors.success, 'Slide to check out', Icons.logout_rounded)
                : ('Not checked in', AppColors.error, 'Slide to check in', Icons.login_rounded);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(radius: 26),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsInitialsAvatar(name: widget.userName, size: 46),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      'Today',
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              DsPill(statusText, color: statusColor),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _TimeBox(
                  label: 'Check in',
                  value: DateFormatter.timestamp(record?.checkIn),
                  active: checkedIn,
                  icon: Icons.login_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _TimeBox(
                  label: 'Check out',
                  value: DateFormatter.timestamp(record?.checkOut),
                  active: checkedOut,
                  icon: Icons.logout_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (checkedOut) ...[
            Container(
              height: 58,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                gradient: const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]),
                borderRadius: BorderRadius.circular(30),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.celebration_rounded, color: Colors.white, size: 20),
                  const SizedBox(width: 8),
                  Text(
                    'Shift completed today',
                    style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: Colors.white),
                  ),
                ],
              ),
            ).animate().fadeIn().scaleXY(begin: 0.95, end: 1),
            Align(
              child: TextButton.icon(
                onPressed: widget.onCheckInAgain,
                icon: const Icon(Icons.login_rounded, size: 18),
                label: const Text('Back at work? Check in again'),
              ),
            ),
          ] else
            LayoutBuilder(
              builder: (context, c) {
                const knob = 52.0;
                final track = c.maxWidth - knob - 6;
                return GestureDetector(
                  onTap: locked ? widget.onTrigger : null,
                  onHorizontalDragUpdate: locked || _triggered
                      ? null
                      : (d) => setState(() => _drag = (_drag + d.primaryDelta! / track).clamp(0.0, 1.0)),
                  onHorizontalDragEnd: locked || _triggered
                      ? null
                      : (_) {
                          if (_drag > 0.8) {
                            _fire();
                          } else {
                            setState(() => _drag = 0);
                          }
                        },
                  child: Container(
                    height: 58,
                    decoration: BoxDecoration(
                      color: locked ? AppColors.lightSurfaceVariant : AppColors.primaryContainer,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Stack(
                      alignment: Alignment.centerLeft,
                      children: [
                        // Progress fill.
                        AnimatedContainer(
                          duration: _drag == 0 ? 250.ms : Duration.zero,
                          width: knob + 6 + track * _drag,
                          decoration: BoxDecoration(
                            color: locked ? Colors.transparent : AppColors.primary.withValues(alpha: 0.18),
                            borderRadius: BorderRadius.circular(30),
                          ),
                        ),
                        Center(
                          child: Padding(
                            padding: const EdgeInsets.only(left: knob),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    prompt,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 13.5,
                                      fontWeight: FontWeight.w700,
                                      color: locked ? AppColors.lightTextSecondary : AppColors.primary,
                                    ),
                                  ),
                                ),
                                if (!locked) ...[
                                  const SizedBox(width: 4),
                                  const Icon(Icons.keyboard_double_arrow_right_rounded, size: 18, color: AppColors.primary)
                                      .animate(onPlay: (c) => c.repeat())
                                      .moveX(begin: -3, end: 4, duration: 900.ms)
                                      .fadeOut(begin: 1, duration: 900.ms),
                                ],
                              ],
                            ),
                          ),
                        ),
                        AnimatedPositioned(
                          duration: _drag == 0 ? 250.ms : Duration.zero,
                          curve: Curves.easeOutBack,
                          left: 3 + track * _drag,
                          child: Container(
                            width: knob,
                            height: knob,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: locked
                                  ? null
                                  : const LinearGradient(colors: [AppColors.primaryLight, AppColors.primaryDark]),
                              color: locked ? const Color(0xFF94A3B8) : null,
                              boxShadow: [
                                BoxShadow(
                                  color: (locked ? const Color(0xFF94A3B8) : AppColors.primary).withValues(alpha: 0.35),
                                  blurRadius: 10,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(actionIcon, color: Colors.white, size: 22),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
        ],
      ),
    );
  }
}

class _TimeBox extends StatelessWidget {
  const _TimeBox({required this.label, required this.value, required this.active, required this.icon});
  final String label;
  final String value;
  final bool active;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: active ? AppColors.primary.withValues(alpha: 0.06) : AppColors.lightBackground,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: active ? AppColors.iconAccent : AppColors.lightTextHint),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: active ? AppColors.lightTextPrimary : AppColors.lightTextHint,
                    ),
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
