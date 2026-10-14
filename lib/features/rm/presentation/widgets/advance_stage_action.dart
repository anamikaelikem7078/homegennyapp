import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/series/series_catalog.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/pipeline_stage.dart';
import '../providers/rm_providers.dart';

/// Confirms and executes a pipeline-stage advance, then refreshes every
/// provider that depends on staff/pipeline state. This is the single place
/// `POST /rm/pipeline/:staffId/advance` is called from — every stage
/// screen's "Complete X" button routes through here so gating (Rule 1: no
/// stage skipping) and the refresh-on-success behavior stay consistent.
///
/// Returns true if the advance succeeded.
Future<bool> advanceStageAction(
  BuildContext context,
  WidgetRef ref, {
  required String staffId,
  required String fromStage,
  required String toStage,
  String? reasonCode,
  Map<String, dynamic>? payload,
  String? terminalOutcome,
  String? confirmTitle,
  String? confirmMessage,
}) async {
  if (!PipelineStages.canAdvance(fromStage, toStage,
      stage25Enabled: ref.read(seriesCatalogProvider).stage25Enabled)) {
    DsSnackBar.show(
      context,
      message:
          'Cannot move from ${PipelineStages.label(fromStage)} to ${PipelineStages.label(toStage)} directly — '
          'stages must be completed in order.',
      type: DsSnackBarType.error,
    );
    return false;
  }

  final isExit =
      toStage == PipelineStages.terminal || toStage == PipelineStages.deferred;
  final confirmed = await DsConfirmationDialog.show(
    context: context,
    title: confirmTitle ?? 'Advance to ${PipelineStages.label(toStage)}?',
    message: confirmMessage ??
        'This will move the staff member from ${PipelineStages.label(fromStage)} to ${PipelineStages.label(toStage)}. '
            'This action is recorded on the pipeline history and cannot be silently undone.',
    confirmLabel: 'Confirm',
    isDestructive: isExit,
    icon: isExit ? Icons.warning_amber_rounded : Icons.rocket_launch_rounded,
  );
  if (confirmed != true) return false;
  if (!context.mounted) return false;

  final result = await ref.read(rmRepositoryProvider).advanceStage(
        staffId,
        toStage,
        reasonCode: reasonCode,
        payload: payload,
        terminalOutcome: terminalOutcome,
      );

  if (!context.mounted) return false;

  return result.fold(
    onSuccess: (staff) {
      ref.invalidate(rmKanbanProvider);
      ref.invalidate(rmDashboardProvider);
      ref.invalidate(staffByIdProvider(staffId));
      DsSnackBar.show(
        context,
        message: 'Moved to ${PipelineStages.label(staff.pipelineStage)}',
        type: DsSnackBarType.success,
      );
      return true;
    },
    onError: (failure) {
      DsSnackBar.show(
        context,
        message: failure.message,
        type: DsSnackBarType.error,
      );
      return false;
    },
  );
}

/// A ready-to-drop button that calls [advanceStageAction] and disables
/// itself while the request is in flight (prevents duplicate submits).
class AdvanceStageButton extends ConsumerStatefulWidget {
  const AdvanceStageButton({
    super.key,
    required this.staffId,
    required this.fromStage,
    required this.toStage,
    required this.label,
    this.reasonCode,
    this.payload,
    this.terminalOutcome,
    this.confirmTitle,
    this.confirmMessage,
    this.onSuccess,
    this.enabled = true,
  });

  final String staffId;
  final String fromStage;
  final String toStage;
  final String label;
  final String? reasonCode;
  final Map<String, dynamic>? payload;
  final String? terminalOutcome;
  final String? confirmTitle;
  final String? confirmMessage;
  final VoidCallback? onSuccess;
  final bool enabled;

  @override
  ConsumerState<AdvanceStageButton> createState() => _AdvanceStageButtonState();
}

class _AdvanceStageButtonState extends ConsumerState<AdvanceStageButton> {
  bool _submitting = false;

  Future<void> _run() async {
    setState(() => _submitting = true);
    final success = await advanceStageAction(
      context,
      ref,
      staffId: widget.staffId,
      fromStage: widget.fromStage,
      toStage: widget.toStage,
      reasonCode: widget.reasonCode,
      payload: widget.payload,
      terminalOutcome: widget.terminalOutcome,
      confirmTitle: widget.confirmTitle,
      confirmMessage: widget.confirmMessage,
    );
    if (mounted) setState(() => _submitting = false);
    if (success) widget.onSuccess?.call();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.enabled) {
      // Locked state: grey pill with a lock so it reads as "not yet".
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: RmTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: RmTheme.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 17, color: RmTheme.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                widget.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return DsGradientButton(
      label: widget.label,
      isLoading: _submitting,
      onPressed: _submitting ? null : _run,
    );
  }
}
