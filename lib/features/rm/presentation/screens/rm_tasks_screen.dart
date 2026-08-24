import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

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
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: Text(
          'Shift Review',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // ── Horizontal Filter Chips ──
          _buildFilterChips(),

          // ── Shift Logs list ──
          Expanded(
            child: RefreshIndicator(
              color: RmTheme.electricBlue,
              onRefresh: () async =>
                  ref.invalidate(rmShiftsProvider(_statusFilter)),
              child: AsyncValueWidget<List<ShiftLogRow>>(
                value: shiftsAsync,
                onRetry: () => ref.invalidate(rmShiftsProvider(_statusFilter)),
                builder: (shifts) {
                  if (shifts.isEmpty) {
                    return Center(
                      child: Text(
                        'No shift logs in this filter.',
                        style: GoogleFonts.inter(
                          color: RmTheme.textSecondary,
                          fontSize: 14,
                        ),
                      ),
                    );
                  }
                  return ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    itemCount: shifts.length,
                    itemBuilder: (context, index) => _ShiftCard(
                      shift: shifts[index],
                      filter: _statusFilter,
                      index: index,
                    ),
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
    const filters = {
      'Pending': 'PENDING',
      'Approved': 'APPROVED',
      'Rejected': 'REJECTED',
      'Flagged': 'FLAGGED',
      'All': null
    };

    return Container(
      color: RmTheme.offWhite,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 20),
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
                backgroundColor: RmTheme.cardSurface,
                side: BorderSide(
                  color: isActive
                      ? RmTheme.electricBlue
                      : RmTheme.borderSubtle.withValues(alpha: 0.5),
                  width: 1.2,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                labelStyle: GoogleFonts.inter(
                  color: isActive ? Colors.white : RmTheme.textSecondary,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _ShiftCard extends ConsumerStatefulWidget {
  const _ShiftCard({
    required this.shift,
    required this.filter,
    required this.index,
  });
  final ShiftLogRow shift;
  final String? filter;
  final int index;

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
            title: Text(
              '${action[0]}${action.substring(1).toLowerCase()} shift',
              style: RmTheme.title(dialogContext),
            ),
            content: TextField(
              controller: controller,
              decoration: const InputDecoration(hintText: 'Notes (optional)'),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () =>
                    Navigator.of(dialogContext).pop(controller.text.trim()),
                child: const Text('Confirm'),
              ),
            ],
          );
        },
      );
      if (notes == null) return;
    }

    setState(() => _busy = true);
    final result = await ref.read(rmRepositoryProvider).reviewShift(
          widget.shift.id,
          action,
          notes: notes?.isEmpty ?? true ? null : notes,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmShiftsProvider(widget.filter));
        ref.invalidate(rmDashboardProvider);
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
    final shift = widget.shift;
    final staffName = shift.staff?.fullName ?? shift.staffId;
    final firstLetter = staffName.isNotEmpty ? staffName[0].toUpperCase() : '?';

    // Status styling colors
    Color statusColor = RmTheme.textSecondary;
    if (shift.status == 'APPROVED') statusColor = RmTheme.emeraldGreen;
    if (shift.status == 'REJECTED') statusColor = RmTheme.crimsonDanger;
    if (shift.status == 'FLAGGED') statusColor = RmTheme.amberWarning;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
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
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Profile and Status row ──
            Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: RmTheme.electricBlue.withValues(alpha: 0.08),
                  child: Text(
                    firstLetter,
                    style: GoogleFonts.inter(
                      color: RmTheme.electricBlue,
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        staffName,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          fontSize: 15,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${shift.staff?.staffCode ?? "rohan001"} • ${shift.shiftDate}',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: RmTheme.textSecondary,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                // Status Badge
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: statusColor.withValues(alpha: 0.2),
                      width: 1,
                    ),
                  ),
                  child: Text(
                    shift.status.toUpperCase(),
                    style: GoogleFonts.inter(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: statusColor,
                      letterSpacing: 0.2,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            // ── Check-in / out Time Details ──
            if (shift.checkInAt != null)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: RmTheme.offWhite,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.schedule_rounded,
                      color: RmTheme.textSecondary,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'In: ${shift.checkInAt}   Out: ${shift.checkOutAt ?? "—"}',
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

            // ── Actions Block if Pending ──
            if (shift.status == 'PENDING') ...[
              const SizedBox(height: 16),
              Row(
                children: [
                  // APPROVE Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: FilledButton(
                        onPressed: _busy ? null : () => _review('APPROVED'),
                        style: FilledButton.styleFrom(
                          backgroundColor: RmTheme.emeraldGreen,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Approve',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // FLAG Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _review('FLAGGED'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: RmTheme.amberWarning.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Flag',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: RmTheme.amberWarning,
                          ),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),

                  // REJECT Button
                  Expanded(
                    child: SizedBox(
                      height: 38,
                      child: OutlinedButton(
                        onPressed: _busy ? null : () => _review('REJECTED'),
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: RmTheme.crimsonDanger.withValues(alpha: 0.8),
                            width: 1.2,
                          ),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          padding: EdgeInsets.zero,
                        ),
                        child: Text(
                          'Reject',
                          style: GoogleFonts.inter(
                            fontWeight: FontWeight.bold,
                            fontSize: 13,
                            color: RmTheme.crimsonDanger,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    )
        .animate()
        .fadeIn(
          delay: Duration(milliseconds: 60 * widget.index),
          duration: 400.ms,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          delay: Duration(milliseconds: 60 * widget.index),
          duration: 400.ms,
        );
  }
}
