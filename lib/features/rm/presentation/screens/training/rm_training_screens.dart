import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

const _trainingModules = [
  ('CRS-001', 'Home Care Basics', '2 weeks', '8 lessons'),
  ('CRS-002', 'Safety & Hygiene', '1 week', '5 lessons'),
  ('CRS-003', 'Client Communication', '1 week', '4 lessons'),
];

/// Pending training assignments.
class RmPendingTrainingScreen extends ConsumerWidget {
  const RmPendingTrainingScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffListProvider(''));

    return RmPageScaffold(
      title: 'Pending Training',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final pending = list.where((s) => s.trainingProgress < 1).toList();
          if (pending.isEmpty) {
            return const DsEmptyState(title: 'All complete', message: 'No pending training');
          }
          return ListView.separated(
            itemCount: pending.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => DsProgressCard(
              title: pending[i].name,
              subtitle: pending[i].role,
              progress: pending[i].trainingProgress,
              icon: Icons.school_outlined,
              onTap: () => context.push(RmRoutes.staffTraining(pending[i].id)),
            ),
          );
        },
      ),
    );
  }
}

/// Assign training to staff.
class RmAssignTrainingScreen extends ConsumerStatefulWidget {
  const RmAssignTrainingScreen({super.key});

  @override
  ConsumerState<RmAssignTrainingScreen> createState() =>
      _RmAssignTrainingScreenState();
}

class _RmAssignTrainingScreenState extends ConsumerState<RmAssignTrainingScreen> {
  String? _staffId;
  String? _moduleId;
  bool _loading = false;

  Future<void> _submit() async {
    if (_staffId == null || _moduleId == null) {
      context.showDsSnackBar('Select staff and module', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).assignTraining(_staffId!, _moduleId!);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Training assigned', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(rmStaffListProvider(''));

    return RmPageScaffold(
      title: 'Assign Training',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (staffList) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Select Staff', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: AppSpacing.sm),
            ...staffList.map(
              (s) => RadioListTile<String>(
                title: Text(s.name),
                subtitle: Text(s.role),
                value: s.id,
                groupValue: _staffId,
                onChanged: (v) => setState(() => _staffId = v),
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text('Training Module', style: Theme.of(context).textTheme.titleSmall),
            SizedBox(height: AppSpacing.sm),
            ..._trainingModules.map(
              (m) => RadioListTile<String>(
                title: Text(m.$2),
                subtitle: Text('${m.$3} · ${m.$4}'),
                value: m.$1,
                groupValue: _moduleId,
                onChanged: (v) => setState(() => _moduleId = v),
              ),
            ),
            const Spacer(),
            DsGradientButton(label: 'Assign Training', isLoading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Track training progress across staff.
class RmTrainingProgressScreen extends ConsumerWidget {
  const RmTrainingProgressScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffListProvider(''));

    return RmPageScaffold(
      title: 'Track Progress',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => DsProgressCard(
            title: list[i].name,
            subtitle: list[i].department,
            progress: list[i].trainingProgress,
            icon: Icons.trending_up_rounded,
          ),
        ),
      ),
    );
  }
}

/// Training certificates list.
class RmCertificatesScreen extends ConsumerWidget {
  const RmCertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffListProvider(''));

    return RmPageScaffold(
      title: 'Certificates',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final certified = list.where((s) => s.trainingProgress >= 1).toList();
          if (certified.isEmpty) {
            return const DsEmptyState(title: 'No certificates', message: 'Complete training to earn certificates');
          }
          return ListView.separated(
            itemCount: certified.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.softCard(context),
              child: Row(
                children: [
                  Icon(Icons.workspace_premium_rounded, color: AppColors.secondary, size: 32),
                  SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(certified[i].name, style: Theme.of(context).textTheme.titleSmall),
                        Text('Home Care Certification'),
                      ],
                    ),
                  ),
                  const DsStatusChip(label: 'Issued', type: DsStatusType.success),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
