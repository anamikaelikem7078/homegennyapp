import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/async_value_widget.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';

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

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: Text('Staff Details', style: RmTheme.headline(context).copyWith(fontSize: 18)),
        centerTitle: true,
      ),
      body: staff == null
          ? AsyncValueWidget<StaffRow?>(
              value: asyncStaff,
              onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
              builder: (data) => data == null
                  ? const Center(child: Text('Staff not found'))
                  : _StaffDetailBody(staff: data),
            )
          : RefreshIndicator(
              onRefresh: () async => ref.invalidate(staffByIdProvider(staffId)),
              child: _StaffDetailBody(staff: staff),
            ),
    );
  }
}

class _StaffDetailBody extends ConsumerWidget {
  const _StaffDetailBody({required this.staff});
  final StaffRow staff;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(staffPlacementProvider(staff.id));

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildProfileSummary(context),
          const SizedBox(height: 16),
          _buildStageProgress(context),
          const SizedBox(height: 16),
          _buildSectionCard(
            context,
            title: 'Verification · S2_VERIFY',
            status: staff.pvStatus == null ? 'Not started' : 'PV: ${staff.pvStatus}',
            done: PipelineStages.order.indexOf(staff.pipelineStage) > 1,
            onTap: () => context.push(RmRoutes.verificationDashboard(staff.id)),
          ),
          _buildSectionCard(
            context,
            title: 'Assessment · S2.5',
            status: staff.pipelineStage == PipelineStages.s25Assess ? 'In progress' : null,
            done: PipelineStages.order.indexOf(staff.pipelineStage) > 2,
            onTap: () => context.push(RmRoutes.stage25Assessment(staff.id)),
          ),
          _buildSectionCard(
            context,
            title: 'Training · S3',
            status: staff.pipelineStage == PipelineStages.s3Train ? 'In progress' : null,
            done: PipelineStages.order.indexOf(staff.pipelineStage) > 3,
            onTap: () => context.push(RmRoutes.stage3Training(staff.id)),
          ),
          _buildSectionCard(
            context,
            title: 'Agreements · S4',
            status: staff.pipelineStage == PipelineStages.s4Agreements ? 'In progress' : null,
            done: PipelineStages.order.indexOf(staff.pipelineStage) > 4,
            onTap: () => context.push(RmRoutes.stage4Hub(staff.id)),
          ),
          const SizedBox(height: 16),
          _buildPlacementSection(context, ref, placementAsync),
          const SizedBox(height: 16),
          _buildQuickLinks(context),
          const SizedBox(height: 24),
          _buildPrimaryAction(context, ref),
        ],
      ),
    );
  }

  Widget _buildProfileSummary(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(24),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 72,
            height: 72,
            decoration: BoxDecoration(color: RmTheme.electricBlue.withOpacity(0.1), shape: BoxShape.circle),
            alignment: Alignment.center,
            child: Text(staff.initials, style: GoogleFonts.libreCaslonText(fontSize: 28, color: RmTheme.electricBlue)),
          ),
          const SizedBox(height: 16),
          Text(staff.fullName, style: RmTheme.headline(context).copyWith(color: RmTheme.electricBlue, fontSize: 18), textAlign: TextAlign.center),
          const SizedBox(height: 8),
          Wrap(
            alignment: WrapAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(color: RmTheme.textSecondary.withOpacity(0.1), borderRadius: BorderRadius.circular(4)),
                child: Text(staff.staffCode, style: RmTheme.label(context).copyWith(color: RmTheme.electricBlue, fontSize: 12)),
              ),
              Text(staff.mobile, style: RmTheme.body(context).copyWith(fontSize: 12)),
              Text(StaffSeries.label(staff.series), style: RmTheme.body(context).copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _stageBgColor(staff.pipelineStage).withOpacity(0.1),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: _stageBgColor(staff.pipelineStage).withOpacity(0.3)),
            ),
            child: Text(
              PipelineStages.label(staff.pipelineStage),
              style: RmTheme.label(context).copyWith(color: _stageBgColor(staff.pipelineStage), fontSize: 11, fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  Color _stageBgColor(String stage) {
    if (stage == PipelineStages.terminal) return RmTheme.crimsonDanger;
    if (stage == PipelineStages.deferred) return RmTheme.amberWarning;
    if (stage == PipelineStages.s5Deploy) return RmTheme.emeraldGreen;
    return RmTheme.electricBlue;
  }

  Widget _buildStageProgress(BuildContext context) {
    if (staff.pipelineStage == PipelineStages.terminal) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.crimsonDanger.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RmTheme.crimsonDanger.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.block, color: RmTheme.crimsonDanger),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Terminal outcome: ${staff.terminalOutcome ?? 'unspecified'}',
                style: RmTheme.body(context).copyWith(color: RmTheme.crimsonDanger, fontWeight: FontWeight.w600),
              ),
            ),
          ],
        ),
      );
    }
    if (staff.pipelineStage == PipelineStages.deferred) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.amberWarning.withOpacity(0.05),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: RmTheme.amberWarning.withOpacity(0.2)),
        ),
        child: Row(
          children: [
            const Icon(Icons.pause_circle_outline, color: RmTheme.amberWarning),
            const SizedBox(width: 12),
            const Expanded(child: Text('Deferred — resume from the Deferred queue to continue the pipeline.')),
          ],
        ),
      );
    }
    final currentIndex = PipelineStages.order.indexOf(staff.pipelineStage);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: RmTheme.cardSurface, borderRadius: BorderRadius.circular(16), boxShadow: RmTheme.sophisticatedShadow),
      child: Row(
        children: [
          for (var i = 0; i < PipelineStages.order.length; i++) ...[
            Expanded(
              child: Container(
                height: 6,
                decoration: BoxDecoration(
                  color: i <= currentIndex ? RmTheme.electricBlue : RmTheme.borderSubtle,
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
            if (i < PipelineStages.order.length - 1) const SizedBox(width: 4),
          ],
        ],
      ),
    );
  }

  Widget _buildSectionCard(BuildContext context, {required String title, String? status, required bool done, required VoidCallback onTap}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(borderRadius: BorderRadius.circular(14), border: Border.all(color: RmTheme.borderSubtle)),
            child: Row(
              children: [
                Icon(
                  done ? Icons.check_circle : Icons.radio_button_unchecked,
                  color: done ? RmTheme.emeraldGreen : RmTheme.textSecondary,
                  size: 22,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: RmTheme.label(context).copyWith(fontWeight: FontWeight.w600, fontSize: 14)),
                      if (status != null) Text(status, style: RmTheme.body(context).copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                const Icon(Icons.chevron_right, color: RmTheme.textSecondary),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildPlacementSection(BuildContext context, WidgetRef ref, AsyncValue<PlacementRow?> placementAsync) {
    return placementAsync.when(
      loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 8), child: LinearProgressIndicator()),
      error: (e, _) => const SizedBox.shrink(),
      data: (placement) {
        if (placement == null) {
          if (staff.pipelineStage != PipelineStages.s5Deploy) return const SizedBox.shrink();
          return _buildSectionCard(
            context,
            title: 'Placement',
            status: 'Ready for placement — no placement created yet',
            done: false,
            onTap: () => context.push(RmRoutes.placementCreate(staff.id)),
          );
        }
        return _buildSectionCard(
          context,
          title: 'Placement · ${placement.status}',
          status: placement.isTrial
              ? 'TRIAL — pending confirmation'
              : placement.isConfirmed
                  ? 'CONFIRMED — attendance & invoicing unlocked'
                  : placement.status,
          done: placement.isConfirmed,
          onTap: () => context.push(RmRoutes.placementDetail(placement.id), extra: staff.id),
        );
      },
    );
  }

  Widget _buildQuickLinks(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(RmRoutes.staffIncidents(staff.id)),
            icon: const Icon(Icons.report_problem_outlined, size: 18),
            label: const Text('Incidents'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: () => context.push(RmRoutes.staffInvoicePreview(staff.id)),
            icon: const Icon(Icons.event_available_outlined, size: 18),
            label: const Text('Attendance'),
          ),
        ),
      ],
    );
  }

  Widget _buildPrimaryAction(BuildContext context, WidgetRef ref) {
    switch (staff.pipelineStage) {
      case PipelineStages.s1Intake:
        return AdvanceStageButton(
          staffId: staff.id,
          fromStage: staff.pipelineStage,
          toStage: PipelineStages.s2Verify,
          label: 'Complete Intake',
          reasonCode: 'INTAKE_COMPLETE',
        );
      case PipelineStages.s2Verify:
        return FilledButton(
          onPressed: () => context.push(RmRoutes.verificationDashboard(staff.id)),
          style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue, minimumSize: const Size.fromHeight(52)),
          child: const Text('Continue Verification'),
        );
      case PipelineStages.s25Assess:
        return FilledButton(
          onPressed: () => context.push(RmRoutes.stage25Assessment(staff.id)),
          style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue, minimumSize: const Size.fromHeight(52)),
          child: const Text('Continue Assessment'),
        );
      case PipelineStages.s3Train:
        return FilledButton(
          onPressed: () => context.push(RmRoutes.stage3Training(staff.id)),
          style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue, minimumSize: const Size.fromHeight(52)),
          child: const Text('Continue Training'),
        );
      case PipelineStages.s4Agreements:
        return FilledButton(
          onPressed: () => context.push(RmRoutes.stage4Hub(staff.id)),
          style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue, minimumSize: const Size.fromHeight(52)),
          child: const Text('Continue Agreements'),
        );
      case PipelineStages.s5Deploy:
        return FilledButton(
          onPressed: () => context.push(RmRoutes.placementCreate(staff.id)),
          style: FilledButton.styleFrom(backgroundColor: RmTheme.emeraldGreen, minimumSize: const Size.fromHeight(52)),
          child: const Text('Create Placement'),
        );
      default:
        return const SizedBox.shrink();
    }
  }
}
