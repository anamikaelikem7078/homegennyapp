import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/care_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';

void _backOr(BuildContext context, String fallback) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(fallback);
  }
}

String _shortDate(String ymd) {
  final d = DateTime.tryParse(ymd);
  if (d == null) return ymd;
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${d.day} ${m[d.month - 1]}';
}

String _ago(DateTime t) {
  final d = DateTime.now().difference(t);
  if (d.inMinutes < 1) return 'just now';
  if (d.inHours < 1) return '${d.inMinutes} min ago';
  if (d.inDays < 1) return '${d.inHours} h ago';
  return '${d.inDays} d ago';
}

// ---------------------------------------------------------------------------
// Entry points
// ---------------------------------------------------------------------------

/// Links into the per-placement daily-care screens, driven by `features`
/// on `GET /client/assigned-staff` (care plan for UC/SC staff).
class ClientDailyCareLinks extends StatelessWidget {
  const ClientDailyCareLinks({super.key, required this.staff});
  final List<ClientAssignedStaff> staff;

  @override
  Widget build(BuildContext context) {
    final care = [for (final s in staff) if (s.placementId != null && s.hasCarePlan) s];
    final cooks = [for (final s in staff) if (s.placementId != null && s.hasMenu) s];
    final instructed = [for (final s in staff) if (s.placementId != null && s.hasInstructions) s];
    if (care.isEmpty && cooks.isEmpty && instructed.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final s in care)
          DsListCard(
            icon: Icons.health_and_safety_rounded,
            title: care.length > 1 ? 'Daily care · ${s.fullName ?? 'Staff'}' : 'Daily care',
            subtitle: 'Care plan, today\'s checklist and reports',
            onTap: () => context.push(ClientRoutes.careHome(s.placementId!), extra: s.fullName),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ),
        for (final s in cooks)
          DsListCard(
            icon: Icons.restaurant_menu_rounded,
            title: cooks.length > 1 ? 'Menu · ${s.fullName ?? 'Cook'}' : 'Menu and meals',
            subtitle: 'Week menu, meals your cook made, food profile',
            onTap: () => context.push(ClientRoutes.menu(s.placementId!), extra: s.fullName),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ),
        for (final s in instructed)
          DsListCard(
            icon: Icons.record_voice_over_rounded,
            title: instructed.length > 1 ? 'Instructions · ${s.fullName ?? 'Staff'}' : 'Instructions',
            subtitle: 'Tell your staff something by text or voice',
            onTap: () => context.push(ClientRoutes.instructions(s.placementId!), extra: s.fullName),
            trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
          ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Daily care: today's checklist + report
// ---------------------------------------------------------------------------

/// The family's view of one placement's care: plan status, the day's
/// checklist (✓ / missed / skipped, readings in red or green) and the
/// caretaker's report.
class ClientCareScreen extends ConsumerStatefulWidget {
  const ClientCareScreen({super.key, required this.placementId, this.staffName});
  final String placementId;
  final String? staffName;

  @override
  ConsumerState<ClientCareScreen> createState() => _ClientCareScreenState();
}

class _ClientCareScreenState extends ConsumerState<ClientCareScreen> {
  late String _date = careTodayIst();

  void _shiftDay(int days) {
    final d = DateTime.parse(_date).add(Duration(days: days));
    if (careYmd(d).compareTo(careTodayIst()) > 0) return;
    setState(() => _date = careYmd(d));
  }

  @override
  Widget build(BuildContext context) {
    final pid = widget.placementId;
    final planAsync = ref.watch(carePlanProvider(pid));
    final dayAsync = ref.watch(careDayProvider((pid: pid, date: _date)));
    final view = planAsync.valueOrNull;
    final staffName = view?.staffName ?? widget.staffName ?? 'Your caretaker';
    final isToday = _date == careTodayIst();

    return DsPage(
      title: 'Daily care',
      subtitle: staffName,
      onBack: () => _backOr(context, ClientRoutes.dashboard),
      onRefresh: () async {
        ref.invalidate(carePlanProvider(pid));
        ref.invalidate(careDayProvider((pid: pid, date: _date)));
      },
      actions: [
        DsPageAction(
          icon: Icons.insights_rounded,
          tooltip: 'History',
          onPressed: () => context.push(ClientRoutes.careHistory(pid)),
        ),
      ],
      body: [
        _PlanStatusCard(
          view: view,
          loading: planAsync.isLoading,
          onOpen: () => context.push(ClientRoutes.carePlan(pid)),
        ),
        const SizedBox(height: 18),
        Row(
          children: [
            IconButton(
              tooltip: 'Previous day',
              onPressed: () => _shiftDay(-1),
              icon: const Icon(Icons.chevron_left_rounded),
            ),
            Expanded(
              child: Text(
                isToday ? 'Today' : _shortDate(_date),
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
              ),
            ),
            IconButton(
              tooltip: 'Next day',
              onPressed: isToday ? null : () => _shiftDay(1),
              icon: const Icon(Icons.chevron_right_rounded),
            ),
          ],
        ),
        ...dsAsyncBody(
          dayAsync,
          onRetry: () => ref.invalidate(careDayProvider((pid: pid, date: _date))),
          builder: (day) => [
            if (day.tasks.isEmpty)
              DsEmptyBlock(
                icon: Icons.checklist_rounded,
                title: 'Nothing scheduled',
                message: view?.plan == null
                    ? 'Write a care plan and the daily checklist will appear here.'
                    : 'There are no medicines, checks or activities on this day.',
              )
            else ...[
              CareSummaryRow(summary: day.summary),
              const SizedBox(height: 12),
              for (final t in day.tasks) CareTaskTile(task: t),
            ],
            const DsSection('Caretaker\'s report'),
            if (day.report == null)
              const DsNote(text: 'The caretaker has not filled in the report for this day yet.')
            else
              CareReportView(report: day.report!),
          ],
        ),
      ],
    );
  }
}

class _PlanStatusCard extends StatelessWidget {
  const _PlanStatusCard({required this.view, required this.loading, required this.onOpen});
  final CarePlanView? view;
  final bool loading;
  final VoidCallback onOpen;

  @override
  Widget build(BuildContext context) {
    final v = view;
    if (v == null) {
      return loading ? const LinearProgressIndicator() : const SizedBox.shrink();
    }
    final plan = v.plan;
    final first = (v.staffName ?? 'Staff').split(' ').first;
    if (plan == null) {
      return DsListCard(
        icon: Icons.assignment_add,
        title: 'Write a care plan',
        subtitle: 'Medicines, checks, activities and notes for $first',
        onTap: onOpen,
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      );
    }
    final read = v.staffAcknowledgedAt;
    return DsListCard(
      icon: Icons.assignment_rounded,
      title: 'Care plan · version ${plan.version}',
      subtitle: read != null ? 'Read by $first ✓ (${_ago(read)})' : 'Not read yet',
      iconColor: read != null ? AppColors.success : AppColors.warning,
      onTap: onOpen,
      trailing: const DsPill('Edit', icon: Icons.edit_rounded),
    );
  }
}

/// The caretaker's end-of-day report, read-only.
class CareReportView extends StatelessWidget {
  const CareReportView({super.key, required this.report});
  final CareReport report;

  @override
  Widget build(BuildContext context) {
    final r = report;
    final hygiene = [for (final e in r.hygiene.entries) if (e.value == true) carePretty(e.key)];
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DsInfoCard(
          lines: [
            for (final m in r.meals)
              DsInfoLine(
                Icons.restaurant_rounded,
                carePretty(m.meal),
                [m.description, if (m.quantity != null) m.quantity!].where((s) => s.isNotEmpty).join(' · '),
              ),
            if (r.fluidIntakeMl != null) DsInfoLine(Icons.water_drop_rounded, 'Water', '${r.fluidIntakeMl} ml'),
            if (r.sleep != null) DsInfoLine(Icons.bedtime_rounded, 'Sleep', carePretty(r.sleep!)),
            if (r.mood != null) DsInfoLine(Icons.mood_rounded, 'Mood', carePretty(r.mood!)),
            if (hygiene.isNotEmpty) DsInfoLine(Icons.shower_rounded, 'Hygiene', hygiene.join(', ')),
            if (r.notes != null) DsInfoLine(Icons.edit_note_rounded, 'Notes', r.notes!),
          ],
        ),
        if (r.photoFileIds.isNotEmpty) ...[
          const SizedBox(height: 10),
          CarePhotoStrip(fileIds: r.photoFileIds),
        ],
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Care plan editor
// ---------------------------------------------------------------------------

class ClientCarePlanScreen extends ConsumerWidget {
  const ClientCarePlanScreen({super.key, required this.placementId});
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(carePlanProvider(placementId));
    return async.when(
      skipLoadingOnRefresh: true,
      loading: () => const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => DsPage(
        title: 'Care plan',
        onBack: () => _backOr(context, ClientRoutes.dashboard),
        body: dsAsyncBody(async, onRetry: () => ref.invalidate(carePlanProvider(placementId)), builder: (_) => const []),
      ),
      // Keyed by version so a save (new version) rebuilds the form from it.
      data: (view) => _CarePlanEditor(key: ValueKey(view.plan?.version ?? 0), placementId: placementId, view: view),
    );
  }
}

class _CarePlanEditor extends ConsumerStatefulWidget {
  const _CarePlanEditor({super.key, required this.placementId, required this.view});
  final String placementId;
  final CarePlanView view;

  @override
  ConsumerState<_CarePlanEditor> createState() => _CarePlanEditorState();
}

class _CarePlanEditorState extends ConsumerState<_CarePlanEditor> {
  late final CarePlan _plan;
  bool _saving = false;

  late final _name = TextEditingController(text: _plan.patient.name);
  late final _age = TextEditingController(text: _plan.patient.age?.toString());
  late final _conditions = TextEditingController(text: _plan.patient.conditions.join(', '));
  late final _allergies = TextEditingController(text: _plan.patient.allergies.join(', '));
  late final _doctorName = TextEditingController(text: _plan.patient.doctorName);
  late final _doctorPhone = TextEditingController(text: _plan.patient.doctorPhone);
  late final _emergencyName = TextEditingController(text: _plan.patient.emergencyContactName);
  late final _emergencyPhone = TextEditingController(text: _plan.patient.emergencyContactPhone);
  late final _diet = TextEditingController(text: _plan.dietNotes);
  late final _dos = TextEditingController(text: _plan.dos);
  late final _donts = TextEditingController(text: _plan.donts);

  bool get _isUc => widget.view.isUnskilled;

  @override
  void initState() {
    super.initState();
    // A fresh, editable copy — item ids are kept so ticks stay attached.
    final p = widget.view.plan;
    _plan = p == null ? CarePlan() : CarePlan.fromJson(_planJson(p));
  }

  Map<String, dynamic> _planJson(CarePlan p) => {
        ...p.toJson(),
        'id': p.id,
        'version': p.version,
      };

  @override
  void dispose() {
    for (final c in [_name, _age, _conditions, _allergies, _doctorName, _doctorPhone, _emergencyName, _emergencyPhone, _diet, _dos, _donts]) {
      c.dispose();
    }
    super.dispose();
  }

  String? _t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

  Future<void> _save() async {
    final p = _plan;
    p.patient
      ..name = _t(_name)
      ..age = num.tryParse(_age.text.trim())
      ..conditions = careSplit(_conditions.text)
      ..allergies = careSplit(_allergies.text)
      ..doctorName = _t(_doctorName)
      ..doctorPhone = _t(_doctorPhone)
      ..emergencyContactName = _t(_emergencyName)
      ..emergencyContactPhone = _t(_emergencyPhone);
    p
      ..dietNotes = _t(_diet)
      ..dos = _t(_dos)
      ..donts = _t(_donts);
    if (_isUc) {
      // The backend refuses medicines and checks for an Unskilled Caretaker.
      p.medications.clear();
      p.vitals.clear();
    }

    setState(() => _saving = true);
    final result = await ref.read(careApiProvider).savePlan(widget.placementId, p);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (view) {
        final changes = view.plan?.changes ?? const <CareChange>[];
        context.showDsSnackBar(
          changes.isEmpty ? 'Care plan saved' : 'Saved. ${changes.first.text}${changes.length > 1 ? ' (+${changes.length - 1} more)' : ''}',
          type: DsSnackBarType.success,
        );
        ref.invalidate(carePlanProvider(widget.placementId));
        ref.invalidate(careDayProvider);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _editMedicine([CareMedication? existing]) async {
    final edited = await showModalBottomSheet<CareMedication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _MedicineSheet(placementId: widget.placementId, initial: existing),
    );
    if (edited == null) return;
    setState(() {
      if (existing == null) {
        _plan.medications.add(edited);
      } else {
        _plan.medications[_plan.medications.indexOf(existing)] = edited;
      }
    });
  }

  Future<void> _editVital([CareVital? existing]) async {
    final edited = await showModalBottomSheet<CareVital>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _VitalSheet(types: widget.view.vitalTypes, initial: existing),
    );
    if (edited == null) return;
    setState(() {
      if (existing == null) {
        _plan.vitals.add(edited);
      } else {
        _plan.vitals[_plan.vitals.indexOf(existing)] = edited;
      }
    });
  }

  Future<void> _editActivity([CareActivity? existing]) async {
    final edited = await showModalBottomSheet<CareActivity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => _ActivitySheet(initial: existing),
    );
    if (edited == null) return;
    setState(() {
      if (existing == null) {
        _plan.activities.add(edited);
      } else {
        _plan.activities[_plan.activities.indexOf(existing)] = edited;
      }
    });
  }

  String _vitalLabel(CareVital v) =>
      widget.view.vitalTypes.where((t) => t.type == v.type).firstOrNull?.label ?? v.label ?? carePretty(v.type);

  @override
  Widget build(BuildContext context) {
    final view = widget.view;
    final first = (view.staffName ?? 'the caretaker').split(' ').first;
    final p = _plan;

    return DsPage(
      title: 'Care plan',
      subtitle: view.plan == null ? 'New' : 'Version ${view.plan!.version}',
      onBack: () => _backOr(context, ClientRoutes.careHome(widget.placementId)),
      bottom: DsGradientButton(
        label: view.plan == null ? 'Save care plan' : 'Save changes',
        icon: Icons.save_rounded,
        isLoading: _saving,
        onPressed: _saving ? null : _save,
      ),
      body: [
        if (view.plan != null)
          DsNote(
            tone: view.staffAcknowledgedAt != null ? DsNoteTone.success : DsNoteTone.warning,
            text: view.staffAcknowledgedAt != null
                ? 'Read by $first ✓ (${_ago(view.staffAcknowledgedAt!)})'
                : 'Not read yet — $first will be asked to read it first.',
          ),
        const DsNote(text: 'Saving makes a new version. The caretaker sees exactly what changed.'),
        const DsSection('Patient'),
        DsLabeledField(label: 'Name', controller: _name, icon: Icons.person_rounded, optional: true, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        DsLabeledField(
          label: 'Age',
          controller: _age,
          icon: Icons.cake_rounded,
          optional: true,
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        const SizedBox(height: 12),
        _ChoiceRow(
          label: 'Gender',
          values: const ['FEMALE', 'MALE'],
          selected: p.patient.gender,
          onChanged: (v) => setState(() => p.patient.gender = v),
        ),
        _ChoiceRow(
          label: 'Mobility',
          values: CareEnums.mobility,
          selected: p.patient.mobility,
          onChanged: (v) => setState(() => p.patient.mobility = v),
        ),
        DsLabeledField(label: 'Conditions', controller: _conditions, icon: Icons.healing_rounded, hint: 'e.g. Diabetes, BP (comma separated)', optional: true),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Allergies', controller: _allergies, icon: Icons.warning_amber_rounded, hint: 'e.g. Penicillin', optional: true),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Doctor', controller: _doctorName, icon: Icons.local_hospital_rounded, optional: true, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Doctor\'s phone', controller: _doctorPhone, icon: Icons.call_rounded, optional: true, keyboardType: TextInputType.phone),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Emergency contact', controller: _emergencyName, icon: Icons.contact_emergency_rounded, optional: true, textCapitalization: TextCapitalization.words),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Emergency phone', controller: _emergencyPhone, icon: Icons.call_rounded, optional: true, keyboardType: TextInputType.phone),

        if (_isUc) ...[
          const DsSection('Medicines and checks'),
          const DsNote(
            tone: DsNoteTone.warning,
            text: 'An Unskilled Caretaker cannot give medicines or take vitals. Keep those with the family or a nurse, '
                'or ask your RM for a Skilled Caretaker (SC).',
          ),
        ] else ...[
          DsSection('Medicines', trailing: DsPill('${p.medications.length}')),
          for (final m in p.medications)
            _ItemCard(
              icon: Icons.medication_rounded,
              title: m.summary,
              subtitle: [
                m.times.join(', '),
                carePretty(m.route),
                if (m.foodRelation != 'ANY') '${carePretty(m.foodRelation)} food',
                if (m.prescriptionFileId != null) 'Prescription ✓',
              ].join(' · '),
              onEdit: () => _editMedicine(m),
              onRemove: () => setState(() => p.medications.remove(m)),
            ),
          _AddButton(label: 'Add medicine', onTap: () => _editMedicine()),
          DsSection('Checks', trailing: DsPill('${p.vitals.length}')),
          for (final v in p.vitals)
            _ItemCard(
              icon: Icons.monitor_heart_rounded,
              title: _vitalLabel(v),
              subtitle: [
                v.times.join(', '),
                if (v.isBp && v.systolicMin != null) '${v.systolicMin}–${v.systolicMax} / ${v.diastolicMin}–${v.diastolicMax}',
                if (!v.isBp && (v.min != null || v.max != null)) '${v.min ?? '…'}–${v.max ?? '…'}',
              ].join(' · '),
              onEdit: () => _editVital(v),
              onRemove: () => setState(() => p.vitals.remove(v)),
            ),
          _AddButton(label: 'Add check (BP, sugar…)', onTap: () => _editVital()),
        ],

        DsSection('Activities', trailing: DsPill('${p.activities.length}')),
        for (final a in p.activities)
          _ItemCard(
            icon: Icons.directions_walk_rounded,
            title: a.title.isEmpty ? carePretty(a.type) : a.title,
            subtitle: [a.times.join(', '), if (a.durationMin != null) '${a.durationMin} min'].join(' · '),
            onEdit: () => _editActivity(a),
            onRemove: () => setState(() => p.activities.remove(a)),
          ),
        _AddButton(label: 'Add activity', onTap: () => _editActivity()),

        const DsSection('Notes'),
        DsLabeledField(label: 'Diet', controller: _diet, icon: Icons.restaurant_rounded, hint: 'e.g. Low salt', optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Do', controller: _dos, icon: Icons.thumb_up_alt_rounded, hint: 'e.g. Help him stand slowly', optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),
        const SizedBox(height: 12),
        DsLabeledField(label: 'Don\'t', controller: _donts, icon: Icons.block_rounded, hint: 'e.g. No sweets', optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),

        if (view.versions.length > 1) ...[
          const DsSection('Earlier versions'),
          for (final ver in view.versions.skip(1).take(5))
            DsExpandableVersion(version: ver),
        ],
      ],
    );
  }
}

/// A past plan version and what changed in it.
class DsExpandableVersion extends StatelessWidget {
  const DsExpandableVersion({super.key, required this.version});
  final CarePlanVersion version;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(12),
        decoration: dsCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Version ${version.version}${version.createdAt != null ? ' · ${_shortDate(careYmd(version.createdAt!))}' : ''}',
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
            ),
            for (final c in version.changes)
              Text('• ${c.text}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary)),
          ],
        ),
      );
}

class _ChoiceRow extends StatelessWidget {
  const _ChoiceRow({required this.label, required this.values, required this.selected, required this.onChanged});
  final String label;
  final List<String> values;
  final String? selected;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final v in values)
                  DsChoiceChip(
                    label: carePretty(v),
                    selected: selected == v,
                    // Tapping the selected chip clears it.
                    onTap: () => onChanged(selected == v ? null : v),
                  ),
              ],
            ),
          ],
        ),
      );
}

