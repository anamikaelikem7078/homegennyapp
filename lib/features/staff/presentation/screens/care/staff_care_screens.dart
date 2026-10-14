import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/care_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../navigation/staff_routes.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(StaffRoutes.home);
  }
}

/// "Mark as read" on the active care plan (a CARE_PLAN client update).
Future<bool> _markPlanRead(BuildContext context, WidgetRef ref, String planId) async {
  final result = await ref.read(careApiProvider).acknowledgeUpdate('CARE_PLAN', planId);
  if (!context.mounted) return false;
  return result.fold(
    onSuccess: (_) {
      context.showDsSnackBar('Marked as read — the family can see it', type: DsSnackBarType.success);
      invalidateAfterAck(ref);
      return true;
    },
    onError: (f) {
      context.showDsSnackBar(f.message, type: DsSnackBarType.error);
      return false;
    },
  );
}

// ---------------------------------------------------------------------------
// Home card
// ---------------------------------------------------------------------------

/// "Today's care" on the staff home screen — only for caretakers with an
/// active care placement.
class StaffCareHomeCard extends ConsumerWidget {
  const StaffCareHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final today = ref.watch(staffCareTodayProvider).valueOrNull;
    if (today == null || today.placements.isEmpty) return const SizedBox.shrink();
    final unread = today.placements.where((p) => p.hasPlan && !p.planAcknowledged).length;
    final done = today.placements.fold<int>(0, (s, p) => s + p.summary.done);
    final total = today.placements.fold<int>(0, (s, p) => s + p.summary.total);
    final missed = today.placements.fold<int>(0, (s, p) => s + p.summary.missed);

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DsListCard(
        icon: unread > 0 ? Icons.mark_email_unread_rounded : Icons.checklist_rounded,
        iconColor: unread > 0 || missed > 0 ? AppColors.error : AppColors.success,
        title: 'Today\'s care checklist',
        subtitle: unread > 0
            ? 'The care plan has changed — please read it first'
            : '$done of $total done${missed > 0 ? ' · $missed missed' : ''}',
        margin: EdgeInsets.zero,
        onTap: () => context.push(StaffRoutes.careToday),
        trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Today checklist
// ---------------------------------------------------------------------------

class StaffCareTodayScreen extends ConsumerWidget {
  const StaffCareTodayScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(staffCareTodayProvider);
    return DsPage(
      title: 'Today\'s care',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(staffCareTodayProvider),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(staffCareTodayProvider),
        builder: (today) {
          if (today.placements.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.checklist_rounded,
                title: 'No care checklist',
                message: 'When you are working at a home with a care plan, your daily list shows here.',
              ),
            ];
          }
          return [for (final p in today.placements) _PlacementChecklist(placement: p, multiple: today.placements.length > 1)];
        },
      ),
    );
  }
}

class _PlacementChecklist extends ConsumerStatefulWidget {
  const _PlacementChecklist({required this.placement, required this.multiple});
  final StaffCarePlacement placement;
  final bool multiple;

  @override
  ConsumerState<_PlacementChecklist> createState() => _PlacementChecklistState();
}

class _PlacementChecklistState extends ConsumerState<_PlacementChecklist> {
  /// Staff can fill today or yesterday only.
  bool _yesterday = false;
  String? _busyTask;

  void _refresh() {
    ref.invalidate(staffCareTodayProvider);
    ref.invalidate(careDayProvider);
  }

