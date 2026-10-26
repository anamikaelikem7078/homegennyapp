part of 'client_staff_request_screens.dart';

// ---------------------------------------------------------------------------
// Request Staff — a booking in five steps:
// kind → when & how long → needs → address → review & send.
// ---------------------------------------------------------------------------

/// One row of a regular cook's optional weekly menu.
class _WeeklyRow {
  String dow = 'MON';
  String meal = 'LUNCH';
  List<PickedDish> dishes = [];
}

class ClientStaffRequestFormScreen extends ConsumerStatefulWidget {
  const ClientStaffRequestFormScreen({super.key});

  @override
  ConsumerState<ClientStaffRequestFormScreen> createState() => _ClientStaffRequestFormScreenState();
}

class _ClientStaffRequestFormScreenState extends ConsumerState<ClientStaffRequestFormScreen> {
  static const _steps = ['Kind of help', 'When', 'Needs', 'Address', 'Review'];
  static const _mobility = ['WALKING', 'ASSISTED', 'BEDRIDDEN'];
  static const _medicalNeeds = ['MEDICATION', 'VITALS', 'WOUND_CARE', 'INJECTION', 'CLINICAL_ESCALATION'];
  static const _dietTypes = ['VEG', 'EGG', 'NON_VEG', 'JAIN'];
  static const _meals = ['BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER'];

  /// "Meals each day" is one pick from these ready-made combos.
  static const _mealCombos = [
    ['BREAKFAST'],
    ['LUNCH'],
    ['DINNER'],
    ['BREAKFAST', 'LUNCH'],
    ['LUNCH', 'DINNER'],
    ['BREAKFAST', 'LUNCH', 'DINNER'],
  ];

  int _step = 0;
  bool _submitting = false;

  // Step 1
  String? _visitType;
  String? _series;

  // Step 2
  DateTime? _startDate;
  TimeOfDay? _startTime;
  String _placementType = 'PERMANENT';
  // 24×7 live-in: a permanent placement on a 24-hour duty — the staff member
  // stays at the home round the clock and is billed per duty. Sent as
  // PERMANENT with shift_hours 24, which the server reads as live-in.
  bool _liveIn = false;
  String _genderPref = 'ANY';
  int _headcount = 1;
  final _shiftHours = TextEditingController(text: '8');
  final _language = TextEditingController();

  // Step 3 — care (UC / SC)
  final _patientName = TextEditingController();
  final _patientAge = TextEditingController();
  final _conditions = TextEditingController();
  String? _mobilityValue;
  String? _patientGender;
  bool _nightCare = false;
  final Set<String> _medical = {};
  final CarePlan _careNeeds = CarePlan();
  final _dietNotes = TextEditingController();
  final _dos = TextEditingController();
  final _donts = TextEditingController();

  // Step 3 — cook (CK)
  final _familySize = TextEditingController();
  final _cuisines = TextEditingController();
  final _healthConditions = TextEditingController();
  String? _dietType;
  final Set<String> _mealsPerDay = {};
  List<PickedDish> _visitDishes = [];
  String? _visitMeal;
  final _instruction = TextEditingController();
  bool _weeklyMenuOn = false;
  final List<_WeeklyRow> _weekly = [];

  // Step 4
  final _address = TextEditingController();
  final _notes = TextEditingController();
  LatLng? _pin;

  bool get _isCook => _series == 'CK';
  bool get _isCare => _series == 'UC' || _series == 'SC';
  bool get _isUc => _series == 'UC';
  bool get _oneTime => _visitType == VisitType.oneTime;

  String? get _startHhmm => _startTime == null ? null : _hhmm(_startTime!);

  /// The visit's meal: the user's pick, else what the server would pick.
  String get _mealForVisit => _visitMeal ?? BookingRules.mealForTime(_startHhmm ?? '12:00');

  @override
  void initState() {
    super.initState();
    _prefillAddress();
  }

  /// The client only confirms or edits their saved address.
  Future<void> _prefillAddress() async {
    try {
      final profile = await ref.read(clientProfileProvider.future);
      final saved = [profile.address, profile.city, profile.pincode].where((s) => s.trim().isNotEmpty).join(', ');
      if (mounted && _address.text.trim().isEmpty && saved.isNotEmpty) _address.text = saved;
    } catch (_) {
      // No saved address — the client types it.
    }
  }

