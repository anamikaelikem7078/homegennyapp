import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/series/series_catalog.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_request_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

/// "BEDRIDDEN" → "Bedridden", "NON_VEG" → "Non veg".
String _pretty(String raw) {
  final s = raw.replaceAll('_', ' ').toLowerCase();
  return s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);
}

List<String> _splitList(String text) =>
    [for (final p in text.split(',')) if (p.trim().isNotEmpty) p.trim()];

String _ymd(DateTime d) =>
    '${d.year.toString().padLeft(4, '0')}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

Color _statusColor(String status) => switch (status) {
      StaffRequestStatus.shortlisted => AppColors.warning,
      StaffRequestStatus.clientSelected => AppColors.primary,
      StaffRequestStatus.fulfilled => AppColors.success,
      StaffRequestStatus.cancelled => AppColors.error,
      _ => AppColors.lightTextSecondary,
    };

/// Asks for the (required) reason for "None of these" / "Cancel request".
Future<String?> _askReason(
  BuildContext context, {
  required String title,
  required String hint,
  required String confirmLabel,
}) {
  final controller = TextEditingController();
  return showModalBottomSheet<String>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (sheetContext) => Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(sheetContext).viewInsets.bottom),
      child: Container(
        decoration: const BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
        child: SafeArea(
          top: false,
          child: StatefulBuilder(
            builder: (context, setSheetState) => Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                DsLabeledField(
                  label: 'Reason',
                  controller: controller,
                  icon: Icons.edit_note_rounded,
                  hint: hint,
                  maxLines: 4,
                  minLines: 3,
                  textCapitalization: TextCapitalization.sentences,
                  onChanged: (_) => setSheetState(() {}),
                ),
                const SizedBox(height: 16),
                DsGradientButton(
                  label: confirmLabel,
                  onPressed: controller.text.trim().isEmpty
                      ? null
                      : () => Navigator.of(sheetContext).pop(controller.text.trim()),
                ),
              ],
            ),
          ),
        ),
      ),
    ),
  );
}

// ---------------------------------------------------------------------------
// Request Staff form
// ---------------------------------------------------------------------------

class ClientStaffRequestFormScreen extends ConsumerStatefulWidget {
  const ClientStaffRequestFormScreen({super.key});

  @override
  ConsumerState<ClientStaffRequestFormScreen> createState() => _ClientStaffRequestFormScreenState();
}

class _ClientStaffRequestFormScreenState extends ConsumerState<ClientStaffRequestFormScreen> {
  static const _mobility = ['WALKING', 'ASSISTED', 'BEDRIDDEN'];
  static const _medicalNeeds = ['MEDICATION', 'VITALS', 'WOUND_CARE', 'INJECTION', 'CLINICAL_ESCALATION'];
  static const _dietTypes = ['VEG', 'EGG', 'NON_VEG', 'JAIN', 'VEGAN'];
  static const _meals = ['BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER'];

  String? _series;
  String _placementType = 'PERMANENT';
  String _genderPref = 'ANY';
  int _headcount = 1;
  DateTime? _startDate;
  bool _submitting = false;

  final _shiftHours = TextEditingController(text: '8');
  final _address = TextEditingController();
  final _language = TextEditingController();
  final _notes = TextEditingController();
  final _budgetMin = TextEditingController();
  final _budgetMax = TextEditingController();

  // Care (UC / SC)
  final _patientAge = TextEditingController();
  final _conditions = TextEditingController();
  String? _mobilityValue;
  String? _patientGender;
  bool _nightCare = false;
  final Set<String> _medical = {};

  // Cook (CK)
  final _familySize = TextEditingController();
  final _cuisines = TextEditingController();
  final _healthConditions = TextEditingController();
  String? _dietType;
  final Set<String> _mealsPerDay = {};

  bool get _isCook => _series == 'CK';
  bool get _isCare => _series == 'UC' || _series == 'SC';

