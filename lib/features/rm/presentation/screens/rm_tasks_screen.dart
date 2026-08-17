import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

/// Shift Review — repurposed from the former "Tasks" tab, which had no
/// backend equivalent of its own (hardcoded mock task list). Shift review
/// (`GET /rm/shifts`, `PATCH /rm/shifts/:id/review`) is a real, required RM
/// module that needed a home; this reuses the existing bottom-nav slot.
class RmTasksScreen extends ConsumerStatefulWidget {
  const RmTasksScreen({super.key});

  @override
  ConsumerState<RmTasksScreen> createState() => _RmTasksScreenState();
}

class _RmTasksScreenState extends ConsumerState<RmTasksScreen> {
  String? _statusFilter = 'PENDING';

  @override
  Widget build(BuildContext context) {
    final shiftsAsync = ref.watch(rmShiftsProvider(_statusFilter));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.cardSurface, elevation: 0, title: const Text('Shift Review')),
      body: Column(
        children: [
          _buildFilterChips(),
          Expanded(
            child: RefreshIndicator(
              onRefresh: () async => ref.invalidate(rmShiftsProvider(_statusFilter)),
              child: AsyncValueWidget<List<ShiftLogRow>>(
                value: shiftsAsync,
                onRetry: () => ref.invalidate(rmShiftsProvider(_statusFilter)),
                builder: (shifts) {
                  if (shifts.isEmpty) return const Center(child: Text('No shift logs in this filter.'));
                  return ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: shifts.length,
                    itemBuilder: (context, index) => _ShiftCard(shift: shifts[index], filter: _statusFilter),
                  );
                },
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 2),
    );
  }

  Widget _buildFilterChips() {
    const filters = {'Pending': 'PENDING', 'Approved': 'APPROVED', 'Rejected': 'REJECTED', 'Flagged': 'FLAGGED', 'All': null};
    return Container(
      color: RmTheme.cardSurface,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Row(
          children: filters.entries.map((entry) {
            final isActive = _statusFilter == entry.value;
            return Padding(
              padding: const EdgeInsets.only(right: 8),
              child: ChoiceChip(
                label: Text(entry.key),
                selected: isActive,
                onSelected: (_) => setState(() => _statusFilter = entry.value),
                selectedColor: RmTheme.electricBlue,
                labelStyle: TextStyle(color: isActive ? Colors.white : RmTheme.textSecondary),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ShiftCard extends ConsumerStatefulWidget {
  const _ShiftCard({required this.shift, required this.filter});
  final ShiftLogRow shift;
  final String? filter;

  @override
  ConsumerState<_ShiftCard> createState() => _ShiftCardState();
}

class _ShiftCardState extends ConsumerState<_ShiftCard> {
  bool _busy = false;

  Future<void> _review(String action) async {
    String? notes;
    if (action == 'FLAGGED' || action == 'REJECTED') {
      notes = await showDialog<String>(
        context: context,
        builder: (dialogContext) {
          final controller = TextEditingController();
          return AlertDialog(
            title: Text('${action[0]}${action.substring(1).toLowerCase()} shift'),
            content: TextField(controller: controller, decoration: const InputDecoration(hintText: 'Notes (optional)')),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: const Text('Confirm')),
            ],
          );
        },
      );
      if (notes == null) return;
    }

    setState(() => _busy = true);
    final result = await ref.read(rmRepositoryProvider).reviewShift(widget.shift.id, action, notes: notes?.isEmpty ?? true ? null : notes);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmShiftsProvider(widget.filter));
        ref.invalidate(rmDashboardProvider);
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final shift = widget.shift;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(shift.staff?.fullName ?? shift.staffId, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${shift.staff?.staffCode ?? ''} · ${shift.shiftDate}', style: RmTheme.body(context).copyWith(fontSize: 12)),
            if (shift.checkInAt != null) Text('In: ${shift.checkInAt}  Out: ${shift.checkOutAt ?? '—'}', style: RmTheme.body(context).copyWith(fontSize: 12)),
            const SizedBox(height: 8),
            Text('Status: ${shift.status}', style: const TextStyle(fontWeight: FontWeight.w600)),
            if (shift.status == 'PENDING') ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: FilledButton(
                      onPressed: _busy ? null : () => _review('APPROVED'),
                      style: FilledButton.styleFrom(backgroundColor: RmTheme.emeraldGreen),
                      child: const Text('Approve'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _review('FLAGGED'),
                      child: const Text('Flag'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      onPressed: _busy ? null : () => _review('REJECTED'),
                      style: OutlinedButton.styleFrom(side: BorderSide(color: RmTheme.crimsonDanger)),
                      child: Text('Reject', style: TextStyle(color: RmTheme.crimsonDanger)),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }
}
