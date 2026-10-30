import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../core/utils/date_formatter.dart';
import '../../../../../core/constants/api_constants.dart';
import '../../../../../core/constants/storage_keys.dart';
import '../../../../../core/di/injection.dart';
import '../../../../../core/series/series_catalog.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_snapshot.dart';
import '../../navigation/client_routes.dart';

const _ink = Color(0xFF0F172A);
const _muted = Color(0xFF64748B);
const _grey = Color(0xFF94A3B8);

final _accessTokenProvider = FutureProvider.autoDispose<String?>(
  (ref) => ref.watch(secureStorageProvider).read(StorageKeys.accessToken),
);

Color snapshotStatusColor(SnapshotStatus s) => switch (s) {
      SnapshotStatus.green => AppColors.success,
      SnapshotStatus.amber => AppColors.warning,
      SnapshotStatus.red => AppColors.error,
      SnapshotStatus.notStarted => _grey,
    };

/// `today.attendance` as the short pill text and its colour (brief §1).
(String, Color) attendanceLabel(SnapshotToday t, SnapshotDeployment d) {
  final inAt = t.checkIn == null ? 'In' : 'In at ${DateFormatter.since(t.checkIn)}';
  final due = d.shiftStart;
  return switch (t.attendance.toUpperCase()) {
    'ON_TIME' => (inAt, AppColors.success),
    'LATE' => (t.lateByMin == null ? inAt : '$inAt · ${t.lateByMin} min late', AppColors.warning),
    'CHECKED_IN' => (inAt, AppColors.success),
    'NOT_IN_YET' => (due == null ? 'Not in yet' : 'Not in yet · due $due', AppColors.warning),
    'NO_SHOW' => ('Not checked in today', AppColors.error),
    'ABSENT' => ('Absent today', AppColors.error),
    'ON_LEAVE' => ('On leave today', AppColors.error),
    _ => (due == null ? 'Not in yet' : 'Due at $due', _grey), // NOT_STARTED
  };
}

/// One staff member's "Today at home" (brief §2–§4). Tapping the card opens
/// today's care (caretaker) or today's meals (cook); the photo/name opens
/// the staff profile. [footer] carries the existing per-staff actions.
class TodayAtHomeCard extends ConsumerWidget {
  const TodayAtHomeCard({
    super.key,
    required this.staff,
    required this.snapshotDate,
    this.replacements = const [],
    this.footer,
  });

  final SnapshotStaff staff;

  /// The snapshot's `date` — "today" for the trial banner.
  final String snapshotDate;
  final List<SnapshotReplacement> replacements;
  final Widget? footer;

