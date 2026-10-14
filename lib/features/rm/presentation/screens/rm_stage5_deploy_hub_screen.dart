import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// S5 Deploy hub — a staff arrives here once S4_AGREEMENTS is done (A1
/// signed). Here the RM picks a client and creates the placement (TRIAL or
/// CONFIRMED), then creates A2 (Scope of Work) and A3 (Client Indemnity)
/// against that specific placement — both are client-specific documents, so
/// they live with the placement they belong to, not with A1 in S4. A staff
/// can be placed with more than one client over time; this hub always
/// operates on the staff's current/most recent placement.
class RmStage5DeployHubScreen extends ConsumerWidget {
  const RmStage5DeployHubScreen({super.key, required this.staffId});
  final String staffId;

  Future<void> _pickClient(BuildContext context, WidgetRef ref) async {
    final selected = await context.push<FinanceCustomer>(RmRoutes.stage4A2Client(staffId));
    if (selected != null) {
      ref.read(agreementClientProvider(staffId).notifier).state = selected;
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final client = ref.watch(agreementClientProvider(staffId));

    return RmStageScaffold(
      title: 'Deploy',
      stageCode: 'S5',
      stageColor: rmStageColor(PipelineStages.s5Deploy),
      onRefresh: () async => ref.invalidate(staffPlacementProvider(staffId)),
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
          return [
            RmStaffBanner(staff: staff, showTracker: false),
            const RmSectionTitle(title: 'Client'),
            _ClientCard(client: client, onTap: () => _pickClient(context, ref)),
            if (client == null) ...[
              const SizedBox(height: 16),
              RmEmptyBlock(
                icon: Icons.business_rounded,
                title: 'Pick a client',
                message: 'Choose the client first — the placement and the A2 / A3 '
                    'documents are all tied to them.',
                action: DsGradientButton(
                  label: 'Select client',
                  icon: Icons.search_rounded,
                  isExpanded: false,
                  onPressed: () => _pickClient(context, ref),
                ),
              ),
            ] else ...[
              const RmSectionTitle(title: 'Deployment steps'),
              _Steps(staffId: staffId, client: client),
            ],
          ];
        },
      ),
    );
  }
}

class _ClientCard extends StatelessWidget {
  const _ClientCard({required this.client, required this.onTap});
  final FinanceCustomer? client;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final has = client != null;
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
            border: Border.all(
              color: has
                  ? RmTheme.electricBlue.withValues(alpha: 0.35)
                  : RmTheme.borderSubtle,
              width: has ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.business_rounded, color: RmTheme.iconAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      client?.customerName ?? 'No client selected',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Placement, A2 and A3 use this client',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: const Color(0xFFE8EEFF),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  has ? 'Change' : 'Select',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.electricBlue,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _Steps extends ConsumerWidget {
  const _Steps({required this.staffId, required this.client});
  final String staffId;
  final FinanceCustomer client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(staffPlacementProvider(staffId));

    return placementAsync.when(
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(vertical: 30),
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (e, _) => RmNote(tone: RmNoteTone.danger, text: '$e'),
      data: (placement) {
        final placementId = placement?.id;
        final sowAsync = placementId == null ? null : ref.watch(rmSowListProvider(placementId));
        final indemnityAsync =
            placementId == null ? null : ref.watch(rmIndemnityListProvider(placementId));

        final sowAck = sowAsync?.maybeWhen(
              data: (items) => items.any((s) => s.status == 'ACKNOWLEDGED'),
              orElse: () => false,
            ) ??
            false;
        final indAck = indemnityAsync?.maybeWhen(
              data: (items) => items.any((i) => i.isAcknowledged),
              orElse: () => false,
            ) ??
            false;

        final sowStatus = sowAsync == null
            ? 'NOT_CREATED'
            : sowAsync.maybeWhen(
                data: (items) => items.isEmpty ? 'NOT_CREATED' : items.first.status,
                orElse: () => 'LOADING',
              );
        final indStatus = indemnityAsync == null
            ? 'NOT_CREATED'
            : indemnityAsync.maybeWhen(
                data: (items) => items.isEmpty
                    ? 'NOT_CREATED'
                    : (indAck ? 'ACKNOWLEDGED' : 'SENT'),
                orElse: () => 'LOADING',
              );

        RmStepState docState(bool ack, String status, bool locked) {
          if (locked) return RmStepState.locked;
          if (ack) return RmStepState.done;
          if (status == 'SENT') return RmStepState.warning;
          return RmStepState.pending;
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            RmStepTile(
              code: '1',
              icon: Icons.handshake_rounded,
              title: 'Placement',
              subtitle: placement == null
                  ? 'Create a trial or confirmed placement'
                  : placement.isTrial
                      ? 'Trial in progress'
                      : 'Placement ${rmTitleCase(placement.status).toLowerCase()}',
              state: placement == null
                  ? RmStepState.active
                  : placement.isConfirmed
                      ? RmStepState.done
                      : RmStepState.warning,
              statusLabel:
                  placement == null ? 'Not created' : rmTitleCase(placement.status),
              onTap: () async {
                if (placement == null) {
                  await context.push(RmRoutes.placementCreate(staffId), extra: client);
                } else {
                  await context.push(RmRoutes.placementDetail(placement.id), extra: staffId);
                }
                ref.invalidate(staffPlacementProvider(staffId));
              },
            ),
            RmStepTile(
              code: '2',
              icon: Icons.assignment_rounded,
              title: 'A2 · Scope of work',
              subtitle: placementId == null
                  ? 'Create the placement first'
                  : 'Duties agreed with the client',
              state: docState(sowAck, sowStatus, placementId == null),
              statusLabel: placementId == null ? 'Locked' : rmTitleCase(sowStatus),
              onTap: placementId == null
                  ? null
                  : () => context.push(RmRoutes.stage4A2(staffId), extra: placementId),
            ),
            RmStepTile(
              code: '3',
              icon: Icons.shield_rounded,
              title: 'A3 · Client indemnity',
              subtitle: placementId == null
                  ? 'Create the placement first'
                  : 'Client liability acknowledgement',
              state: docState(indAck, indStatus, placementId == null),
              statusLabel: placementId == null ? 'Locked' : rmTitleCase(indStatus),
              onTap: placementId == null
                  ? null
                  : () => context.push(RmRoutes.stage4A3(staffId), extra: placementId),
            ),
            if (placement?.isConfirmed == true && sowAck && indAck) ...[
              const SizedBox(height: 4),
              const RmNote(
                tone: RmNoteTone.success,
                title: 'Fully deployed',
                text: 'Placement confirmed and both client documents acknowledged.',
              ),
            ],
          ],
        );
      },
    );
  }
}
