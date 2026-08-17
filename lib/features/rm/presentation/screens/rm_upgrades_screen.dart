import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Series/role upgrade requests — read-only. No approval endpoint is
/// exposed by the backend, so none is fabricated here (§30).
class RmUpgradesScreen extends ConsumerWidget {
  const RmUpgradesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final upgradesAsync = ref.watch(rmUpgradesProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Upgrades')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmUpgradesProvider),
        child: AsyncValueWidget<List<UpgradeRequestRow>>(
          value: upgradesAsync,
          onRetry: () => ref.invalidate(rmUpgradesProvider),
          builder: (rows) {
            if (rows.isEmpty) return const Center(child: Text('No upgrade requests.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final u = rows[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.trending_up, color: RmTheme.electricBlue),
                    title: Text(u.staff?.fullName ?? u.staffId),
                    subtitle: Text('${u.fromSeries} → ${u.toSeries} · ${u.status}${u.eligibilityScore != null ? ' · Score ${u.eligibilityScore}' : ''}'),
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
