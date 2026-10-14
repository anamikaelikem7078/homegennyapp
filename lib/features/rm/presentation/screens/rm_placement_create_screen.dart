import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';
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
      DsSnackBar.show(context, message: 'Placement can only be created once the staff has reached S5_DEPLOY (current stage: ${staff.pipelineStage}).', type: DsSnackBarType.error);
      return;
    }
    if (_client == null) {
      DsSnackBar.show(context, message: 'Select a client first', type: DsSnackBarType.warning);
      return;
    }
    if (_confirmNow && !_confirmFieldsFilled) {
      DsSnackBar.show(context, message: _detailedWage
              ? 'Basic Wage and Management Fee % are required to confirm the placement now.'
              : 'Staff salary and management fee are required to confirm the placement now.', type: DsSnackBarType.error);
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
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));
    final staff = staffAsync.valueOrNull;
    final allowed = staff != null && _stageAllowsPlacement(staff.pipelineStage);
    final canSubmit = !_submitting && !(_confirmNow && !_confirmFieldsFilled);

    return RmStageScaffold(
      title: 'Create placement',
      stageCode: 'S5',
      stageColor: rmStageColor(PipelineStages.s5Deploy),
      bottom: !allowed
          ? null
          : canSubmit
              ? DsGradientButton(
                  label: _confirmNow ? 'Create confirmed placement' : 'Create trial placement',
                  icon: _confirmNow ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                  isLoading: _submitting,
                  gradient: _confirmNow
                      ? const LinearGradient(colors: [Color(0xFF34D399), Color(0xFF059669)])
                      : null,
                  onPressed: () => _submit(staff),
                )
              : const RmHint(text: 'Enter salary and management fee to confirm now.'),
      body: rmAsyncBody<StaffRow?>(
        staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        builder: (staff) {
          if (staff == null) {
            return const [
              RmEmptyBlock(
                icon: Icons.person_off_rounded,
                title: 'Staff not found',
                message: 'This staff record could not be loaded.',
              ),
            ];
          }
          if (!_stageAllowsPlacement(staff.pipelineStage)) {
            return [
              RmStaffBanner(staff: staff, showTracker: false),
              const SizedBox(height: 16),
              RmEmptyBlock(
                icon: Icons.lock_rounded,
                title: 'Not ready for placement',
                message: '${staff.fullName} is at ${PipelineStages.label(staff.pipelineStage)}. '
                    'Placement unlocks once they reach Deploy (S5).',
              ),
            ];
          }
          return [
            RmStaffBanner(staff: staff, showTracker: false),
            const RmSectionTitle(title: 'Client'),
            _PickCard(
              icon: Icons.business_rounded,
              title: _client?.customerName ?? 'Select client',
              subtitle: _client == null
                  ? 'Required to create a placement'
                  : 'Tap to change',
              selected: _client != null,
              onTap: _pickClient,
            ),
            const RmSectionTitle(title: 'Placement type'),
            Row(
              children: [
                Expanded(
                  child: _ModeCard(
                    icon: Icons.hourglass_top_rounded,
                    title: 'Trial',
                    subtitle: 'Try first, confirm later',
                    color: RmTheme.iconAccent,
                    selected: !_confirmNow,
                    onTap: () => setState(() => _confirmNow = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ModeCard(
                    icon: Icons.verified_rounded,
                    title: 'Confirm now',
                    subtitle: 'Skip the trial',
                    color: RmTheme.emeraldGreen,
                    selected: _confirmNow,
                    onTap: () => setState(() => _confirmNow = true),
                  ),
                ),
              ],
            ),
            RmSectionTitle(
              title: 'Wages',
              trailing: _Toggle(
                left: 'Simple',
                right: 'Detailed',
                value: _detailedWage,
                onChanged: (v) => setState(() => _detailedWage = v),
              ),
            ),
            if (_detailedWage)
              RmWageConfigForm(onConfigChanged: (config) => setState(() => _wageConfig = config))
            else ...[
              _MoneyField(
                label: 'Staff salary (monthly)',
                required: _confirmNow,
                controller: _salaryController,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 14),
              _MoneyField(
                label: 'Management fee (monthly)',
                required: _confirmNow,
                controller: _feeController,
                onChanged: () => setState(() {}),
              ),
            ],
            const SizedBox(height: 16),
            RmNote(
              tone: _confirmNow ? RmNoteTone.success : RmNoteTone.warning,
              title: _confirmNow ? 'Confirmed placement' : 'Trial placement',
              text: _confirmNow
                  ? 'Created already confirmed — no trial period. Salary and fee are required.'
                  : 'Confirmation is a separate step afterward. Trial dates default to today → +14 days.',
            ),
          ];
        },
      ),
    );
  }
}

class _PickCard extends StatelessWidget {
  const _PickCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: selected ? RmTheme.electricBlue.withValues(alpha: 0.4) : RmTheme.borderSubtle,
              width: selected ? 1.5 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, color: RmTheme.iconAccent),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                selected ? Icons.check_circle_rounded : Icons.chevron_right_rounded,
                color: selected ? RmTheme.emeraldGreen : RmTheme.electricBlue,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ModeCard extends StatelessWidget {
  const _ModeCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.selectionClick();
        onTap();
      },
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(22),
          border: Border.all(
            color: selected ? color : RmTheme.borderSubtle,
            width: selected ? 1.8 : 1,
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: color.withValues(alpha: 0.18),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ]
              : RmTheme.subtleShadow,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 38,
                  height: 38,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.14),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, size: 20, color: color),
                ),
                const Spacer(),
                AnimatedScale(
                  scale: selected ? 1 : 0,
                  duration: 250.ms,
                  curve: Curves.elasticOut,
                  child: Icon(Icons.check_circle_rounded, color: color, size: 22),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: RmTheme.textPrimary,
              ),
            ),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Toggle extends StatelessWidget {
  const _Toggle({
    required this.left,
    required this.right,
    required this.value,
    required this.onChanged,
  });

  final String left;
  final String right;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    Widget seg(String label, bool v) {
      final on = value == v;
      return GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onChanged(v);
        },
        child: AnimatedContainer(
          duration: 200.ms,
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: on ? RmTheme.electricBlue : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: on ? Colors.white : RmTheme.textSecondary,
            ),
          ),
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.all(3),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RmTheme.borderSubtle),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [seg(left, false), seg(right, true)],
      ),
    );
  }
}

class _MoneyField extends StatelessWidget {
  const _MoneyField({
    required this.label,
    required this.required,
    required this.controller,
    required this.onChanged,
  });

  final String label;
  final bool required;
  final TextEditingController controller;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: RmTheme.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            RmStatusPill(
              label: required ? 'Required' : 'Optional',
              color: required ? RmTheme.crimsonDanger : RmTheme.electricBlue,
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          onChanged: (_) => onChanged(),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: RmTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: '0',
            fillColor: Colors.white,
            prefixIcon: Padding(
              padding: const EdgeInsets.only(left: 16, right: 8),
              child: Text(
                '₹',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.iconAccent,
                ),
              ),
            ),
            prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
            suffixText: '/ month',
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: RmTheme.borderSubtle),
            ),
          ),
        ),
      ],
    );
  }
}
