import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

String _deploymentStatusLabel(RmDeploymentStatus status) => switch (status) {
      RmDeploymentStatus.trial => 'Trial',
      RmDeploymentStatus.permanent => 'Permanent',
      RmDeploymentStatus.pending => 'Pending',
    };

DsStatusType _deploymentStatusType(RmDeploymentStatus status) => switch (status) {
      RmDeploymentStatus.trial => DsStatusType.warning,
      RmDeploymentStatus.permanent => DsStatusType.success,
      RmDeploymentStatus.pending => DsStatusType.primary,
    };

/// Deployment hub.
class RmDeploymentHubScreen extends ConsumerWidget {
  const RmDeploymentHubScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployments = ref.watch(rmDeploymentsProvider);

    return RmPageScaffold(
      title: 'Deployment',
      body: deployments.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView(
          children: [
            RmMenuTile(icon: Icons.person_add_alt_1_outlined, title: 'Assign Staff', onTap: () => context.push(RmRoutes.deploymentAssignStaff)),
            RmMenuTile(icon: Icons.home_work_outlined, title: 'Assign Client', onTap: () => context.push(RmRoutes.deploymentAssignClient)),
            RmMenuTile(icon: Icons.hourglass_top_rounded, title: 'Trial Monitoring', onTap: () => context.push(RmRoutes.deploymentTrial)),
            RmMenuTile(icon: Icons.verified_outlined, title: 'Permanent Placement', onTap: () => context.push(RmRoutes.deploymentPermanent)),
            SizedBox(height: AppSpacing.xl),
            RmSectionHeader(title: 'Active Deployments'),
            ...list.map((d) => Padding(
                  padding: EdgeInsets.only(bottom: AppSpacing.sm),
                  child: _DeploymentCard(deployment: d),
                )),
          ],
        ),
      ),
    );
  }
}

class _DeploymentCard extends StatelessWidget {
  const _DeploymentCard({required this.deployment});
  final RmDeployment deployment;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.all(AppSpacing.lg),
      decoration: AppDecorations.softCard(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(child: Text(deployment.clientName, style: Theme.of(context).textTheme.titleSmall)),
              DsStatusChip(
                label: _deploymentStatusLabel(deployment.status),
                type: _deploymentStatusType(deployment.status),
              ),
            ],
          ),
          Text('Staff: ${deployment.staffName}'),
          Text('Location: ${deployment.location}'),
          Text('Started: ${deployment.startDate}'),
        ],
      ),
    );
  }
}

/// Pending deployment screen.
class RmPendingDeploymentScreen extends ConsumerWidget {
  const RmPendingDeploymentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final followUps = ref.watch(rmFollowUpsProvider);

    return RmPageScaffold(
      title: 'Pending Deployment',
      body: followUps.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final pending = list.where((f) => f.type == RmPendingType.deployment).toList();
          if (pending.isEmpty) {
            return const DsEmptyState(title: 'All deployed', message: 'No pending deployments');
          }
          return ListView.separated(
            itemCount: pending.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => RmMenuTile(
              icon: Icons.rocket_launch_outlined,
              title: pending[i].title,
              subtitle: pending[i].subtitle,
              onTap: () {
                if (pending[i].clientId != null) {
                  context.push(RmRoutes.clientDetail(pending[i].clientId!));
                } else {
                  context.push(RmRoutes.deployment);
                }
              },
            ),
          );
        },
      ),
    );
  }
}

/// Assign staff for deployment.
class RmDeploymentAssignStaffScreen extends ConsumerStatefulWidget {
  const RmDeploymentAssignStaffScreen({super.key});

  @override
  ConsumerState<RmDeploymentAssignStaffScreen> createState() =>
      _RmDeploymentAssignStaffScreenState();
}