class _ItemCard extends StatelessWidget {
  const _ItemCard({required this.icon, required this.title, required this.subtitle, required this.onEdit, required this.onRemove});
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onEdit;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) => DsListCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onEdit,
        margin: const EdgeInsets.only(bottom: 10),
        trailing: IconButton(
          tooltip: 'Remove',
          icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
          onPressed: onRemove,
        ),
      );
}

class _AddButton extends StatelessWidget {
  const _AddButton({required this.label, required this.onTap});
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Align(
        alignment: Alignment.centerLeft,
        child: TextButton.icon(
          onPressed: onTap,
          icon: const Icon(Icons.add_circle_outline_rounded),
          label: Text(label, style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700)),
        ),
      );
}

// ── Item editor sheets ──

class _Sheet extends StatelessWidget {
  const _Sheet({required this.title, required this.children, required this.onDone});
  final String title;
  final List<Widget> children;
  final VoidCallback onDone;

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.88),
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SafeArea(
            top: false,
            child: ListView(
              shrinkWrap: true,
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
              children: [
                Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
                const SizedBox(height: 14),
                ...children,
                const SizedBox(height: 18),
                DsGradientButton(label: 'Done', icon: Icons.check_rounded, onPressed: onDone),
              ],
            ),
          ),
        ),
      );
}

