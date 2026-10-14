import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// Terminal outcome staff — read-only. Swagger exposes no explicit action
/// on this list, so none is offered (per §23: don't provide unsupported
/// actions).
class RmTerminalScreen extends ConsumerWidget {
  const RmTerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminalAsync = ref.watch(rmTerminalProvider);

    return RmStageScaffold(
      title: 'Exited',
      stageColor: RmTheme.crimsonDanger,
      stageCode: terminalAsync.valueOrNull == null
          ? null
          : '${terminalAsync.valueOrNull!.length}',
      onRefresh: () async => ref.invalidate(rmTerminalProvider),
      body: rmAsyncBody<List<StaffRow>>(
        terminalAsync,
        onRetry: () => ref.invalidate(rmTerminalProvider),
        builder: (rows) => [
          const RmNote(
            tone: RmNoteTone.danger,
            title: 'Exited the pipeline',
            text: 'Staff with a terminal outcome. This list is read-only.',
          ),
          const RmSectionTitle(title: 'Staff'),
          if (rows.isEmpty)
            const RmEmptyBlock(
              icon: Icons.verified_user_rounded,
              color: RmTheme.emeraldGreen,
              title: 'Nobody has exited',
              message: 'Staff moved to a terminal outcome will be listed here.',
            )
          else
            for (final s in rows)
              RmStepTile(
                icon: Icons.block_rounded,
                title: s.fullName,
                subtitle: '${s.staffCode} · ${StaffSeries.label(s.series)}',
                state: RmStepState.failed,
                statusLabel: rmTitleCase(s.terminalOutcome ?? 'Unspecified'),
              ),
        ],
      ),
    );
  }
}
