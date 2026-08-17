import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

class RmDeferredScreen extends ConsumerWidget {
  const RmDeferredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deferredAsync = ref.watch(rmDeferredProvider);

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: const Text('Deferred')),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmDeferredProvider),
        child: AsyncValueWidget<List<DeferredRow>>(
          value: deferredAsync,
          onRetry: () => ref.invalidate(rmDeferredProvider),
          builder: (rows) {
            if (rows.isEmpty) return const Center(child: Text('No deferred cases.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rows.length,
              itemBuilder: (context, index) => _DeferredCard(row: rows[index]),
            );
          },
        ),
      ),
    );
  }
}

class _DeferredCard extends ConsumerStatefulWidget {
  const _DeferredCard({required this.row});
  final DeferredRow row;

  @override
  ConsumerState<_DeferredCard> createState() => _DeferredCardState();
}

class _DeferredCardState extends ConsumerState<_DeferredCard> {
  bool _busy = false;

  Future<void> _resume() async {
    final toStage = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        String selected = widget.row.resumeStage ?? PipelineStages.s1Intake;
        return StatefulBuilder(
          builder: (context, setDialogState) => AlertDialog(
            title: const Text('Resume to stage'),
            content: DropdownButtonFormField<String>(
              initialValue: selected,
              items: [for (final s in PipelineStages.order) DropdownMenuItem(value: s, child: Text(PipelineStages.label(s)))],
              onChanged: (v) => setDialogState(() => selected = v ?? selected),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
              FilledButton(onPressed: () => Navigator.of(dialogContext).pop(selected), child: const Text('Resume')),
            ],
          ),
        );
      },
    );
    if (toStage == null) return;

    setState(() => _busy = true);
    final result = await ref.read(rmRepositoryProvider).resumeDeferred(widget.row.staffId, toStage);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmDeferredProvider);
        ref.invalidate(rmKanbanProvider);
        ref.invalidate(rmDashboardProvider);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Resumed to ${PipelineStages.label(toStage)}')));
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(row.staff?.fullName ?? row.staffId, style: const TextStyle(fontWeight: FontWeight.w600)),
            Text('${row.staff?.staffCode ?? ''} · Reason: ${row.reason}', style: RmTheme.body(context).copyWith(fontSize: 12)),
            if (row.deferredAt != null) Text('Deferred at: ${row.deferredAt}', style: RmTheme.body(context).copyWith(fontSize: 12)),
            if (row.notes != null) Text(row.notes!, style: RmTheme.body(context).copyWith(fontSize: 12)),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton(
                onPressed: _busy ? null : _resume,
                child: _busy ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Resume'),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
