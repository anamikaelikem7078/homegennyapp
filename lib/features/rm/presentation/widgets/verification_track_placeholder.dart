import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../providers/rm_providers.dart';

/// Shared placeholder for the 5 verification-track screens, which are
/// deliberately deferred for this integration pass. Honest about being
/// unwired rather than faking a result — never marks a track "complete".
class VerificationTrackPlaceholder extends ConsumerWidget {
  const VerificationTrackPlaceholder({
    super.key,
    required this.title,
    required this.staffId,
    required this.onBack,
  });

  final String title;
  final String staffId;
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final staffName = staffAsync.maybeWhen(data: (s) => s?.fullName, orElse: () => null);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: Text(title)),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.construction_outlined, size: 48, color: RmTheme.textSecondary),
            const SizedBox(height: 16),
            Text('$title — deferred', style: RmTheme.headline(context).copyWith(fontSize: 22)),
            const SizedBox(height: 8),
            Text(
              'This individual verification track for ${staffName ?? staffId} is not wired up in this pass. '
              'Use the Verification hub for the tracks that are already live.',
              style: RmTheme.body(context),
            ),
            const SizedBox(height: 24),
            OutlinedButton(onPressed: onBack, child: const Text('Back')),
          ],
        ),
      ),
    );
  }
}
