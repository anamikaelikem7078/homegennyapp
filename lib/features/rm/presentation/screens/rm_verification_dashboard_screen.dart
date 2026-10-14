import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/series/series_catalog.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';
import '../widgets/rm_stage_ui.dart';

/// S2 Verification hub — Aadhaar / DL / eChallan / police-verification /
/// medical, each backed by a real endpoint (see `RmRemoteDataSource`'s
/// verification section). Status per track is read from the aggregate
/// `GET /verification/:staffId`, falling back to the session-local
/// "attempted" set (`verificationSessionProvider`) if that call fails.
class RmVerificationDashboardScreen extends ConsumerWidget {
  const RmVerificationDashboardScreen({super.key, required this.staffId});
  final String staffId;

  static const _tracks = [
    _TrackDef(
      key: 'aadhaar',
      label: 'Aadhaar eKYC',
      subtitle: 'Identity verification via UIDAI OTP',
      icon: Icons.badge_rounded,
      route: RmRoutes.track1,
    ),
    _TrackDef(
      key: 'dl',
      label: 'Driving licence',
      subtitle: 'Licence validity & vehicle authorisation',
      icon: Icons.directions_car_rounded,
      route: RmRoutes.track2,
    ),
    _TrackDef(
      key: 'echallan',
      label: 'eChallan check',
      subtitle: 'Traffic violations & offence history',
      icon: Icons.receipt_long_rounded,
      route: RmRoutes.track3,
    ),
    _TrackDef(
      key: 'pv',
      label: 'Police verification',
      subtitle: 'Criminal background screening',
      icon: Icons.local_police_rounded,
      route: RmRoutes.track4,
    ),
    _TrackDef(
      key: 'medical',
      label: 'Medical screening',
      subtitle: 'General health & sobriety check',
      icon: Icons.health_and_safety_rounded,
      route: RmRoutes.track5,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final statusAsync = ref.watch(rmVerificationStatusProvider(staffId));
    final sessionAttempted = ref.watch(verificationSessionProvider(staffId));

    final staff = staffAsync.valueOrNull;
    if (staff == null) {
      return Scaffold(
        backgroundColor: RmTheme.offWhite,
        appBar: AppBar(title: const Text('Verification')),
        body: AsyncValueWidget<StaffRow?>(
          value: staffAsync,
          onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
          builder: (_) => Center(
            child: Text(
              'Staff not found',
              style: GoogleFonts.plusJakartaSans(color: RmTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    final isDriver = staff.series == StaffSeries.driver;
    final visible = _tracks
        .where((t) => isDriver || (t.key != 'dl' && t.key != 'echallan'))
        .toList();
    final status = statusAsync.maybeWhen(
      data: (m) => m,
      orElse: () => const <String, String>{},
    );

    String? effective(_TrackDef t) =>
        status[t.key] ?? (t.key == 'pv' ? staff.pvStatus : null);
    final cleared = visible
        .where((t) => _isClear(effective(t) ?? ''))
        .length;

    final serverVerdict = status['__all_required_clear__'];
    final bool allDone;
    if (serverVerdict != null) {
      allDone = serverVerdict == 'true';
    } else {
      final isMaid = staff.series == StaffSeries.maid;
      final aadhaarOk = (status['aadhaar'] ?? '').toUpperCase() == 'VERIFIED' ||
          (status['aadhaar'] ?? '').toUpperCase() == 'CLEAR';
      final medicalOk = (status['medical'] ?? '').toUpperCase() == 'CLEAR';
      final dlOk = !isDriver || (status['dl'] ?? '').toUpperCase() == 'VALID';
      final pvValue = (status['pv'] ?? staff.pvStatus ?? '').toUpperCase();
      final pvOk = isMaid
          ? pvValue != 'ADVERSE' && pvValue != 'FAILED'
          : pvValue == 'CLEAR' || pvValue == 'VERIFIED';
      allDone = aadhaarOk && medicalOk && dlOk && pvOk;
    }

    // S2.5 (the Driver practical) only while the backend has it switched on;
    // otherwise S2 goes straight to S3 for every series.
    final toS25 = isDriver && ref.watch(seriesCatalogProvider).stage25Enabled;
    final nextStage = toS25 ? PipelineStages.s25Assess : PipelineStages.s3Train;
    final nextLabel =
        toS25 ? 'Advance to Assessment (S2.5)' : 'Advance to Training (S3)';

    return RmStageScaffold(
      title: 'Verification',
      stageCode: 'S2',
      stageColor: rmStageColor(PipelineStages.s2Verify),
      onRefresh: () async => ref.invalidate(rmVerificationStatusProvider(staffId)),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdvanceStageButton(
            staffId: staffId,
            fromStage: staff.pipelineStage,
            toStage: nextStage,
            label: nextLabel,
            reasonCode: 'VERIFICATION_COMPLETE',
            enabled: allDone,
          ),
          RmHint(
            done: allDone,
            text: allDone
                ? 'All required checks cleared — ready to advance.'
                : 'All checks required for this series must clear first.',
          ),
        ],
      ),
      body: [
        RmStaffBanner(staff: staff, showTracker: false),
        const SizedBox(height: 14),
        _ProgressCard(
          cleared: cleared,
          total: visible.length,
          loading: statusAsync.isLoading,
        ),
        const RmSectionTitle(title: 'Verification checks'),
        for (final track in visible)
          _TrackTile(
            track: track,
            staffId: staffId,
            status: statusAsync.maybeWhen(
              data: (m) => m[track.key],
              orElse: () => null,
            ),
            attempted: sessionAttempted.contains(track.key),
            pvStatusOverride: track.key == 'pv' ? staff.pvStatus : null,
          ),
      ],
    );
  }
}

bool _isClear(String s) {
  final u = s.toUpperCase();
  return u == 'VERIFIED' || u == 'VALID' || u == 'CLEAR';
}

class _ProgressCard extends StatelessWidget {
  const _ProgressCard({
    required this.cleared,
    required this.total,
    required this.loading,
  });

  final int cleared;
  final int total;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    final frac = total == 0 ? 0.0 : cleared / total;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            height: 60,
            child: TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: frac),
              duration: 900.ms,
              curve: Curves.easeOutCubic,
              builder: (_, v, _) => Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox.expand(
                    child: CircularProgressIndicator(
                      value: v,
                      strokeWidth: 6,
                      strokeCap: StrokeCap.round,
                      color: RmTheme.emeraldGreen,
                      backgroundColor: RmTheme.surfaceSecondary,
                    ),
                  ),
                  Text(
                    '$cleared/$total',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: RmTheme.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cleared == total && total > 0
                      ? 'All checks cleared'
                      : '$cleared of $total checks cleared',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  loading
                      ? 'Refreshing status…'
                      : 'Tap a check below to start or review it.',
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
    );
  }
}

class _TrackDef {
  const _TrackDef({
    required this.key,
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.route,
  });
  final String key;
  final String label;
  final String subtitle;
  final IconData icon;
  final String Function(String staffId) route;
}

class _TrackTile extends ConsumerWidget {
  const _TrackTile({
    required this.track,
    required this.staffId,
    required this.status,
    required this.attempted,
    this.pvStatusOverride,
  });

  final _TrackDef track;
  final String staffId;
  final String? status;
  final bool attempted;
  final String? pvStatusOverride;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `status` comes from the live per-staff `GET /verification/:staffId` call
    // and reflects Submit/Record Result immediately. `pvStatusOverride`
    // (staff.pvStatus) is sourced from the cached, unfiltered kanban list —
    // it can lag behind right after a PV action, so it's only a fallback
    // for when the live call hasn't resolved yet, never the primary source.
    final effectiveStatus = status ?? pvStatusOverride;
    final display = effectiveStatus ?? (attempted ? 'ATTEMPTED' : 'NOT STARTED');

    return RmStepTile(
      icon: track.icon,
      title: track.label,
      subtitle: track.subtitle,
      state: _stateFor(display),
      statusLabel: rmTitleCase(display),
      onTap: () async {
        ref
            .read(verificationSessionProvider(staffId).notifier)
            .update((s) => {...s, track.key});
        await context.push<void>(track.route(staffId));
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(rmVerificationStatusProvider(staffId));
          ref.invalidate(rmKanbanProvider);
          ref.invalidate(staffByIdProvider(staffId));
        });
      },
    );
  }

  RmStepState _stateFor(String display) {
    final upper = display.toUpperCase();
    if (_isClear(upper)) return RmStepState.done;
    if (upper == 'PENDING' || upper == 'ATTEMPTED' || upper == 'IN_PROGRESS') {
      return RmStepState.warning;
    }
    if (upper == 'NOT STARTED' || upper == 'NOT_INITIATED') {
      return RmStepState.pending;
    }
    return RmStepState.failed;
  }
}
