import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

/// Incidents filtered to one staff member — `GET /rm/incidents` has no
/// `staff_id` filter, so this filters the full list client-side.
class RmStaffIncidentsScreen extends ConsumerWidget {
  const RmStaffIncidentsScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(rmIncidentsProvider(null));
    final staff = ref.watch(staffByIdProvider(staffId)).valueOrNull;

    return RmStageScaffold(
      title: 'Incidents',
      stageColor: RmTheme.crimsonDanger,
      onRefresh: () async => ref.invalidate(rmIncidentsProvider(null)),
      body: rmAsyncBody<List<IncidentRow>>(
        incidentsAsync,
        onRetry: () => ref.invalidate(rmIncidentsProvider(null)),
        builder: (all) {
          final mine = all.where((i) => i.staffId == staffId).toList();
          return [
            if (staff != null) RmStaffBanner(staff: staff, showTracker: false),
            RmSectionTitle(
              title: 'Logged incidents',
              trailing: RmStatusPill(
                label: '${mine.length}',
                color: mine.isEmpty ? RmTheme.emeraldGreen : RmTheme.crimsonDanger,
              ),
            ),
            if (mine.isEmpty)
              const RmEmptyBlock(
                icon: Icons.verified_user_rounded,
                color: RmTheme.emeraldGreen,
                title: 'All clear',
                message: 'No incidents have been logged for this staff member.',
              )
            else
              for (final i in mine)
                RmStepTile(
                  icon: Icons.report_rounded,
                  title: i.title.isEmpty
                      ? IncidentTypes.label(i.type)
                      : i.title[0].toUpperCase() + i.title.substring(1),
                  subtitle: [
                    IncidentTypes.label(i.type),
                    if (i.description?.trim().isNotEmpty ?? false) i.description!.trim(),
                  ].join(' · '),
                  state: _isOpen(i.status) ? RmStepState.failed : RmStepState.done,
                  statusLabel: rmTitleCase(i.status),
                ),
          ];
        },
      ),
    );
  }

  bool _isOpen(String s) {
    final u = s.toUpperCase();
    return !(u == 'RESOLVED' || u == 'CLOSED' || u == 'DISMISSED');
  }
}
