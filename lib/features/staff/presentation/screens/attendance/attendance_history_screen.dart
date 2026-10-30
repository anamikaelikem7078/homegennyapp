import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Real backend status values: "present" | "in_progress" | "absent"
/// (see GET /staff/attendance/history) — there is no "late"/"leave".
(Color, IconData, String) staffAttendanceStyle(String status) => switch (status) {
      'present' => (AppColors.success, Icons.check_circle_rounded, 'Present'),
      'in_progress' => (AppColors.warning, Icons.timelapse_rounded, 'In progress'),
      'absent' => (AppColors.error, Icons.cancel_rounded, 'Absent'),
      _ => (AppColors.primary, Icons.circle_rounded, status.replaceAll('_', ' ')),
    };

/// Attendance history.
class StaffAttendanceHistoryScreen extends ConsumerStatefulWidget {
  const StaffAttendanceHistoryScreen({super.key});

  @override
  ConsumerState<StaffAttendanceHistoryScreen> createState() => _StaffAttendanceHistoryScreenState();
}

class _StaffAttendanceHistoryScreenState extends ConsumerState<StaffAttendanceHistoryScreen> {
  String? _filter;

  static const _filters = [
    ('All', null),
    ('Present', 'present'),
    ('In progress', 'in_progress'),
    ('Absent', 'absent'),
  ];

  @override
  Widget build(BuildContext context) {
    final history = ref.watch(staffAttendanceHistoryProvider);

    return DsPage(
      title: 'Attendance history',
      subtitle: 'Your daily check-ins',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.attendance),
      onRefresh: () async => ref.invalidate(staffAttendanceHistoryProvider),
      actions: [
        DsPageAction(
          icon: Icons.calendar_month_rounded,
          tooltip: 'Monthly view',
          onPressed: () => context.push(StaffRoutes.monthlyAttendance),
        ),
      ],
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(staffAttendanceHistoryProvider),
        builder: (records) {
          final present = records.where((r) => r.status == 'present').length;
          final inProgress = records.where((r) => r.status == 'in_progress').length;
          final absent = records.where((r) => r.status == 'absent').length;
          final shown = _filter == null ? records : records.where((r) => r.status == _filter).toList();

          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(child: DsGlassStat(value: '$present', label: 'Present', icon: Icons.check_circle_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: '$inProgress', label: 'In progress', icon: Icons.timelapse_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: '$absent', label: 'Absent', icon: Icons.cancel_rounded)),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (_, i) => DsChoiceChip(
                  label: _filters[i].$1,
                  selected: _filter == _filters[i].$2,
                  onTap: () => setState(() => _filter = _filters[i].$2),
                ),
              ),
            ),
            const SizedBox(height: 14),
            if (shown.isEmpty)
              const DsEmptyBlock(
                icon: Icons.history_rounded,
                title: 'No attendance records',
                message: 'Your attendance history will appear here.',
              )
            else
              for (var i = 0; i < shown.length; i++)
                StaffAttendanceTile(record: shown[i])
                    .animate(delay: (40 * i.clamp(0, 10)).ms)
                    .fadeIn(duration: 280.ms)
                    .slideX(begin: 0.05, end: 0),
          ];
        },
      ),
    );
  }
}

/// One day's attendance card (date, status, in/out times).
class StaffAttendanceTile extends StatelessWidget {
  const StaffAttendanceTile({super.key, required this.record});
  final AttendanceRecord record;

  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = staffAttendanceStyle(record.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: dsCardDecoration(radius: 20),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(12, 12, 14, 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            record.date,
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
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(child: _time(Icons.login_rounded, 'In', DateFormatter.time(record.checkIn))),
                        Expanded(child: _time(Icons.logout_rounded, 'Out', DateFormatter.time(record.checkOut))),
                      ],
                    ),
                    if (_clientTag(record.clientStatus) case (final tag, final tagColor, final tagIcon)) ...[
                      const SizedBox(height: 8),
                      Align(alignment: Alignment.centerLeft, child: DsPill(tag, color: tagColor, icon: tagIcon)),
                    ],
                    if (record.clientStatus == 'DISPUTED' && (record.clientNote?.isNotEmpty ?? false))
                      _note('Client: ${record.clientNote}', AppColors.error),
                    if (record.resolutionNote?.isNotEmpty ?? false)
                      _note('Resolved: ${record.resolutionNote}', AppColors.success),
                    if (record.location != null && record.location!.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.location_on_rounded, size: 14, color: AppColors.iconAccent),
                          const SizedBox(width: 4),
                          Expanded(
                            child: Text(
                              record.location!,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
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
    );
  }

  /// The client's confirmation of the day; null = no tag (NOT_REQUIRED, or
  /// an older server).
  static (String, Color, IconData)? _clientTag(String? s) => switch (s) {
        'PENDING' => ('Waiting for client', AppColors.warning, Icons.hourglass_top_rounded),
        'APPROVED' || 'DEEMED' || 'APPROVED_PAPER' => ('Confirmed', AppColors.success, Icons.verified_rounded),
        'DISPUTED' => ('Under review', AppColors.error, Icons.report_rounded),
        _ => null,
      };

  Widget _note(String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w600, color: color),
        ),
      );

  Widget _time(IconData icon, String label, String value) => Row(
        children: [
          Icon(icon, size: 15, color: AppColors.iconAccent),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              '$label  $value',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      );
}
