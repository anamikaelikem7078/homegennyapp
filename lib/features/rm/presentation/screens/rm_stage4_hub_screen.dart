import 'package:flutter/material.dart';
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

/// S4 Agreements hub — only A1 (Employment, `/agreements`) lives here. A1 is
/// staff-level, so no client needs to be picked before signing it — the RM
/// goes straight from this hub into the A1 e-sign flow.
///
/// Placement (and A2/Scope of Work, A3/Client Indemnity, which ARE
/// client-specific documents scoped to a real `placement_id`) moved to the
/// S5 Deploy hub (`RmStage5DeployHubScreen`) — a staff can end up placed
/// with more than one client over time, so those documents don't belong
/// behind a throwaway placement created mid-S4 just to unlock them. The
/// client is picked at S5, when the placement is created.
/// Advancing to S5_DEPLOY only requires A1 to be signed.
class RmStage4HubScreen extends ConsumerWidget {
  const RmStage4HubScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final params = AgreementListParams(staffId: staffId);
    final agreementsAsync = ref.watch(rmAgreementsProvider(params));
    final staff = staffAsync.valueOrNull;

    if (staff == null) {
      return Scaffold(
        backgroundColor: RmTheme.offWhite,
        appBar: AppBar(title: const Text('Agreements')),
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

    final matches = (agreementsAsync.valueOrNull ?? const <Agreement>[])
        .where((a) => a.type == AgreementTypes.a1Employment)
        .toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    final a1 = matches.isEmpty ? null : matches.first;
    final a1Signed = a1?.isSigned == true;
    final a1Status = a1?.status ?? 'NOT_CREATED';

    final a1State = a1Signed
        ? RmStepState.done
        : a1Status == 'SENT'
            ? RmStepState.warning
            : RmStepState.pending;

    return RmStageScaffold(
      title: 'Agreements',
      stageCode: 'S4',
      stageColor: rmStageColor(PipelineStages.s4Agreements),
      onRefresh: () async => ref.invalidate(rmAgreementsProvider(params)),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdvanceStageButton(
            staffId: staffId,
            fromStage: staff.pipelineStage,
            toStage: PipelineStages.s5Deploy,
            label: 'Advance to Deploy (S5)',
            reasonCode: 'AGREEMENTS_SIGNED',
            enabled: a1Signed,
          ),
          RmHint(
            done: a1Signed,
            text: a1Signed
                ? 'Employment agreement signed — ready to deploy.'
                : 'Sign A1 to advance to Deploy (S5).',
          ),
        ],
      ),
      body: [
        RmStaffBanner(staff: staff, showTracker: false),
        const RmSectionTitle(title: 'Documents to sign'),
        AsyncValueWidget<List<Agreement>>(
          value: agreementsAsync,
          onRetry: () => ref.invalidate(rmAgreementsProvider(params)),
          builder: (_) => RmStepTile(
            code: 'A1',
            icon: a1Status == 'SENT' ? Icons.send_rounded : Icons.edit_document,
            title: 'Employment agreement',
            subtitle: a1Signed
                ? 'Signed by staff'
                : a1Status == 'SENT'
                    ? 'Sent — waiting for the staff signature'
                    : 'Create and send for e-sign',
            state: a1State,
            statusLabel: rmTitleCase(a1Status),
            onTap: () => context.push(RmRoutes.stage4A1(staffId)),
          ),
        ),
        const SizedBox(height: 4),
        const RmNote(
          text:
              'Client documents (scope of work, indemnity) are signed at Deploy (S5), '
              'once a client and placement are chosen.',
        ),
      ],
    );
  }
}