/// Times of day as chips, plus "Add time" (24-hour HH:MM).
class _TimesField extends StatelessWidget {
  const _TimesField({required this.times, required this.onChanged});
  final List<String> times;
  final ValueChanged<List<String>> onChanged;

  Future<void> _add(BuildContext context) async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (!times.contains(s)) onChanged([...times, s]..sort());
  }

  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Times', style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final t in times)
                InputChip(label: Text(t), onDeleted: () => onChanged([...times]..remove(t))),
              ActionChip(
                avatar: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add time'),
                onPressed: () => _add(context),
              ),
            ],
          ),
        ],
      );
}

class _MedicineSheet extends ConsumerStatefulWidget {
  const _MedicineSheet({required this.placementId, this.initial});
  final String placementId;
  final CareMedication? initial;

  @override
  ConsumerState<_MedicineSheet> createState() => _MedicineSheetState();
}

class _MedicineSheetState extends ConsumerState<_MedicineSheet> {
  late final CareMedication _m = widget.initial == null
      ? CareMedication(startDate: careTodayIst())
      : CareMedication.fromJson(widget.initial!.toJson());
  late final _name = TextEditingController(text: _m.name);
  late final _dose = TextEditingController(text: _m.dose);
  late final _unit = TextEditingController(text: _m.unit);
  late final _instructions = TextEditingController(text: _m.instructions);
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [_name, _dose, _unit, _instructions]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate(bool start) async {
    final now = careNowIst();
    final current = DateTime.tryParse((start ? _m.startDate : _m.endDate) ?? '') ?? now;
    final d = await showDatePicker(
      context: context,
      initialDate: current,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 730)),
    );
    if (d == null) return;
    setState(() => start ? _m.startDate = careYmd(d) : _m.endDate = careYmd(d));
  }

  Future<void> _attachPrescription() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['jpg', 'jpeg', 'png', 'webp', 'pdf'],
    );
    final file = picked?.files.firstOrNull;
    if (file?.path == null) return;
    setState(() => _uploading = true);
    final result = await ref.read(careApiProvider).uploadFile(
          placementId: widget.placementId,
          kind: 'PRESCRIPTION',
          path: file!.path!,
          filename: file.name,
        );
    if (!mounted) return;
    setState(() => _uploading = false);
    result.fold(
      onSuccess: (f) => setState(() => _m.prescriptionFileId = f.id),
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  void _done() {
    String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    if (_name.text.trim().isEmpty || _dose.text.trim().isEmpty || _m.times.isEmpty) {
      context.showDsSnackBar('Please add the medicine name, dose and at least one time.', type: DsSnackBarType.warning);
      return;
    }
    _m
      ..name = _name.text.trim()
      ..dose = _dose.text.trim()
      ..unit = t(_unit)
      ..instructions = t(_instructions);
    Navigator.of(context).pop(_m);
  }

  @override
  Widget build(BuildContext context) => _Sheet(
        title: widget.initial == null ? 'Add medicine' : 'Edit medicine',
        onDone: _done,
        children: [
          DsLabeledField(label: 'Medicine', controller: _name, icon: Icons.medication_rounded, hint: 'e.g. Metformin', textCapitalization: TextCapitalization.words),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: DsLabeledField(label: 'Dose', controller: _dose, hint: '500')),
              const SizedBox(width: 12),
              Expanded(child: DsLabeledField(label: 'Unit', controller: _unit, hint: 'mg', optional: true)),
            ],
          ),
          const SizedBox(height: 12),
          _TimesField(times: _m.times, onChanged: (v) => setState(() => _m.times = v)),
          const SizedBox(height: 12),
          _ChoiceRow(label: 'How it is given', values: CareEnums.routes, selected: _m.route, onChanged: (v) => setState(() => _m.route = v ?? 'ORAL')),
          _ChoiceRow(label: 'With food', values: CareEnums.foodRelations, selected: _m.foodRelation, onChanged: (v) => setState(() => _m.foodRelation = v ?? 'ANY')),
          Row(
            children: [
              Expanded(
                child: DsListCard(
                  icon: Icons.event_rounded,
                  title: _m.startDate ?? 'Start',
                  subtitle: 'Start date',
                  onTap: () => _pickDate(true),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: DsListCard(
                  icon: Icons.event_busy_rounded,
                  title: _m.endDate ?? 'No end',
                  subtitle: 'End date',
                  onTap: () => _pickDate(false),
                  trailing: _m.endDate == null
                      ? null
                      : IconButton(
                          tooltip: 'Clear',
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () => setState(() => _m.endDate = null),
                        ),
                ),
              ),
            ],
          ),
          DsLabeledField(label: 'Instructions', controller: _instructions, icon: Icons.notes_rounded, hint: 'e.g. With water', optional: true),
          const SizedBox(height: 12),
          DsListCard(
            icon: _m.prescriptionFileId == null ? Icons.upload_file_rounded : Icons.check_circle_rounded,
            iconColor: _m.prescriptionFileId == null ? null : AppColors.success,
            title: _m.prescriptionFileId == null ? 'Attach prescription' : 'Prescription attached',
            subtitle: _uploading ? 'Uploading…' : 'Photo or PDF, up to 10 MB',
            onTap: _uploading ? null : _attachPrescription,
            trailing: _m.prescriptionFileId == null
                ? null
                : IconButton(
                    tooltip: 'Remove',
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => setState(() => _m.prescriptionFileId = null),
                  ),
          ),
        ],
      );
}

