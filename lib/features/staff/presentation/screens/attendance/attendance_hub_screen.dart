import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

class StaffAttendanceHubScreen extends ConsumerWidget {
  const StaffAttendanceHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(staffTodayAttendanceProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        title: Column(
          children: [
            Text(
              'Attendance',
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF0F172A),
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Track your daily presence',
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF64748B),
                fontSize: 14,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(24),
        children: [
          const SizedBox(height: 16),
          // Integrated Performance Hub
          _PerformanceGaugeCard(),
          const SizedBox(height: 32),

          // Sleek Precision Actions
          today.when(
            data: (record) {
              final authState = ref.watch(authProvider);
              final userName = authState.user?.name ?? 'Rajesh Kumar';
              return _TactileAttendanceToggle(
                userName: userName,
                record: record,
                onTrigger: () {
                  if (record != null && record.checkIn != null) {
                    context.push(StaffRoutes.checkOut);
                  } else {
                    context.push(StaffRoutes.checkIn);
                  }
                },
              );
            },
            loading: () => const Center(
              child: Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: CircularProgressIndicator(),
              ),
            ),
            error: (err, stack) => Center(
              child: Text(
                'Failed to load attendance: $err',
                style: GoogleFonts.inter(color: Colors.red),
              ),
            ),
          ),
          const SizedBox(height: 32),

          // Tech Highlight Milestone
          _PerfectWeekCard(),
          const SizedBox(height: 32),

          // Condensed Activity Log
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'HISTORY',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: const Color(0xFF64748B),
                  letterSpacing: 1.5,
                ),
              ),
              GestureDetector(
                onTap: () => context.push(StaffRoutes.attendanceHistory),
                child: Text(
                  'Archive',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF1A56FF),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Consumer(
            builder: (context, ref, _) {
              final history = ref.watch(staffAttendanceHistoryProvider);
              return history.when(
                loading: () => const Padding(
                  padding: EdgeInsets.symmetric(vertical: 16),
                  child: Center(child: CircularProgressIndicator()),
                ),
                error: (err, _) => Text(
                  'Failed to load history',
                  style: GoogleFonts.inter(color: Colors.red),
                ),
                data: (records) {
                  if (records.isEmpty) {
                    return Text(
                      'No attendance history yet',
                      style: GoogleFonts.inter(color: const Color(0xFF64748B)),
                    );
                  }
                  final recent = records.take(3).toList();
                  return Column(
                    children: [
                      for (var i = 0; i < recent.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Builder(builder: (context) {
                          final r = recent[i];
                          final isPresent = r.status == 'present';
                          final isInProgress = r.status == 'in_progress';
                          final subtitle = r.checkOut != null
                              ? 'In: ${DateFormatter.time(r.checkIn, fallback: '—')} · Out: ${DateFormatter.time(r.checkOut)}'
                              : r.checkIn != null
                                  ? 'In: ${DateFormatter.time(r.checkIn)}'
                                  : 'Absent';
                          return _HistoryLogItem(
                            title: r.date,
                            subtitle: subtitle,
                            tagLabel: r.status.toUpperCase(),
                            tagColor: isPresent
                                ? const Color(0xFF1A56FF)
                                : isInProgress
                                    ? const Color(0xFFF59E0B)
                                    : const Color(0xFFEF4444),
                            tagBgColor: isPresent
                                ? const Color(0xFF1A56FF).withOpacity(0.1)
                                : isInProgress
                                    ? const Color(0xFFF59E0B).withOpacity(0.1)
                                    : const Color(0xFFFEE2E2),
                            icon: Icons.calendar_today_outlined,
                          );
                        }),
                      ],
                    ],
                  );
                },
              );
            },
          ),
          const SizedBox(height: 32),

          const SizedBox(height: 48),
        ],
      ),
    );
  }
}

class _PerformanceGaugeCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Container(
          width: 200,
          height: 200,
          decoration: BoxDecoration(
            color: const Color(0xFF1A56FF),
            borderRadius: BorderRadius.circular(32),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFF1A56FF).withOpacity(0.2),
                blurRadius: 24,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Center(
            child: Container(
              width: 160,
              height: 160,
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '94%',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 48,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF1A56FF),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'CONSISTENCY',
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF64748B),
                      letterSpacing: 1.5,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        const SizedBox(height: 20),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.check_circle_outline,
              color: Color(0xFF1A56FF),
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              'Exceptional status maintained',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
              ),
            ),
          ],
        ),
      ],
    );
  }
}

class _TactileAttendanceToggle extends StatefulWidget {
  const _TactileAttendanceToggle({
    required this.userName,
    required this.record,
    required this.onTrigger,
  });

  final String userName;
  final AttendanceRecord? record;
  final VoidCallback onTrigger;

  @override
  State<_TactileAttendanceToggle> createState() =>
      _TactileAttendanceToggleState();
}

class _TactileAttendanceToggleState extends State<_TactileAttendanceToggle> {
  double _dragAlignment = -1.0;
  bool _isTriggered = false;