  @override
  void dispose() {
    for (final c in [
      _shiftHours, _language, _patientName, _patientAge, _conditions, _dietNotes, _dos, _donts,
      _familySize, _cuisines, _healthConditions, _instruction, _address, _notes,
    ]) {
      c.dispose();
    }
    super.dispose();
  }

  // ── Pickers ──

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

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _startTime ?? const TimeOfDay(hour: 9, minute: 0),
    );
    if (picked != null) setState(() => _startTime = picked);
  }

  Future<void> _pickPin() async {
    final pin = await pickMapPin(context, initial: _pin);
    if (pin != null) setState(() => _pin = pin);
  }

  Future<void> _editMedicine([CareMedication? existing]) async {
    final edited = await showModalBottomSheet<CareMedication>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      // No placement yet → the sheet hides the prescription upload.
      builder: (_) => CareMedicineSheet(initial: existing),
    );
    if (edited == null) return;
    setState(() {
      final list = _careNeeds.medications;
      existing == null ? list.add(edited) : list[list.indexOf(existing)] = edited;
    });
  }

  Future<void> _editVital([CareVital? existing]) async {
    final edited = await showModalBottomSheet<CareVital>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CareVitalSheet(types: VitalType.fallback, initial: existing),
    );
    if (edited == null) return;
    setState(() {
      final list = _careNeeds.vitals;
      existing == null ? list.add(edited) : list[list.indexOf(existing)] = edited;
    });
  }

  Future<void> _editActivity([CareActivity? existing]) async {
    final edited = await showModalBottomSheet<CareActivity>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => CareActivitySheet(initial: existing),
    );
    if (edited == null) return;
    setState(() {
      final list = _careNeeds.activities;
      existing == null ? list.add(edited) : list[list.indexOf(existing)] = edited;
    });
  }

  // ── Validation (the server re-checks; its message is shown as-is) ──

  String? _validateStep(int step) {
    switch (step) {
      case 0:
        if (_visitType == null) return 'Please choose a one-time visit or regular staff.';
        if (_series == null) return 'Please choose the kind of staff you need.';
      case 1:
        if (_startDate == null) return 'Please choose the date.';
        if (_startTime == null) return 'Please choose the time.';
        final now = DateTime.now();
        final start = DateTime(_startDate!.year, _startDate!.month, _startDate!.day, _startTime!.hour, _startTime!.minute);
        if (start.isBefore(now)) return 'That time has already passed today.';
        if (!_oneTime && !_liveIn) {
          final hours = int.tryParse(_shiftHours.text.trim()) ?? 0;
          if (hours < 1) return 'Please enter the hours per day.';
          if (hours > 24) return 'A day has 24 hours — for round-the-clock staff choose 24×7 Live-in.';
        }
      case 2:
        if (_isCare) {
          if (int.tryParse(_patientAge.text.trim()) == null) return 'Please enter the patient\'s age.';
          if (_mobilityValue == null) return 'Please choose how the patient moves around.';
        }
        if (_isCook) {
          if (_dietType == null) return 'Please choose the diet type.';
          if ((int.tryParse(_familySize.text.trim()) ?? 0) < 1) return 'Please enter how many people the cook feeds.';
          if (_mealsPerDay.isEmpty) return 'Please choose at least one meal.';
          if (_oneTime && _visitDishes.isEmpty) return 'Please add at least one dish for the visit.';
        }
      case 3:
        if (_address.text.trim().length < 5) return 'Please enter the address where the staff will work.';
    }
    return null;
  }

  void _next() {
    final problem = _validateStep(_step);
    if (problem != null) {
      context.showDsSnackBar(problem, type: DsSnackBarType.warning);
      return;
    }
    if (_step == _steps.length - 1) {
      _submit();
    } else {
      setState(() => _step++);
    }
  }

  void _back() {
    if (_step == 0) {
      _backOrHome(context);
    } else {
      setState(() => _step--);
    }
  }

  // ── Body ──

  Map<String, dynamic>? _menuBody() {
    if (!_isCook) return null;
    if (_oneTime) {
      final split = splitPickedDishes(_visitDishes);
      return {
        if (split.ids.isNotEmpty) 'dish_ids': split.ids,
        if (split.typed.isNotEmpty) 'dishes': split.typed,
        'meal': _mealForVisit,
        if (_instruction.text.trim().isNotEmpty) 'special_instruction': _instruction.text.trim(),
      };
    }
    final rows = [for (final r in _weekly) if (_weeklyMenuOn && r.dishes.isNotEmpty) r];
    if (rows.isEmpty) return null;
    return {
      'items': [
        for (final r in rows)
          () {
            final split = splitPickedDishes(r.dishes);
            return WeeklyMenuEntry(dow: r.dow, meal: r.meal, dishIds: split.ids).toJson(typed: split.typed);
          }(),
      ],
    };
  }

  Map<String, dynamic>? _careNeedsBody() {
    if (!_isCare) return null;
    String? t(TextEditingController c) => c.text.trim().isEmpty ? null : c.text.trim();
    final p = _careNeeds;
    p.patient
      ..name = t(_patientName)
      ..age = num.tryParse(_patientAge.text.trim())
      ..gender = _patientGender
      ..mobility = _mobilityValue
      ..conditions = _splitList(_conditions.text);
    p
      ..dietNotes = t(_dietNotes)
      ..dos = t(_dos)
      ..donts = t(_donts);
    if (_isUc) {
      // An Unskilled Caretaker can't give medicines or take vitals.
      p.medications.clear();
      p.vitals.clear();
    }
    final hasNeeds = p.patient.name != null ||
        p.medications.isNotEmpty ||
        p.vitals.isNotEmpty ||
        p.activities.isNotEmpty ||
        p.dietNotes != null ||
        p.dos != null ||
        p.donts != null;
    return hasNeeds ? p.toJson() : null;
  }

  Map<String, dynamic> _body() {
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
    final menu = _menuBody();
    final careNeeds = _careNeedsBody();

    return {
      'series': _series,
      'visit_type': _visitType,
      'start_date': _ymd(_startDate!),
      'start_time': _startHhmm,
      // One-time: no duration from the client — the cook sets how long the
      // visit takes. Regular staff send their placement type and hours.
      if (!_oneTime) ...{
        'placement_type': _liveIn ? 'PERMANENT' : _placementType,
        'shift_hours': _liveIn ? 24 : (num.tryParse(_shiftHours.text.trim()) ?? 8),
      },
      'address': _address.text.trim(),
      if (_pin != null) ...{'lat': _pin!.latitude, 'lng': _pin!.longitude},
      if (t(_language) != null) 'language': t(_language),
      if (t(_notes) != null) 'notes': t(_notes),
      'gender_pref': _genderPref,
      'headcount': _headcount,
      'requirements': requirements,
      'menu': ?menu,
      'care_needs': ?careNeeds,
    };
  }

  Future<void> _submit() async {
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

  // ── UI ──

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
    final last = _step == _steps.length - 1;
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) setState(() => _step--);
      },
      child: DsPage(
        title: 'Request staff',
        subtitle: 'Step ${_step + 1} of ${_steps.length} · ${_steps[_step]}',
        onBack: _back,
        bottom: DsGradientButton(
          label: last ? 'Send request' : 'Next',
          icon: last ? Icons.send_rounded : Icons.arrow_forward_rounded,
          isLoading: _submitting,
          onPressed: _submitting ? null : _next,
        ),
        body: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: LinearProgressIndicator(
              value: (_step + 1) / _steps.length,
              minHeight: 6,
              backgroundColor: AppColors.lightBorder,
            ),
          ),
          ...switch (_step) {
            0 => _kindStep(),
            1 => _whenStep(),
            2 => _needsStep(),
            3 => _addressStep(),
            _ => _reviewStep(),
          },
        ],
      ),
    );
  }

  // Step 1
  List<Widget> _kindStep() {
    final active = ref.watch(seriesCatalogProvider).active;
    return [
      const DsSection('What kind of help?'),
      _ChoiceCard(
        icon: Icons.event_available_rounded,
        title: 'One-time visit',
        subtitle: 'A cook for a dinner party, a caretaker for an afternoon',
        selected: _visitType == VisitType.oneTime,
        onTap: () => setState(() => _visitType = VisitType.oneTime),
      ),
      _ChoiceCard(
        icon: Icons.autorenew_rounded,
        title: 'Regular staff',
        subtitle: 'Comes every day',
        selected: _visitType == VisitType.regular,
        onTap: () => setState(() => _visitType = VisitType.regular),
      ),
      const DsSection('Who do you need?'),
      for (final s in active)
        _SeriesOptionCard(
          option: s,
          selected: _series == s.short,
          onTap: () => setState(() {
            _series = s.short;
            if (s.short != 'SC') _medical.clear();
          }),
        ),
    ];
  }

  // Step 2
  List<Widget> _whenStep() => [
        DsSection(_oneTime ? 'Visit date & time' : 'Start date & time'),
        _PickerLabel(icon: Icons.event_rounded, label: 'Date', action: 'Calendar', onAction: _pickDate),
        const SizedBox(height: 8),
        _DateStrip(selected: _startDate, onPick: (d) => setState(() => _startDate = d)),
        const SizedBox(height: 18),
        _PickerLabel(icon: Icons.schedule_rounded, label: 'Time', action: 'Other time', onAction: _pickTime),
        const SizedBox(height: 8),
        _TimeSlots(
          date: _startDate,
          selected: _startTime,
          onPick: (t) => setState(() => _startTime = t),
        ),
        if (_startDate != null || _startTime != null) ...[
          const SizedBox(height: 12),
          _WhenSummary(
            text: [
              _startDate == null ? 'Pick a date' : _weekdayDayMonth(_startDate!),
              _startHhmm == null ? 'pick a time' : _time12(_startHhmm!),
            ].join(' · '),
            complete: _startDate != null && _startTime != null,
          ),
        ],
        // One-time visits have no duration: the cook sets the time.
        if (!_oneTime) ...[
          const DsSection('Work schedule'),
          _chips<String>(
            values: const ['PERMANENT', 'LIVE_IN', 'TEMPORARY'],
            isSelected: (v) => v == 'LIVE_IN' ? _liveIn : (!_liveIn && _placementType == v),
            onTap: (v) => setState(() {
              if (v == 'LIVE_IN') {
                _liveIn = true;
                _placementType = 'PERMANENT';
              } else {
                _liveIn = false;
                _placementType = v;
              }
            }),
            label: (v) => switch (v) {
              'TEMPORARY' => 'Hourly',
              'LIVE_IN' => '24×7 Live-in',
              _ => 'Permanent (monthly)',
            },
          ),
          _gap(),
          if (_liveIn)
            const _LiveInNote()
          else
            DsLabeledField(
              label: 'Hours per day',
              controller: _shiftHours,
              icon: Icons.timelapse_rounded,
              hint: '8',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
        ],
        const DsSection('Staff'),
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
      ];

  // Step 3
  List<Widget> _needsStep() => [
        if (_isCare) ..._careFields(),
        if (_isCook) ..._cookFields(),
      ];

  List<Widget> _careFields() => [
        const DsSection('About the patient'),
        DsLabeledField(
          label: 'Patient\'s name',
          controller: _patientName,
          icon: Icons.person_rounded,
          hint: 'e.g. Papa',
          optional: true,
          textCapitalization: TextCapitalization.words,
        ),
        _gap(),
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
        ],
        const DsSection('Care needs', trailing: DsPill('Optional', color: AppColors.lightTextSecondary)),
        const DsNote(text: 'Add what the caretaker should do each day. It becomes the care plan once your booking is confirmed.'),
        if (_isUc) ...[
          const SizedBox(height: 10),
          const DsNote(
            tone: DsNoteTone.warning,
            text: 'An Unskilled Caretaker cannot give medicines or take vitals. '
                'Choose Skilled Caretaker if you need them.',
          ),
        ] else ...[
          DsSection('Medicines', trailing: DsPill('${_careNeeds.medications.length}')),
          for (final m in _careNeeds.medications)
            CareItemCard(
              icon: Icons.medication_rounded,
              title: m.summary,
              subtitle: [
                m.times.join(', '),
                if (m.foodRelation != 'ANY') '${carePretty(m.foodRelation)} food',
              ].join(' · '),
              onEdit: () => _editMedicine(m),
              onRemove: () => setState(() => _careNeeds.medications.remove(m)),
            ),
          CareAddButton(label: 'Add medicine', onTap: () => _editMedicine()),
          const DsNote(text: 'You can add the prescription after the booking is confirmed.'),
          DsSection('Checks', trailing: DsPill('${_careNeeds.vitals.length}')),
          for (final v in _careNeeds.vitals)
            CareItemCard(
              icon: Icons.monitor_heart_rounded,
              title: VitalType.fallback.where((t) => t.type == v.type).firstOrNull?.label ?? carePretty(v.type),
              subtitle: v.times.join(', '),
              onEdit: () => _editVital(v),
              onRemove: () => setState(() => _careNeeds.vitals.remove(v)),
            ),
          CareAddButton(label: 'Add check (BP, sugar…)', onTap: () => _editVital()),
        ],
        DsSection('Activities', trailing: DsPill('${_careNeeds.activities.length}')),
        for (final a in _careNeeds.activities)
          CareItemCard(
            icon: Icons.directions_walk_rounded,
            title: a.title.isEmpty ? carePretty(a.type) : a.title,
            subtitle: [a.times.join(', '), if (a.durationMin != null) '${a.durationMin} min'].join(' · '),
            onEdit: () => _editActivity(a),
            onRemove: () => setState(() => _careNeeds.activities.remove(a)),
          ),
        CareAddButton(label: 'Add activity', onTap: () => _editActivity()),
        _gap(),
        DsLabeledField(label: 'Diet', controller: _dietNotes, icon: Icons.restaurant_rounded, hint: 'e.g. Low salt', optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),
        _gap(),
        DsLabeledField(label: 'Do', controller: _dos, icon: Icons.thumb_up_alt_rounded, hint: 'e.g. Help him walk to the balcony', optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),
        _gap(),
        DsLabeledField(label: 'Don\'t', controller: _donts, icon: Icons.block_rounded, hint: 'e.g. No sugar in tea', optional: true, maxLines: 3, textCapitalization: TextCapitalization.sentences),
      ];

  List<Widget> _cookFields() => [
        const DsSection('About your kitchen'),
        _FieldLabel('Diet type'),
        _chips<String>(
          values: _dietTypes,
          isSelected: (v) => _dietType == v,
          onTap: (v) => setState(() => _dietType = v),
          label: _dietLabel,
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
        _chips<List<String>>(
          values: _mealCombos,
          isSelected: (combo) => _mealsPerDay.length == combo.length && _mealsPerDay.containsAll(combo),
          onTap: (combo) => setState(() => _mealsPerDay
            ..clear()
            ..addAll(combo)),
          label: (combo) => combo.map(_pretty).join(' + '),
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
        if (_oneTime) ..._visitMenuFields() else ..._weeklyMenuFields(),
      ];

  List<Widget> _visitMenuFields() => [
        DsSection('${_pretty(_mealForVisit)} menu', trailing: DsPill('${_visitDishes.length} dishes')),
        _chips<String>(
          values: _meals,
          isSelected: (v) => _mealForVisit == v,
          onTap: (v) => setState(() => _visitMeal = v),
          label: _pretty,
        ),
        _gap(),
        Text(
          'The cook sets how long the visit takes for these dishes.',
          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
        ),
        const SizedBox(height: 8),
        DishPicker(
          dishes: _visitDishes,
          meal: _mealForVisit,
          onChanged: (v) => setState(() => _visitDishes = v),
        ),
        _gap(),
        DsLabeledField(
          label: 'Note for the cook',
          controller: _instruction,
          icon: Icons.edit_note_rounded,
          hint: 'e.g. Less oil',
          optional: true,
          textCapitalization: TextCapitalization.sentences,
        ),
      ];

  List<Widget> _weeklyMenuFields() => [
        const DsSection('Weekly menu', trailing: DsPill('Optional', color: AppColors.lightTextSecondary)),
        _SwitchRow(
          title: 'Set the weekly menu now',
          icon: Icons.restaurant_menu_rounded,
          value: _weeklyMenuOn,
          onChanged: (v) => setState(() {
            _weeklyMenuOn = v;
            if (v && _weekly.isEmpty) _weekly.add(_WeeklyRow());
          }),
        ),
        if (!_weeklyMenuOn) ...[
          _gap(),
          const DsNote(text: 'You can set it later from the menu screen. If you already have a weekly menu, it is kept.'),
        ] else ...[
          _gap(),
          for (final r in _weekly) _weeklyRowCard(r),
          CareAddButton(label: 'Add another meal', onTap: () => setState(() => _weekly.add(_WeeklyRow()))),
        ],
      ];

  Widget _weeklyRowCard(_WeeklyRow r) => Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(14),
        decoration: dsCardDecoration(),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${_pretty(r.dow)} · ${_pretty(r.meal)}',
                    style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
                  ),
                ),
                IconButton(
                  tooltip: 'Remove',
                  icon: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                  onPressed: () => setState(() => _weekly.remove(r)),
                ),
              ],
            ),
            _chips<String>(
              values: WeeklyMenuEntry.days,
              isSelected: (v) => r.dow == v,
              onTap: (v) => setState(() => r.dow = v),
              label: _pretty,
            ),
            const SizedBox(height: 10),
            _chips<String>(
              values: _meals,
              isSelected: (v) => r.meal == v,
              onTap: (v) => setState(() => r.meal = v),
              label: _pretty,
            ),
            const SizedBox(height: 10),
            DishPicker(
              dishes: r.dishes,
              meal: r.meal,
              onChanged: (v) => setState(() => r.dishes = v),
            ),
          ],
        ),
      );

  // Step 4
  List<Widget> _addressStep() => [
        const DsSection('Where will the staff work?'),
        DsLabeledField(
          label: 'Address',
          controller: _address,
          icon: Icons.home_rounded,
          hint: 'House, street, area, city',
          maxLines: 3,
          minLines: 2,
        ),
        _gap(),
        DsListCard(
          icon: _pin == null ? Icons.add_location_alt_rounded : Icons.location_on_rounded,
          iconColor: _pin == null ? null : AppColors.success,
          title: _pin == null ? 'Pin your home on the map' : 'Home pinned',
          subtitle: _pin == null ? 'Helps staff find you and check in' : 'Tap to move the pin',
          onTap: _pickPin,
          trailing: _pin == null
              ? null
              : IconButton(
                  tooltip: 'Remove pin',
                  icon: const Icon(Icons.close_rounded),
                  onPressed: () => setState(() => _pin = null),
                ),
        ),
        if (_pin != null) LocationAddressWidget(latitude: _pin!.latitude, longitude: _pin!.longitude),
        const DsSection('Anything else'),
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

  // Step 5
  List<Widget> _reviewStep() {
    final when = '${_dayMonth(_ymd(_startDate!))}, ${_time12(_startHhmm!)}';
    final how = _oneTime
        ? 'Set by the cook'
        : _liveIn
            ? '24×7 Live-in · stays round the clock'
            : '${_placementType == 'TEMPORARY' ? 'Hourly' : 'Permanent'} · ${_shiftHours.text.trim()} h a day';
    final care = _careNeeds;
    return [
      const DsSection('Your booking'),
      DsInfoCard(
        lines: [
          DsInfoLine(Icons.badge_rounded, 'Staff', '${SeriesDisplay.label(_series!)} × $_headcount'),
          DsInfoLine(Icons.event_available_rounded, 'Visit', _oneTime ? 'One-time visit' : 'Regular staff'),
          DsInfoLine(Icons.event_rounded, _oneTime ? 'When' : 'Starts', when),
          DsInfoLine(Icons.timelapse_rounded, 'How long', how),
          DsInfoLine(Icons.home_rounded, 'Address', _address.text.trim()),
          if (_pin != null) const DsInfoLine(Icons.location_on_rounded, 'Map pin', 'Set'),
          if (_genderPref != 'ANY') DsInfoLine(Icons.wc_rounded, 'Staff gender', _pretty(_genderPref)),
          if (_language.text.trim().isNotEmpty) DsInfoLine(Icons.translate_rounded, 'Language', _language.text.trim()),
        ],
      ),
      if (_isCook && _oneTime) ...[
        DsSection('${_pretty(_mealForVisit)} menu'),
        DsInfoCard(
          lines: [
            DsInfoLine(Icons.restaurant_rounded, 'Dishes', _visitDishes.map((d) => d.name).join(', ')),
            if (_instruction.text.trim().isNotEmpty)
              DsInfoLine(Icons.edit_note_rounded, 'Note', _instruction.text.trim()),
          ],
        ),
      ],
      if (_isCook && !_oneTime && _weeklyMenuOn && _weekly.any((r) => r.dishes.isNotEmpty)) ...[
        const DsSection('Weekly menu'),
        DsInfoCard(
          lines: [
            for (final r in _weekly)
              if (r.dishes.isNotEmpty)
                DsInfoLine(Icons.restaurant_rounded, '${_pretty(r.dow)} ${_pretty(r.meal)}', r.dishes.map((d) => d.name).join(', ')),
          ],
        ),
      ],
      if (_isCare) ...[
        const DsSection('Care needs'),
        DsInfoCard(
          lines: [
            DsInfoLine(
              Icons.person_rounded,
              'Patient',
              [
                if (_patientName.text.trim().isNotEmpty) _patientName.text.trim(),
                '${_patientAge.text.trim()} yrs',
                if (_mobilityValue != null) _pretty(_mobilityValue!),
              ].join(' · '),
            ),
            if (!_isUc && care.medications.isNotEmpty)
              DsInfoLine(Icons.medication_rounded, 'Medicines', care.medications.map((m) => m.summary).join(', ')),
            if (!_isUc && care.vitals.isNotEmpty)
              DsInfoLine(Icons.monitor_heart_rounded, 'Checks', care.vitals.map((v) => carePretty(v.type)).join(', ')),
            if (care.activities.isNotEmpty)
              DsInfoLine(
                Icons.directions_walk_rounded,
                'Activities',
                care.activities.map((a) => a.title.isEmpty ? carePretty(a.type) : a.title).join(', '),
              ),
            if (_dietNotes.text.trim().isNotEmpty) DsInfoLine(Icons.restaurant_rounded, 'Diet', _dietNotes.text.trim()),
            if (_dos.text.trim().isNotEmpty) DsInfoLine(Icons.thumb_up_alt_rounded, 'Do', _dos.text.trim()),
            if (_donts.text.trim().isNotEmpty) DsInfoLine(Icons.block_rounded, 'Don\'t', _donts.text.trim()),
          ],
        ),
      ],
      const SizedBox(height: 12),
      const DsNote(text: 'Your relationship manager will shortlist staff for you to choose from.'),
    ];
  }
}