class _VitalSheet extends StatefulWidget {
  const _VitalSheet({required this.types, this.initial});
  final List<VitalType> types;
  final CareVital? initial;

  @override
  State<_VitalSheet> createState() => _VitalSheetState();
}

class _VitalSheetState extends State<_VitalSheet> {
  late final CareVital _v = widget.initial == null
      ? CareVital(type: '')
      : CareVital.fromJson(widget.initial!.toJson());
  final _min = TextEditingController();
  final _max = TextEditingController();
  final _sysMin = TextEditingController();
  final _sysMax = TextEditingController();
  final _diaMin = TextEditingController();
  final _diaMax = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fill();
  }

  @override
  void dispose() {
    for (final c in [_min, _max, _sysMin, _sysMax, _diaMin, _diaMax]) {
      c.dispose();
    }
    super.dispose();
  }

  /// Puts the item's range (or the type's default) into the fields.
  void _fill() {
    final def = widget.types.where((t) => t.type == _v.type).firstOrNull;
    String s(num? a, num? b) => (a ?? b)?.toString() ?? '';
    _min.text = s(_v.min, def?.defaultMin);
    _max.text = s(_v.max, def?.defaultMax);
    _sysMin.text = s(_v.systolicMin, def?.systolicMin);
    _sysMax.text = s(_v.systolicMax, def?.systolicMax);
    _diaMin.text = s(_v.diastolicMin, def?.diastolicMin);
    _diaMax.text = s(_v.diastolicMax, def?.diastolicMax);
  }

  void _done() {
    if (_v.type.isEmpty || _v.times.isEmpty) {
      context.showDsSnackBar('Please choose the check and at least one time.', type: DsSnackBarType.warning);
      return;
    }
    num? n(TextEditingController c) => num.tryParse(c.text.trim());
    if (_v.isBp) {
      _v
        ..systolicMin = n(_sysMin)
        ..systolicMax = n(_sysMax)
        ..diastolicMin = n(_diaMin)
        ..diastolicMax = n(_diaMax);
    } else {
      _v
        ..min = n(_min)
        ..max = n(_max);
    }
    Navigator.of(context).pop(_v);
  }

  Widget _range(String label, TextEditingController lo, TextEditingController hi) => Padding(
        padding: const EdgeInsets.only(bottom: 12),
        child: Row(
          children: [
            Expanded(child: DsLabeledField(label: '$label from', controller: lo, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
            const SizedBox(width: 12),
            Expanded(child: DsLabeledField(label: 'to', controller: hi, keyboardType: const TextInputType.numberWithOptions(decimal: true))),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) {
    final def = widget.types.where((t) => t.type == _v.type).firstOrNull;
    return _Sheet(
      title: widget.initial == null ? 'Add check' : 'Edit check',
      onDone: _done,
      children: [
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final t in widget.types)
              DsChoiceChip(
                label: t.label,
                selected: _v.type == t.type,
                onTap: () => setState(() {
                  _v
                    ..type = t.type
                    ..min = null
                    ..max = null
                    ..systolicMin = null
                    ..systolicMax = null
                    ..diastolicMin = null
                    ..diastolicMax = null;
                  _fill();
                }),
              ),
          ],
        ),
        const SizedBox(height: 14),
        _TimesField(times: _v.times, onChanged: (v) => setState(() => _v.times = v)),
        if (_v.type.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(
            'Safe range${def != null && def.unit.isNotEmpty ? ' (${def.unit})' : ''} — a reading outside it alerts you and the RM',
            style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
          ),
          const SizedBox(height: 8),
          if (_v.isBp) ...[
            _range('Upper (systolic)', _sysMin, _sysMax),
            _range('Lower (diastolic)', _diaMin, _diaMax),
          ] else
            _range('Normal', _min, _max),
        ],
      ],
    );
  }
}

