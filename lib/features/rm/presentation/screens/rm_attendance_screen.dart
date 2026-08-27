import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';

/// `GET`/`PUT /rm/attendance` requires a `branchId` — this screen picks a
/// branch (from `GET /rm/locations`) plus month/year, then shows the real
/// per-staff attendance grid for confirmed placements in that branch.
class RmAttendanceScreen extends ConsumerStatefulWidget {
  const RmAttendanceScreen({super.key});

  @override
  ConsumerState<RmAttendanceScreen> createState() => _RmAttendanceScreenState();
}

class _RmAttendanceScreenState extends ConsumerState<RmAttendanceScreen> {
  String? _branchId;
  DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);

  @override
  Widget build(BuildContext context) {
    final locationsAsync = ref.watch(rmLocationsProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Attendance')),
      body: AsyncValueWidget<LocationsData>(
        value: locationsAsync,
        onRetry: () => ref.invalidate(rmLocationsProvider),
        builder: (locations) {
          _branchId ??= locations.branches.isNotEmpty ? locations.branches.first.id : null;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        initialValue: _branchId,
                        isExpanded: true,
                        items: [
                          for (final b in locations.branches)
                            DropdownMenuItem(
                              value: b.id,
                              child: Text(b.name, overflow: TextOverflow.ellipsis),
                            ),
                        ],
                        onChanged: (v) => setState(() => _branchId = v),
                        decoration: const InputDecoration(labelText: 'Branch', border: OutlineInputBorder(), isDense: true),
                      ),
                    ),
                    const SizedBox(width: 12),
                    IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
                    Text('${_month.month}/${_month.year}'),
                    IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
                  ],
                ),
              ),
              Expanded(
                child: _branchId == null
                    ? const Center(child: Text('No branches available.'))
                    : _AttendanceGrid(branchId: _branchId!, month: _month.month, year: _month.year),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _AttendanceGrid extends ConsumerWidget {
  const _AttendanceGrid({required this.branchId, required this.month, required this.year});
  final String branchId;
  final int month;
  final int year;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final params = AttendanceParams(branchId: branchId, month: month, year: year);
    final attendanceAsync = ref.watch(rmAttendanceProvider(params));

    return RefreshIndicator(
      onRefresh: () async => ref.invalidate(rmAttendanceProvider(params)),
      child: AsyncValueWidget<AttendanceMonthResult>(
        value: attendanceAsync,
        onRetry: () => ref.invalidate(rmAttendanceProvider(params)),
        builder: (data) {
          if (data.staff.isEmpty) {
            return const Center(child: Text('No confirmed placements in this branch for this period.'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: data.staff.length,
            itemBuilder: (context, index) => _StaffAttendanceCard(row: data.staff[index], branchId: branchId, month: month, year: year),
          );
        },
      ),
    );
  }
}

class _StaffAttendanceCard extends ConsumerStatefulWidget {
  const _StaffAttendanceCard({required this.row, required this.branchId, required this.month, required this.year});
  final StaffAttendanceRow row;
  final String branchId;
  final int month;
  final int year;

  @override
  ConsumerState<_StaffAttendanceCard> createState() => _StaffAttendanceCardState();
}

class _StaffAttendanceCardState extends ConsumerState<_StaffAttendanceCard> {
  bool _busy = false;

  Future<void> _markToday(String status) async {
    setState(() => _busy = true);
    final today = DateTime.now().toIso8601String().substring(0, 10);
    final result = await ref.read(rmRepositoryProvider).markAttendance(
          staffId: widget.row.staffId,
          date: today,
          status: status,
          branchId: widget.branchId,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) => ref.invalidate(rmAttendanceProvider(AttendanceParams(branchId: widget.branchId, month: widget.month, year: widget.year))),
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.fullName, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(row.staffCode, style: RmTheme.body(context).copyWith(fontSize: 12)),
                    ],
                  ),
                ),
                TextButton(
                  onPressed: () => context.push(RmRoutes.staffInvoicePreview(row.staffId)),
                  child: const Text('Invoice'),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text('Present ${row.presentDays} · Absent ${row.absentDays} · Leave ${row.leaveDays} · OT ${row.overtimeDays} · Billable ${row.billableDays}/${row.daysInMonth}'),
            Text('Prorated gross: ₹${row.proratedGross}', style: const TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 12),
            Wrap(
              spacing: 8,
              children: [
                for (final s in AttendanceStatuses.all)
                  OutlinedButton(
                    onPressed: _busy ? null : () => _markToday(s),
                    child: Text('Mark today: $s'),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
