import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/rm_models.dart';
import '../../navigation/rm_routes.dart';
import '../../providers/rm_providers.dart';
import '../../widgets/rm_scaffold.dart';

/// Staff management tab.
class RmStaffTabScreen extends ConsumerStatefulWidget {
  const RmStaffTabScreen({super.key});

  @override
  ConsumerState<RmStaffTabScreen> createState() => _RmStaffTabScreenState();
}

class _RmStaffTabScreenState extends ConsumerState<RmStaffTabScreen> {
  String _query = '';

  @override
  Widget build(BuildContext context) {
    final staff = ref.watch(rmStaffListProvider(_query));

    return Scaffold(
      appBar: const DsAppBar(title: 'Staff Management', subtitle: 'Manage your team'),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push(RmRoutes.staffCreate),
        icon: Icon(Icons.person_add_rounded),
        label: Text('Create Staff'),
      ),
      body: Column(
        children: [
          Padding(
            padding: AppBreakpoints.pagePadding(context),
            child: DsSearchBar(
              hint: 'Search staff...',
              onChanged: (v) => setState(() => _query = v),
            ),
          ),
          Expanded(
            child: staff.when(
              loading: () => const DsLoadingWidget(),
              error: (_, __) => const DsErrorState(title: 'Error'),
              data: (list) => ListView.separated(
                padding: AppBreakpoints.pagePadding(context),
                itemCount: list.length,
                separatorBuilder: (_, __) => SizedBox(height: AppSpacing.sm),
                itemBuilder: (_, i) => _StaffCard(
                  member: list[i],
                  onTap: () => context.push(RmRoutes.staffDetail(list[i].id)),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _StaffCard extends StatelessWidget {
  const _StaffCard({required this.member, required this.onTap});
  final RmStaffMember member;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return DsStaffCard(
      name: member.name,
      role: member.role,
      department: member.department,
      onTap: onTap,
    );
  }
}

/// Staff detail screen.
class RmStaffDetailScreen extends ConsumerWidget {
  const RmStaffDetailScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rmStaffDetailProvider(staffId));

    return RmPageScaffold(
      title: 'Staff Details',
      actions: [
        IconButton(
          icon: Icon(Icons.edit_outlined),
          onPressed: () => context.push(RmRoutes.staffEdit(staffId)),
        ),
      ],
      body: detail.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          children: [
            Center(
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 40,
                    backgroundColor: AppColors.primary.withValues(alpha: 0.15),
                    child: Text(s.name[0], style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w700)),
                  ),
                  SizedBox(height: AppSpacing.md),
                  Text(s.name, style: Theme.of(context).textTheme.headlineSmall),
                  DsStatusChip(label: s.status, type: DsStatusType.primary),
                ],
              ),
            ),
            SizedBox(height: AppSpacing.xl),
            DsProgressCard(
              title: 'Training Progress',
              progress: s.trainingProgress,
              icon: Icons.school_outlined,
              onTap: () => context.push(RmRoutes.staffTraining(staffId)),
            ),
            SizedBox(height: AppSpacing.md),
            _InfoRow('Pipeline', s.pipelineStage),
            _InfoRow('Attendance', '${s.attendancePercent}%'),
            _InfoRow('Last Salary', s.lastSalary),
            _InfoRow('Phone', s.phone),
            _InfoRow('Email', s.email),
            SizedBox(height: AppSpacing.lg),
            RmMenuTile(icon: Icons.folder_outlined, title: 'Documents', subtitle: '${s.documentsCount} files', onTap: () => context.push(RmRoutes.staffDocuments(staffId))),
            RmMenuTile(icon: Icons.fingerprint_outlined, title: 'Verification', onTap: () => context.push(RmRoutes.verificationPending)),
            RmMenuTile(icon: Icons.schedule_outlined, title: 'Attendance', onTap: () => context.push(RmRoutes.staffAttendance(staffId))),
            RmMenuTile(icon: Icons.payments_outlined, title: 'Salary', onTap: () => context.push(RmRoutes.staffSalary(staffId))),
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
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [Text(label), Text(value, style: Theme.of(context).textTheme.titleSmall)],
      ),
    );
  }
}

/// Create staff form.
class RmCreateStaffScreen extends ConsumerStatefulWidget {
  const RmCreateStaffScreen({super.key});