  Future<void> _done(CareTask t) async {
    Map<String, dynamic>? value;
    String? notes;
    if (t.isVital) {
      final r = await showModalBottomSheet<_Reading>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ReadingSheet(task: t),
      );
      if (r == null) return;
      value = r.value;
      notes = r.notes;
    }
    setState(() => _busyTask = t.id);
    final result = await ref.read(careApiProvider).markTaskDone(t.id, value: value, notes: notes);
    if (!mounted) return;
    setState(() => _busyTask = null);
    result.fold(
      onSuccess: (done) {
        HapticFeedback.mediumImpact();
        context.showDsSnackBar(
          done.outOfRange ? 'Saved. This reading is outside the safe range — the family and RM have been told.' : 'Done',
          type: done.outOfRange ? DsSnackBarType.warning : DsSnackBarType.success,
        );
        _refresh();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _skip(CareTask t) async {
    final reason = await careAskText(
      context,
      title: 'Why was it skipped?',
      label: 'Reason',
      hint: 'The family sees this',
      confirmLabel: 'Skip',
    );
    if (reason == null || !mounted) return;
    setState(() => _busyTask = t.id);
    final result = await ref.read(careApiProvider).skipTask(t.id, reason);
    if (!mounted) return;
    setState(() => _busyTask = null);
    result.fold(
      onSuccess: (_) => _refresh(),
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Widget? _actions(CareTask t) {
    if (t.status == CareTaskStatus.done || t.status == CareTaskStatus.skipped) return null;
    final busy = _busyTask == t.id;
    return Row(
      children: [
        Expanded(
          flex: 2,
          child: DsGradientButton(
            label: t.isVital ? 'Enter reading' : 'Done',
            icon: t.isVital ? Icons.dialpad_rounded : Icons.check_rounded,
            isLoading: busy,
            onPressed: busy ? null : () => _done(t),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: DsOutlineButton(label: 'Skip', onPressed: busy ? null : () => _skip(t)),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.placement;
    final dayAsync = _yesterday ? ref.watch(careDayProvider((pid: p.placementId, date: careYesterdayIst()))) : null;
    final tasks = _yesterday ? (dayAsync?.valueOrNull?.tasks ?? const <CareTask>[]) : p.tasks;
    final summary = _yesterday ? (dayAsync?.valueOrNull?.summary ?? const CareSummary()) : p.summary;
    final report = _yesterday ? dayAsync?.valueOrNull?.report : p.report;
    final date = _yesterday ? careYesterdayIst() : careTodayIst();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        if (widget.multiple) DsSection(p.clientName),
        if (p.hasPlan && !p.planAcknowledged)
          _PlanChangedBanner(
            changes: p.planChanges,
            onRead: () => _markPlanRead(context, ref, p.planId!),
            onOpen: () => context.push(StaffRoutes.carePlan(p.placementId)),
          ),
        Row(
          children: [
            DsChoiceChip(label: 'Today', selected: !_yesterday, onTap: () => setState(() => _yesterday = false)),
            const SizedBox(width: 8),
            DsChoiceChip(label: 'Yesterday', selected: _yesterday, onTap: () => setState(() => _yesterday = true)),
            const Spacer(),
            if (p.hasPlan)
              TextButton.icon(
                onPressed: () => context.push(StaffRoutes.carePlan(p.placementId)),
                icon: const Icon(Icons.assignment_rounded, size: 18),
                label: const Text('Care plan'),
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (dayAsync?.isLoading ?? false) const LinearProgressIndicator(),
        if (tasks.isEmpty)
          DsEmptyBlock(
            icon: Icons.event_available_rounded,
            title: 'Nothing on the list',
            message: p.hasPlan ? 'No medicines, checks or activities for this day.' : 'The family has not written a care plan yet.',
          )
        else ...[
          CareSummaryRow(summary: summary),
          const SizedBox(height: 12),
          for (final t in tasks) CareTaskTile(task: t, actions: _actions(t)),
        ],
        const SizedBox(height: 8),
        DsListCard(
          icon: report == null ? Icons.edit_note_rounded : Icons.task_alt_rounded,
          iconColor: report == null ? null : AppColors.success,
          title: report == null ? 'Fill the daily report' : 'Daily report filled',
          subtitle: report == null ? 'Meals, water, sleep, mood, notes and photos' : 'Tap to update',
          onTap: () => context.push(
            StaffRoutes.careReport(p.placementId),
            extra: (date: date, report: report),
          ),
          trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
        ),
        const SizedBox(height: 16),
      ],
    );
  }
}

class _PlanChangedBanner extends StatelessWidget {
  const _PlanChangedBanner({required this.changes, required this.onRead, this.onOpen});
  final List<CareChange> changes;
  final Future<bool> Function() onRead;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) => Container(
        margin: const EdgeInsets.only(bottom: 14),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFFFFBEB),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.warning, width: 1.4),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                const Icon(Icons.campaign_rounded, color: AppColors.warning),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The care plan has changed — please read it first',
                    style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                  ),
                ),
              ],
            ),
            CareChangesList(changes: changes),
            const SizedBox(height: 12),
            Row(
              children: [
                if (onOpen != null) ...[
                  Expanded(child: DsOutlineButton(label: 'Open plan', onPressed: onOpen)),
                  const SizedBox(width: 10),
                ],
                Expanded(child: DsGradientButton(label: 'Mark as read', icon: Icons.done_all_rounded, onPressed: onRead)),
              ],
            ),
          ],
        ),
      );
}

typedef _Reading = ({Map<String, dynamic> value, String? notes});