  void _openToday(BuildContext context) {
    final pid = staff.placementId;
    if (pid.isEmpty) return;
    if (staff.isCook) {
      context.push(ClientRoutes.meals(pid));
    } else {
      context.push(ClientRoutes.careHome(pid), extra: staff.firstName);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = staff;
    final statusColor = snapshotStatusColor(s.statusToday);
    final (attText, attColor) = attendanceLabel(s.today, s.deployment);
    final name = s.firstName.isEmpty ? 'Staff' : s.firstName;
    final seriesLabel = s.seriesLabel.isNotEmpty ? s.seriesLabel : SeriesDisplay.label(s.series);
    final trialEnds = s.deployment.trialEnds;
    final today = DateTime.tryParse(snapshotDate);
    final trialDaysLeft = (s.deployment.isTrial && trialEnds != null && today != null)
        ? trialEnds.difference(DateTime(today.year, today.month, today.day)).inDays
        : null;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: const Color(0xFFE8EBF2)),
        boxShadow: [BoxShadow(color: const Color(0xFF0B1B4D).withValues(alpha: 0.04), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      clipBehavior: Clip.antiAlias,
      child: Stack(
        children: [
          Positioned(left: 0, top: 0, bottom: 0, width: 5, child: ColoredBox(color: statusColor)),
          Padding(
            padding: const EdgeInsets.only(left: 5),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: () => _openToday(context),
                      child: Padding(
                        padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _header(context, ref, name, seriesLabel, statusColor, attText, attColor),
                            const SizedBox(height: 10),
                            Text(
                              s.message,
                              style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.4, fontWeight: FontWeight.w600, color: _ink),
                            ),
                            ..._progress(),
                            const SizedBox(height: 12),
                            _WeekStrip(days: s.last7Days),
                            for (final r in replacements) ...[
                              const SizedBox(height: 10),
                              _InfoLine(
                                icon: Icons.swap_horiz_rounded,
                                color: AppColors.primary,
                                text: r.status.toUpperCase() == 'UNDER_RM_REVIEW' || r.status.isEmpty
                                    ? 'Replacement requested · RM reviewing'
                                    : 'Replacement requested · ${_pretty(r.status)}',
                              ),
                            ],
                            if (trialDaysLeft != null && trialDaysLeft >= 0 && trialDaysLeft <= 3) ...[
                              const SizedBox(height: 10),
                              _TrialBanner(name: name, ends: trialEnds!, placementId: s.placementId),
                            ],
                          ],
                        ),
                      ),
                    ),
                  ),
                  if (footer != null) ...[
                    const Divider(height: 1, color: Color(0xFFEFF1F6)),
                    footer!,
                  ],
                ],
              ),
          ),
        ],
      ),
    );
  }

  Widget _header(
    BuildContext context,
    WidgetRef ref,
    String name,
    String seriesLabel,
    Color statusColor,
    String attText,
    Color attColor,
  ) {
    final trial = staff.deployment.isTrial;
    final ends = staff.deployment.trialEnds;
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        GestureDetector(
          onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              _StaffPhoto(
                photoUrl: staff.photoUrl,
                name: name,
                token: ref.watch(_accessTokenProvider).valueOrNull,
                accent: SeriesDisplay.color(staff.series),
              ),
              Positioned(
                right: -1,
                bottom: -1,
                child: Container(
                  width: 15,
                  height: 15,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: statusColor,
                    border: Border.all(color: Colors.white, width: 3),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              GestureDetector(
                onTap: () => context.push(ClientRoutes.staffProfile(staff.staffId)),
                child: Text(
                  '$name · $seriesLabel',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: _ink),
                ),
              ),
              const SizedBox(height: 4),
              Wrap(
                spacing: 6,
                runSpacing: 4,
                children: [
                  _Pill(text: attText, color: attColor),
                  if (trial)
                    _Pill(
                      text: ends == null ? 'Trial' : 'Trial · ends ${DateFormat('d MMM').format(ends)}',
                      color: AppColors.warning,
                    ),
                ],
              ),
            ],
          ),
        ),
        const Icon(Icons.chevron_right_rounded, color: _grey),
      ],
    );
  }

  List<Widget> _progress() {
    final work = staff.today.work;
    final meals = staff.today.meals;
    final (done, total, unit, next) = work != null
        ? (work.done, work.total, 'tasks', work.next == null ? null : 'Next: ${work.next}')
        : meals != null
            ? (
                meals.logged,
                meals.planned,
                'meals',
                meals.notLogged.isEmpty ? null : 'Not logged: ${meals.notLogged.map(_pretty).join(', ')}',
              )
            : (0, 0, '', null);
    if (total <= 0) return const [];
    return [
      const SizedBox(height: 10),
      Row(
        children: [
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: (done / total).clamp(0, 1).toDouble(),
                minHeight: 7,
                backgroundColor: const Color(0xFFEFF1F6),
                color: done >= total ? AppColors.success : AppColors.primary,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            '$done/$total $unit',
            style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w800, color: _ink),
          ),
        ],
      ),
      if (next != null) ...[
        const SizedBox(height: 6),
        Text(
          next,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(fontSize: 12, color: _muted),
        ),
      ],
    ];
  }
}

String _pretty(String s) => s
    .replaceAll('_', ' ')
    .toLowerCase()
    .split(' ')
    .where((w) => w.isNotEmpty)
    .map((w) => w[0].toUpperCase() + w.substring(1))
    .join(' ');