  @override
  void dispose() {
    for (final c in [
      _shiftHours, _address, _language, _notes, _budgetMin, _budgetMax,
      _patientAge, _conditions, _familySize, _cuisines, _healthConditions,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final picked = await showDatePicker(
      context: context,
      initialDate: _startDate ?? today,
      firstDate: today,
      lastDate: today.add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _startDate = picked);
  }

  /// Client-side checks for the required fields; the server re-checks and
  /// its message is shown as-is.
  String? _validate() {
    if (_series == null) return 'Please choose the kind of staff you need.';
    if (_isCare) {
      if (int.tryParse(_patientAge.text.trim()) == null) return 'Please enter the patient\'s age.';
      if (_mobilityValue == null) return 'Please choose how the patient moves around.';
    }
    if (_isCook) {
      if (_dietType == null) return 'Please choose the diet type.';
      if ((int.tryParse(_familySize.text.trim()) ?? 0) < 1) return 'Please enter how many people the cook feeds.';
      if (_mealsPerDay.isEmpty) return 'Please choose at least one meal.';
    }
    return null;
  }

  Map<String, dynamic> _body() {
    num? n(TextEditingController c) => num.tryParse(c.text.trim());
    String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();

    final requirements = <String, dynamic>{
      if (_isCare) ...{
        'patient_age': int.parse(_patientAge.text.trim()),
        'mobility': _mobilityValue,
        if (_patientGender != null) 'patient_gender': _patientGender,
        'conditions': _splitList(_conditions.text),
        'night_care': _nightCare,
        // Medical duties only for SC — the backend refuses them for UC.
        if (_series == 'SC') 'medical_needs': _medical.toList(),
      },
      if (_isCook) ...{
        'diet_type': _dietType,
        'family_size': int.parse(_familySize.text.trim()),
        'meals_per_day': [for (final m in _meals) if (_mealsPerDay.contains(m)) m],
        'cuisines': _splitList(_cuisines.text),
        'health_conditions': _splitList(_healthConditions.text),
      },
    };

    return {
      'series': _series,
      'placement_type': _placementType,
      'shift_hours': n(_shiftHours) ?? 8,
      if (_startDate != null) 'start_date': _ymd(_startDate!),
      if (t(_address) != null) 'address': t(_address),
      if (t(_language) != null) 'language': t(_language),
      if (t(_notes) != null) 'notes': t(_notes),
      'gender_pref': _genderPref,
      if (n(_budgetMin) != null) 'budget_min': n(_budgetMin),
      if (n(_budgetMax) != null) 'budget_max': n(_budgetMax),
      'headcount': _headcount,
      'requirements': requirements,
    };
  }

  Future<void> _submit() async {
    final problem = _validate();
    if (problem != null) {
      context.showDsSnackBar(problem, type: DsSnackBarType.warning);
      return;
    }
    setState(() => _submitting = true);
    final result = await ref.read(clientRepositoryProvider).createStaffRequest(_body());
    if (!mounted) return;
    setState(() => _submitting = false);
    result.fold(
      onSuccess: (request) {
        ref.invalidate(clientStaffRequestsProvider);
        context.showDsSnackBar('Request ${request.requestNo} sent', type: DsSnackBarType.success);
        context.pushReplacement(ClientRoutes.staffRequestDetail(request.id));
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Widget _chips<T>({
    required List<T> values,
    required bool Function(T) isSelected,
    required void Function(T) onTap,
    required String Function(T) label,
  }) =>
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          for (final v in values)
            DsChoiceChip(
              label: label(v),
              selected: isSelected(v),
              onTap: () {
                HapticFeedback.selectionClick();
                onTap(v);
              },
            ),
        ],
      );

  Widget _gap() => const SizedBox(height: 14);

  @override
  Widget build(BuildContext context) {
    final active = ref.watch(seriesCatalogProvider).active;

    return DsPage(
      title: 'Request staff',
      onBack: () => _backOrHome(context),
      bottom: DsGradientButton(
        label: 'Send request',
        icon: Icons.send_rounded,
        isLoading: _submitting,
        onPressed: _submitting ? null : _submit,
      ),
      body: [
        const DsSection('What kind of staff?', top: 4),
        for (final s in active)
          _SeriesOptionCard(
            option: s,
            selected: _series == s.short,
            onTap: () => setState(() {
              _series = s.short;
              if (s.short != 'SC') _medical.clear();
            }),
          ),
        if (_isCare) ..._careFields(),
        if (_isCook) ..._cookFields(),
        if (_series != null) ..._commonFields(),
      ],
    );
  }

  List<Widget> _careFields() => [
        const DsSection('About the patient'),
        DsLabeledField(
          label: 'Patient\'s age',
          controller: _patientAge,
          icon: Icons.cake_rounded,
          hint: 'e.g. 78',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _gap(),
        _FieldLabel('How do they move around?'),
        _chips<String>(
          values: _mobility,
          isSelected: (v) => _mobilityValue == v,
          onTap: (v) => setState(() => _mobilityValue = v),
          label: _pretty,
        ),
        _gap(),
        _FieldLabel('Patient\'s gender', optional: true),
        _chips<String>(
          values: const ['FEMALE', 'MALE'],
          isSelected: (v) => _patientGender == v,
          onTap: (v) => setState(() => _patientGender = _patientGender == v ? null : v),
          label: _pretty,
        ),
        _gap(),
        DsLabeledField(
          label: 'Health conditions',
          controller: _conditions,
          icon: Icons.healing_rounded,
          hint: 'e.g. Diabetes, Arthritis (comma separated)',
          optional: true,
          textCapitalization: TextCapitalization.words,
        ),
        _gap(),
        _SwitchRow(
          title: 'Night care needed',
          value: _nightCare,
          onChanged: (v) => setState(() => _nightCare = v),
        ),
        if (_series == 'SC') ...[
          _gap(),
          _FieldLabel('Medical duties', optional: true),
          _chips<String>(
            values: _medicalNeeds,
            isSelected: _medical.contains,
            onTap: (v) => setState(() => _medical.contains(v) ? _medical.remove(v) : _medical.add(v)),
            label: _pretty,
          ),
        ] else ...[
          _gap(),
          const DsNote(
            text: 'An Unskilled Caretaker cannot do medical duties such as medicines, '
                'injections or vitals. Choose Skilled Caretaker if you need them.',
          ),
        ],
      ];

  List<Widget> _cookFields() => [
        const DsSection('About your kitchen'),
        _FieldLabel('Diet type'),
        _chips<String>(
          values: _dietTypes,
          isSelected: (v) => _dietType == v,
          onTap: (v) => setState(() => _dietType = v),
          label: _pretty,
        ),
        _gap(),
        DsLabeledField(
          label: 'People to cook for',
          controller: _familySize,
          icon: Icons.groups_rounded,
          hint: 'e.g. 4',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _gap(),
        _FieldLabel('Meals each day'),
        _chips<String>(
          values: _meals,
          isSelected: _mealsPerDay.contains,
          onTap: (v) => setState(() => _mealsPerDay.contains(v) ? _mealsPerDay.remove(v) : _mealsPerDay.add(v)),
          label: _pretty,
        ),
        _gap(),
        DsLabeledField(
          label: 'Cuisines',
          controller: _cuisines,
          icon: Icons.restaurant_menu_rounded,
          hint: 'e.g. North Indian, South Indian',
          optional: true,
          textCapitalization: TextCapitalization.words,
        ),
        _gap(),
        DsLabeledField(
          label: 'Health needs',
          controller: _healthConditions,
          icon: Icons.favorite_rounded,
          hint: 'e.g. Diabetic, Low sodium',
          optional: true,
          textCapitalization: TextCapitalization.words,
        ),
      ];

  List<Widget> _commonFields() => [
        const DsSection('Work details'),
        _FieldLabel('Type of work'),
        _chips<String>(
          values: const ['PERMANENT', 'TEMPORARY'],
          isSelected: (v) => _placementType == v,
          onTap: (v) => setState(() => _placementType = v),
          label: (v) => v == 'TEMPORARY' ? 'Temporary (hourly)' : 'Permanent',
        ),
        _gap(),
        DsLabeledField(
          label: 'Hours per day',
          controller: _shiftHours,
          icon: Icons.schedule_rounded,
          hint: '8',
          keyboardType: TextInputType.number,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        ),
        _gap(),
        _FieldLabel('Start date', optional: true),
        DsListCard(
          icon: Icons.event_rounded,
          title: _startDate == null ? 'Choose a date' : _ymd(_startDate!),
          subtitle: _startDate == null ? 'As soon as possible' : 'Tap to change',
          onTap: _pickDate,
        ),
        _FieldLabel('How many staff?'),
        _Stepper(
          value: _headcount,
          min: 1,
          max: 20,
          onChanged: (v) => setState(() => _headcount = v),
        ),
        _gap(),
        _FieldLabel('Staff gender'),
        _chips<String>(
          values: const ['ANY', 'FEMALE', 'MALE'],
          isSelected: (v) => _genderPref == v,
          onTap: (v) => setState(() => _genderPref = v),
          label: (v) => v == 'ANY' ? 'No preference' : _pretty(v),
        ),
        _gap(),
        DsLabeledField(
          label: 'Language',
          controller: _language,
          icon: Icons.translate_rounded,
          hint: 'e.g. Hindi',
          optional: true,
          textCapitalization: TextCapitalization.words,
        ),
        const DsSection('Budget (₹ per month)', trailing: DsPill('Optional', color: AppColors.lightTextSecondary)),
        Row(
          children: [
            Expanded(
              child: DsLabeledField(
                label: 'From',
                controller: _budgetMin,
                hint: '15000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: DsLabeledField(
                label: 'To',
                controller: _budgetMax,
                hint: '20000',
                keyboardType: TextInputType.number,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              ),
            ),
          ],
        ),
        const DsSection('Anything else'),
        DsLabeledField(
          label: 'Address',
          controller: _address,
          icon: Icons.home_rounded,
          hint: 'Leave empty to use your saved address',
          optional: true,
          maxLines: 2,
        ),
        _gap(),
        DsLabeledField(
          label: 'Notes for your RM',
          controller: _notes,
          icon: Icons.edit_note_rounded,
          hint: 'e.g. Father needs help walking',
          optional: true,
          maxLines: 4,
          minLines: 3,
          textCapitalization: TextCapitalization.sentences,
        ),
      ];
}

class _SeriesOptionCard extends StatelessWidget {
  const _SeriesOptionCard({required this.option, required this.selected, required this.onTap});
  final SeriesOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final subtitle = switch (option.short) {
      'UC' => 'Daily help: bathing, walking, meals, company',
      'SC' => 'Trained nurse: medicines, vitals, wound care',
      'CK' => 'Home cook for your family\'s meals',
      _ => option.short,
    };
    return DsListCard(
      icon: SeriesDisplay.icon(option.value),
      iconColor: SeriesDisplay.color(option.value),
      title: option.label,
      subtitle: subtitle,
      onTap: onTap,
      trailing: Icon(
        selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
        color: selected ? AppColors.primary : AppColors.lightBorder,
      ),
    );
  }
}

class _FieldLabel extends StatelessWidget {
  const _FieldLabel(this.text, {this.optional = false});
  final String text;
  final bool optional;

  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(bottom: 8),
        child: Text(
          optional ? '$text (optional)' : text,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: AppColors.lightTextPrimary,
          ),
        ),
      );
}

class _SwitchRow extends StatelessWidget {
  const _SwitchRow({required this.title, required this.value, required this.onChanged});
  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        decoration: dsCardDecoration(),
        child: Row(
          children: [
            const DsIconTile(Icons.nightlight_round, size: 36),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            Switch.adaptive(value: value, onChanged: onChanged),
          ],
        ),
      );
}

class _Stepper extends StatelessWidget {
  const _Stepper({required this.value, required this.min, required this.max, required this.onChanged});
  final int value;
  final int min;
  final int max;
  final ValueChanged<int> onChanged;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
        decoration: dsCardDecoration(),
        child: Row(
          children: [
            IconButton(
              tooltip: 'Fewer',
              onPressed: value > min ? () => onChanged(value - 1) : null,
              icon: const Icon(Icons.remove_circle_outline_rounded),
            ),
            Expanded(
              child: Text(
                '$value',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                ),
              ),
            ),
            IconButton(
              tooltip: 'More',
              onPressed: value < max ? () => onChanged(value + 1) : null,
              icon: const Icon(Icons.add_circle_outline_rounded),
            ),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// My Requests list
// ---------------------------------------------------------------------------

class ClientStaffRequestsScreen extends ConsumerWidget {
  const ClientStaffRequestsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final requests = ref.watch(clientStaffRequestsProvider);

    return DsPage(
      title: 'My staff requests',
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(clientStaffRequestsProvider),
      bottom: DsGradientButton(
        label: 'Request staff',
        icon: Icons.person_add_alt_1_rounded,
        onPressed: () => context.push(ClientRoutes.staffRequestNew),
      ),
      body: dsAsyncBody(
        requests,
        onRetry: () => ref.invalidate(clientStaffRequestsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.person_search_rounded,
                title: 'No requests yet',
                message: 'Ask for a caretaker or a cook, and your relationship manager will find the right person.',
              ),
            ];
          }
          return [for (final r in items) _RequestListCard(request: r)];
        },
      ),
    );
  }
}

