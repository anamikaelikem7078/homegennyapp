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
import '../widgets/rm_wage_config_form.dart';

/// Placement creation — only reachable once a staff member is at
/// S5_DEPLOY. The backend now hard-gates `POST /placements` on
/// `pipeline_stage === 'S5_DEPLOY'` (400 otherwise, naming the current
/// stage), so the client-side check below is a pre-flight UX nicety, not
/// the source of truth — the 400 is still handled as a safety net for a
/// stale cached staff object.
///
/// The RM chooses **Trial** (default — unchanged behavior, salary/fee
/// optional) or **Confirm Now** (`status: "CONFIRMED"`, which skips the
/// trial step entirely; the backend then requires `staff_salary` and
/// `management_fee` in the same request, so both fields become mandatory
/// in that mode).
class RmPlacementCreateScreen extends ConsumerStatefulWidget {
  const RmPlacementCreateScreen({super.key, required this.staffId, this.initialClient});
  final String staffId;
  /// Pre-fills the client picker — set when navigated from the S4 hub,
  /// which already had the RM pick a client for the agreement instruments.
  final FinanceCustomer? initialClient;

  @override
  ConsumerState<RmPlacementCreateScreen> createState() => _RmPlacementCreateScreenState();
}

class _RmPlacementCreateScreenState extends ConsumerState<RmPlacementCreateScreen> {
  FinanceCustomer? _client;
  final _salaryController = TextEditingController();
  final _feeController = TextEditingController();
  bool _submitting = false;
  bool _confirmNow = false;
  bool _detailedWage = false;
  WageConfig? _wageConfig;

  @override
  void initState() {
    super.initState();
    _client = widget.initialClient;
  }

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

  bool _stageAllowsPlacement(String stage) => stage == PipelineStages.s5Deploy;

  bool get _confirmFieldsFilled => _detailedWage
      ? (_wageConfig != null && _wageConfig!.basicWage > 0 && _wageConfig!.managementPct > 0)
      : (_salaryController.text.trim().isNotEmpty && _feeController.text.trim().isNotEmpty);

  Future<void> _submit(StaffRow staff) async {
    if (!_stageAllowsPlacement(staff.pipelineStage)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Placement can only be created once the staff has reached S5_DEPLOY (current stage: ${staff.pipelineStage}).'), backgroundColor: RmTheme.crimsonDanger),
      );
      return;
    }
    if (_client == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Select a client first')));
      return;
    }
    if (_confirmNow && !_confirmFieldsFilled) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_detailedWage
              ? 'Basic Wage and Management Fee % are required to confirm the placement now.'
              : 'Staff salary and management fee are required to confirm the placement now.'),
          backgroundColor: RmTheme.crimsonDanger,
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    final body = <String, dynamic>{
      // staff_id is StaffApplicant.id (the kanban row id), never User.id.
      'staff_id': staff.id,
      // client_id is FinanceCustomer.id, never the client's login user.id.
      'client_id': _client!.id,
      if (_confirmNow) 'status': 'CONFIRMED',
      if (_detailedWage && _wageConfig != null)
        'wage_config': _wageConfig!.toJson()
      else ...{
        if (_salaryController.text.trim().isNotEmpty) 'staff_salary': num.tryParse(_salaryController.text.trim()),
        if (_feeController.text.trim().isNotEmpty) 'management_fee': num.tryParse(_feeController.text.trim()),
      },
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
          if (!_stageAllowsPlacement(staff.pipelineStage)) {
            return Padding(
              padding: const EdgeInsets.all(24),
              child: Text('${staff.fullName} is at ${PipelineStages.label(staff.pipelineStage)} — placement is only available once the staff reaches S5_DEPLOY.'),
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
                SegmentedButton<bool>(
                  segments: const [
                    ButtonSegment(value: false, label: Text('Trial'), icon: Icon(Icons.hourglass_empty_rounded)),
                    ButtonSegment(value: true, label: Text('Confirm Now'), icon: Icon(Icons.verified_rounded)),
                  ],
                  selected: {_confirmNow},
                  onSelectionChanged: (selection) => setState(() => _confirmNow = selection.first),
                ),
                const SizedBox(height: 20),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Wage entry', style: RmTheme.headline(context).copyWith(fontSize: 15)),
                    SegmentedButton<bool>(
                      segments: const [
                        ButtonSegment(value: false, label: Text('Simple')),
                        ButtonSegment(value: true, label: Text('Detailed')),
                      ],
                      selected: {_detailedWage},
                      onSelectionChanged: (s) => setState(() => _detailedWage = s.first),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (_detailedWage)
                  RmWageConfigForm(onConfigChanged: (config) => setState(() => _wageConfig = config))
                else ...[
                  TextField(
                    controller: _salaryController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _confirmNow ? 'Staff salary (monthly) *' : 'Staff salary (monthly)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _feeController,
                    keyboardType: TextInputType.number,
                    onChanged: (_) => setState(() {}),
                    decoration: InputDecoration(
                      labelText: _confirmNow ? 'Management fee (monthly) *' : 'Management fee (monthly)',
                      border: const OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (!_confirmNow)
                    Text('Trial dates default to today → +14 days if left blank.', style: RmTheme.body(context).copyWith(fontSize: 12)),
                ],
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: (_confirmNow ? RmTheme.emeraldGreen : RmTheme.amberWarning).withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    _confirmNow
                        ? 'This creates the placement already CONFIRMED — no trial period. Salary and management fee are required.'
                        : 'This creates a TRIAL placement, not a confirmed one. Confirmation is a separate, explicit step afterward.',
                  ),
                ),
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _submitting || (_confirmNow && !_confirmFieldsFilled) ? null : () => _submit(staff),
                    style: FilledButton.styleFrom(backgroundColor: _confirmNow ? RmTheme.emeraldGreen : RmTheme.electricBlue),
                    child: _submitting
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : Text(_confirmNow ? 'Create Placement (Confirmed)' : 'Create Placement (TRIAL)'),
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