class _ActivitySheet extends StatefulWidget {
  const _ActivitySheet({this.initial});
  final CareActivity? initial;

  @override
  State<_ActivitySheet> createState() => _ActivitySheetState();
}

class _ActivitySheetState extends State<_ActivitySheet> {
  late final CareActivity _a = widget.initial == null ? CareActivity() : CareActivity.fromJson(widget.initial!.toJson());
  late final _title = TextEditingController(text: _a.title);
  late final _duration = TextEditingController(text: _a.durationMin?.toString());

  @override
  void dispose() {
    _title.dispose();
    _duration.dispose();
    super.dispose();
  }

  void _done() {
    if (_a.times.isEmpty) {
      context.showDsSnackBar('Please add at least one time.', type: DsSnackBarType.warning);
      return;
    }
    _a
      ..title = _title.text.trim().isEmpty ? carePretty(_a.type) : _title.text.trim()
      ..durationMin = num.tryParse(_duration.text.trim());
    Navigator.of(context).pop(_a);
  }

  @override
  Widget build(BuildContext context) => _Sheet(
        title: widget.initial == null ? 'Add activity' : 'Edit activity',
        onDone: _done,
        children: [
          _ChoiceRow(label: 'Type', values: CareEnums.activityTypes, selected: _a.type, onChanged: (v) => setState(() => _a.type = v ?? 'OTHER')),
          DsLabeledField(label: 'Title', controller: _title, icon: Icons.title_rounded, hint: 'e.g. Evening walk', optional: true, textCapitalization: TextCapitalization.sentences),
          const SizedBox(height: 12),
          _TimesField(times: _a.times, onChanged: (v) => setState(() => _a.times = v)),
          const SizedBox(height: 12),
          DsLabeledField(
            label: 'Minutes',
            controller: _duration,
            icon: Icons.timer_rounded,
            optional: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
        ],
      );
}

// ---------------------------------------------------------------------------
// History
// ---------------------------------------------------------------------------

class ClientCareHistoryScreen extends ConsumerStatefulWidget {
  const ClientCareHistoryScreen({super.key, required this.placementId});
  final String placementId;

