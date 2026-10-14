import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/pipeline_stage.dart';
import '../widgets/rm_stage_ui.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';

/// Placement state machine detail view — the single most important business
/// rule in the RM workflow: `S5_DEPLOY → POST /placements → TRIAL →
/// POST /placements/:id/confirm → CONFIRMED → POST /placements/:id/exit →
/// EXITED`. `Confirm` is only ever shown while `status === 'TRIAL'`, never
/// inferred from placement creation succeeding (Rule 4). A 400 on confirm
/// (already confirmed / not TRIAL, or A2/A3 not yet sent — `POST
/// /:id/confirm` now requires an SOW with status SENT/ACKNOWLEDGED and at
/// least one Indemnity row) surfaces the backend's own message; the A2/A3
/// case also offers a shortcut into the S5 Deploy hub to send them. This
/// requirement does not apply to a placement created directly as
/// `status: "CONFIRMED"` — that fast path is handled entirely in
/// `rm_placement_create_screen.dart`.
class RmPlacementDetailScreen extends ConsumerWidget {
  const RmPlacementDetailScreen({
    super.key,
    required this.placementId,
    required this.staffId,
  });
  final String placementId;

  /// Needed to invalidate the staff-scoped placement provider on
  /// confirm/exit — there is no `GET /placements/:id`, only the list.
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(staffPlacementProvider(staffId));

    return RmStageScaffold(
      title: 'Placement',
      stageCode: 'S5',
      stageColor: rmStageColor(PipelineStages.s5Deploy),
      onRefresh: () async => ref.invalidate(staffPlacementProvider(staffId)),
      body: rmAsyncBody<PlacementRow?>(
        placementAsync,
        onRetry: () => ref.invalidate(staffPlacementProvider(staffId)),
        builder: (placement) {
          if (placement == null || placement.id != placementId) {
            return const [
              RmEmptyBlock(
                icon: Icons.search_off_rounded,
                title: 'Placement not found',
                message: 'It may have been replaced by a newer placement.',
              ),
            ];
          }
          return [_PlacementBody(placement: placement, staffId: staffId)];
        },
      ),
    );
  }
}

class _PlacementBody extends ConsumerStatefulWidget {
  const _PlacementBody({required this.placement, required this.staffId});
  final PlacementRow placement;
  final String staffId;

  @override
  ConsumerState<_PlacementBody> createState() => _PlacementBodyState();
}

class _PlacementBodyState extends ConsumerState<_PlacementBody> {
  bool _busy = false;

  Future<void> _confirm() async {
    setState(() => _busy = true);
    final result = await ref
        .read(rmRepositoryProvider)
        .confirmPlacement(widget.placement.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (updated) {
        ref.invalidate(staffPlacementProvider(widget.staffId));
        ref.invalidate(
          rmPlacementsProvider(PlacementListParams(staffId: widget.staffId)),
        );
        ref.invalidate(rmDashboardProvider);
        DsSnackBar.show(
          context,
          message: 'Placement Confirmed — attendance, check-in, and invoicing now unlocked',
          type: DsSnackBarType.success,
        );
      },
      onError: (f) {
        final missingA2A3 = f.message.contains('A2') || f.message.contains('A3');
        DsSnackBar.show(
          context,
          message: f.message,
          type: DsSnackBarType.error,
          duration: missingA2A3 ? const Duration(seconds: 6) : const Duration(seconds: 4),
          actionLabel: missingA2A3 ? 'Send A2/A3' : null,
          onAction: missingA2A3 ? () => context.push(RmRoutes.stage5Hub(widget.staffId)) : null,
        );
        ref.invalidate(staffPlacementProvider(widget.staffId));
      },
    );
  }

