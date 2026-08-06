import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// Clients tab.
class RmClientsTabScreen extends ConsumerStatefulWidget {
  const RmClientsTabScreen({super.key});

  @override
  ConsumerState<RmClientsTabScreen> createState() => _RmClientsTabScreenState();
}

class _RmClientsTabScreenState extends ConsumerState<RmClientsTabScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final clients = ref.watch(rmClientsProvider(_query));

    return Scaffold(
      appBar: const DsAppBar(title: 'Clients', subtitle: 'Manage client relationships'),
      body: Column(
        children: [
          Padding(
            padding: AppBreakpoints.pagePadding(context),
            child: DsSearchBar(hint: 'Search clients...', onChanged: (v) => setState(() => _query = v)),
          ),
          Expanded(
            child: clients.when(
              loading: () => const DsLoadingWidget(),
              error: (_, __) => const DsErrorState(title: 'Error'),
              data: (list) => ListView.separated(
                padding: AppBreakpoints.pagePadding(context),
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => DsClientCard(
                  name: list[i].name,
                  property: list[i].address,
                  status: _clientStatus(list[i].status),
                  onTap: () => context.push(RmRoutes.clientDetail(list[i].id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  DsStatusType? _clientStatus(String status) => switch (status) {
        'Active' => DsStatusType.success,
        'Trial' => DsStatusType.warning,
        _ => DsStatusType.primary,
      };
}

/// Client profile detail.
class RmClientDetailScreen extends ConsumerWidget {
  const RmClientDetailScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rmClientDetailProvider(clientId));

    return RmPageScaffold(
      title: 'Client Profile',
      body: detail.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (c) => ListView(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(c.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(c.name, style: Theme.of(context).textTheme.headlineSmall),
                  DsStatusChip(label: c.status, type: DsStatusType.success),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            _InfoRow('Address', c.address),
            _InfoRow('Phone', c.phone),
            _InfoRow('Requirements', c.requirements),
            _InfoRow('Assigned Staff', c.assignedStaffName ?? 'Unassigned'),
            SizedBox(height: AppSpacing.lg),
            RmMenuTile(icon: Icons.checklist_rounded, title: 'Requirements', onTap: () => context.push(RmRoutes.clientRequirements(clientId))),
            RmMenuTile(icon: Icons.person_add_alt_1_outlined, title: 'Assign Staff', onTap: () => context.push(RmRoutes.clientAssignStaff(clientId))),
            RmMenuTile(icon: Icons.swap_horiz_rounded, title: 'Replacement', onTap: () => context.push(RmRoutes.clientReplacement(clientId))),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 120, child: Text(label)),
          Expanded(child: Text(value, style: Theme.of(context).textTheme.titleSmall)),
        ],
      ),
    );
  }
}

/// Client requirements.
class RmClientRequirementsScreen extends ConsumerWidget {
  const RmClientRequirementsScreen({super.key, required this.clientId});
  final String clientId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rmClientDetailProvider(clientId));

    return RmPageScaffold(
      title: 'Requirements',
      body: detail.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (c) => ListView(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.softCard(context),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.check_circle_outline, color: AppColors.secondary),
                  SizedBox(width: AppSpacing.md),
                  Expanded(child: Text(c.requirements)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Assign staff to client.
class RmClientAssignStaffScreen extends ConsumerStatefulWidget {
  const RmClientAssignStaffScreen({super.key, required this.clientId});
  final String clientId;

  @override
  ConsumerState<RmClientAssignStaffScreen> createState() =>
      _RmClientAssignStaffScreenState();
}

class _RmClientAssignStaffScreenState extends ConsumerState<RmClientAssignStaffScreen> {
  String? _staffId;
  bool _loading = false;

  Future<void> _submit() async {
    if (_staffId == null) {
      context.showDsSnackBar('Select staff', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).assignDeployment(
          staffId: _staffId!,
          clientId: widget.clientId,
          type: 'assignment',
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Staff assigned', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(rmStaffListProvider(''));

    return RmPageScaffold(
      title: 'Assign Staff',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => Column(
          children: [
            ...list.map(
              (s) => RadioListTile<String>(
                title: Text(s.name),
                subtitle: Text('${s.role} · ${s.department}'),
                value: s.id,
                groupValue: _staffId,
                onChanged: (v) => setState(() => _staffId = v),
              ),
            ),
            const Spacer(),
            DsGradientButton(label: 'Assign Staff', isLoading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Staff replacement request.
class RmClientReplacementScreen extends ConsumerStatefulWidget {
  const RmClientReplacementScreen({super.key, required this.clientId});
  final String clientId;

  @override
  ConsumerState<RmClientReplacementScreen> createState() =>
      _RmClientReplacementScreenState();
}

class _RmClientReplacementScreenState extends ConsumerState<RmClientReplacementScreen> {
  final _reason = TextEditingController();
  String? _staffId;
  bool _loading = false;

  @override
  void dispose() {
    _reason.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_staffId == null || _reason.text.isEmpty) {
      context.showDsSnackBar('Fill all fields', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).assignDeployment(
          staffId: _staffId!,
          clientId: widget.clientId,
          type: 'replacement',
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Replacement requested', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(rmStaffListProvider(''));

    return RmPageScaffold(
      title: 'Replacement',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Current Staff', style: Theme.of(context).textTheme.titleSmall),
            ...list.map(
              (s) => RadioListTile<String>(
                title: Text(s.name),
                value: s.id,
                groupValue: _staffId,
                onChanged: (v) => setState(() => _staffId = v),
              ),
            ),
            SizedBox(height: AppSpacing.md),
            DsTextField(controller: _reason, label: 'Reason', hint: 'Why replacement needed?', maxLines: 3),
            const Spacer(),
            DsPrimaryButton(label: 'Request Replacement', isLoading: _loading, onPressed: _submit),
          ],
        ),
      ),
    );
  }
}

/// Pending agreement screen.
class RmPendingAgreementScreen extends ConsumerWidget {
  const RmPendingAgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUps = ref.watch(rmFollowUpsProvider);

    return RmPageScaffold(
      title: 'Pending Agreement',
      body: followUps.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final pending = list.where((f) => f.type == RmPendingType.agreement).toList();
          if (pending.isEmpty) {
            return const DsEmptyState(title: 'All signed', message: 'No pending agreements');
          }
          return ListView.separated(
            itemCount: pending.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => RmMenuTile(
              icon: Icons.description_outlined,
              title: pending[i].title,
              subtitle: pending[i].subtitle,
              onTap: () {
                if (pending[i].staffId != null) {
                  context.push(RmRoutes.staffDetail(pending[i].staffId!));
                }
              },
            ),
          );
        },
      ),
    );
  }
}