class _ChoiceCard extends StatelessWidget {
  const _ChoiceCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => DsListCard(
        icon: icon,
        title: title,
        subtitle: subtitle,
        onTap: onTap,
        trailing: Icon(
          selected ? Icons.check_circle_rounded : Icons.radio_button_unchecked_rounded,
          color: selected ? AppColors.primary : AppColors.lightBorder,
        ),
      );
}

// ── Visit date & time pickers ──

const _weekdays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
const _months = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];

/// "Thu, 16 Oct".
String _weekdayDayMonth(DateTime d) => '${_weekdays[d.weekday - 1]}, ${d.day} ${_months[d.month - 1]}';

bool _sameDay(DateTime a, DateTime b) => a.year == b.year && a.month == b.month && a.day == b.day;

/// "Date" / "Time" heading with a link to the full picker on the right.
class _PickerLabel extends StatelessWidget {
  const _PickerLabel({required this.icon, required this.label, required this.action, required this.onAction});

  final IconData icon;
  final String label;
  final String action;
  final VoidCallback onAction;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, size: 18, color: AppColors.primary),
        const SizedBox(width: 6),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
        ),
        const Spacer(),
        TextButton(
          onPressed: onAction,
          style: TextButton.styleFrom(visualDensity: VisualDensity.compact),
          child: Text(action, style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700)),
        ),
      ],
    );
  }
}

