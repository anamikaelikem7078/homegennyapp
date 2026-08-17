import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';

/// `GET /rm/trials` returns raw Placement rows with no staff/client name
/// embedded — this screen cross-references the kanban's staff list (already
/// fetched) for display names rather than adding another round trip.
class RmTrialsScreen extends ConsumerWidget {
  const RmTrialsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final trialsAsync = ref.watch(rmTrialsProvider);
    final kanbanAsync = ref.watch(rmKanbanProvider(const KanbanParams()));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Trials')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmTrialsProvider),
        child: AsyncValueWidget<List<TrialRow>>(
          value: trialsAsync,
          onRetry: () => ref.invalidate(rmTrialsProvider),
          builder: (trials) {
            if (trials.isEmpty) return const Center(child: Text('No active trial placements.'));
            final kanban = kanbanAsync.valueOrNull;
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: trials.length,
              itemBuilder: (context, index) {
                final t = trials[index];
                final staff = kanban?.findById(t.staffId);
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.play_circle_outline, color: RmTheme.amberWarning),
                    title: Text(staff?.fullName ?? t.staffId),
                    subtitle: Text('Trial: ${t.trialStartDate ?? '?'} → ${t.trialEndDate ?? '?'}'),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => context.push(RmRoutes.placementDetail(t.id), extra: t.staffId),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}
