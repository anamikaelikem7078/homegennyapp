import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

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
          'Placement Details',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
      ),
      body: placementAsync.when(
        loading: () => const Center(
          child: CircularProgressIndicator(color: RmTheme.electricBlue),
        ),
        error: (e, _) => Center(
          child: Text(
            '$e',
            style: GoogleFonts.inter(color: RmTheme.crimsonDanger),
          ),
        ),
        data: (placement) {
          if (placement == null || placement.id != placementId) {
            return Center(
              child: Text(
                'Placement not found',
                style: GoogleFonts.inter(color: RmTheme.textSecondary),
              ),
            );
          }
          return _PlacementBody(placement: placement, staffId: staffId);
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
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Placement Confirmed — attendance, check-in, and invoicing now unlocked',
            ),
            backgroundColor: RmTheme.emeraldGreen,
          ),
        );
      },
      onError: (f) {
        final missingA2A3 = f.message.contains('A2') || f.message.contains('A3');
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            backgroundColor: RmTheme.crimsonDanger,
            duration: missingA2A3 ? const Duration(seconds: 6) : const Duration(seconds: 4),
            action: missingA2A3
                ? SnackBarAction(
                    label: 'SEND A2/A3',
                    textColor: Colors.white,
                    onPressed: () => context.push(RmRoutes.stage5Hub(widget.staffId)),
                  )
                : null,
          ),
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
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Placement exited')));
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
    final placement = widget.placement;

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Status Overview Card ──
          _buildStatusCard(placement.status),

          const SizedBox(height: 16),

          // ── Trial Lockout Warning Block ──
          if (placement.isTrial)
            _buildWarningBlock()
                .animate()
                .fadeIn(duration: 400.ms)
                .slideY(begin: 0.05, end: 0, duration: 400.ms),

          const SizedBox(height: 16),

          // ── Primary Details Card ──
          _buildDetailsCard(placement),

          const SizedBox(height: 16),

          // ── Financial Numbers Card ──
          if (placement.staffSalary != null || placement.managementFee != null)
            _buildFinancialsCard(placement),

          const SizedBox(height: 32),

          // ── Actions Footer ──
          if (placement.isTrial)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton(
                onPressed: _busy ? null : _confirm,
                style: FilledButton.styleFrom(
                  backgroundColor: RmTheme.emeraldGreen,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  elevation: 2,
                ),
                child: _busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        'Confirm Placement',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
              ),
            ).animate().scale(delay: 200.ms, duration: 300.ms)
          else if (placement.isConfirmed)
            SizedBox(
              width: double.infinity,
              height: 54,
              child: OutlinedButton(
                onPressed: _busy ? null : _exit,
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: RmTheme.crimsonDanger, width: 1.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: Text(
                  'End Placement',
                  style: GoogleFonts.inter(
                    color: RmTheme.crimsonDanger,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ).animate().scale(delay: 200.ms, duration: 300.ms),
        ],
      ),
    );
  }

  // ─── Component Builders ───────────────────────────────────────────────────

  Widget _buildStatusCard(String status) {
    final isConfirmed = status == 'CONFIRMED';
    final isTrial = status == 'TRIAL';

    final Color primaryColor = isConfirmed
        ? RmTheme.emeraldGreen
        : isTrial
            ? RmTheme.amberWarning
            : RmTheme.textSecondary;

    final IconData statusIcon = isConfirmed
        ? Icons.verified_rounded
        : isTrial
            ? Icons.hourglass_empty_rounded
            : Icons.cancel_outlined;

    final String helperText = isConfirmed
        ? 'Active & Invoicing unlocked'
        : isTrial
            ? 'Awaiting validation'
            : 'Placement concluded';

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
            color: Color(0x06000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: primaryColor.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(statusIcon, color: primaryColor, size: 28),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'STATUS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: RmTheme.textSecondary,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  status,
                  style: GoogleFonts.inter(
                    fontSize: 22,
                    fontWeight: FontWeight.w800,
                    color: primaryColor,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  helperText,
                  style: GoogleFonts.inter(
                    fontSize: 13,
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
        .slideY(begin: -0.05, end: 0, duration: 400.ms);
  }

  Widget _buildWarningBlock() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.amberWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RmTheme.amberWarning.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: RmTheme.amberWarning,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'TRIAL — pending confirmation. Check-in, attendance, and invoicing are locked until confirmed.',
              style: GoogleFonts.inter(
                color: const Color(0xFFB45309), // Warm dark amber
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
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
          Text(
            'Assignment & Schedule',
            style: GoogleFonts.libreCaslonText(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
          Text(
            'Financial Plan',
            style: GoogleFonts.libreCaslonText(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
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
          Icon(icon, color: RmTheme.electricBlue.withValues(alpha: 0.8), size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: RmTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
                  style: GoogleFonts.inter(
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
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text('$label copied to clipboard'),
                    duration: const Duration(seconds: 1),
                  ),
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
            style: GoogleFonts.inter(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: RmTheme.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '₹${amount.toString()}',
            style: GoogleFonts.inter(
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
