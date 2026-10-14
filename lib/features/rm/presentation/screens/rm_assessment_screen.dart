import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:homegennyapp/core/theme/app_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';
import '../widgets/rm_stage_ui.dart';

/// S2.5 Assessment — the real assessment stage, between Verification and
/// Training. Backed by `/assessments`. RM must not be able to blindly skip
/// it: advancing to S3_TRAIN is only offered once the latest attempt's
/// `result` is `PASS`; `PARTIAL`/`FAIL` keep the staff at S2_5_ASSESS with
/// the real status shown, and a new attempt can be started.
class RmAssessmentScreen extends ConsumerStatefulWidget {
  const RmAssessmentScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmAssessmentScreen> createState() => _RmAssessmentScreenState();
}

class _RmAssessmentScreenState extends ConsumerState<RmAssessmentScreen> {
  bool _creating = false;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));
    final assessmentsAsync = ref.watch(staffAssessmentsProvider(widget.staffId));

    final staff = staffAsync.valueOrNull;
    if (staff == null) {
      return Scaffold(
        backgroundColor: RmTheme.offWhite,
        appBar: AppBar(title: const Text('Assessment')),
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

    final assessments = assessmentsAsync.valueOrNull;
    final latest =
        (assessments == null || assessments.isEmpty) ? null : assessments.first;
    final passed = latest != null && latest.passed;

    return RmStageScaffold(
      title: 'Assessment',
      stageCode: 'S2.5',
      stageColor: rmStageColor(PipelineStages.s25Assess),
      onRefresh: () async => ref.invalidate(rmAssessmentsProvider),
      bottom: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          AdvanceStageButton(
            staffId: staff.id,
            fromStage: staff.pipelineStage,
            toStage: PipelineStages.s3Train,
            label: 'Advance to Training (S3)',
            reasonCode: 'ASSESSMENT_PASSED',
            enabled: passed,
          ),
          RmHint(
            done: passed,
            text: passed
                ? 'Latest attempt passed — ready to advance.'
                : 'A passing attempt is required to advance.',
          ),
        ],
      ),
      body: [
        RmStaffBanner(staff: staff, showTracker: false),
        RmSectionTitle(
          title: 'Assessment log',
          trailing: assessments == null || assessments.isEmpty
              ? null
              : RmStatusPill(
                  label: '${assessments.length} attempt${assessments.length == 1 ? '' : 's'}',
                  color: RmTheme.electricBlue,
                ),
        ),
        AsyncValueWidget<List<Assessment>>(
          value: assessmentsAsync,
          onRetry: () => ref.invalidate(rmAssessmentsProvider),
          builder: (list) => _buildContent(staff, list),
        ),
      ],
    );
  }

  Widget _buildContent(StaffRow staff, List<Assessment> assessments) {
    final latest = assessments.isEmpty ? null : assessments.first;
    final canStart = latest == null || latest.status == 'COMPLETED';

    final startButton = DsGradientButton(
      label: assessments.isEmpty ? 'Start assessment' : 'New attempt',
      icon: Icons.add_rounded,
      isLoading: _creating,
      onPressed: _creating ? null : () => _createAssessment(staff),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (assessments.isEmpty)
          RmEmptyBlock(
            icon: Icons.assignment_rounded,
            title: 'No assessments yet',
            message: staff.series == StaffSeries.driver
                ? 'Start the driver practical road test to continue.'
                : 'Start a general assessment to continue.',
            action: startButton,
          )
        else ...[
          for (final a in assessments) _attemptTile(a),
          const SizedBox(height: 8),
          if (canStart)
            startButton
          else
            _SubmitAssessmentCard(assessment: latest, staffId: staff.id),
        ],
      ],
    );
  }

  Widget _attemptTile(Assessment a) {
    final (state, icon) = switch (a.result) {
      AssessmentResults.pass => (RmStepState.done, Icons.check_circle_rounded),
      AssessmentResults.fail => (RmStepState.failed, Icons.cancel_rounded),
      AssessmentResults.partial => (RmStepState.warning, Icons.warning_rounded),
      _ => (RmStepState.active, Icons.pending_rounded),
    };
    final details = [
      rmTitleCase(a.status),
      if (a.score != null) 'Score ${a.score}',
      if (a.remarks != null && a.remarks!.trim().isNotEmpty) a.remarks!.trim(),
    ].join(' · ');

    return RmStepTile(
      icon: icon,
      title: 'Attempt #${a.attemptNumber}',
      subtitle: '${rmTitleCase(a.assessmentType ?? 'GENERAL')} · $details',
      state: state,
      statusLabel: a.result == null ? 'In progress' : rmTitleCase(a.result!),
    );
  }

  Future<void> _createAssessment(StaffRow staff) async {
    setState(() => _creating = true);
    final assessmentType =
        staff.series == StaffSeries.driver ? 'DRIVER_PRACTICAL' : 'GENERAL';
    final result = await ref
        .read(rmRepositoryProvider)
        .createAssessment(staffId: staff.id, assessmentType: assessmentType);
    if (!mounted) return;
    setState(() => _creating = false);
    result.fold(
      onSuccess: (_) => ref.invalidate(rmAssessmentsProvider),
      onError: (f) => DsSnackBar.show(
        context,
        message: f.message,
        type: DsSnackBarType.error,
      ),
    );
  }
}