  @override
  ConsumerState<ClientCareHistoryScreen> createState() => _ClientCareHistoryScreenState();
}

class _ClientCareHistoryScreenState extends ConsumerState<ClientCareHistoryScreen> {
  int _days = 7;
  bool _downloading = false;

  Future<void> _downloadReport() async {
    final now = careNowIst();
    final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    setState(() => _downloading = true);
    final result = await ref.read(careApiProvider).getMonthlyReport(widget.placementId, month);
    if (!mounted) return;
    setState(() => _downloading = false);
    switch (result) {
      case Success(data: final bytes):
        final dir = await getTemporaryDirectory();
        final file = File('${dir.path}/care-report-$month.pdf');
        await file.writeAsBytes(bytes);
        await SharePlus.instance.share(
          ShareParams(files: [XFile(file.path, mimeType: 'application/pdf')], text: 'Care report — $month'),
        );
      case Error(failure: final f):
        context.showDsSnackBar(f.message, type: DsSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    final key = (pid: widget.placementId, days: _days);
    final async = ref.watch(careHistoryProvider(key));

    return DsPage(
      title: 'Care history',
      onBack: () => _backOr(context, ClientRoutes.careHome(widget.placementId)),
      onRefresh: () async => ref.invalidate(careHistoryProvider(key)),
      bottom: DsGradientButton(
        label: 'Download monthly report',
        icon: Icons.picture_as_pdf_rounded,
        isLoading: _downloading,
        onPressed: _downloading ? null : _downloadReport,
      ),
      body: [
        Wrap(
          spacing: 8,
          children: [
            for (final d in const [7, 30, 90])
              DsChoiceChip(label: 'Last $d days', selected: _days == d, onTap: () => setState(() => _days = d)),
          ],
        ),
        const SizedBox(height: 14),
        ...dsAsyncBody(
          async,
          onRetry: () => ref.invalidate(careHistoryProvider(key)),
          builder: (h) {
            final byTitle = <String, List<CareReading>>{};
            for (final r in h.vitals) {
              (byTitle[r.title] ??= []).add(r);
            }
            return [
              Row(
                children: [
                  Expanded(
                    child: _StatTile(
                      label: 'Medicines given',
                      value: h.medicationAdherencePct == null ? '—' : '${h.medicationAdherencePct}%',
                      color: (h.medicationAdherencePct ?? 100) >= 90 ? AppColors.success : AppColors.warning,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _StatTile(
                      label: 'Missed doses',
                      value: '${h.missedDoses}',
                      color: h.missedDoses == 0 ? AppColors.success : AppColors.error,
                    ),
                  ),
                ],
              ),
              const DsSection('Each day'),
              if (h.days.isEmpty)
                const DsNote(text: 'No checklist days in this period yet.')
              else
                for (final d in h.days.reversed) _DayRow(day: d),
              const DsSection('Readings'),
              if (byTitle.isEmpty)
                const DsNote(text: 'No readings recorded in this period.')
              else
                for (final e in byTitle.entries) _ReadingsCard(title: e.key, readings: e.value),
            ];
          },
        ),
      ],
    );
  }
}

class _StatTile extends StatelessWidget {
  const _StatTile({required this.label, required this.value, required this.color});
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(14),
        decoration: dsCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 24, fontWeight: FontWeight.w800, color: color)),
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary)),
          ],
        ),
      );
}

