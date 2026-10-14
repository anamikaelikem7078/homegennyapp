import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// Video certification review status. `PUT
/// /trainer/video-certifications/:id/review` (the actual approve/reject
/// action) is TRAINER/ADMIN-only, not RM — confirmed via live role guards,
/// despite living under the "Mobile App RM APIs" Swagger tag. This screen
/// therefore shows review status read-only via `GET /video-cert/list/:staffId`
/// and lets RM play back a submission (`POST /video-cert/view-url`), but
/// offers no approve/reject action.
class RmStage3VideoReviewScreen extends ConsumerWidget {
  const RmStage3VideoReviewScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemsAsync = ref.watch(rmVideoCertsProvider(staffId));
    final staff = ref.watch(staffByIdProvider(staffId)).valueOrNull;

    return RmStageScaffold(
      title: 'Video review',
      stageCode: 'S3',
      stageColor: rmStageColor(PipelineStages.s3Train),
      onRefresh: () async => ref.invalidate(rmVideoCertsProvider(staffId)),
      body: rmAsyncBody<List<VideoCertItem>>(
        itemsAsync,
        onRetry: () => ref.invalidate(rmVideoCertsProvider(staffId)),
        builder: (items) {
          final approved = items.where((i) => i.reviewStatus == 'APPROVED').length;
          return [
            if (staff != null) RmStaffBanner(staff: staff, showTracker: false),
            const SizedBox(height: 14),
            const RmNote(
              text: 'Trainers approve or reject videos. You can track status and '
                  'play back each submission here.',
            ),
            RmSectionTitle(
              title: 'Submissions',
              trailing: items.isEmpty
                  ? null
                  : RmStatusPill(
                      label: '$approved/${items.length} approved',
                      color: approved == items.length
                          ? RmTheme.emeraldGreen
                          : RmTheme.electricBlue,
                    ),
            ),
            if (items.isEmpty)
              const RmEmptyBlock(
                icon: Icons.videocam_off_rounded,
                title: 'No videos yet',
                message: 'Submitted video certifications will show up here.',
              )
            else
              for (final item in items) _VideoTile(item: item),
          ];
        },
      ),
    );
  }
}

class _VideoTile extends ConsumerWidget {
  const _VideoTile({required this.item});
  final VideoCertItem item;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = switch (item.reviewStatus) {
      'APPROVED' => RmStepState.done,
      'REJECTED' => RmStepState.failed,
      _ => RmStepState.warning,
    };
    final color = rmStepColor(state);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Row(
        children: [
          Container(
            width: 46,
            height: 46,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(15),
            ),
            child: Icon(Icons.videocam_rounded, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  rmTitleCase(item.promptKey),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
                Text(
                  'Attempt #${item.attemptNumber}'
                  '${item.reviewNotes != null ? ' · ${item.reviewNotes}' : ''}',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 8),
                RmStatusPill(label: rmTitleCase(item.reviewStatus), color: color),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: RmTheme.electricBlue,
            shape: const CircleBorder(),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: () {
                HapticFeedback.lightImpact();
                _play(context, ref);
              },
              child: const SizedBox(
                width: 42,
                height: 42,
                child: Icon(Icons.play_arrow_rounded, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _play(BuildContext context, WidgetRef ref) async {
    final result = await ref.read(rmRepositoryProvider).getVideoCertViewUrl(item.videoUrl);
    if (!context.mounted) return;
    result.fold(
      onSuccess: (url) {
        if (url.isEmpty) {
          DsSnackBar.show(context, message: 'No playback URL returned', type: DsSnackBarType.warning);
          return;
        }
        showDialog<void>(
          context: context,
          builder: (dialogContext) => DsDialogCard(
            children: [
              const DsDialogIcon(icon: Icons.play_circle_rounded, color: RmTheme.electricBlue),
              const SizedBox(height: 16),
              Text(
                'Playback link',
                style: GoogleFonts.plusJakartaSans(fontSize: 19, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 10),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: RmTheme.surfaceSecondary,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: SelectableText(url, style: GoogleFonts.robotoMono(fontSize: 12)),
              ),
              const SizedBox(height: 16),
              DsSecondaryButton(
                label: 'Copy link',
                icon: Icons.copy_rounded,
                onPressed: () {
                  Clipboard.setData(ClipboardData(text: url));
                  Navigator.of(dialogContext).pop();
                  DsSnackBar.show(context, message: 'Link copied', type: DsSnackBarType.success);
                },
              ),
              const SizedBox(height: 8),
              DsOutlineButton(label: 'Close', onPressed: () => Navigator.of(dialogContext).pop()),
            ],
          ),
        );
      },
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
  }
}
