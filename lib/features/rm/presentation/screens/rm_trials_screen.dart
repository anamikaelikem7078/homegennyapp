import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// `GET /rm/trials` returns raw Placement rows with no staff/client name
/// embedded — this screen cross-references the kanban's staff list (already
/// fetched) for display names rather than adding another round trip.
class RmTrialsScreen extends ConsumerWidget {
  const RmTrialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialsAsync = ref.watch(rmTrialsProvider);
    final kanban = ref.watch(rmKanbanProvider(const KanbanParams())).valueOrNull;

    return RmStageScaffold(
      title: 'Trials',
      stageColor: RmTheme.emeraldGreen,
      stageCode: trialsAsync.valueOrNull == null
          ? null
          : '${trialsAsync.valueOrNull!.length} live',
      onRefresh: () async => ref.invalidate(rmTrialsProvider),
      body: rmAsyncBody<List<TrialRow>>(
        trialsAsync,
        onRetry: () => ref.invalidate(rmTrialsProvider),
        builder: (trials) => [
          const RmNote(
            tone: RmNoteTone.success,
            title: 'Trial placements',
            text: 'Staff currently on trial with a client. Confirm or end each '
                'trial from its placement page.',
          ),
          const RmSectionTitle(title: 'Live trials'),
          if (trials.isEmpty)
            const RmEmptyBlock(
              icon: Icons.play_circle_rounded,
              color: RmTheme.emeraldGreen,
              title: 'No active trials',
              message: 'Trial placements will appear here once created at Deploy (S5).',
            )
          else
            for (final t in trials)
              RmStepTile(
                icon: Icons.play_circle_rounded,
                title: kanban?.findById(t.staffId)?.fullName ?? t.staffId,
                subtitle: 'Trial: ${t.trialStartDate ?? '?'} → ${t.trialEndDate ?? '?'}',
                state: RmStepState.done,
                statusLabel: 'On trial',
                onTap: () => context.push(RmRoutes.placementDetail(t.id), extra: t.staffId),
              ),
        ],
      ),
    );
  }
}