class _SubmitAssessmentCard extends ConsumerStatefulWidget {
  const _SubmitAssessmentCard({
    required this.assessment,
    required this.staffId,
  });
  final Assessment assessment;
  final String staffId;

  @override
  ConsumerState<_SubmitAssessmentCard> createState() =>
      _SubmitAssessmentCardState();
}

class _SubmitAssessmentCardState extends ConsumerState<_SubmitAssessmentCard> {
  String _result = AssessmentResults.pass;
  final _scoreController = TextEditingController();
  final _remarksController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _scoreController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);
    final score = num.tryParse(_scoreController.text.trim());
    final result = await ref.read(rmRepositoryProvider).submitAssessment(
          id: widget.assessment.id,
          score: score,
          result: _result,
          remarks: _remarksController.text.trim().isEmpty
              ? null
              : _remarksController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (submitResult) {
        ref.invalidate(rmAssessmentsProvider);
        if (submitResult.autoTerminated) {
          ref.invalidate(rmKanbanProvider);
          ref.invalidate(staffByIdProvider(widget.staffId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                submitResult.message ??
                    'Staff record moved to TERMINAL after repeated failures.',
              ),
              backgroundColor: RmTheme.crimsonDanger,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Assessment result submitted')),
          );
        }
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: RmTheme.crimsonDanger,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.electricBlue.withValues(alpha: 0.3),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Title ──
          Text(
            'Record Assessment Result',
            style: AppFonts.display(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),

          // ── custom verdict choice chips ──
          Row(
            children: [
              Expanded(
                child: _VerdictChoiceCard(
                  label: 'PASS',
                  color: RmTheme.emeraldGreen,
                  selected: _result == AssessmentResults.pass,
                  onTap: () => setState(() => _result = AssessmentResults.pass),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerdictChoiceCard(
                  label: 'PARTIAL',
                  color: RmTheme.amberWarning,
                  selected: _result == AssessmentResults.partial,
                  onTap: () =>
                      setState(() => _result = AssessmentResults.partial),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _VerdictChoiceCard(
                  label: 'FAIL',
                  color: RmTheme.crimsonDanger,
                  selected: _result == AssessmentResults.fail,
                  onTap: () => setState(() => _result = AssessmentResults.fail),
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // ── Score textfield ──
          TextFormField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Score (optional)',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
              filled: true,
              fillColor: RmTheme.offWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: RmTheme.electricBlue, width: 1.6),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 14),

          // ── Remarks textfield ──
          TextFormField(
            controller: _remarksController,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Remarks (optional)',
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
              filled: true,
              fillColor: RmTheme.offWhite,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: RmTheme.electricBlue, width: 1.6),
              ),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
          ),

          const SizedBox(height: 20),

          // ── Submit Button ──
          SizedBox(
            width: double.infinity,
            height: 52,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(
                backgroundColor: RmTheme.electricBlue,
                shape: const StadiumBorder(),
              ),
              child: _submitting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      'Submit Result',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.bold,
                        fontSize: 15,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _VerdictChoiceCard extends StatelessWidget {
  const _VerdictChoiceCard({
    required this.label,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.08) : RmTheme.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: selected ? color : RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: selected ? 1.8 : 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 11),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  color: selected ? color : RmTheme.textSecondary,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                  letterSpacing: 0.2,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