class _Pill extends StatelessWidget {
  const _Pill({required this.text, required this.color});
  final String text;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(8)),
        child: Text(
          text,
          style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: color == _grey ? _muted : color),
        ),
      );
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.icon, required this.color, required this.text});
  final IconData icon;
  final Color color;
  final String text;

  @override
  Widget build(BuildContext context) => Row(
        children: [
          Icon(icon, size: 16, color: color),
          const SizedBox(width: 6),
          Expanded(
            child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w700, color: color)),
          ),
        ],
      );
}

/// §3 — one dot per day, oldest first; tap → attendance history.
class _WeekStrip extends StatelessWidget {
  const _WeekStrip({required this.days});
  final List<SnapshotDay> days;

  @override
  Widget build(BuildContext context) {
    if (days.isEmpty) return const SizedBox.shrink();
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => context.push(ClientRoutes.attendanceHistory),
      child: Row(
        children: [
          Text('Last 7 days', style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w600, color: _muted)),
          const SizedBox(width: 10),
          for (final d in days)
            Expanded(
              child: Column(
                children: [
                  Text(
                    d.date == null ? '' : DateFormat('E').format(d.date!)[0],
                    style: GoogleFonts.plusJakartaSans(fontSize: 10.5, fontWeight: FontWeight.w700, color: _muted),
                  ),
                  const SizedBox(height: 3),
                  _dot(d.attendance),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _dot(String attendance) {
    final color = switch (attendance.toUpperCase()) {
      'PRESENT' => AppColors.success,
      'ABSENT' => AppColors.error,
      'LEAVE' => AppColors.warning,
      _ => null, // NONE — nothing recorded
    };
    return Container(
      width: 11,
      height: 11,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: color,
        border: color == null ? Border.all(color: _grey, width: 1.5) : null,
      ),
    );
  }
}

/// §4 — shown when a trial ends today or within 3 days.
class _TrialBanner extends StatelessWidget {
  const _TrialBanner({required this.name, required this.ends, required this.placementId});
  final String name;
  final DateTime ends;
  final String placementId;

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(fontSize: 12.5, height: 1.4, color: _ink);
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text.rich(
        TextSpan(
          style: base,
          children: [
            TextSpan(
              text: 'Trial ends on ${DateFormat('d MMM').format(ends)}. ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(text: 'Happy with $name? Your RM will confirm the placement. Want a change? '),
            WidgetSpan(
              alignment: PlaceholderAlignment.baseline,
              baseline: TextBaseline.alphabetic,
              child: GestureDetector(
                onTap: () => context.push(
                  placementId.isEmpty
                      ? ClientRoutes.replacementRequest
                      : '${ClientRoutes.replacementRequest}?placement=${Uri.encodeComponent(placementId)}',
                ),
                child: Text(
                  'Request replacement',
                  style: base.copyWith(
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                    decoration: TextDecoration.underline,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// `photo_url` needs the bearer token and 404s when no photo is on file —
/// initials then.
class _StaffPhoto extends StatelessWidget {
  const _StaffPhoto({required this.photoUrl, required this.name, required this.token, required this.accent});

  final String? photoUrl;
  final String name;
  final String? token;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final initials = name.trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).take(2).map((w) => w[0].toUpperCase()).join();
    final fallback = Container(
      width: 50,
      height: 50,
      decoration: BoxDecoration(shape: BoxShape.circle, color: accent.withValues(alpha: 0.12)),
      alignment: Alignment.center,
      child: Text(
        initials.isEmpty ? '?' : initials,
        style: GoogleFonts.plusJakartaSans(color: accent, fontSize: 17, fontWeight: FontWeight.w800),
      ),
    );
    final url = photoUrl;
    if (url == null || url.isEmpty || token == null) return fallback;
    return ClipOval(
      child: Image.network(
        url.startsWith('http') ? url : '${ApiConstants.baseUrl}$url',
        width: 50,
        height: 50,
        fit: BoxFit.cover,
        headers: {ApiConstants.headerAuthorization: '${ApiConstants.bearerPrefix}$token'},
        errorBuilder: (_, _, _) => fallback,
      ),
    );
  }
}
