import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';
import '../widgets/rm_stage_ui.dart';

/// Stage-aware staff detail hub — every action here depends on the staff's
/// real `pipeline_stage` and placement status; the screen never shows every
/// possible action at once (§31).
class RmStaffDetailScreen extends ConsumerWidget {
  const RmStaffDetailScreen({super.key, required this.staffId, this.initialStaff});

  final String staffId;
  /// Fast-path row passed via `context.push(..., extra: staffRow)` from a
  /// kanban card tap — shown immediately while `staffByIdProvider`
  /// refreshes in the background. See the plan's "Architecture decisions #4".
  final StaffRow? initialStaff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncStaff = ref.watch(staffByIdProvider(staffId));
    final staff = asyncStaff.maybeWhen(data: (d) => d, orElse: () => initialStaff);

    if (staff == null) {
      return Scaffold(
        backgroundColor: RmTheme.offWhite,
        appBar: AppBar(title: const Text('Staff details')),
        body: AsyncValueWidget<StaffRow?>(
          value: asyncStaff,
          onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
          builder: (data) => data == null
              ? const Center(child: Text('Staff not found'))
              : _StaffDetailView(staff: data),
        ),
      );
    }
    return _StaffDetailView(staff: staff);
  }
}

class _StaffDetailView extends ConsumerWidget {
  const _StaffDetailView({required this.staff});
  final StaffRow staff;

  // Ranked on the full flow so the indices below stay stable whether or not
  // S2.5 is shown.
  int get _idx => PipelineStages.orderWithS25.indexOf(staff.pipelineStage);

  /// S2.5 is switched off; show its tile only for a staff member still in it.
  bool get _showS25 => staff.pipelineStage == PipelineStages.s25Assess;

  RmStepState _stateFor(int stageIndex) {
    if (_idx > stageIndex) return RmStepState.done;
    if (_idx == stageIndex) return RmStepState.active;
    return RmStepState.pending;
  }

  String? _statusFor(int stageIndex) => switch (_stateFor(stageIndex)) {
        RmStepState.done => 'Completed',
        RmStepState.active => 'In progress',
        _ => 'Up next',
      };

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(staffPlacementProvider(staff.id));
    final primary = _buildPrimaryAction(context, placementAsync);

