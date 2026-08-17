import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';

/// S3 Training. No dedicated RM-facing training-completion endpoint exists
/// on the backend (verified against live Swagger — see the plan's
/// "Architecture decisions #6"), so this screen does not fabricate a
/// completion status. Advancing to S4 requires an explicit RM attestation
/// checkbox rather than a fake automated "complete" signal. Video
/// certification — the one part of this stage with real backend support —
/// is linked out to its own read-only monitoring screen.
class RmStage3TrainingScreen extends ConsumerStatefulWidget {
  const RmStage3TrainingScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmStage3TrainingScreen> createState() => _RmStage3TrainingScreenState();
}

class _RmStage3TrainingScreenState extends ConsumerState<RmStage3TrainingScreen> {
  bool _attested = false;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Training (S3)')),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        builder: (staff) {
          if (staff == null) return const Center(child: Text('Staff not found'));
          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(staff.fullName, style: RmTheme.headline(context).copyWith(fontSize: 22)),
                Text('${staff.staffCode} · ${staff.series}', style: RmTheme.body(context)),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RmTheme.amberWarning.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RmTheme.amberWarning.withOpacity(0.3)),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.info_outline, color: RmTheme.amberWarning),
                      SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          'No training-completion API exists on the backend yet. Video certification is the only '
                          'part of this stage with real backend support — check it, then attest completion below.',
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Card(
                  child: ListTile(
                    leading: const Icon(Icons.videocam_outlined, color: RmTheme.electricBlue),
                    title: const Text('Video certification'),
                    subtitle: const Text('View submitted prompts and trainer review status'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RmRoutes.stage3VideoReview(staff.id)),
                  ),
                ),
                const SizedBox(height: 24),
                CheckboxListTile(
                  value: _attested,
                  onChanged: (v) => setState(() => _attested = v ?? false),
                  controlAffinity: ListTileControlAffinity.leading,
                  title: const Text('I attest this staff member\'s training requirements are complete'),
                  subtitle: const Text('Manual RM sign-off — the backend has no automated completion check for this stage.'),
                ),
                const SizedBox(height: 12),
                AdvanceStageButton(
                  staffId: staff.id,
                  fromStage: staff.pipelineStage,
                  toStage: PipelineStages.s4Agreements,
                  label: 'Advance to Agreements (S4)',
                  reasonCode: 'TRAINING_ATTESTED',
                  enabled: _attested,
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