/// Number pad for a check. BP has two numbers. The reading turns red as
/// soon as it is outside the plan's range.
class _ReadingSheet extends StatefulWidget {
  const _ReadingSheet({required this.task});
  final CareTask task;

  @override
  State<_ReadingSheet> createState() => _ReadingSheetState();
}

class _ReadingSheetState extends State<_ReadingSheet> {
  final _a = TextEditingController();
  final _b = TextEditingController();
  final _notes = TextEditingController();

  @override
  void dispose() {
    _a.dispose();
    _b.dispose();
    _notes.dispose();
    super.dispose();
  }

  Widget _numberField(TextEditingController c, String label, bool outside) => TextField(
        controller: c,
        autofocus: c == _a,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.]'))],
        textAlign: TextAlign.center,
        onChanged: (_) => setState(() {}),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 34,
          fontWeight: FontWeight.w800,
          color: outside ? AppColors.error : AppColors.lightTextPrimary,
        ),
        decoration: InputDecoration(labelText: label),
      );

  @override
  Widget build(BuildContext context) {
    final t = widget.task;
    final unit = '${t.target['unit'] ?? ''}';
    final a = num.tryParse(_a.text);
    final b = num.tryParse(_b.text);
    final outside = t.isBp ? t.isOutside(sys: a, dia: b) : t.isOutside(v: a);
    final ready = t.isBp ? a != null && b != null : a != null;
    final range = t.isBp
        ? 'Safe: ${t.target['systolic_min']}–${t.target['systolic_max']} / ${t.target['diastolic_min']}–${t.target['diastolic_max']} $unit'
        : (t.target['min'] != null || t.target['max'] != null)
            ? 'Safe: ${t.target['min'] ?? '…'}–${t.target['max'] ?? '…'} $unit'
            : unit;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(t.title, style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
              Text(range, style: GoogleFonts.plusJakartaSans(fontSize: 13, color: AppColors.lightTextSecondary)),
              const SizedBox(height: 14),
              if (t.isBp)
                Row(
                  children: [
                    Expanded(child: _numberField(_a, 'Upper', outside)),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 10),
                      child: Text('/', style: GoogleFonts.plusJakartaSans(fontSize: 34, fontWeight: FontWeight.w800)),
                    ),
                    Expanded(child: _numberField(_b, 'Lower', outside)),
                  ],
                )
              else
                _numberField(_a, unit.isEmpty ? 'Reading' : 'Reading ($unit)', outside),
              if (outside) ...[
                const SizedBox(height: 10),
                const DsNote(
                  tone: DsNoteTone.danger,
                  text: 'This is outside the safe range. The family and your RM will be alerted when you save.',
                ),
              ],
              const SizedBox(height: 12),
              DsLabeledField(label: 'Note', controller: _notes, hint: 'e.g. Felt dizzy', optional: true),
              const SizedBox(height: 16),
              DsGradientButton(
                label: 'Save reading',
                icon: Icons.check_rounded,
                onPressed: !ready
                    ? null
                    : () => Navigator.of(context).pop((
                          value: t.isBp ? {'systolic': a, 'diastolic': b} : {'value': a},
                          notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
                        )),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Care plan (read-only)
// ---------------------------------------------------------------------------

class StaffCarePlanScreen extends ConsumerWidget {
  const StaffCarePlanScreen({super.key, required this.placementId});
  final String placementId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(carePlanProvider(placementId));
    return DsPage(
      title: 'Care plan',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(carePlanProvider(placementId)),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(carePlanProvider(placementId)),
        builder: (view) {
          final plan = view.plan;
          if (plan == null) {
            return const [
              DsEmptyBlock(icon: Icons.assignment_rounded, title: 'No care plan yet', message: 'The family has not written one yet.'),
            ];
          }
          final pt = plan.patient;
          String vitalLabel(CareVital v) =>
              view.vitalTypes.where((t) => t.type == v.type).firstOrNull?.label ?? v.label ?? carePretty(v.type);
          return [
            if (view.staffAcknowledgedAt == null && plan.id != null)
              _PlanChangedBanner(
                changes: plan.changes,
                onRead: () => _markPlanRead(context, ref, plan.id!),
              )
            else
              DsNote(tone: DsNoteTone.success, text: 'You have read version ${plan.version} ✓'),
            const DsSection('Patient'),
            DsInfoCard(
              lines: [
                if (pt.name != null) DsInfoLine(Icons.person_rounded, 'Name', [pt.name!, if (pt.age != null) '${pt.age} yrs'].join(', ')),
                if (pt.mobility != null) DsInfoLine(Icons.accessible_rounded, 'Mobility', carePretty(pt.mobility!)),
                if (pt.conditions.isNotEmpty) DsInfoLine(Icons.healing_rounded, 'Conditions', pt.conditions.join(', ')),
                if (pt.allergies.isNotEmpty)
                  DsInfoLine(Icons.warning_amber_rounded, 'Allergies', pt.allergies.join(', '), valueColor: AppColors.error),
                if (pt.doctorName != null)
                  DsInfoLine(Icons.local_hospital_rounded, 'Doctor', [pt.doctorName!, if (pt.doctorPhone != null) pt.doctorPhone!].join(' · ')),
                if (pt.emergencyContactName != null)
                  DsInfoLine(
                    Icons.contact_emergency_rounded,
                    'Emergency',
                    [pt.emergencyContactName!, if (pt.emergencyContactPhone != null) pt.emergencyContactPhone!].join(' · '),
                  ),
              ],
            ),
            if (plan.medications.isNotEmpty) ...[
              const DsSection('Medicines'),
              for (final m in plan.medications)
                DsListCard(
                  icon: Icons.medication_rounded,
                  title: m.summary,
                  subtitle: [
                    m.times.join(', '),
                    carePretty(m.route),
                    if (m.foodRelation != 'ANY') '${carePretty(m.foodRelation)} food',
                    if (m.instructions != null) m.instructions!,
                  ].join(' · '),
                  trailing: m.prescriptionFileId == null ? null : _PrescriptionThumb(fileId: m.prescriptionFileId!),
                ),
            ],
            if (plan.vitals.isNotEmpty) ...[
              const DsSection('Checks'),
              for (final v in plan.vitals)
                DsListCard(icon: Icons.monitor_heart_rounded, title: vitalLabel(v), subtitle: v.times.join(', ')),
            ],
            if (plan.activities.isNotEmpty) ...[
              const DsSection('Activities'),
              for (final a in plan.activities)
                DsListCard(
                  icon: Icons.directions_walk_rounded,
                  title: a.title,
                  subtitle: [a.times.join(', '), if (a.durationMin != null) '${a.durationMin} min'].join(' · '),
                ),
            ],
            if (plan.dietNotes != null || plan.dos != null || plan.donts != null) ...[
              const DsSection('Notes from the family'),
              DsInfoCard(
                lines: [
                  if (plan.dietNotes != null) DsInfoLine(Icons.restaurant_rounded, 'Diet', plan.dietNotes!),
                  if (plan.dos != null) DsInfoLine(Icons.thumb_up_alt_rounded, 'Do', plan.dos!),
                  if (plan.donts != null) DsInfoLine(Icons.block_rounded, 'Don\'t', plan.donts!, valueColor: AppColors.error),
                ],
              ),
            ],
          ];
        },
      ),
    );
  }
}