class _DayRow extends StatelessWidget {
  const _DayRow({required this.day});
  final CareHistoryDay day;

  @override
  Widget build(BuildContext context) {
    final pct = day.adherencePct;
    final color = pct == null ? AppColors.lightTextSecondary : pct >= 90 ? AppColors.success : pct >= 70 ? AppColors.warning : AppColors.error;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          SizedBox(
            width: 56,
            child: Text(_shortDate(day.date), style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: (pct ?? 0) / 100,
                minHeight: 10,
                backgroundColor: AppColors.lightBorder,
                color: color,
              ),
            ),
          ),
          SizedBox(
            width: 92,
            child: Text(
              pct == null ? '—' : '$pct%${day.missed > 0 ? ' · ${day.missed} missed' : ''}',
              textAlign: TextAlign.right,
              style: GoogleFonts.plusJakartaSans(fontSize: 12, fontWeight: FontWeight.w700, color: color),
            ),
          ),
        ],
      ),
    );
  }
}

/// One check's readings: a small line chart plus the latest values.
class _ReadingsCard extends StatelessWidget {
  const _ReadingsCard({required this.title, required this.readings});
  final String title;
  final List<CareReading> readings;

  @override
  Widget build(BuildContext context) {
    final points = [for (final r in readings) if (r.chartValue != null) r];
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
          if (points.length > 1) ...[
            const SizedBox(height: 10),
            SizedBox(height: 90, child: CustomPaint(size: Size.infinite, painter: _LinePainter(points))),
          ],
          const SizedBox(height: 8),
          for (final r in readings.reversed.take(5))
            Padding(
              padding: const EdgeInsets.only(top: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Text('${_shortDate(r.date)} · ${r.time}', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary)),
                  ),
                  Text(
                    r.text,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: r.outOfRange ? AppColors.error : AppColors.success,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _LinePainter extends CustomPainter {
  _LinePainter(this.points);
  final List<CareReading> points;

  @override
  void paint(Canvas canvas, Size size) {
    final values = [for (final p in points) p.chartValue!.toDouble()];
    final lo = values.reduce((a, b) => a < b ? a : b);
    final hi = values.reduce((a, b) => a > b ? a : b);
    final span = (hi - lo) == 0 ? 1 : hi - lo;
    Offset at(int i) => Offset(
          values.length == 1 ? size.width / 2 : size.width * i / (values.length - 1),
          size.height - 6 - (values[i] - lo) / span * (size.height - 12),
        );
    final path = Path()..moveTo(at(0).dx, at(0).dy);
    for (var i = 1; i < values.length; i++) {
      path.lineTo(at(i).dx, at(i).dy);
    }
    canvas.drawPath(
      path,
      Paint()
        ..color = AppColors.primary
        ..strokeWidth = 2
        ..style = PaintingStyle.stroke,
    );
    for (var i = 0; i < values.length; i++) {
      canvas.drawCircle(at(i), 3.5, Paint()..color = points[i].outOfRange ? AppColors.error : AppColors.success);
    }
  }

  @override
  bool shouldRepaint(_LinePainter old) => old.points != points;
}
