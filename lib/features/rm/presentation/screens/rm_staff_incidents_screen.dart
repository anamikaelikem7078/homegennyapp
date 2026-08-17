import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Incidents filtered to one staff member — `GET /rm/incidents` has no
/// `staff_id` filter, so this filters the full list client-side.
class RmStaffIncidentsScreen extends ConsumerWidget {
  const RmStaffIncidentsScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(rmIncidentsProvider(null));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Staff Incidents')),
      body: AsyncValueWidget<List<IncidentRow>>(
        value: incidentsAsync,
        onRetry: () => ref.invalidate(rmIncidentsProvider(null)),
        builder: (all) {
          final mine = all.where((i) => i.staffId == staffId).toList();
          if (mine.isEmpty) return const Center(child: Text('No incidents for this staff member.'));
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: mine.length,
            itemBuilder: (context, index) {
              final i = mine[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: const Icon(Icons.report_problem_outlined, color: RmTheme.crimsonDanger),
                  title: Text(i.title),
                  subtitle: Text('${IncidentTypes.label(i.type)} · ${i.status}'),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
