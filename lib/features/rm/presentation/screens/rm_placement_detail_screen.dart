import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Placement state machine detail view — the single most important business
/// rule in the RM workflow: `S5_DEPLOY → POST /placements → TRIAL →
/// POST /placements/:id/confirm → CONFIRMED → POST /placements/:id/exit →
/// EXITED`. `Confirm` is only ever shown while `status === 'TRIAL'`, never
/// inferred from placement creation succeeding (Rule 4). A 400 on confirm
/// (already confirmed / not TRIAL) surfaces the backend's own message.
class RmPlacementDetailScreen extends ConsumerWidget {
  const RmPlacementDetailScreen({super.key, required this.placementId, required this.staffId});
  final String placementId;
  /// Needed to invalidate the staff-scoped placement provider on
  /// confirm/exit — there is no `GET /placements/:id`, only the list.
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final placementAsync = ref.watch(staffPlacementProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Placement')),
      body: placementAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (placement) {
          if (placement == null || placement.id != placementId) {
            return const Center(child: Text('Placement not found'));
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
    final result = await ref.read(rmRepositoryProvider).confirmPlacement(widget.placement.id);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (updated) {
        ref.invalidate(staffPlacementProvider(widget.staffId));
        ref.invalidate(rmPlacementsProvider(PlacementListParams(staffId: widget.staffId)));
        ref.invalidate(rmDashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Placement Confirmed — attendance, check-in, and invoicing now unlocked'), backgroundColor: RmTheme.emeraldGreen),
        );
      },
      onError: (f) {
        // Surface the backend's own message directly (e.g. "already confirmed" / "not TRIAL") — don't crash, don't invent custom copy.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger));
        ref.invalidate(staffPlacementProvider(widget.staffId));
      },
    );
  }

  Future<void> _exit() async {
    final scenario = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        final dateController = TextEditingController(text: DateTime.now().toIso8601String().substring(0, 10));
        String selectedScenario = 'CLIENT_INITIATED';
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('End Placement'),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(controller: dateController, decoration: const InputDecoration(labelText: 'Exit date (YYYY-MM-DD)')),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  initialValue: selectedScenario,
                  items: const [
                    DropdownMenuItem(value: 'CLIENT_INITIATED', child: Text('Client Initiated')),
                    DropdownMenuItem(value: 'STAFF_INITIATED', child: Text('Staff Initiated')),
                    DropdownMenuItem(value: 'RM_INITIATED', child: Text('RM Initiated')),
                  ],
                  onChanged: (v) => setDialogState(() => selectedScenario = v ?? selectedScenario),
                  decoration: const InputDecoration(labelText: 'Exit scenario'),
                ),
              ],
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop('${dateController.text.trim()}|$selectedScenario'),
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
    final result = await ref.read(rmRepositoryProvider).exitPlacement(widget.placement.id, exitDate: parts[0], exitScenarioCode: parts[1]);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffPlacementProvider(widget.staffId));
        ref.invalidate(rmPlacementsProvider(PlacementListParams(staffId: widget.staffId)));
        ref.invalidate(rmDashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Placement exited')));
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final placement = widget.placement;
    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _statusBadge(placement.status),
          const SizedBox(height: 20),
          _row('Staff ID', placement.staffId),
          _row('Client ID', placement.clientId),
          if (placement.staffSalary != null) _row('Staff salary', '₹${placement.staffSalary}'),
          if (placement.managementFee != null) _row('Management fee', '₹${placement.managementFee}'),
          if (placement.trialStartDate != null) _row('Trial start', placement.trialStartDate!),
          if (placement.trialEndDate != null) _row('Trial end', placement.trialEndDate!),
          const SizedBox(height: 24),
          if (placement.isTrial)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: RmTheme.amberWarning.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
              child: const Text('TRIAL — pending confirmation. Check-in, attendance, and invoicing are locked until confirmed.'),
            ),
          const SizedBox(height: 16),
          if (placement.isTrial)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: FilledButton(
                onPressed: _busy ? null : _confirm,
                style: FilledButton.styleFrom(backgroundColor: RmTheme.emeraldGreen),
                child: _busy
                    ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Confirm Placement'),
              ),
            )
          else if (placement.isConfirmed)
            SizedBox(
              width: double.infinity,
              height: 52,
              child: OutlinedButton(
                onPressed: _busy ? null : _exit,
                style: OutlinedButton.styleFrom(side: const BorderSide(color: RmTheme.crimsonDanger)),
                child: Text('End Placement', style: TextStyle(color: RmTheme.crimsonDanger)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _statusBadge(String status) {
    final color = status == 'CONFIRMED'
        ? RmTheme.emeraldGreen
        : status == 'TRIAL'
            ? RmTheme.amberWarning
            : RmTheme.textSecondary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(color: color.withOpacity(0.1), borderRadius: BorderRadius.circular(12), border: Border.all(color: color.withOpacity(0.3))),
      child: Text(status, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 18)),
    );
  }

  Widget _row(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: RmTheme.textSecondary)),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}
