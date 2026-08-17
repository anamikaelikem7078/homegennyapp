import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/presentation/async_value_widget.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// S2 Verification hub. The 5 individual track screens (Aadhaar/DL/eChallan/
/// police-verification/medical) are deliberately deferred for this pass —
/// the RM asked to skip wiring the 3rd-party-backed verification flows for
/// now and continue with the rest of the pipeline. This screen still shows
/// real staff data and the real, newly-deployed `GET /verification/:staffId`
/// status read-back so it's not a dead end — it's just not yet offering the
/// individual check actions.
class RmVerificationDashboardScreen extends ConsumerWidget {
  const RmVerificationDashboardScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final statusAsync = ref.watch(rmVerificationStatusProvider(staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: const Text('Verification (S2)'),
      ),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(staffId)),
        builder: (staff) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(staff?.fullName ?? staffId, style: RmTheme.headline(context).copyWith(fontSize: 22)),
              Text(staff?.staffCode ?? '', style: RmTheme.body(context)),
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
                        'The individual Aadhaar/DL/eChallan/police-verification/medical check actions are deferred for '
                        'this integration pass. This section reads real status from GET /verification/:staffId only.',
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),
              Text('Track status', style: RmTheme.title(context)),
              const SizedBox(height: 12),
              statusAsync.when(
                loading: () => const LinearProgressIndicator(),
                error: (_, __) => const Text('Could not load verification status.'),
                data: (status) {
                  if (status.isEmpty) {
                    return const Text('No verification tracks recorded yet.');
                  }
                  return Column(
                    children: [
                      for (final entry in status.entries)
                        Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(entry.key),
                              Text(entry.value, style: const TextStyle(fontWeight: FontWeight.w600)),
                            ],
                          ),
                        ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 12),
              if (staff?.pvStatus != null)
                Text('Police verification (from staff record): ${staff!.pvStatus}', style: RmTheme.body(context)),
              const SizedBox(height: 32),
              OutlinedButton(onPressed: () => context.pop(), child: const Text('Back')),
            ],
          ),
        ),
      ),
    );
  }
}
