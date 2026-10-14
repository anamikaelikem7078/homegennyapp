import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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
import '../widgets/rm_stage_ui.dart';

/// S3 Training. No dedicated RM-facing training-completion endpoint exists
/// on the backend (verified against live Swagger — see the plan's
/// "Architecture decisions #6"), so this screen does not fabricate a
/// completion status. Advancing to S4 requires an explicit RM attestation
/// checkbox rather than a fake automated "complete" signal. Video
/// certification — the one part of this stage with real backend support —
/// is linked out to its own read-only monitoring screen.
class RmStage3TrainingScreen extends ConsumerStatefulWidget {
  const RmStage3TrainingScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmStage3TrainingScreen> createState() =>
      _RmStage3TrainingScreenState();
}

class _RmStage3TrainingScreenState extends ConsumerState<RmStage3TrainingScreen> {
  bool _attested = false;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));
    final staff = staffAsync.valueOrNull;

    if (staff == null) {
      return Scaffold(
        backgroundColor: RmTheme.offWhite,
        appBar: AppBar(title: const Text('Training')),
        body: AsyncValueWidget<StaffRow?>(
          value: staffAsync,
          onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
          builder: (_) => Center(
            child: Text(
              'Staff not found',
              style: GoogleFonts.plusJakartaSans(color: RmTheme.textSecondary),
            ),
          ),
        ),
      );
    }

    return RmStageScaffold(
      title: 'Training',
      stageCode: 'S3',
      stageColor: rmStageColor(PipelineStages.s3Train),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdvanceStageButton(
            staffId: staff.id,
            fromStage: staff.pipelineStage,
            toStage: PipelineStages.s4Agreements,
            label: 'Advance to Agreements (S4)',
            reasonCode: 'TRAINING_ATTESTED',
            enabled: _attested,
          ),
          RmHint(
            done: _attested,
            text: _attested
                ? 'Signed off — ready to advance.'
                : 'Tick the sign-off above to unlock.',
          ),
        ],
      ),
      body: [
        RmStaffBanner(staff: staff, showTracker: false),
        const SizedBox(height: 14),
        const RmNote(
          tone: RmNoteTone.warning,
          title: 'How this stage works',
          text:
              'Training completion isn\'t tracked automatically yet. Check the '
              'video certification below, then sign off to advance.',
        ),
        const RmSectionTitle(title: 'Certification'),
        _videoCertTile(staff.id, staff.series),
        const RmSectionTitle(title: 'RM sign-off'),
        _AttestCard(
          value: _attested,
          onChanged: (v) {
            HapticFeedback.mediumImpact();
            setState(() => _attested = v);
          },
        ),
      ],
    );
  }

  Widget _videoCertTile(String staffId, String series) {
    final promptsAsync = ref.watch(rmVideoCertPromptsProvider(series));
    final itemsAsync = ref.watch(rmVideoCertsProvider(staffId));

    // Complete only once every required prompt has a submitted item that a
    // trainer has approved — a PENDING/REJECTED or missing item still counts
    // as incomplete.
    bool? complete;
    var approvedCount = 0;
    var totalCount = 0;
    String subtitle = 'View submitted prompts and trainer review status';
    final prompts = promptsAsync.valueOrNull;
    final items = itemsAsync.valueOrNull;
    if (prompts != null && items != null) {
      final approvedKeys = items
          .where((i) => i.reviewStatus == 'APPROVED')
          .map((i) => i.promptKey)
          .toSet();
      complete = prompts.prompts.isNotEmpty &&
          prompts.prompts.every(approvedKeys.contains);
      approvedCount = prompts.prompts.where(approvedKeys.contains).length;
      totalCount = prompts.prompts.length;
      subtitle = complete
          ? 'All $approvedCount/$totalCount prompts trainer-approved'
          : '$approvedCount/$totalCount prompts trainer-approved';
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        RmStepTile(
          icon: Icons.videocam_rounded,
          title: 'Video certification',
          subtitle: subtitle,
          state: complete == true ? RmStepState.done : RmStepState.active,
          statusLabel: complete == null
              ? 'Loading…'
              : complete
                  ? 'Approved'
                  : 'In review',
          onTap: () => context.push(RmRoutes.stage3VideoReview(staffId)),
        ),
        if (totalCount > 0)
          Padding(
            padding: const EdgeInsets.fromLTRB(6, 0, 6, 4),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: approvedCount / totalCount),
                duration: 900.ms,
                curve: Curves.easeOutCubic,
                builder: (_, v, _) => LinearProgressIndicator(
                  value: v,
                  minHeight: 6,
                  color: complete == true
                      ? RmTheme.emeraldGreen
                      : RmTheme.electricBlue,
                  backgroundColor: RmTheme.surfaceSecondary,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AttestCard extends StatelessWidget {
  const _AttestCard({required this.value, required this.onChanged});
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: value ? RmTheme.emeraldGreen.withValues(alpha: 0.07) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: value ? RmTheme.emeraldGreen : RmTheme.borderSubtle,
            width: value ? 1.6 : 1,
          ),
          boxShadow: RmTheme.subtleShadow,
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            AnimatedContainer(
              duration: 220.ms,
              curve: Curves.easeOutBack,
              width: 28,
              height: 28,
              decoration: BoxDecoration(
                color: value ? RmTheme.emeraldGreen : Colors.white,
                borderRadius: BorderRadius.circular(9),
                border: Border.all(
                  color: value ? RmTheme.emeraldGreen : RmTheme.textSecondary.withValues(alpha: 0.4),
                  width: 1.8,
                ),
              ),
              child: AnimatedScale(
                scale: value ? 1 : 0,
                duration: 250.ms,
                curve: Curves.elasticOut,
                child: const Icon(Icons.check_rounded, color: Colors.white, size: 19),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'I confirm training requirements are complete',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: RmTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Manual RM sign-off — recorded on the pipeline history.',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      height: 1.4,
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
    );
  }
}
