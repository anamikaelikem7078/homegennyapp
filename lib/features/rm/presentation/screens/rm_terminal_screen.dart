import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Terminal outcome staff — read-only. Swagger exposes no explicit action
/// on this list, so none is offered (per §23: don't provide unsupported
/// actions).
class RmTerminalScreen extends ConsumerWidget {
  const RmTerminalScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final terminalAsync = ref.watch(rmTerminalProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Terminal')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmTerminalProvider),
        child: AsyncValueWidget<List<StaffRow>>(
          value: terminalAsync,
          onRetry: () => ref.invalidate(rmTerminalProvider),
          builder: (rows) {
            if (rows.isEmpty) return const Center(child: Text('No terminal-outcome staff.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, index) {
                final s = rows[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: const Icon(Icons.block, color: RmTheme.crimsonDanger),
                    title: Text(s.fullName),
                    subtitle: Text('${s.staffCode} · Outcome: ${s.terminalOutcome ?? 'unspecified'}'),
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
