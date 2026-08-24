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

/// S4 Agreements hub — sequenced as the real pipeline requires: A1
/// (Employment, `/agreements`) signed first, which unlocks creating the
/// TRIAL placement right here in S4 (not at S5_DEPLOY) — A2 (Scope of
/// Work, `/sow`) and A3 (Client Indemnity, `/indemnity`) are both
/// placement-scoped documents and need a real `placement_id` to point at.
/// Advancing to S5_DEPLOY is only offered once A1 is signed, the placement
/// exists, and both A2/A3 have been sent to the client.
class RmStage4HubScreen extends ConsumerWidget {
  const RmStage4HubScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final client = ref.watch(agreementClientProvider(staffId));

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
          'Agreements (S4)',
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
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Header ──
                _buildProfileHeader(staff),

                const SizedBox(height: 20),

                // ── Client Selector Card ──
                _buildClientCard(context, ref, client)
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 350.ms)
                    .slideY(begin: 0.05, end: 0, delay: 50.ms, duration: 350.ms),

                const SizedBox(height: 20),

                // ── Client Check Content ──
                if (client == null)
                  Expanded(
                    child: _buildEmptyClientState(context, ref, staffId)
                        .animate()
                        .fadeIn(delay: 100.ms, duration: 350.ms)
                        .slideY(begin: 0.04, end: 0, delay: 100.ms, duration: 350.ms),
                  )
                else
                  Expanded(
                    child: _InstrumentList(
                      staffId: staffId,
                      staff: staff,
                      clientId: client.id,
                      client: client,
                    ),
                  ),
              ],
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

  Widget _buildClientCard(
    BuildContext context,
    WidgetRef ref,
    FinanceCustomer? client,
  ) {
    final hasClient = client != null;

    return Container(
      decoration: BoxDecoration(
        color: hasClient ? RmTheme.electricBlue.withValues(alpha: 0.04) : RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: hasClient ? RmTheme.electricBlue.withValues(alpha: 0.6) : RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: hasClient ? 1.8 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () async {
            final selected = await context.push<FinanceCustomer>(
              RmRoutes.stage4A2Client(staffId),
            );
            if (selected != null) {
              ref.read(agreementClientProvider(staffId).notifier).state = selected;
            }
          },
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Circle Lead Icon ──
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: hasClient ? RmTheme.electricBlue.withValues(alpha: 0.1) : RmTheme.borderSubtle.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.business_rounded,
                    color: hasClient ? RmTheme.electricBlue : RmTheme.textSecondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Client Info ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        client?.customerName ?? 'No client selected',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'A1, the placement, A2, and A3 are all tied to this client',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(width: 8),

                // ── Select Action Badge ──
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: hasClient ? RmTheme.electricBlue.withValues(alpha: 0.1) : Colors.transparent,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    hasClient ? 'CHANGE' : 'SELECT',
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: hasClient ? RmTheme.electricBlue : RmTheme.textSecondary,
                    ),
                  ),
                ),
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
    );
  }

  Widget _buildEmptyClientState(BuildContext context, WidgetRef ref, String staffId) {
    return Center(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.assignment_ind_outlined,
                  color: RmTheme.textSecondary.withValues(alpha: 0.6),
                  size: 48,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Assigned Client Required',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: RmTheme.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Please select a client from the panel above to start generating agreements and managing S4 placement steps.',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 13.5,
                  color: RmTheme.textSecondary,
                  height: 1.45,
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: 180,
                height: 44,
                child: FilledButton(
                  onPressed: () async {
                    final selected = await context.push<FinanceCustomer>(
                      RmRoutes.stage4A2Client(staffId),
                    );
                    if (selected != null) {
                      ref.read(agreementClientProvider(staffId).notifier).state = selected;
                    }
                  },
                  style: FilledButton.styleFrom(
                    backgroundColor: RmTheme.electricBlue,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Text(
                    'Select Client',
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
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

class _InstrumentList extends ConsumerWidget {
  const _InstrumentList({
    required this.staffId,
    required this.staff,
    required this.clientId,
    required this.client,
  });
  final String staffId;
  final StaffRow staff;
  final String clientId;
  final FinanceCustomer client;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreementsAsync = ref.watch(
      rmAgreementsProvider(AgreementListParams(staffId: staffId, clientId: clientId)),
    );
    final placementAsync = ref.watch(staffPlacementProvider(staffId));

    return RefreshIndicator(
      color: RmTheme.electricBlue,
      onRefresh: () async {
        ref.invalidate(rmAgreementsProvider(AgreementListParams(staffId: staffId, clientId: clientId)));
        ref.invalidate(staffPlacementProvider(staffId));
      },
      child: AsyncValueWidget<List<Agreement>>(
        value: agreementsAsync,
        onRetry: () => ref.invalidate(
          rmAgreementsProvider(AgreementListParams(staffId: staffId, clientId: clientId)),
        ),
        builder: (agreements) {
          final matches = agreements.where((a) => a.type == AgreementTypes.a1Employment).toList()
            ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
          final a1 = matches.isEmpty ? null : matches.first;
          final a1Signed = a1?.isSigned == true;

          return placementAsync.when(
            loading: () => const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('$e')),
            data: (placement) => _StepsList(
              staffId: staffId,
              staff: staff,
              clientId: clientId,
              client: client,
              a1: a1,
              a1Signed: a1Signed,
              placement: placement,
            ),
          );
        },
      ),
    );
  }
}

class _StepsList extends ConsumerWidget {
  const _StepsList({
    required this.staffId,
    required this.staff,
    required this.clientId,
    required this.client,
    required this.a1,
    required this.a1Signed,
    required this.placement,
  });

  final String staffId;
  final StaffRow staff;
  final String clientId;
  final FinanceCustomer client;
  final Agreement? a1;
  final bool a1Signed;
  final PlacementRow? placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return _StepsListContent(
      staffId: staffId,
      staff: staff,
      clientId: clientId,
      client: client,
      a1: a1,
      a1Signed: a1Signed,
      placement: placement,
    );
  }
}

class _StepsListContent extends ConsumerWidget {
  const _StepsListContent({
    required this.staffId,
    required this.staff,
    required this.clientId,
    required this.client,
    required this.a1,
    required this.a1Signed,
    required this.placement,
  });

  final String staffId;
  final StaffRow staff;
  final String clientId;
  final FinanceCustomer client;
  final Agreement? a1;
  final bool a1Signed;
  final PlacementRow? placement;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementId = placement?.id;

    final sowAsync = placementId == null ? null : ref.watch(rmSowListProvider(placementId));
    final indemnityAsync = placementId == null ? null : ref.watch(rmIndemnityListProvider(placementId));

    final sowSent = sowAsync?.maybeWhen(data: (items) => items.any((s) => s.status != 'DRAFT'), orElse: () => false) ?? false;
    final indemnitySent = indemnityAsync?.maybeWhen(data: (items) => items.isNotEmpty, orElse: () => false) ?? false;

    // Completed means fully complete (e.g. signed/acknowledged).
    // Otherwise, steps like SENT, DRAFT, NOT CREATED will show in orange.
    final sowAcknowledged = sowAsync?.maybeWhen(data: (items) => items.any((s) => s.status == 'ACKNOWLEDGED'), orElse: () => false) ?? false;
    final indemnityAcknowledged = indemnityAsync?.maybeWhen(data: (items) => items.any((i) => i.isAcknowledged), orElse: () => false) ?? false;

    final allDone = a1Signed && placement != null && sowSent && indemnitySent;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _instrumentTile(
          context,
          'A1 · Employment Agreement',
          a1?.status ?? 'NOT CREATED',
          a1Signed,
          () => context.push(RmRoutes.stage4A1(staffId), extra: clientId),
          index: 0,
        ),
        _instrumentTile(
          context,
          'Placement (TRIAL)',
          placement == null ? 'NOT CREATED' : placement!.status,
          placement != null,
          !a1Signed
              ? null
              : () async {
                  if (placement == null) {
                    await context.push(RmRoutes.placementCreate(staffId), extra: client);
                  } else {
                    await context.push(RmRoutes.placementDetail(placement!.id), extra: staffId);
                  }
                  ref.invalidate(staffPlacementProvider(staffId));
                },
          lockedMessage: 'Sign A1 first.',
          index: 1,
        ),
        _instrumentTile(
          context,
          'A2 · Scope of Work',
          sowAsync == null
              ? 'NOT CREATED'
              : sowAsync.maybeWhen(data: (items) => items.isEmpty ? 'NOT CREATED' : items.first.status, orElse: () => '...'),
          sowAcknowledged,
          placementId == null ? null : () => context.push(RmRoutes.stage4A2(staffId), extra: placementId),
          lockedMessage: 'Create the placement first.',
          index: 2,
        ),
        _instrumentTile(
          context,
          'A3 · Client Indemnity',
          indemnityAsync == null
              ? 'NOT CREATED'
              : indemnityAsync.maybeWhen(data: (items) => items.isEmpty ? 'NOT CREATED' : (indemnityAcknowledged ? 'ACKNOWLEDGED' : 'SENT'), orElse: () => '...'),
          indemnityAcknowledged,
          placementId == null ? null : () => context.push(RmRoutes.stage4A3(staffId), extra: placementId),
          lockedMessage: 'Create the placement first.',
          index: 3,
        ),
        const SizedBox(height: 24),
        AdvanceStageButton(
          staffId: staffId,
          fromStage: staff.pipelineStage,
          toStage: PipelineStages.s5Deploy,
          label: 'Advance to Deploy (S5)',
          reasonCode: 'AGREEMENTS_SIGNED',
          enabled: allDone,
        ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
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
                    'A1 must be signed, the placement created, and A2/A3 sent to the client before advancing.',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ).animate().fadeIn(delay: 240.ms, duration: 350.ms),
      ],
    );
  }

  Widget _instrumentTile(
    BuildContext context,
    String title,
    String status,
    bool done,
    VoidCallback? onTap, {
    String? lockedMessage,
    required int index,
  }) {
    final locked = onTap == null;
    final isSent = status == 'SENT';
    
    // completed -> emeraldGreen, otherwise -> amberWarning
    final Color statusColor = done ? RmTheme.emeraldGreen : RmTheme.amberWarning;

    final Widget leadingIcon;
    if (done) {
      leadingIcon = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RmTheme.emeraldGreen.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.check_circle_outline_rounded,
          color: RmTheme.emeraldGreen,
          size: 20,
        ),
      );
    } else if (isSent) {
      leadingIcon = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RmTheme.amberWarning.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: const Icon(
          Icons.send_outlined,
          color: RmTheme.amberWarning,
          size: 20,
        ),
      );
    } else {
      leadingIcon = Container(
        padding: const EdgeInsets.all(8),
        decoration: BoxDecoration(
          color: RmTheme.amberWarning.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          locked ? Icons.lock_outline : Icons.radio_button_unchecked,
          color: RmTheme.amberWarning,
          size: 20,
        ),
      );
    }

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
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: ListTile(
          leading: leadingIcon,
          title: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              fontSize: 15,
              color: RmTheme.textPrimary,
            ),
          ),
          subtitle: Text(
            locked && lockedMessage != null ? lockedMessage : status.toUpperCase(),
            style: GoogleFonts.inter(
              color: statusColor,
              fontWeight: FontWeight.bold,
              fontSize: 11,
              letterSpacing: 0.5,
            ),
          ),
          trailing: locked ? null : const Icon(Icons.chevron_right_rounded, size: 20, color: RmTheme.textSecondary),
          onTap: onTap,
          enabled: !locked,
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 60 * index),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 60 * index),
          duration: 400.ms,
        );
  }
}