/// The next 14 days as tappable tiles; a date picked from the calendar
/// beyond that is shown first so the choice stays visible.
class _DateStrip extends StatelessWidget {
  const _DateStrip({required this.selected, required this.onPick});

  final DateTime? selected;
  final ValueChanged<DateTime> onPick;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final days = [for (var i = 0; i < 14; i++) today.add(Duration(days: i))];
    final picked = selected;
    if (picked != null && !days.any((d) => _sameDay(d, picked))) days.insert(0, picked);

    return SizedBox(
      height: 84,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        clipBehavior: Clip.none,
        itemCount: days.length,
        separatorBuilder: (_, _) => const SizedBox(width: 8),
        itemBuilder: (context, i) {
          final d = days[i];
          final isSelected = picked != null && _sameDay(d, picked);
          final offset = d.difference(today).inDays;
          final top = offset == 0
              ? 'Today'
              : offset == 1
                  ? 'Tmrw'
                  : _weekdays[d.weekday - 1];
          final fg = isSelected ? Colors.white : AppColors.lightTextPrimary;
          final muted = isSelected ? Colors.white.withValues(alpha: 0.85) : AppColors.lightTextSecondary;
          return Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(16),
              onTap: () => onPick(d),
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 180),
                width: 60,
                decoration: isSelected
                    ? BoxDecoration(
                        gradient: const LinearGradient(
                          colors: [AppColors.primary, Color(0xFF3B6BFF)],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.primary.withValues(alpha: 0.3),
                            blurRadius: 12,
                            offset: const Offset(0, 6),
                          ),
                        ],
                      )
                    : dsCardDecoration(radius: 16),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(top, style: GoogleFonts.plusJakartaSans(fontSize: 11.5, fontWeight: FontWeight.w700, color: muted)),
                    const SizedBox(height: 2),
                    Text(
                      '${d.day}',
                      style: GoogleFonts.plusJakartaSans(fontSize: 20, fontWeight: FontWeight.w800, color: fg),
                    ),
                    Text(
                      _months[d.month - 1],
                      style: GoogleFonts.plusJakartaSans(fontSize: 11, fontWeight: FontWeight.w600, color: muted),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

/// Hourly start times, 7 AM – 8 PM, three per row. Times already past
/// today are greyed out; a custom time from the clock picker shows first.
class _TimeSlots extends StatelessWidget {
  const _TimeSlots({required this.date, required this.selected, required this.onPick});

  final DateTime? date;
  final TimeOfDay? selected;
  final ValueChanged<TimeOfDay> onPick;

  static final _slots = [for (var h = 7; h <= 20; h++) TimeOfDay(hour: h, minute: 0)];

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final isToday = date != null && _sameDay(date!, now);
    final picked = selected;
    final slots = [
      if (picked != null && !_slots.contains(picked)) picked,
      ..._slots,
    ];

    return LayoutBuilder(
      builder: (context, c) {
        const gap = 8.0;
        final width = (c.maxWidth - gap * 2) / 3;
        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final t in slots)
              _TimeSlot(
                width: width,
                label: _time12(_hhmm(t)),
                selected: picked == t,
                // Keep a little lead time so staff can actually get there.
                disabled: isToday && (t.hour * 60 + t.minute) <= (now.hour * 60 + now.minute + 30),
                onTap: () => onPick(t),
              ),
          ],
        );
      },
    );
  }
}

