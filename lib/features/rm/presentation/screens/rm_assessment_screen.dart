import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Assessment (S2.5)',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
      ),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        builder: (staff) {
          if (staff == null) {
            return Center(
              child: Text(
                'Staff not found',
                style: GoogleFonts.inter(color: RmTheme.textSecondary),
              ),
            );
          }
          return RefreshIndicator(
            color: RmTheme.electricBlue,
            onRefresh: () async => ref.invalidate(rmAssessmentsProvider),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Profile Header ──
                  _buildProfileHeader(staff),

                  const SizedBox(height: 20),

                  // ── Main Content Area ──
                  AsyncValueWidget<List<Assessment>>(
                    value: assessmentsAsync,
                    onRetry: () => ref.invalidate(rmAssessmentsProvider),
                    builder: (assessments) =>
                        _buildContent(context, staff, assessments),
                  ),
                ],
              ),
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

  Widget _buildContent(
    BuildContext context,
    StaffRow staff,
    List<Assessment> assessments,
  ) {
    final latest = assessments.isEmpty ? null : assessments.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ── List Section Title ──
        Text(
          'Assessment Log',
          style: GoogleFonts.libreCaslonText(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: RmTheme.textPrimary,
          ),
        )
            .animate()
            .fadeIn(delay: 50.ms, duration: 300.ms),
        const SizedBox(height: 12),

        if (assessments.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 8),
            child: Center(
              child: Text(
                'No assessments yet for this staff member.',
                style: GoogleFonts.inter(
                  color: RmTheme.textSecondary,
                  fontSize: 14,
                ),
              ),
            ),
          ).animate().fadeIn(delay: 100.ms, duration: 300.ms)
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: assessments.length,
            itemBuilder: (context, index) =>
                _buildAssessmentCard(context, assessments[index], index),
          ),

        const SizedBox(height: 24),

        // ── Form Area / New Attempt CTA ──
        if (latest == null || latest.status == 'COMPLETED')
          SizedBox(
            width: double.infinity,
            height: 52,
            child: OutlinedButton(
              onPressed: _creating ? null : () => _createAssessment(staff),
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RmTheme.electricBlue, width: 1.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: _creating
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: RmTheme.electricBlue,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.add_rounded, size: 20),
                        const SizedBox(width: 8),
                        Text(
                          assessments.isEmpty
                              ? 'Start Assessment'
                              : 'New Attempt',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 15,
                          ),
                        ),
                      ],
                    ),
            ),
          )
              .animate()
              .fadeIn(delay: 150.ms, duration: 350.ms)
              .slideY(begin: 0.05, end: 0, delay: 150.ms, duration: 350.ms)
        else
          _SubmitAssessmentCard(assessment: latest, staffId: staff.id)
              .animate()
              .fadeIn(delay: 150.ms, duration: 350.ms)
              .slideY(begin: 0.05, end: 0, delay: 150.ms, duration: 350.ms),

        const SizedBox(height: 24),

        // ── Advance Action Footer ──
        if (latest != null && latest.passed)
          AdvanceStageButton(
            staffId: staff.id,
            fromStage: staff.pipelineStage,
            toStage: PipelineStages.s3Train,
            label: 'Advance to Training (S3)',
            reasonCode: 'ASSESSMENT_PASSED',
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
      ],
    );
  }

  Widget _buildAssessmentCard(BuildContext context, Assessment a, int index) {
    Color color = RmTheme.textSecondary;
    IconData icon = Icons.help_outline_rounded;
    if (a.result == AssessmentResults.pass) {
      color = RmTheme.emeraldGreen;
      icon = Icons.check_circle_outline_rounded;
    }
    if (a.result == AssessmentResults.fail) {
      color = RmTheme.crimsonDanger;
      icon = Icons.cancel_outlined;
    }
    if (a.result == AssessmentResults.partial) {
      color = RmTheme.amberWarning;
      icon = Icons.warning_amber_rounded;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        children: [
          // ── Circular Type Indicator ──
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 22),
          ),
          const SizedBox(width: 14),

          // ── Content Info ──
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Attempt #${a.attemptNumber} • ${a.assessmentType ?? 'GENERAL'}',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 14.5,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Status: ${a.status.toUpperCase()}${a.score != null ? ' • Score: ${a.score}' : ''}',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
                if (a.remarks != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    a.remarks!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontStyle: FontStyle.italic,
                      color: RmTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),

          // ── Badge Label ──
          if (a.result != null)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: color.withValues(alpha: 0.25),
                  width: 1,
                ),
              ),
              child: Text(
                a.result!.toUpperCase(),
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 11,
                  letterSpacing: 0.2,
                ),
              ),
            ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 50 * index),
          duration: 400.ms,
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
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(f.message),
          backgroundColor: RmTheme.crimsonDanger,
        ),
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
            style: GoogleFonts.libreCaslonText(
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
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Score (optional)',
              labelStyle: GoogleFonts.inter(
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
            style: GoogleFonts.inter(
              fontSize: 14.5,
              fontWeight: FontWeight.w500,
              color: RmTheme.textPrimary,
            ),
            decoration: InputDecoration(
              labelText: 'Remarks (optional)',
              labelStyle: GoogleFonts.inter(
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
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
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
                      style: GoogleFonts.inter(
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
                style: GoogleFonts.inter(
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