class _RmDeploymentAssignStaffScreenState
    extends ConsumerState<RmDeploymentAssignStaffScreen> {
  String? _staffId;
  String? _clientId;
  bool _loading = false;

  Future<void> _submit() async {
    if (_staffId == null || _clientId == null) {
      context.showDsSnackBar('Select staff and client', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).assignDeployment(
          staffId: _staffId!,
          clientId: _clientId!,
          type: 'trial',
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Deployment created', type: DsSnackBarType.success);
        context.go(RmRoutes.deployment);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(rmStaffListProvider(''));
    final clients = ref.watch(rmClientsProvider(''));

    return RmPageScaffold(
      title: 'Assign Staff',
      body: staff.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (staffList) => clients.when(
          loading: () => const DsLoadingWidget(),
          error: (_, __) => const DsErrorState(title: 'Error'),
          data: (clientList) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Staff', style: Theme.of(context).textTheme.titleSmall),
              ...staffList.map(
                (s) => RadioListTile<String>(
                  title: Text(s.name),
                  value: s.id,
                  groupValue: _staffId,
                  onChanged: (v) => setState(() => _staffId = v),
                ),
              ),
              Text('Client', style: Theme.of(context).textTheme.titleSmall),
              ...clientList.map(
                (c) => RadioListTile<String>(
                  title: Text(c.name),
                  value: c.id,
                  groupValue: _clientId,
                  onChanged: (v) => setState(() => _clientId = v),
                ),
              ),
              const Spacer(),
              DsGradientButton(label: 'Create Deployment', isLoading: _loading, onPressed: _submit),
            ],
          ),
        ),
      ),
    );
  }
}

/// Assign client for deployment.
class RmDeploymentAssignClientScreen extends ConsumerWidget {
  const RmDeploymentAssignClientScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final clients = ref.watch(rmClientsProvider(''));

    return RmPageScaffold(
      title: 'Assign Client',
      body: clients.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView.separated(
          itemCount: list.length,
          separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
          itemBuilder: (_, i) => RmMenuTile(
            icon: Icons.home_work_outlined,
            title: list[i].name,
            subtitle: list[i].address,
            onTap: () => context.push(RmRoutes.deploymentAssignStaff),
          ),
        ),
      ),
    );
  }
}

/// Trial monitoring.
class RmTrialMonitoringScreen extends ConsumerWidget {
  const RmTrialMonitoringScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployments = ref.watch(rmDeploymentsProvider);

    return RmPageScaffold(
      title: 'Trial Monitoring',
      body: deployments.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final trials = list.where((d) => d.status == RmDeploymentStatus.trial).toList();
          if (trials.isEmpty) {
            return const DsEmptyState(title: 'No trials', message: 'No active trial deployments');
          }
          return ListView.separated(
            itemCount: trials.length,
            separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
            itemBuilder: (_, i) => _DeploymentCard(deployment: trials[i]),
          );
        },
      ),
    );
  }
}

/// Permanent placement.
class RmPermanentPlacementScreen extends ConsumerStatefulWidget {
  const RmPermanentPlacementScreen({super.key});

  @override
  ConsumerState<RmPermanentPlacementScreen> createState() =>
      _RmPermanentPlacementScreenState();
}

class _RmPermanentPlacementScreenState
    extends ConsumerState<RmPermanentPlacementScreen> {
  String? _deploymentId;
  bool _loading = false;

  Future<void> _confirm() async {
    if (_deploymentId == null) return;
    final deployments = await ref.read(rmDeploymentsProvider.future);
    final deployment = deployments.firstWhere((d) => d.id == _deploymentId);
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).assignDeployment(
          staffId: deployment.staffId,
          clientId: deployment.clientId,
          type: 'permanent',
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmDeploymentsProvider);
        context.showDsSnackBar('Permanent placement confirmed', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deployments = ref.watch(rmDeploymentsProvider);

    return RmPageScaffold(
      title: 'Permanent Placement',
      body: deployments.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          final trials = list.where((d) => d.status == RmDeploymentStatus.trial).toList();
          if (trials.isEmpty) {
            return const DsEmptyState(title: 'No trials', message: 'No trial deployments to confirm');
          }
          return Column(
            children: [
              ...trials.map(
                (d) => RadioListTile<String>(
                  title: Text('${d.staffName} → ${d.clientName}'),
                  subtitle: Text('Started ${d.startDate}'),
                  value: d.id,
                  groupValue: _deploymentId,
                  onChanged: (v) => setState(() => _deploymentId = v),
                ),
              ),
              const Spacer(),
              DsPrimaryButton(label: 'Confirm Permanent', isLoading: _loading, onPressed: _confirm),
            ],
          );
        },
      ),
    );
  }
}