class _PrescriptionThumb extends StatelessWidget {
  const _PrescriptionThumb({required this.fileId});
  final String fileId;

  @override
  Widget build(BuildContext context) => CareFileImage(fileId: fileId, size: 44);
}

// ---------------------------------------------------------------------------
// Daily report
// ---------------------------------------------------------------------------

typedef StaffCareReportArgs = ({String date, CareReport? report});

class StaffCareReportScreen extends ConsumerStatefulWidget {
  const StaffCareReportScreen({super.key, required this.placementId, this.args});
  final String placementId;
  final StaffCareReportArgs? args;

  @override
  ConsumerState<StaffCareReportScreen> createState() => _StaffCareReportScreenState();
}

class _StaffCareReportScreenState extends ConsumerState<StaffCareReportScreen> {
  static const _sleep = ['GOOD', 'FAIR', 'POOR'];
  static const _moods = ['HAPPY', 'CALM', 'SAD', 'IRRITABLE', 'CONFUSED'];
  static const _hygiene = ['BATH', 'ORAL_CARE', 'HAIR', 'NAILS', 'CLOTHES_CHANGED'];

  late final String _date = widget.args?.date ?? careTodayIst();
  late final CareReport? _initial = widget.args?.report;
  late final Map<String, TextEditingController> _meals = {
    for (final m in CareEnums.meals)
      m: TextEditingController(text: _initial?.meals.where((x) => x.meal == m).firstOrNull?.description),
  };
  late final _water = TextEditingController(text: _initial?.fluidIntakeMl?.toString());
  late final _notes = TextEditingController(text: _initial?.notes);
  late String? _sleepValue = _initial?.sleep;
  late String? _mood = _initial?.mood;
  late final Set<String> _hygieneDone = {
    for (final e in (_initial?.hygiene ?? const <String, dynamic>{}).entries) if (e.value == true) e.key.toUpperCase(),
  };
  late final List<String> _photos = [...?_initial?.photoFileIds];
  bool _saving = false;
  bool _uploading = false;

