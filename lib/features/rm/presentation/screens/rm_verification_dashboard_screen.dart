import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';

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
      icon: Icons.badge_outlined,
      route: RmRoutes.track1,
    ),
    _TrackDef(
      key: 'dl',
      label: 'Driving License',
      subtitle: 'License validity & vehicle authorization',
      icon: Icons.directions_car_outlined,
      route: RmRoutes.track2,
    ),
    _TrackDef(
      key: 'echallan',
      label: 'eChallan Check',
      subtitle: 'Traffic violations & offense history',
      icon: Icons.receipt_long_outlined,
      route: RmRoutes.track3,
    ),
    _TrackDef(
      key: 'pv',
      label: 'Police Verification',
      subtitle: 'Criminal background screening',
      icon: Icons.local_police_outlined,
      route: RmRoutes.track4,
    ),
    _TrackDef(
      key: 'medical',
      label: 'Medical Screening',
      subtitle: 'General health & sobriety check',
      icon: Icons.health_and_safety_outlined,
      route: RmRoutes.track5,
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final statusAsync = ref.watch(rmVerificationStatusProvider(staffId));
    final sessionAttempted = ref.watch(verificationSessionProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Verification (S2)',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
      ),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
        builder: (staff) {
          if (staff == null) {
            return Center(
              child: Text(
                'Staff not found',
                style: GoogleFonts.inter(color: RmTheme.textSecondary),
              ),
            );
          }
          final isDriver = staff.series == StaffSeries.driver;

          return RefreshIndicator(
            color: RmTheme.electricBlue,
            onRefresh: () async =>
                ref.invalidate(rmVerificationStatusProvider(staffId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Staff Profile Card Header ──
                  _buildProfileHeader(staff),

                  const SizedBox(height: 20),

                  // ── Loading Bar ──
                  statusAsync.when(
                    loading: () => const Padding(
                      padding: EdgeInsets.only(bottom: 16),
                      child: LinearProgressIndicator(
                        color: RmTheme.electricBlue,
                        backgroundColor: RmTheme.offWhite,
                      ),
                    ),
                    error: (_, __) => const SizedBox.shrink(),
                    data: (_) => const SizedBox.shrink(),
                  ),

                  // ── Verification Track Cards ──
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: _tracks.length,
                    itemBuilder: (context, index) {
                      final track = _tracks[index];
                      if ((track.key == 'dl' || track.key == 'echallan') &&
                          !isDriver) {
                        return const SizedBox.shrink();
                      }

                      return _TrackTile(
                        track: track,
                        staffId: staffId,
                        status: statusAsync.maybeWhen(
                          data: (m) => m[track.key],
                          orElse: () => null,
                        ),
                        attempted: sessionAttempted.contains(track.key),
                        pvStatusOverride:
                            track.key == 'pv' ? staff.pvStatus : null,
                        index: index,
                      );
                    },
                  ),

                  const SizedBox(height: 20),

                  // ── Advanced Footer Actions ──
                  Builder(
                    builder: (context) {
                      final status = statusAsync.maybeWhen(
                        data: (m) => m,
                        orElse: () => const <String, String>{},
                      );

                      final serverVerdict = status['__all_required_clear__'];
                      final bool allDone;
                      if (serverVerdict != null) {
                        allDone = serverVerdict == 'true';
                      } else {
                        final isMaid = staff.series == StaffSeries.maid;
                        final aadhaarOk =
                            (status['aadhaar'] ?? '').toUpperCase() == 'VERIFIED' ||
                                (status['aadhaar'] ?? '').toUpperCase() == 'CLEAR';
                        final medicalOk =
                            (status['medical'] ?? '').toUpperCase() == 'CLEAR';
                        final dlOk = !isDriver ||
                            (status['dl'] ?? '').toUpperCase() == 'VALID';
                        final pvValue =
                            (status['pv'] ?? staff.pvStatus ?? '').toUpperCase();
                        final pvOk = isMaid
                            ? pvValue != 'ADVERSE' && pvValue != 'FAILED'
                            : pvValue == 'CLEAR' || pvValue == 'VERIFIED';
                        allDone = aadhaarOk && medicalOk && dlOk && pvOk;
                      }

                      final nextStage = isDriver
                          ? PipelineStages.s25Assess
                          : PipelineStages.s3Train;
                      final nextLabel = isDriver
                          ? 'Advance to Assessment (S2.5)'
                          : 'Advance to Training (S3)';

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          AdvanceStageButton(
                            staffId: staffId,
                            fromStage: staff.pipelineStage,
                            toStage: nextStage,
                            label: nextLabel,
                            reasonCode: 'VERIFICATION_COMPLETE',
                            enabled: allDone,
                          ),
                          if (!allDone)
                            Padding(
                              padding: const EdgeInsets.only(top: 10, left: 4),
                              child: Row(
                                children: [
                                  const Icon(
                                    Icons.info_outline_rounded,
                                    color: RmTheme.textSecondary,
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'All tracks required for this series must clear before advancing.',
                                      style: GoogleFonts.inter(
                                        color: RmTheme.textSecondary,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ).animate().fadeIn(delay: 250.ms, duration: 350.ms);
                    },
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(StaffRow staff) {
    final firstLetter =
        staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: RmTheme.electricBlue.withValues(alpha: 0.1),
            child: Text(
              firstLetter,
              style: GoogleFonts.inter(
                color: RmTheme.electricBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  staff.fullName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${staff.staffCode} • ${StaffSeries.label(staff.series).toUpperCase()}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.02, end: 0, duration: 400.ms);
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
    required this.index,
  });

  final _TrackDef track;
  final String staffId;
  final String? status;
  final bool attempted;
  final String? pvStatusOverride;
  final int index;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // `status` comes from the live per-staff `GET /verification/:staffId` call
    // and reflects Submit/Record Result immediately. `pvStatusOverride`
    // (staff.pvStatus) is sourced from the cached, unfiltered kanban list —
    // it can lag behind right after a PV action, so it's only a fallback
    // for when the live call hasn't resolved yet, never the primary source.
    final effectiveStatus = status ?? pvStatusOverride;
    final display =
        effectiveStatus ?? (attempted ? 'ATTEMPTED' : 'NOT STARTED');
    final displayFormatted = display.replaceAll('_', ' ').toUpperCase();

    final statusColor = _colorFor(display);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
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
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Circle Lead Icon ──
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(track.icon, color: statusColor, size: 22),
                ),
                const SizedBox(width: 14),

                // ── Title & Helper Details ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        track.label,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        track.subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 10),

                // ── Pill Status ──
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    displayFormatted,
                    style: GoogleFonts.inter(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: statusColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: RmTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        );
  }

  Color _colorFor(String display) {
    final upper = display.toUpperCase();
    if (upper == 'VERIFIED' || upper == 'VALID' || upper == 'CLEAR') {
      return RmTheme.emeraldGreen;
    }
    if (upper == 'PENDING' || upper == 'ATTEMPTED' || upper == 'IN_PROGRESS') {
      return RmTheme.amberWarning;
    }
    if (upper == 'NOT STARTED' || upper == 'NOT_INITIATED') {
      return RmTheme.textSecondary;
    }
    return RmTheme.crimsonDanger;
  }
}