  @override
  ConsumerState<RmCreateStaffScreen> createState() => _RmCreateStaffScreenState();
}

class _RmCreateStaffScreenState extends ConsumerState<RmCreateStaffScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _loading = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _email.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).createStaff({
      'name': _name.text,
      'phone': _phone.text,
      'email': _email.text,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar('Staff created', type: DsSnackBarType.success);
        context.go(RmRoutes.staff);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return RmPageScaffold(
      title: 'Create Staff',
      body: Column(
        children: [
          DsTextField(controller: _name, label: 'Full Name', prefixIcon: Icons.person_outline),
          SizedBox(height: AppSpacing.md),
          DsTextField(controller: _phone, label: 'Phone', prefixIcon: Icons.phone_outlined, keyboardType: TextInputType.phone),
          SizedBox(height: AppSpacing.md),
          DsTextField(controller: _email, label: 'Email', prefixIcon: Icons.email_outlined, keyboardType: TextInputType.emailAddress),
          const Spacer(),
          DsGradientButton(label: 'Create Staff', isLoading: _loading, onPressed: _submit),
        ],
      ),
    );
  }
}

/// Edit staff form.
class RmEditStaffScreen extends ConsumerStatefulWidget {
  const RmEditStaffScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmEditStaffScreen> createState() => _RmEditStaffScreenState();
}

class _RmEditStaffScreenState extends ConsumerState<RmEditStaffScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  bool _loading = false;
  bool _initialized = false;

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _loading = true);
    final result = await ref.read(rmRepositoryProvider).updateStaff(widget.staffId, {
      'name': _name.text,
      'phone': _phone.text,
    });
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmStaffDetailProvider(widget.staffId));
        context.showDsSnackBar('Updated', type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final detail = ref.watch(rmStaffDetailProvider(widget.staffId));

    return RmPageScaffold(
      title: 'Edit Staff',
      body: detail.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) {
          if (!_initialized) {
            _name.text = s.name;
            _phone.text = s.phone;
            _initialized = true;
          }
          return Column(
            children: [
              DsTextField(controller: _name, label: 'Name', prefixIcon: Icons.person_outline),
              SizedBox(height: AppSpacing.md),
              DsTextField(controller: _phone, label: 'Phone', prefixIcon: Icons.phone_outlined),
              const Spacer(),
              DsPrimaryButton(label: 'Save Changes', isLoading: _loading, onPressed: _submit),
            ],
          );
        },
      ),
    );
  }
}

/// Staff sub-pages (documents, training, attendance, salary).
class RmStaffDocumentsScreen extends StatelessWidget {
  const RmStaffDocumentsScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return RmPageScaffold(
      title: 'Documents',
      body: ListView(
        children: [
          DsDocumentCard(title: 'Aadhaar Card', subtitle: 'Approved', fileType: 'PDF'),
          SizedBox(height: AppSpacing.sm),
          DsDocumentCard(title: 'Police Verification', subtitle: 'Pending', fileType: 'PDF'),
        ],
      ),
    );
  }
}

class RmStaffTrainingScreen extends ConsumerWidget {
  const RmStaffTrainingScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final detail = ref.watch(rmStaffDetailProvider(staffId));
    return RmPageScaffold(
      title: 'Training Progress',
      body: detail.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => Column(
          children: [
            DsProgressCard(title: 'Overall Progress', progress: s.trainingProgress, icon: Icons.school_outlined),
            SizedBox(height: AppSpacing.lg),
            RmMenuTile(icon: Icons.add_circle_outline, title: 'Assign Training', onTap: () => context.push(RmRoutes.trainingAssign)),
          ],
        ),
      ),
    );
  }
}

class RmStaffAttendanceScreen extends StatelessWidget {
  const RmStaffAttendanceScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return RmPageScaffold(
      title: 'Attendance',
      body: ListView(
        children: [
          DsAttendanceCard(date: 'Today', checkIn: '09:02 AM', checkOut: '06:30 PM', status: DsStatusType.success),
          DsAttendanceCard(date: 'Yesterday', checkIn: '09:15 AM', checkOut: '06:15 PM', status: DsStatusType.warning),
        ],
      ),
    );
  }
}

class RmStaffSalaryScreen extends StatelessWidget {
  const RmStaffSalaryScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return RmPageScaffold(
      title: 'Salary',
      body: Column(
        children: [
          DsSalaryCard(month: 'June 2024', amount: '₹25,760', status: DsStatusType.success),
          SizedBox(height: AppSpacing.md),
          DsSalaryCard(month: 'May 2024', amount: '₹25,760', status: DsStatusType.success),
        ],
      ),
    );
  }
}