class _RequestListCard extends StatelessWidget {
  const _RequestListCard({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final color = _statusColor(r.status);
    return GestureDetector(
      onTap: () => context.push(ClientRoutes.staffRequestDetail(r.id)),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(16),
        decoration: dsCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                DsIconTile(SeriesDisplay.icon(r.series), color: SeriesDisplay.color(r.series)),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        r.headcount > 1
                            ? '${SeriesDisplay.label(r.series)} × ${r.headcount}'
                            : SeriesDisplay.label(r.series),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                          color: AppColors.lightTextPrimary,
                        ),
                      ),
                      Text(
                        r.requestNo,
                        style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                      ),
                    ],
                  ),
                ),
                DsPill(StaffRequestStatus.label(r.status), color: color),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              StaffRequestStatus.message(r.status),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextSecondary,
              ),
            ),
            if (r.shortlistedCount > 0 && r.canChoose) ...[
              const SizedBox(height: 10),
              DsPill(
                r.shortlistedCount == 1 ? '1 staff to choose from' : '${r.shortlistedCount} staff to choose from',
                color: AppColors.warning,
                icon: Icons.how_to_reg_rounded,
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Request detail
// ---------------------------------------------------------------------------

class ClientStaffRequestDetailScreen extends ConsumerStatefulWidget {
  const ClientStaffRequestDetailScreen({super.key, required this.requestId});
  final String requestId;

  @override
  ConsumerState<ClientStaffRequestDetailScreen> createState() => _ClientStaffRequestDetailScreenState();
}

class _ClientStaffRequestDetailScreenState extends ConsumerState<ClientStaffRequestDetailScreen> {
  bool _busy = false;

  void _refresh() {
    ref.invalidate(clientStaffRequestProvider(widget.requestId));
    ref.invalidate(clientStaffRequestsProvider);
  }

  Future<void> _run(Future<Result<void>> Function() action, String success) async {
    setState(() => _busy = true);
    final result = await action();
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar(success, type: DsSnackBarType.success);
        _refresh();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _choose(CandidateStaff staff) async {
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Choose ${staff.firstName}?',
      message: 'Your relationship manager will set up a trial with ${staff.firstName}.',
      confirmLabel: 'Choose',
      icon: Icons.how_to_reg_rounded,
    );
    if (ok != true || !mounted) return;
    await _run(
      // Send the staff id, not the candidate id.
      () => ref.read(clientRepositoryProvider).selectStaffForRequest(widget.requestId, staffId: staff.id),
      'You chose ${staff.firstName}',
    );
  }

  Future<void> _noneOfThese() async {
    final reason = await _askReason(
      context,
      title: 'None of these?',
      hint: 'Tell your RM what you are looking for instead',
      confirmLabel: 'Send to my RM',
    );
    if (reason == null || !mounted) return;
    await _run(
      () => ref.read(clientRepositoryProvider).rejectStaffRequestShortlist(widget.requestId, reason),
      'Your RM will look for other staff',
    );
  }

  Future<void> _cancel() async {
    final reason = await _askReason(
      context,
      title: 'Cancel this request?',
      hint: 'Why are you cancelling?',
      confirmLabel: 'Cancel request',
    );
    if (reason == null || !mounted) return;
    await _run(
      () => ref.read(clientRepositoryProvider).cancelStaffRequest(widget.requestId, reason),
      'Request cancelled',
    );
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(clientStaffRequestProvider(widget.requestId));
    final request = async.valueOrNull;

    return DsPage(
      title: request?.requestNo ?? 'Staff request',
      onBack: () => _backOrHome(context),
      onRefresh: () async => _refresh(),
      bottom: request != null && request.canChoose
          ? DsOutlineButton(
              label: 'None of these',
              icon: Icons.thumb_down_alt_outlined,
              onPressed: _busy ? null : _noneOfThese,
            )
          : null,
      body: dsAsyncBody(
        async,
        onRetry: _refresh,
        builder: (r) => [
          _StatusCard(request: r),
          if (r.rm != null && (r.rm!.name != null || r.rm!.phone != null)) ...[
            const DsSection('Your relationship manager'),
            DsListCard(
              icon: Icons.support_agent_rounded,
              title: r.rm!.name ?? 'Relationship manager',
              subtitle: r.rm!.phone,
              trailing: r.rm!.phone == null
                  ? null
                  : IconButton(
                      tooltip: 'Call',
                      icon: const Icon(Icons.call_rounded, color: AppColors.primary),
                      onPressed: () => CommunicationHelper.makePhoneCall(
                        context,
                        r.rm!.phone!,
                        recipientName: r.rm!.name,
                      ),
                    ),
            ),
          ],
          if (r.candidates.isNotEmpty) ...[
            DsSection(
              r.canChoose ? 'Choose your staff' : 'Staff put forward',
              trailing: DsPill('${r.candidates.length}'),
            ),
            for (final c in r.candidates)
              _CandidateCard(
                candidate: c,
                canChoose: r.canChoose && !_busy,
                onChoose: () => _choose(c.staff),
              ),
          ],
          const DsSection('What you asked for'),
          _AskedFor(request: r),
          if (r.isOpen) ...[
            const SizedBox(height: 18),
            Center(
              child: TextButton.icon(
                onPressed: _busy ? null : _cancel,
                icon: const Icon(Icons.close_rounded, color: AppColors.error),
                label: Text(
                  'Cancel request',
                  style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.error),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final color = _statusColor(r.status);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsIconTile(SeriesDisplay.icon(r.series), color: SeriesDisplay.color(r.series)),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  SeriesDisplay.label(r.series),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              DsPill(StaffRequestStatus.label(r.status), color: color),
            ],
          ),
          const SizedBox(height: 12),
          DsNote(
            tone: switch (r.status) {
              StaffRequestStatus.fulfilled => DsNoteTone.success,
              StaffRequestStatus.cancelled => DsNoteTone.danger,
              StaffRequestStatus.shortlisted => DsNoteTone.warning,
              _ => DsNoteTone.info,
            },
            text: r.status == StaffRequestStatus.cancelled && (r.cancelReason ?? '').isNotEmpty
                ? 'Cancelled — ${r.cancelReason}'
                : StaffRequestStatus.message(r.status),
          ),
        ],
      ),
    );
  }
}

class _CandidateCard extends StatelessWidget {
  const _CandidateCard({required this.candidate, required this.canChoose, required this.onChoose});
  final StaffRequestCandidate candidate;
  final bool canChoose;
  final VoidCallback onChoose;

  @override
  Widget build(BuildContext context) {
    final s = candidate.staff;
    final facts = [
      SeriesDisplay.label(s.series),
      if (s.experienceYears != null) '${s.experienceYears} yrs experience',
      if (s.gender != null) _pretty(s.gender!),
      if (s.languageTier != null) 'Language ${s.languageTier}',
    ];
    final (statusLabel, statusColor) = switch (candidate.status) {
      StaffRequestCandidateStatus.clientSelected => ('You chose', AppColors.primary),
      StaffRequestCandidateStatus.placed => ('Placed', AppColors.success),
      StaffRequestCandidateStatus.clientRejected => ('Not chosen', AppColors.lightTextSecondary),
      _ => (null, AppColors.lightTextSecondary),
    };
    final showChoose = canChoose && candidate.status == StaffRequestCandidateStatus.proposed;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              DsInitialsAvatar(name: s.firstName, size: 44),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      s.firstName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                    Text(
                      facts.join(' · '),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
                    ),
                  ],
                ),
              ),
              if (statusLabel != null) DsPill(statusLabel, color: statusColor),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              DsPill(
                s.aadhaarVerified ? 'Aadhaar verified' : 'Aadhaar pending',
                color: s.aadhaarVerified ? AppColors.success : AppColors.lightTextSecondary,
                icon: s.aadhaarVerified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
              ),
              DsPill(
                s.policeVerified ? 'Police verified' : 'Police check pending',
                color: s.policeVerified ? AppColors.success : AppColors.lightTextSecondary,
                icon: s.policeVerified ? Icons.verified_user_rounded : Icons.hourglass_top_rounded,
              ),
            ],
          ),
          if ((candidate.rmNote ?? '').isNotEmpty) ...[
            const SizedBox(height: 10),
            Text(
              '“${candidate.rmNote}” — your RM',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                fontStyle: FontStyle.italic,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ],
          if (showChoose) ...[
            const SizedBox(height: 12),
            DsGradientButton(label: 'Choose', icon: Icons.how_to_reg_rounded, onPressed: onChoose),
          ],
        ],
      ),
    );
  }
}

