import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';

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

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Assessment (S2.5)')),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        builder: (staff) {
          if (staff == null) return const Center(child: Text('Staff not found'));
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(staffAssessmentsProvider(widget.staffId)),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staff.fullName, style: RmTheme.headline(context).copyWith(fontSize: 22)),
                  Text('${staff.staffCode} · ${staff.series}', style: RmTheme.body(context)),
                  const SizedBox(height: 24),
                  AsyncValueWidget<List<Assessment>>(
                    value: assessmentsAsync,
                    onRetry: () => ref.invalidate(staffAssessmentsProvider(widget.staffId)),
                    builder: (assessments) => _buildContent(context, staff, assessments),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildContent(BuildContext context, StaffRow staff, List<Assessment> assessments) {
    final latest = assessments.isEmpty ? null : assessments.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (assessments.isEmpty)
          const Text('No assessments yet for this staff member.')
        else
          for (final a in assessments) _buildAssessmentCard(context, a),
        const SizedBox(height: 20),
        if (latest == null || latest.status == 'COMPLETED')
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: _creating ? null : () => _createAssessment(staff),
              icon: _creating
                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                  : const Icon(Icons.add),
              label: Text(assessments.isEmpty ? 'Start Assessment' : 'New Attempt'),
            ),
          )
        else
          _SubmitAssessmentCard(assessment: latest, staffId: staff.id),
        const SizedBox(height: 24),
        if (latest != null && latest.passed)
          AdvanceStageButton(
            staffId: staff.id,
            fromStage: staff.pipelineStage,
            toStage: PipelineStages.s3Train,
            label: 'Advance to Training (S3)',
            reasonCode: 'ASSESSMENT_PASSED',
          ),
      ],
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Assessment a) {
    Color color = RmTheme.textSecondary;
    if (a.result == AssessmentResults.pass) color = RmTheme.emeraldGreen;
    if (a.result == AssessmentResults.fail) color = RmTheme.crimsonDanger;
    if (a.result == AssessmentResults.partial) color = RmTheme.amberWarning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: RmTheme.cardSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: RmTheme.borderSubtle)),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Attempt #${a.attemptNumber} · ${a.assessmentType ?? 'GENERAL'}', style: const TextStyle(fontWeight: FontWeight.w600)),
                Text('Status: ${a.status}${a.score != null ? ' · Score: ${a.score}' : ''}', style: RmTheme.body(context).copyWith(fontSize: 12)),
                if (a.remarks != null) Text(a.remarks!, style: RmTheme.body(context).copyWith(fontSize: 12)),
              ],
            ),
          ),
          if (a.result != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(8), border: Border.all(color: color.withOpacity(0.3))),
              child: Text(a.result!, style: TextStyle(color: color, fontWeight: FontWeight.w700, fontSize: 12)),
            ),
        ],
      ),
    );
  }

  Future<void> _createAssessment(StaffRow staff) async {
    setState(() => _creating = true);
    final assessmentType = staff.series == StaffSeries.driver ? 'DRIVER_PRACTICAL' : 'GENERAL';
    final result = await ref.read(rmRepositoryProvider).createAssessment(staffId: staff.id, assessmentType: assessmentType);
    if (!mounted) return;
    setState(() => _creating = false);
    result.fold(
      onSuccess: (_) => ref.invalidate(staffAssessmentsProvider(staff.id)),
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }
}

class _SubmitAssessmentCard extends ConsumerStatefulWidget {
  const _SubmitAssessmentCard({required this.assessment, required this.staffId});
  final Assessment assessment;
  final String staffId;

  @override
  ConsumerState<_SubmitAssessmentCard> createState() => _SubmitAssessmentCardState();
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
          remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (submitResult) {
        ref.invalidate(staffAssessmentsProvider(widget.staffId));
        if (submitResult.autoTerminated) {
          ref.invalidate(rmKanbanProvider);
          ref.invalidate(staffByIdProvider(widget.staffId));
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(submitResult.message ?? 'Staff record moved to TERMINAL after repeated failures.'), backgroundColor: RmTheme.crimsonDanger),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Assessment result submitted')));
        }
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(color: RmTheme.cardSurface, borderRadius: BorderRadius.circular(12), border: Border.all(color: RmTheme.electricBlue.withOpacity(0.3))),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Submit result', style: TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              for (final r in AssessmentResults.all)
                ChoiceChip(
                  label: Text(r),
                  selected: _result == r,
                  onSelected: (_) => setState(() => _result = r),
                ),
            ],
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _scoreController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(labelText: 'Score (optional)', isDense: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _remarksController,
            decoration: const InputDecoration(labelText: 'Remarks (optional)', isDense: true, border: OutlineInputBorder()),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
              child: _submitting
                  ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Text('Submit'),
            ),
          ),
        ],
      ),
    );
  }
}