  @override
  void didUpdateWidget(covariant _TactileAttendanceToggle oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.record != widget.record) {
      setState(() {
        _dragAlignment = -1.0;
        _isTriggered = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);

    final record = widget.record;
    final isCheckedIn = record != null && record.checkIn != null;
    final isCheckedOut = record != null && record.checkOut != null;

    String statusText = 'Checked Out';
    String actionPrompt = 'Slide right to Check In';
    IconData actionIcon = Icons.login_rounded;
    Color statusColor = const Color(0xFFEF4444);

    if (isCheckedIn && !isCheckedOut) {
      statusText = 'Checked In';
      actionPrompt = 'Slide right to Check Out';
      actionIcon = Icons.logout_rounded;
      statusColor = const Color(0xFF10B981);
    } else if (isCheckedOut) {
      statusText = 'Shift Completed';
      actionPrompt = 'Work Completed';
      statusColor = const Color(0xFF64748B);
    }

    final checkInTime = DateFormatter.timestamp(record?.checkIn);
    final checkOutTime = DateFormatter.timestamp(record?.checkOut);

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.01),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Row 1: Profile details & Status Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.userName,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: textDark,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Active Care Specialist',
                      style: GoogleFonts.inter(fontSize: 12, color: textGrey),
                    ),
                  ],
                ),
              ),
              // Status Indicator Badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: statusColor,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      statusText,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: statusColor,
                        letterSpacing: 0.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 24),
          const Divider(color: Color(0xFFF1F5F9), height: 1),
          const SizedBox(height: 24),

          // Row 2: Double precision time log metrics
          Row(
            children: [
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'CHECK IN',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textGrey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkInTime,
                      style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isCheckedIn ? primaryColor : textGrey,
                      ),
                    ),
                  ],
                ),
              ),
              Container(width: 1.5, height: 40, color: const Color(0xFFF1F5F9)),
              Expanded(
                child: Column(
                  children: [
                    Text(
                      'CHECK OUT',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: textGrey,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      checkOutTime,
                      style: GoogleFonts.robotoMono(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: isCheckedOut ? primaryColor : textGrey,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // Row 3: Trending Slide to confirm Toggle Switch
          if (isCheckedOut) ...[
            Container(
              height: 56,
              decoration: BoxDecoration(
                color: const Color(0xFF10B981),
                borderRadius: BorderRadius.circular(28),
              ),
              child: Center(
                child: Text(
                  'Shift Completed Today',
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
            ),
          ] else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final maxDragWidth =
                    constraints.maxWidth - 56.0; // Subtract toggle button width
                return Container(
                  height: 56,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Stack(
                    alignment: Alignment.centerLeft,
                    children: [
                      // Action Prompt Text
                      Center(
                        child: Text(
                          actionPrompt,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textGrey,
                          ),
                        ),
                      ),
                      // The slide target area
                      GestureDetector(
                        onHorizontalDragUpdate: (details) {
                          if (_isTriggered) return;

                          // Calculate delta percentage
                          final delta = details.primaryDelta! / maxDragWidth;
                          setState(() {
                            _dragAlignment +=
                                delta *
                                2.0; // alignment ranges from -1.0 to 1.0
                            if (_dragAlignment < -1.0) _dragAlignment = -1.0;
                            if (_dragAlignment > 1.0) _dragAlignment = 1.0;
                          });
                        },
                        onHorizontalDragEnd: (details) {
                          if (_isTriggered) return;

                          if (_dragAlignment > 0.8) {
                            // Successfully completed slide confirm
                            setState(() {
                              _dragAlignment = 1.0;
                              _isTriggered = true;
                            });
                            widget.onTrigger();
                          } else {
                            // Snap back
                            setState(() {
                              _dragAlignment = -1.0;
                            });
                          }
                        },
                        child: Align(
                          alignment: Alignment(_dragAlignment, 0.0),
                          child: Container(
                            width: 50,
                            height: 50,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: primaryColor,
                              boxShadow: [
                                BoxShadow(
                                  color: primaryColor.withOpacity(0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 4),
                                ),
                              ],
                            ),
                            child: Icon(
                              actionIcon,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ],
      ),
    );
  }
}

class _PerfectWeekCard extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFF1E293B), // Dark container
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF1E293B).withOpacity(0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: const Color(0xFF1A56FF).withOpacity(0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.stars_rounded,
                  color: Color(0xFF60A5FA),
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Perfect Week',
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.arrow_forward_rounded,
                  color: Colors.white,
                  size: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Seamless check-ins across all shifts since Monday.',
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class _HistoryLogItem extends StatelessWidget {
  final String title;
  final String subtitle;
  final String tagLabel;
  final Color tagColor;
  final Color tagBgColor;
  final IconData icon;

  const _HistoryLogItem({
    required this.title,
    required this.subtitle,
    required this.tagLabel,
    required this.tagColor,
    required this.tagBgColor,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 8,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFF8FAFC),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: const Color(0xFF64748B), size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF64748B),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              color: tagBgColor,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              tagLabel,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: tagColor,
                letterSpacing: 1,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
