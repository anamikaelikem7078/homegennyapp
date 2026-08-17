import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';

/// Placement creation — only reachable/enabled for staff at `S5_DEPLOY`.
/// The backend itself does **not** enforce this stage restriction on
/// `POST /placements` (verified — it accepts any staff at any stage), so
/// this is a client-side gate (Rule 2). `POST /placements` always creates a
/// `TRIAL` placement, never `CONFIRMED` — the UI must not imply otherwise
/// (Rule 3).
class RmPlacementCreateScreen extends ConsumerStatefulWidget {
  const RmPlacementCreateScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmPlacementCreateScreen> createState() => _RmPlacementCreateScreenState();
}

class _RmPlacementCreateScreenState extends ConsumerState<RmPlacementCreateScreen> {
  FinanceCustomer? _client;
  final _salaryController = TextEditingController();
  final _feeController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _salaryController.dispose();
    _feeController.dispose();
    super.dispose();
  }

  Future<void> _pickClient() async {
    final selected = await context.push<FinanceCustomer>(RmRoutes.stage4A2Client(widget.staffId));
    if (selected != null) setState(() => _client = selected);
  }

  Future<void> _submit(StaffRow staff) async {
    if (staff.pipelineStage != PipelineStages.s5Deploy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only staff at S5_DEPLOY can be placed.'), backgroundColor: RmTheme.crimsonDanger),
      );
      return;
    }
    if (_client == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a client first')));
      return;
    }

    setState(() => _submitting = true);
    final body = <String, dynamic>{
      // staff_id is StaffApplicant.id (the kanban row id), never User.id.
      'staff_id': staff.id,
      // client_id is FinanceCustomer.id, never the client's login user.id.
      'client_id': _client!.id,
      if (_salaryController.text.trim().isNotEmpty) 'staff_salary': num.tryParse(_salaryController.text.trim()),
      if (_feeController.text.trim().isNotEmpty) 'management_fee': num.tryParse(_feeController.text.trim()),
    };

    final result = await ref.read(rmRepositoryProvider).createPlacement(body);
    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      onSuccess: (placement) {
        ref.invalidate(staffPlacementProvider(staff.id));
        ref.invalidate(rmPlacementsProvider(PlacementListParams(staffId: staff.id)));
        ref.invalidate(rmDashboardProvider);
        context.pushReplacement(RmRoutes.placementDetail(placement.id), extra: staff.id);
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Create Placement')),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        builder: (staff) {
          if (staff == null) return const Center(child: Text('Staff not found'));
          if (staff.pipelineStage != PipelineStages.s5Deploy) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${staff.fullName} is at ${PipelineStages.label(staff.pipelineStage)} — placement is only available at S5_DEPLOY.'),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName, style: RmTheme.headline(context).copyWith(fontSize: 22)),
                Text('${staff.staffCode} · Staff ID: ${staff.id}', style: RmTheme.body(context).copyWith(fontSize: 12)),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.business_outlined),
                    title: Text(_client?.customerName ?? 'Select client'),
                    subtitle: _client != null ? Text('FinanceCustomer ID: ${_client!.id}') : null,
                    trailing: const Icon(Icons.chevron_right),
                    onTap: _pickClient,
                  ),
                ),
                const SizedBox(height: 20),
                TextField(
                  controller: _salaryController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Staff salary (monthly)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _feeController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Management fee (monthly)', border: OutlineInputBorder()),
                ),
                const SizedBox(height: 8),
                Text('Trial dates default to today → +14 days if left blank.', style: RmTheme.body(context).copyWith(fontSize: 12)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: RmTheme.amberWarning.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                  child: const Text('This creates a TRIAL placement, not a confirmed one. Confirmation is a separate, explicit step afterward.'),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting ? null : () => _submit(staff),
                    style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Create Placement (TRIAL)'),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