class _AskedFor extends StatelessWidget {
  const _AskedFor({required this.request});
  final StaffRequest request;

  @override
  Widget build(BuildContext context) {
    final r = request;
    final q = r.requirements;
    String list(Object? v) => v is List ? v.map((e) => _pretty('$e')).join(', ') : '';
    final budget = r.budgetMin != null || r.budgetMax != null
        ? '₹${r.budgetMin ?? '…'} – ₹${r.budgetMax ?? '…'} / month'
        : null;

    return DsInfoCard(
      lines: [
        DsInfoLine(Icons.badge_rounded, 'Staff', '${SeriesDisplay.label(r.series)} × ${r.headcount}'),
        DsInfoLine(
          Icons.work_history_rounded,
          'Work',
          '${r.placementType == 'TEMPORARY' ? 'Temporary (hourly)' : 'Permanent'} · ${r.shiftHours} hrs/day',
        ),
        if (r.startDate != null) DsInfoLine(Icons.event_rounded, 'Start', r.startDate!),
        if (r.genderPref != 'ANY') DsInfoLine(Icons.wc_rounded, 'Staff gender', _pretty(r.genderPref)),
        if ((r.language ?? '').isNotEmpty) DsInfoLine(Icons.translate_rounded, 'Language', r.language!),
        if (budget != null) DsInfoLine(Icons.currency_rupee_rounded, 'Budget', budget),
        if (q['patient_age'] != null) DsInfoLine(Icons.cake_rounded, 'Patient age', '${q['patient_age']}'),
        if (q['mobility'] != null) DsInfoLine(Icons.accessible_rounded, 'Mobility', _pretty('${q['mobility']}')),
        if (list(q['conditions']).isNotEmpty) DsInfoLine(Icons.healing_rounded, 'Conditions', list(q['conditions'])),
        if (list(q['medical_needs']).isNotEmpty)
          DsInfoLine(Icons.medical_services_rounded, 'Medical duties', list(q['medical_needs'])),
        if (q['night_care'] == true) const DsInfoLine(Icons.nightlight_round, 'Night care', 'Yes'),
        if (q['diet_type'] != null) DsInfoLine(Icons.restaurant_rounded, 'Diet', _pretty('${q['diet_type']}')),
        if (q['family_size'] != null) DsInfoLine(Icons.groups_rounded, 'People', '${q['family_size']}'),
        if (list(q['meals_per_day']).isNotEmpty)
          DsInfoLine(Icons.lunch_dining_rounded, 'Meals', list(q['meals_per_day'])),
        if (list(q['cuisines']).isNotEmpty) DsInfoLine(Icons.restaurant_menu_rounded, 'Cuisines', list(q['cuisines'])),
        if (list(q['health_conditions']).isNotEmpty)
          DsInfoLine(Icons.favorite_rounded, 'Health needs', list(q['health_conditions'])),
        if ((r.address ?? '').isNotEmpty) DsInfoLine(Icons.home_rounded, 'Address', r.address!),
        if ((r.notes ?? '').isNotEmpty) DsInfoLine(Icons.edit_note_rounded, 'Notes', r.notes!),
      ],
    );
  }
}
