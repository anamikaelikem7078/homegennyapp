import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_bottom_navigation.dart';

/// Incidents — repurposed from the former "Alerts" tab, which had no
/// backend equivalent (hardcoded mock notification list). Incidents
/// (`GET`/`POST /rm/incidents`) is a real, required RM module needing a
/// home; this reuses the existing bottom-nav slot.
class RmAlertsScreen extends ConsumerWidget {
  const RmAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final incidentsAsync = ref.watch(rmIncidentsProvider(null));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.cardSurface,
        elevation: 0,
        title: const Text('Incidents'),
        actions: [
          IconButton(icon: const Icon(Icons.add), onPressed: () => _showCreateSheet(context, ref)),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(rmIncidentsProvider(null)),
        child: AsyncValueWidget<List<IncidentRow>>(
          value: incidentsAsync,
          onRetry: () => ref.invalidate(rmIncidentsProvider(null)),
          builder: (incidents) {
            if (incidents.isEmpty) return const Center(child: Text('No incidents on file.'));
            return ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: incidents.length,
              itemBuilder: (context, index) {
                final i = incidents[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  child: ListTile(
                    leading: Icon(_iconFor(i.type), color: RmTheme.crimsonDanger),
                    title: Text(i.title),
                    subtitle: Text('${IncidentTypes.label(i.type)}${i.staff != null ? ' · ${i.staff!.fullName}' : ''}\n${i.status}'),
                    isThreeLine: i.staff != null,
                  ),
                );
              },
            );
          },
        ),
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 3),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        IncidentTypes.clientComplaint => Icons.sentiment_dissatisfied_outlined,
        IncidentTypes.staffMisconduct => Icons.person_off_outlined,
        IncidentTypes.safetyIssue => Icons.warning_amber_rounded,
        IncidentTypes.attendanceFraud => Icons.gpp_bad_outlined,
        IncidentTypes.drivingViolation => Icons.car_crash_outlined,
        IncidentTypes.lateExit => Icons.exit_to_app,
        _ => Icons.report_problem_outlined,
      };

  void _showCreateSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => _CreateIncidentSheet(ref: ref),
    );
  }
}

class _CreateIncidentSheet extends StatefulWidget {
  const _CreateIncidentSheet({required this.ref});
  final WidgetRef ref;

  @override
  State<_CreateIncidentSheet> createState() => _CreateIncidentSheetState();
}

class _CreateIncidentSheetState extends State<_CreateIncidentSheet> {
  String _type = IncidentTypes.clientComplaint;
  final _titleController = TextEditingController();
  final _descController = TextEditingController();
  final _staffIdController = TextEditingController();
  bool _submitting = false;

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    _staffIdController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_titleController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Title is required')));
      return;
    }
    setState(() => _submitting = true);
    final result = await widget.ref.read(rmRepositoryProvider).createIncident({
      'type': _type,
      'title': _titleController.text.trim(),
      if (_descController.text.trim().isNotEmpty) 'description': _descController.text.trim(),
      if (_staffIdController.text.trim().isNotEmpty) 'staff_id': _staffIdController.text.trim(),
    });
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (_) {
        widget.ref.invalidate(rmIncidentsProvider(null));
        widget.ref.invalidate(rmDashboardProvider);
        Navigator.of(context).pop();
      },
      onError: (f) => ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(left: 20, right: 20, top: 20, bottom: MediaQuery.of(context).viewInsets.bottom + 20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('New Incident', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18)),
          const SizedBox(height: 16),
          DropdownButtonFormField<String>(
            initialValue: _type,
            items: [for (final t in IncidentTypes.all) DropdownMenuItem(value: t, child: Text(IncidentTypes.label(t)))],
            onChanged: (v) => setState(() => _type = v ?? _type),
            decoration: const InputDecoration(labelText: 'Type', border: OutlineInputBorder()),
          ),
          const SizedBox(height: 12),
          TextField(controller: _titleController, decoration: const InputDecoration(labelText: 'Title', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _descController, maxLines: 3, decoration: const InputDecoration(labelText: 'Description (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 12),
          TextField(controller: _staffIdController, decoration: const InputDecoration(labelText: 'Staff ID (optional)', border: OutlineInputBorder())),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              onPressed: _submitting ? null : _submit,
              style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
              child: _submitting ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)) : const Text('File Incident'),
            ),
          ),
        ],
      ),
    );
  }
}
