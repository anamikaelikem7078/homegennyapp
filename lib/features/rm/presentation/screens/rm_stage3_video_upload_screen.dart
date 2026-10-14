import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// Video certification — prompts view. `POST /video-cert/upload-url` and
/// `/finalize` are STAFF/ADMIN-only (verified against live Swagger role
/// guards), so RM cannot upload on a staff member's behalf. This screen is
/// monitoring-only: it shows what the staff member is required to submit,
/// via the real `GET /video-cert/prompts/:series`.
class RmStage3VideoUploadScreen extends ConsumerWidget {
  const RmStage3VideoUploadScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));

    return RmStageScaffold(
      title: 'Video prompts',
      stageCode: 'S3',
      stageColor: rmStageColor(PipelineStages.s3Train),
      body: rmAsyncBody<StaffRow?>(
        staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
        builder: (staff) {
          if (staff == null) {
            return const [
              RmEmptyBlock(
                icon: Icons.person_off_rounded,
                title: 'Staff not found',
                message: 'This staff record could not be loaded.',
              ),
            ];
          }
          final promptsAsync = ref.watch(rmVideoCertPromptsProvider(staff.series));
          return [
            RmStaffBanner(staff: staff, showTracker: false),
            const SizedBox(height: 14),
            const RmNote(
              title: 'Read-only view',
              text: 'Staff record these videos themselves — RM can\'t upload on '
                  'their behalf. This shows what they need to submit.',
            ),
            ...rmAsyncBody<VideoCertPrompts>(
              promptsAsync,
              onRetry: () => ref.invalidate(rmVideoCertPromptsProvider(staff.series)),
              builder: (prompts) => [
                RmSectionTitle(
                  title: 'Required prompts',
                  trailing: RmStatusPill(
                    label: '${prompts.count} · min ${prompts.minDuration}s',
                    color: RmTheme.electricBlue,
                  ),
                ),
                for (var i = 0; i < prompts.prompts.length; i++)
                  RmStepTile(
                    code: '${i + 1}',
                    icon: Icons.videocam_rounded,
                    title: rmTitleCase(prompts.prompts[i]),
                    subtitle: 'At least ${prompts.minDuration} seconds',
                    state: RmStepState.pending,
                  ),
              ],
            ),
          ];
        },
      ),
    );
  }
}
