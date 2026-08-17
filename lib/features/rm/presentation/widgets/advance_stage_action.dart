import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
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
  if (!PipelineStages.canAdvance(fromStage, toStage)) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Cannot move from ${PipelineStages.label(fromStage)} to ${PipelineStages.label(toStage)} directly — '
          'stages must be completed in order.',
        ),
        backgroundColor: RmTheme.crimsonDanger,
      ),
    );
    return false;
  }

  final confirmed = await showDialog<bool>(
    context: context,
    builder: (dialogContext) => AlertDialog(
      title: Text(confirmTitle ?? 'Advance to ${PipelineStages.label(toStage)}?'),
      content: Text(
        confirmMessage ??
            'This will move the staff member from ${PipelineStages.label(fromStage)} to ${PipelineStages.label(toStage)}. '
                'This action is recorded on the pipeline history and cannot be silently undone.',
      ),
      actions: [
        TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
        FilledButton(
          onPressed: () => Navigator.of(dialogContext).pop(true),
          style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
          child: const Text('Confirm'),
        ),
      ],
    ),
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
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Moved to ${PipelineStages.label(staff.pipelineStage)}'),
          backgroundColor: RmTheme.emeraldGreen,
        ),
      );
      return true;
    },
    onError: (failure) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(failure.message), backgroundColor: RmTheme.crimsonDanger),
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

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: FilledButton(
        onPressed: (!widget.enabled || _submitting)
            ? null
            : () async {
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
              },
        style: FilledButton.styleFrom(
          backgroundColor: RmTheme.electricBlue,
          disabledBackgroundColor: RmTheme.borderSubtle,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
        child: _submitting
            ? const SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : Text(widget.label, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
      ),
    );
  }
}
