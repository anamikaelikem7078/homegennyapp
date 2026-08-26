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

                // ── A1 Steps ──
                Expanded(
                  child: _InstrumentList(staffId: staffId, staff: staff),
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
}

class _InstrumentList extends ConsumerWidget {
  const _InstrumentList({required this.staffId, required this.staff});
  final String staffId;
  final StaffRow staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreementsAsync = ref.watch(
      rmAgreementsProvider(AgreementListParams(staffId: staffId)),
    );

    return RefreshIndicator(
      color: RmTheme.electricBlue,
      onRefresh: () async {
        ref.invalidate(rmAgreementsProvider(AgreementListParams(staffId: staffId)));
      },
      child: AsyncValueWidget<List<Agreement>>(
        value: agreementsAsync,
        onRetry: () => ref.invalidate(
          rmAgreementsProvider(AgreementListParams(staffId: staffId)),
        ),
        builder: (agreements) {
          final matches = agreements.where((a) => a.type == AgreementTypes.a1Employment).toList()
            ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
          final a1 = matches.isEmpty ? null : matches.first;
          final a1Signed = a1?.isSigned == true;

          return _StepsListContent(staffId: staffId, staff: staff, a1: a1, a1Signed: a1Signed);
        },
      ),
    );
  }
}

class _StepsListContent extends ConsumerWidget {
  const _StepsListContent({
    required this.staffId,
    required this.staff,
    required this.a1,
    required this.a1Signed,
  });

  final String staffId;
  final StaffRow staff;
  final Agreement? a1;
  final bool a1Signed;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final allDone = a1Signed;

    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      children: [
        _instrumentTile(
          context,
          'A1 · Employment Agreement',
          a1?.status ?? 'NOT CREATED',
          a1Signed,
          () => context.push(RmRoutes.stage4A1(staffId)),
          index: 0,
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
                    'Sign A1 to advance to Deploy (S5).',
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