  Future<void> _exit() async {
    final scenario = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dateController = TextEditingController(
          text: DateTime.now().toIso8601String().substring(0, 10),
        );
        String selectedScenario = 'CLIENT_INITIATED';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: Text(
              'End Placement',
              style: RmTheme.title(context),
            ),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: dateController,
                  decoration: const InputDecoration(
                    labelText: 'Exit date (YYYY-MM-DD)',
                  ),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedScenario,
                  items: const [
                    DropdownMenuItem(
                      value: 'CLIENT_INITIATED',
                      child: Text('Client Initiated'),
                    ),
                    DropdownMenuItem(
                      value: 'STAFF_INITIATED',
                      child: Text('Staff Initiated'),
                    ),
                    DropdownMenuItem(
                      value: 'RM_INITIATED',
                      child: Text('RM Initiated'),
                    ),
                  ],
                  onChanged: (v) => setDialogState(
                    () => selectedScenario = v ?? selectedScenario,
                  ),
                  decoration: const InputDecoration(labelText: 'Exit scenario'),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(
                  dialogContext,
                ).pop('${dateController.text.trim()}|$selectedScenario'),
                style: FilledButton.styleFrom(
                  backgroundColor: RmTheme.crimsonDanger,
                ),
                child: const Text('End Placement'),
              ),
            ],
          ),
        );
      },
    );
    if (scenario == null) return;
    final parts = scenario.split('|');
    if (parts.length != 2) return;

    setState(() => _busy = true);
    final result = await ref
        .read(rmRepositoryProvider)
        .exitPlacement(
          widget.placement.id,
          exitDate: parts[0],
          exitScenarioCode: parts[1],
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffPlacementProvider(widget.staffId));
        ref.invalidate(
          rmPlacementsProvider(PlacementListParams(staffId: widget.staffId)),
        );
        ref.invalidate(rmDashboardProvider);
        DsSnackBar.show(context, message: 'Placement exited', type: DsSnackBarType.success);
      },
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placement = widget.placement;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildStatusCard(placement.status),
        if (placement.isTrial) ...[
          const SizedBox(height: 14),
          const RmNote(
            tone: RmNoteTone.warning,
            title: 'Trial — pending confirmation',
            text: 'Check-in, attendance and invoicing stay locked until you confirm.',
          ),
        ],
        const RmSectionTitle(title: 'Assignment & schedule'),
        _buildDetailsCard(placement),
        if (placement.staffSalary != null || placement.managementFee != null) ...[
          const RmSectionTitle(title: 'Financial plan'),
          _buildFinancialsCard(placement),
        ],
        const SizedBox(height: 24),
        if (placement.isTrial)
          DsGradientButton(
            label: 'Confirm placement',
            icon: Icons.verified_rounded,
            isLoading: _busy,
            gradient: const LinearGradient(
              colors: [Color(0xFF34D399), Color(0xFF059669)],
            ),
            onPressed: _busy ? null : _confirm,
          )
        else if (placement.isConfirmed)
          DsOutlineButton(
            label: 'End placement',
            icon: Icons.logout_rounded,
            color: RmTheme.crimsonDanger,
            isLoading: _busy,
            onPressed: _busy ? null : _exit,
          ),
      ],
    );
  }

  // ─── Component Builders ───────────────────────────────────────────────────

  /// Gradient status hero with a TRIAL → CONFIRMED → EXITED journey.
  Widget _buildStatusCard(String status) {
    final isConfirmed = status == 'CONFIRMED';
    final isTrial = status == 'TRIAL';
    final step = isTrial ? 0 : (isConfirmed ? 1 : 2);

    final (IconData icon, String helper) = isConfirmed
        ? (Icons.verified_rounded, 'Active — attendance & invoicing unlocked')
        : isTrial
            ? (Icons.hourglass_top_rounded, 'Awaiting your confirmation')
            : (Icons.flag_rounded, 'Placement concluded');

    Widget node(int i, String label) {
      final done = i <= step;
      final current = i == step;
      return Expanded(
        child: Column(
          children: [
            AnimatedContainer(
              duration: 300.ms,
              width: current ? 30 : 24,
              height: current ? 30 : 24,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: done ? Colors.white : Colors.white.withValues(alpha: 0.18),
                border: current
                    ? Border.all(color: const Color(0xFFFFD84D), width: 3)
                    : null,
              ),
              child: Icon(
                done ? Icons.check_rounded : Icons.circle,
                size: done ? 15 : 7,
                color: done ? RmTheme.electricBlue : Colors.white.withValues(alpha: 0.5),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: current ? FontWeight.w800 : FontWeight.w600,
                color: Colors.white.withValues(alpha: done ? 1 : 0.6),
              ),
            ),
          ],
        ),
      );
    }

    Widget line(int i) => Expanded(
          child: Container(
            height: 3,
            margin: const EdgeInsets.only(bottom: 22),
            decoration: BoxDecoration(
              color: i < step ? Colors.white : Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: isConfirmed
              ? const [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)]
              : const [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
        ),
        borderRadius: BorderRadius.circular(26),
        boxShadow: [
          BoxShadow(
            color: (isConfirmed ? RmTheme.emeraldGreen : RmTheme.electricBlue)
                .withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Icon(icon, color: RmTheme.iconAccent, size: 26),
              ).animate().scaleXY(
                    begin: 0.5,
                    end: 1,
                    duration: 550.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rmTitleCase(status),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 24,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    Text(
                      helper,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              node(0, 'Trial'),
              line(0),
              node(1, 'Confirmed'),
              line(1),
              node(2, 'Exited'),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailsCard(PlacementRow placement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(22),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildDetailRow(
            icon: Icons.person_pin_rounded,
            label: 'Staff ID',
            value: placement.staffId,
            showCopy: true,
          ),
          const Divider(height: 24, thickness: 0.8),
          _buildDetailRow(
            icon: Icons.business_center_rounded,
            label: 'Client ID',
            value: placement.clientId,
            showCopy: true,
          ),
          if (placement.trialStartDate != null || placement.trialEndDate != null) ...[
            const Divider(height: 24, thickness: 0.8),
            _buildDetailRow(
              icon: Icons.calendar_month_rounded,
              label: 'Trial Duration',
              value: _formatDateRange(
                placement.trialStartDate,
                placement.trialEndDate,
              ),
            ),
          ],
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0, delay: 100.ms, duration: 400.ms);
  }

  Widget _buildFinancialsCard(PlacementRow placement) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              if (placement.staffSalary != null)
                Expanded(
                  child: _buildFinancialCell(
                    label: 'Staff Salary',
                    amount: placement.staffSalary!,
                    color: RmTheme.electricBlue,
                  ),
                ),
              if (placement.staffSalary != null && placement.managementFee != null)
                Container(
                  width: 1,
                  height: 48,
                  color: RmTheme.borderSubtle.withValues(alpha: 0.7),
                ),
              if (placement.managementFee != null)
                Expanded(
                  child: _buildFinancialCell(
                    label: 'Management Fee',
                    amount: placement.managementFee!,
                    color: RmTheme.emeraldGreen,
                  ),
                ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.05, end: 0, delay: 150.ms, duration: 400.ms);
  }

  Widget _buildDetailRow({
    required IconData icon,
    required String label,
    required String value,
    bool showCopy = false,
  }) {
    return Builder(
      builder: (context) => Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: RmTheme.iconAccentSoft,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: RmTheme.iconAccent, size: 19),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          if (showCopy)
            IconButton(
              icon: const Icon(Icons.copy_rounded, size: 18),
              color: RmTheme.textSecondary.withValues(alpha: 0.7),
              onPressed: () {
                Clipboard.setData(ClipboardData(text: value));
                DsSnackBar.show(
                  context,
                  message: '$label copied',
                  type: DsSnackBarType.success,
                  duration: const Duration(seconds: 1),
                );
              },
              tooltip: 'Copy ID',
              splashRadius: 18,
            ),
        ],
      ),
    );
  }

  Widget _buildFinancialCell({
    required String label,
    required num amount,
    required Color color,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RmTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toString()}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  String _formatDateRange(String? start, String? end) {
    if (start == null && end == null) return 'N/A';
    final cleanStart = start?.replaceAll('Z', '') ?? '...';
    final cleanEnd = end?.replaceAll('Z', '') ?? '...';
    
    // Simplifies format (2026-08-21T00:00:00 -> 2026-08-21)
    final formattedStart = cleanStart.contains('T') ? cleanStart.split('T')[0] : cleanStart;
    final formattedEnd = cleanEnd.contains('T') ? cleanEnd.split('T')[0] : cleanEnd;

    return '$formattedStart to $formattedEnd';
  }
}
