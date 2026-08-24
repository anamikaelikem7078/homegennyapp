import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/verification_form_scaffold.dart';

/// Police verification track — `POST /verification/pv/submit/{staffId}`.
/// This always creates a PENDING `VerificationTrack` record; the actual
/// CLEAR/ADVERSE outcome is set later by the back office, not by this call.
/// The staff row's `pv_status` field reflects the latest outcome, so it's
/// shown here as read-only context above the submit form.
class RmTrack4PvScreen extends ConsumerStatefulWidget {
  const RmTrack4PvScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmTrack4PvScreen> createState() => _RmTrack4PvScreenState();
}

class _RmTrack4PvScreenState extends ConsumerState<RmTrack4PvScreen> {
  final _notesController = TextEditingController();
  bool _submitting = false;
  PvResult? _result;

  final _closeNotesController = TextEditingController();
  String? _closeResult; // null | 'CLEAR' | 'ADVERSE' — no default selection
  bool _closing = false;

  /// Local optimistic status from the last submit/close response — shown
  /// immediately instead of waiting on the kanban refetch (which sources
  /// `staffByIdProvider` and can lag right after a mutation).
  String? _localStatusOverride;

  @override
  void dispose() {
    _notesController.dispose();
    _closeNotesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await ref.read(rmRepositoryProvider).submitPv(
          widget.staffId,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      onSuccess: (data) {
        setState(() {
          _result = data;
          _localStatusOverride = data.status;
        });
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(rmVerificationStatusProvider(widget.staffId));
          ref.invalidate(rmKanbanProvider);
          ref.invalidate(staffByIdProvider(widget.staffId));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Police verification request submitted — status PENDING.'),
            backgroundColor: RmTheme.amberWarning,
          ),
        );
      },
      onError: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: RmTheme.crimsonDanger),
        );
      },
    );
  }

  Future<void> _closePv() async {
    if (_closeResult == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Record PV Result?',
          style: RmTheme.title(context),
        ),
        content: Text(
          'This will mark police verification as $_closeResult for this staff member. '
          'This is a compliance record and cannot be silently undone.',
          style: GoogleFonts.inter(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _closing = true);
    final result = await ref.read(rmRepositoryProvider).closePv(
          widget.staffId,
          result: _closeResult!,
          notes: _closeNotesController.text.trim().isEmpty ? null : _closeNotesController.text.trim(),
        );
    if (!mounted) return;
    setState(() => _closing = false);

    result.fold(
      onSuccess: (data) {
        setState(() => _localStatusOverride = data.pvStatus);
        WidgetsBinding.instance.addPostFrameCallback((_) {
          ref.invalidate(rmVerificationStatusProvider(widget.staffId));
          ref.invalidate(rmKanbanProvider);
          ref.invalidate(staffByIdProvider(widget.staffId));
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('PV result recorded — ${data.pvStatus}'),
            backgroundColor: data.pvStatus == 'CLEAR' ? RmTheme.emeraldGreen : RmTheme.crimsonDanger,
          ),
        );
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));
    final currentPvStatus =
        _localStatusOverride ?? staffAsync.maybeWhen(data: (s) => s?.pvStatus, orElse: () => null);
    final alreadySubmitted = currentPvStatus != null && currentPvStatus != 'NOT_INITIATED';
    final isClear = currentPvStatus == 'CLEAR';
    final isAdverse = currentPvStatus == 'ADVERSE';
    final canRecordResult = alreadySubmitted && !isClear && !isAdverse;

    return VerificationFormScaffold(
      title: 'Police Verification',
      staffId: widget.staffId,
      onBack: () => context.pop(),
      children: [
        // ── Current Status Display Block ──
        if (currentPvStatus != null)
          _buildCurrentStatusBlock(currentPvStatus)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: -0.04, end: 0, duration: 300.ms),

        if (isClear)
          const VerificationResultCard(
            success: true,
            headline: 'Cleared',
            rows: {},
          )
        else if (isAdverse)
          const VerificationResultCard(
            success: false,
            headline: 'Failed / Adverse',
            rows: {
              'Deployment': 'Blocked until this is resolved for this staff member\'s series.',
            },
          )
        else ...[
          // ── Form Area ──
          VerificationTextField(
            label: 'Notes (optional)',
            controller: _notesController,
            hint: 'Any context for the back-office verifier',
          )
              .animate()
              .fadeIn(delay: 80.ms, duration: 350.ms)
              .slideY(begin: 0.04, end: 0, delay: 80.ms, duration: 300.ms),
          const SizedBox(height: 20),
          VerificationSubmitButton(
            label: alreadySubmitted ? 'Re-submit PV Request' : 'Submit PV Request',
            submitting: _submitting,
            onPressed: _submit,
          )
              .animate()
              .fadeIn(delay: 140.ms, duration: 350.ms)
              .slideY(begin: 0.03, end: 0, delay: 140.ms, duration: 300.ms),
          const SizedBox(height: 10),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              'Submitting always creates a new PENDING request — the outcome (CLEAR/ADVERSE) is '
              'recorded later by the back office, not returned immediately.',
              style: GoogleFonts.inter(
                color: RmTheme.textSecondary,
                fontSize: 12,
                height: 1.35,
              ),
            ),
          )
              .animate()
              .fadeIn(delay: 180.ms, duration: 350.ms),

          // ── Results Display Card ──
          if (_result != null) ...[
            const SizedBox(height: 24),
            VerificationResultCard(
              success: false,
              pending: true,
              headline: 'Request Submitted — ${_result!.status}',
              rows: {
                'Reference number': _result!.referenceNumber,
                'Submitted at': _result!.submittedAt,
                'Status': _result!.status,
              },
            ),
          ],

          // ── Record PV Results (Manual Sandbox Option) ──
          if (canRecordResult) ...[
            const SizedBox(height: 32),
            const Divider(height: 1),
            const SizedBox(height: 24),
            Text(
              'Record Final Outcome',
              style: GoogleFonts.libreCaslonText(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: RmTheme.textPrimary,
              ),
            )
                .animate()
                .fadeIn(delay: 200.ms, duration: 300.ms),
            const SizedBox(height: 12),
            _buildResultChoiceChips()
                .animate()
                .fadeIn(delay: 240.ms, duration: 300.ms),
            const SizedBox(height: 16),
            VerificationTextField(
              label: 'Notes (optional)',
              controller: _closeNotesController,
              hint: 'e.g. Certificate received from local police station',
            )
                .animate()
                .fadeIn(delay: 280.ms, duration: 300.ms),
            const SizedBox(height: 16),
            VerificationSubmitButton(
              label: 'Record Result',
              submitting: _closing,
              enabled: _closeResult != null,
              onPressed: _closePv,
            )
                .animate()
                .fadeIn(delay: 320.ms, duration: 300.ms),
          ],
        ],
      ],
    );
  }

  Widget _buildCurrentStatusBlock(String status) {
    final statusFormatted = status.replaceAll('_', ' ').toUpperCase();
    final isClear = status == 'CLEAR';
    final isAdverse = status == 'ADVERSE';
    final isPending = status == 'PENDING' || status == 'IN_PROGRESS';

    final Color statusColor = isClear
        ? RmTheme.emeraldGreen
        : isAdverse
            ? RmTheme.crimsonDanger
            : isPending
                ? RmTheme.amberWarning
                : RmTheme.textSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 6,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            'Current PV Status',
            style: GoogleFonts.inter(
              fontSize: 14,
              fontWeight: FontWeight.w500,
              color: RmTheme.textSecondary,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(8),
              border: Border.all(
                color: statusColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            child: Text(
              statusFormatted,
              style: GoogleFonts.inter(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: statusColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultChoiceChips() {
    return Row(
      children: [
        Expanded(
          child: _ChoiceChipCard(
            label: 'CLEAR',
            color: RmTheme.emeraldGreen,
            selected: _closeResult == 'CLEAR',
            onTap: () => setState(() => _closeResult = 'CLEAR'),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: _ChoiceChipCard(
            label: 'ADVERSE',
            color: RmTheme.crimsonDanger,
            selected: _closeResult == 'ADVERSE',
            onTap: () => setState(() => _closeResult = 'ADVERSE'),
          ),
        ),
      ],
    );
  }
}

class _ChoiceChipCard extends StatelessWidget {
  const _ChoiceChipCard({
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
        color: selected ? color.withValues(alpha: 0.08) : RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: selected ? color : RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: selected ? 1.8 : 1.2,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12),
            child: Center(
              child: Text(
                label,
                style: GoogleFonts.inter(
                  color: selected ? color : RmTheme.textSecondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