    return RmStageScaffold(
      title: 'Staff details',
      onRefresh: () async => ref.invalidate(staffByIdProvider(staff.id)),
      bottom: primary,
      body: [
        RmStaffBanner(
          staff: staff,
          extra: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              RmBannerChip(icon: Icons.phone_rounded, label: staff.mobile),
              if (staff.pvStatus != null)
                RmBannerChip(
                  icon: Icons.shield_rounded,
                  label: 'PV ${rmTitleCase(staff.pvStatus!)}',
                ),
            ],
          ),
        ),
        if (staff.pipelineStage == PipelineStages.terminal) ...[
          const SizedBox(height: 16),
          RmNote(
            tone: RmNoteTone.danger,
            title: 'Exited the pipeline',
            text: 'Terminal outcome: ${staff.terminalOutcome ?? 'unspecified'}',
          ),
        ],
        if (staff.pipelineStage == PipelineStages.deferred) ...[
          const SizedBox(height: 16),
          const RmNote(
            tone: RmNoteTone.warning,
            title: 'Deferred',
            text: 'Resume from the Deferred queue to continue the pipeline.',
          ),
        ],
        const RmSectionTitle(title: 'Pipeline steps'),
        RmStepTile(
          code: 'S2',
          icon: rmStageIcon(PipelineStages.s2Verify),
          title: 'Verification',
          subtitle: staff.pvStatus == null
              ? 'Identity, police & medical checks'
              : 'Police verification: ${rmTitleCase(staff.pvStatus!)}',
          state: _stateFor(1),
          statusLabel: _statusFor(1),
          onTap: () => context.push(RmRoutes.verificationDashboard(staff.id)),
        ),
        if (_showS25) RmStepTile(
          code: 'S2.5',
          icon: rmStageIcon(PipelineStages.s25Assess),
          title: 'Assessment',
          subtitle: 'Practical skills check',
          state: _stateFor(2),
          statusLabel: _statusFor(2),
          onTap: () => context.push(RmRoutes.stage25Assessment(staff.id)),
        ),
        RmStepTile(
          code: 'S3',
          icon: rmStageIcon(PipelineStages.s3Train),
          title: 'Training',
          subtitle: 'Modules & video certification',
          state: _stateFor(3),
          statusLabel: _statusFor(3),
          onTap: () => context.push(RmRoutes.stage3Training(staff.id)),
        ),
        RmStepTile(
          code: 'S4',
          icon: rmStageIcon(PipelineStages.s4Agreements),
          title: 'Agreements',
          subtitle: 'Employment agreement e-sign',
          state: _stateFor(4),
          statusLabel: _statusFor(4),
          onTap: () => context.push(RmRoutes.stage4Hub(staff.id)),
        ),
        _buildPlacement(context, placementAsync),
        const RmSectionTitle(title: 'Records'),
        Row(
          children: [
            Expanded(
              child: _QuickLink(
                icon: Icons.report_rounded,
                label: 'Incidents',
                hint: 'Logged issues',
                onTap: () => context.push(RmRoutes.staffIncidents(staff.id)),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _QuickLink(
                icon: Icons.event_available_rounded,
                label: 'Attendance',
                hint: 'Days & invoice',
                onTap: () => context.push(RmRoutes.staffInvoicePreview(staff.id)),
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildPlacement(BuildContext context, AsyncValue<PlacementRow?> placementAsync) {
    return placementAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
      error: (e, _) => const SizedBox.shrink(),
      data: (placement) {
        if (placement == null) {
          if (staff.pipelineStage != PipelineStages.s5Deploy) {
            return const SizedBox.shrink();
          }
          return RmStepTile(
            code: 'S5',
            icon: Icons.handshake_rounded,
            title: 'Placement',
            subtitle: 'Ready for placement — none created yet',
            state: RmStepState.active,
            statusLabel: 'Action needed',
            onTap: () => context.push(RmRoutes.stage5Hub(staff.id)),
          );
        }
        return RmStepTile(
          code: 'S5',
          icon: Icons.handshake_rounded,
          title: 'Placement',
          subtitle: placement.isTrial
              ? 'Trial — pending confirmation'
              : placement.isConfirmed
                  ? 'Confirmed — attendance & invoicing unlocked'
                  : rmTitleCase(placement.status),
          state: placement.isConfirmed ? RmStepState.done : RmStepState.warning,
          statusLabel: rmTitleCase(placement.status),
          onTap: () => context.push(RmRoutes.placementDetail(placement.id), extra: staff.id),
        );
      },
    );
  }

  Widget? _buildPrimaryAction(BuildContext context, AsyncValue<PlacementRow?> placementAsync) {
    Widget go(String label, VoidCallback onTap, {IconData? icon}) =>
        DsGradientButton(label: label, icon: icon, onPressed: onTap);

    switch (staff.pipelineStage) {
      case PipelineStages.s1Intake:
        return AdvanceStageButton(
          staffId: staff.id,
          fromStage: staff.pipelineStage,
          toStage: PipelineStages.s2Verify,
          label: 'Complete intake',
          reasonCode: 'INTAKE_COMPLETE',
        );
      case PipelineStages.s2Verify:
        return go('Continue verification',
            () => context.push(RmRoutes.verificationDashboard(staff.id)));
      case PipelineStages.s25Assess:
        return go('Continue assessment',
            () => context.push(RmRoutes.stage25Assessment(staff.id)));
      case PipelineStages.s3Train:
        return go('Continue training',
            () => context.push(RmRoutes.stage3Training(staff.id)));
      case PipelineStages.s4Agreements:
        return go('Continue agreements',
            () => context.push(RmRoutes.stage4Hub(staff.id)));
      case PipelineStages.s5Deploy:
        final placement = placementAsync.valueOrNull;
        const green = LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)]);
        if (placement == null) {
          return DsGradientButton(
            label: 'Create placement',
            icon: Icons.handshake_rounded,
            gradient: green,
            onPressed: () => context.push(RmRoutes.stage5Hub(staff.id)),
          );
        }
        return DsGradientButton(
          label: placement.isTrial ? 'Manage trial placement' : 'View placement',
          gradient: green,
          onPressed: () =>
              context.push(RmRoutes.placementDetail(placement.id), extra: staff.id),
        );
      default:
        return null;
    }
  }
}

class _QuickLink extends StatelessWidget {
  const _QuickLink({
    required this.icon,
    required this.label,
    required this.hint,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String hint;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
          ),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, size: 20, color: RmTheme.iconAccent),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      label,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      hint,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w500,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