  @override
  void dispose() {
    for (final c in [..._meals.values, _water, _notes]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _addPhoto() async {
    setState(() => _uploading = true);
    final id = await carePickAndUpload(context, ref, placementId: widget.placementId);
    if (!mounted) return;
    setState(() {
      _uploading = false;
      if (id != null) _photos.add(id);
    });
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final body = {
      'placement_id': widget.placementId,
      'date': _date,
      'meals': [
        for (final e in _meals.entries)
          if (e.value.text.trim().isNotEmpty) CareReportMeal(meal: e.key, description: e.value.text.trim()).toJson(),
      ],
      if (int.tryParse(_water.text.trim()) != null) 'fluid_intake_ml': int.parse(_water.text.trim()),
      'sleep': ?_sleepValue,
      'mood': ?_mood,
      'hygiene': {for (final h in _hygiene) h.toLowerCase(): _hygieneDone.contains(h)},
      if (_notes.text.trim().isNotEmpty) 'notes': _notes.text.trim(),
      'photo_file_ids': _photos,
    };
    final result = await ref.read(careApiProvider).saveDailyReport(body);
    if (!mounted) return;
    setState(() => _saving = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffCareTodayProvider);
        ref.invalidate(careDayProvider);
        context.showDsSnackBar('Report saved', type: DsSnackBarType.success);
        _backOrHome(context);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Widget _chips(String label, List<String> values, bool Function(String) isOn, void Function(String) onTap) => Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [for (final v in values) DsChoiceChip(label: carePretty(v), selected: isOn(v), onTap: () => onTap(v))],
            ),
          ],
        ),
      );

  @override
  Widget build(BuildContext context) => DsPage(
        title: 'Daily report',
        subtitle: _date == careTodayIst() ? 'Today' : 'Yesterday',
        onBack: () => _backOrHome(context),
        bottom: DsGradientButton(
          label: 'Save report',
          icon: Icons.save_rounded,
          isLoading: _saving,
          onPressed: _saving || _uploading ? null : _save,
        ),
        body: [
          const DsSection('Meals', top: 4),
          for (final e in _meals.entries) ...[
            DsLabeledField(
              label: carePretty(e.key),
              controller: e.value,
              icon: Icons.restaurant_rounded,
              hint: 'What and how much',
              optional: true,
              textCapitalization: TextCapitalization.sentences,
            ),
            const SizedBox(height: 10),
          ],
          DsLabeledField(
            label: 'Water (ml)',
            controller: _water,
            icon: Icons.water_drop_rounded,
            hint: 'e.g. 1500',
            optional: true,
            keyboardType: TextInputType.number,
            inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          ),
          const DsSection('How the day went'),
          _chips('Sleep', _sleep, (v) => _sleepValue == v, (v) => setState(() => _sleepValue = _sleepValue == v ? null : v)),
          _chips('Mood', _moods, (v) => _mood == v, (v) => setState(() => _mood = _mood == v ? null : v)),
          _chips('Hygiene done', _hygiene, _hygieneDone.contains,
              (v) => setState(() => _hygieneDone.contains(v) ? _hygieneDone.remove(v) : _hygieneDone.add(v))),
          DsLabeledField(
            label: 'Notes',
            controller: _notes,
            icon: Icons.edit_note_rounded,
            hint: 'Anything the family should know',
            optional: true,
            maxLines: 4,
            minLines: 3,
            textCapitalization: TextCapitalization.sentences,
          ),
          const DsSection('Photos', trailing: DsPill('Optional', color: AppColors.lightTextSecondary)),
          if (_photos.isNotEmpty) ...[
            CarePhotoStrip(fileIds: _photos, onRemove: (id) => setState(() => _photos.remove(id))),
            const SizedBox(height: 10),
          ],
          DsListCard(
            icon: Icons.add_a_photo_rounded,
            title: _uploading ? 'Uploading…' : 'Add a photo',
            subtitle: 'JPG, PNG or WebP, up to 5 MB',
            onTap: _uploading ? null : _addPhoto,
          ),
        ],
      );
}