class _TimeSlot extends StatelessWidget {
  const _TimeSlot({
    required this.width,
    required this.label,
    required this.selected,
    required this.disabled,
    required this.onTap,
  });

  final double width;
  final String label;
  final bool selected;
  final bool disabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected
        ? Colors.white
        : disabled
            ? AppColors.lightTextHint
            : AppColors.lightTextPrimary;
    return SizedBox(
      width: width,
      height: 44,
      child: Material(
        color: selected ? AppColors.primary : (disabled ? AppColors.lightSurfaceVariant : Colors.white),
        borderRadius: BorderRadius.circular(12),
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: disabled ? null : onTap,
          child: Container(
            alignment: Alignment.center,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: selected ? AppColors.primary : AppColors.lightBorder),
            ),
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: color,
                decoration: disabled ? TextDecoration.lineThrough : null,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// "Thu, 16 Oct · 9:00 AM" — green once both are chosen.
class _WhenSummary extends StatelessWidget {
  const _WhenSummary({required this.text, required this.complete});

  final String text;
  final bool complete;

  @override
  Widget build(BuildContext context) {
    final color = complete ? AppColors.success : AppColors.warning;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(complete ? Icons.event_available_rounded : Icons.info_outline_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w800,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Shown in place of "Hours per day" when 24×7 Live-in is chosen: there are
/// no hours to enter, and the family should know how it is billed.
class _LiveInNote extends StatelessWidget {
  const _LiveInNote();

  @override
  Widget build(BuildContext context) {
    const color = AppColors.success;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.nights_stay_rounded, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Staff stays at your home round the clock. Billed per day of duty; '
              'on their days off we send a relief staff member.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
