import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/onboarding/city_fields.dart';
import '../../../../../core/onboarding/onboarding_models.dart';
import '../../../../../core/onboarding/onboarding_providers.dart';
import '../../../../../core/onboarding/onboarding_wizard_scaffold.dart';
import '../../../../../core/series/series_catalog.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

const _stepLabels = ['About you', 'Home', 'Contact', 'Review'];

/// Hero copy per step: line 1, highlighted line 2, subtitle, faded icon.
const _heroCopy = <(String, String, String, IconData)>[
  ('Tell us', 'about you.', 'Your name and work, just as on your Aadhaar card.', Icons.person_rounded),
  ('Where do', 'you live?', 'Your city decides your HomeGenny branch and RM.', Icons.home_work_rounded),
  ('Someone we', 'can call.', 'A family member we can reach in an emergency.', Icons.contact_emergency_rounded),
  ('Almost', 'done!', 'Check your details, then submit to start verification.', Icons.fact_check_rounded),
];

const _genders = [('FEMALE', 'Female'), ('MALE', 'Male'), ('OTHER', 'Other')];

const _languageOptions = [
  'Hindi', 'English', 'Marathi', 'Bengali', 'Punjabi', 'Gujarati', 'Urdu', //
  'Tamil', 'Telugu', 'Kannada', 'Malayalam', 'Odia', 'Assamese', 'Nepali',
];

/// Fields the server locks after Submit (`locked_fields`).
const _lockable = {'full_name', 'date_of_birth', 'gender', 'series'};

/// Staff "Complete your profile" wizard — 3 steps, a review, then Submit
/// (`POST /staff/profile/submit`), which finishes Stage 1 and assigns an RM.
/// Each step's Next saves that step with `PUT /staff/profile`. Opened after
/// the profile is submitted, the same screens edit what isn't locked.
class StaffProfileWizardScreen extends ConsumerStatefulWidget {
  const StaffProfileWizardScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  ConsumerState<StaffProfileWizardScreen> createState() => _StaffProfileWizardScreenState();
}

class _StaffProfileWizardScreenState extends ConsumerState<StaffProfileWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _step = widget.initialStep.clamp(0, 3);

  final _name = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  final _ecName = TextEditingController();
  final _ecMobile = TextEditingController();
  final _experience = TextEditingController();
  final _relation = TextEditingController(); // father_or_husband_name
  DateTime? _dob;
  String? _gender;
  String? _series; // short code: UC / SC / CK
  String? _city;
  String? _area;
  final Set<String> _languages = {};

  StaffProfile? _profile;
  bool _busy = false;
  String? _serverError;
  StaffProfileSubmitResult? _result;

  @override
  void dispose() {
    for (final c in [_name, _address, _pincode, _ecName, _ecMobile, _experience, _relation]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(StaffProfile p) {
    _profile = p;
    _name.text = p.fullName;
    _address.text = p.address ?? '';
    _pincode.text = p.pincode ?? '';
    _ecName.text = p.emergencyContactName ?? '';
    _ecMobile.text = p.emergencyContactMobile ?? '';
    _experience.text = p.experienceYears?.toString() ?? '';
    _relation.text = p.fatherOrHusbandName ?? '';
    _dob = DateTime.tryParse(p.dateOfBirth ?? '');
    _gender = _genders.any((g) => g.$1 == p.gender?.toUpperCase()) ? p.gender!.toUpperCase() : null;
    _series = SeriesCatalog.fallback.find(p.series)?.short;
    _city = (p.city?.isEmpty ?? true) ? null : p.city;
    _area = (p.area?.isEmpty ?? true) ? null : p.area;
    _languages
      ..clear()
      ..addAll(p.languages);
  }

  bool _locked(String field) => _profile?.isLocked(field) ?? false;

  /// After Submit the wizard edits; its last button saves instead.
  bool get _alreadySubmitted => _profile?.lockedFields.isNotEmpty ?? false;

  String get _ownMobile => (_profile?.mobile.isNotEmpty ?? false)
      ? _profile!.mobile
      : (ref.read(authProvider).user?.phone ?? '');

  // ── payloads (snake_case, as the server takes them) ──

  Map<String, dynamic> _stepFields(int step) {
    final fields = switch (step) {
      0 => {
          'full_name': _name.text.trim(),
          if (_dob != null) 'date_of_birth': DateFormat('yyyy-MM-dd').format(_dob!),
          if (_gender != null) 'gender': _gender,
          // Optional; a blank is never sent (the server takes 2–150 letters).
          if (_relation.text.trim().isNotEmpty) 'father_or_husband_name': _relation.text.trim(),
          if (_series != null) 'series': _series,
        },
      1 => {
          if (_city != null) 'city': _city,
          if (_area != null) 'area': _area,
          'address': _address.text.trim(),
          'pincode': _pincode.text.trim(),
        },
      _ => {
          'emergency_contact_name': _ecName.text.trim(),
          'emergency_contact_mobile': _ecMobile.text.trim(),
          'languages': _languages.toList(),
          if (_experience.text.trim().isNotEmpty) 'experience_years': int.parse(_experience.text.trim()),
        },
    };
    // The server refuses locked fields with a 400 — never send them.
    fields.removeWhere((k, _) => _locked(k));
    return fields;
  }

  Map<String, dynamic> get _allFields => {..._stepFields(0), ..._stepFields(1), ..._stepFields(2)};

  // ── actions ──

  Future<void> _next() async {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false) || !_validateExtras()) {
      HapticFeedback.mediumImpact();
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(staffRepositoryProvider).updateProfile(_stepFields(_step));
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (profile) {
        _profile = profile;
        ref.invalidate(staffProfileProvider);
        setState(() => _step++);
      },
      onError: (f) => setState(() => _serverError = f.message),
    );
  }

  /// Choices that aren't text fields, so the Form can't validate them.
  bool _validateExtras() {
    String? error;
    if (_step == 0) {
      if (!_locked('date_of_birth') && _dob == null) {
        error = 'Choose your date of birth';
      } else if (!_locked('date_of_birth') && _ageError(_dob!) != null) {
        error = _ageError(_dob!);
      } else if (!_locked('gender') && _gender == null) {
        error = 'Choose your gender';
      } else if (!_locked('series') && _series == null) {
        error = 'Choose your work category';
      }
    } else if (_step == 1 && _city == null) {
      error = 'Choose your city';
    }
    if (error != null) setState(() => _serverError = error);
    return error == null;
  }

  Future<void> _submit() async {
    setState(() {
      _busy = true;
      _serverError = null;
    });
    final repo = ref.read(staffRepositoryProvider);

    if (_alreadySubmitted) {
      final result = await repo.updateProfile(_allFields);
      if (!mounted) return;
      setState(() => _busy = false);
      result.fold(
        onSuccess: (_) {
          _refreshAll();
          context.showDsSnackBar('Profile saved', type: DsSnackBarType.success);
          _close();
        },
        onError: (f) => setState(() => _serverError = f.message),
      );
      return;
    }

    final result = await repo.submitProfile(_allFields);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (r) {
        _refreshAll();
        setState(() => _result = r);
      },
      onError: (f) {
        if (f.isProfileIncomplete && f.missing.isNotEmpty) {
          // Jump to the step holding the first missing field.
          final step = f.missing.map(staffWizardStepFor).reduce((a, b) => a < b ? a : b);
          setState(() {
            _step = step;
            _serverError = f.message;
          });
        } else {
          setState(() => _serverError = f.message);
        }
      },
    );
  }

  void _refreshAll() {
    ref.invalidate(onboardingProvider);
    ref.invalidate(staffProfileProvider);
    ref.invalidate(staffDashboardProvider);
    ref.invalidate(staffTasksProvider);
    // The cached login user still has `full_name: ""`.
    ref.read(authProvider.notifier).fetchProfile();
  }

  void _close() => context.canPop() ? context.pop() : context.go(StaffRoutes.home);

  void _back() {
    if (_step == 0 || _result != null) return _close();
    setState(() {
      _step--;
      _serverError = null;
    });
  }

  // ── validation helpers ──

  static String? _ageError(DateTime dob) {
    final now = DateTime.now();
    var age = now.year - dob.year;
    if (now.month < dob.month || (now.month == dob.month && now.day < dob.day)) age--;
    if (age < 18) return 'You must be at least 18 years old';
    if (age > 65) return 'Age must be 65 or under';
    return null;
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(staffProfileProvider);
    if (_profile == null && profileAsync.hasValue) _prefill(profileAsync.value!);

    if (_result != null) return _SubmitSuccess(result: _result!, mobile: _ownMobile);

    final isReview = _step == 3;
    final (line1, highlight, subtitle, icon) = _heroCopy[_step];
    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: OnboardingWizardScaffold(
        steps: _stepLabels,
        currentStep: _step,
        titleLine1: _alreadySubmitted && _step == 0 ? 'Edit your' : line1,
        titleHighlight: _alreadySubmitted && _step == 0 ? 'profile.' : highlight,
        subtitle: subtitle,
        icon: icon,
        onBack: _back,
        bottom: profileAsync.hasValue
            ? Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(flex: 2, child: DsOutlineButton(label: 'Back', onPressed: _busy ? null : _back)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 3,
                    child: DsGradientButton(
                      label: isReview ? (_alreadySubmitted ? 'Save changes' : 'Submit profile') : 'Next',
                      icon: isReview ? Icons.check_rounded : Icons.arrow_forward_rounded,
                      isLoading: _busy,
                      onPressed: _busy ? null : (isReview ? _submit : _next),
                    ),
                  ),
                ],
              )
            : null,
        children: profileAsync.when(
          loading: () => [const SizedBox(height: 80), const DsLoadingWidget(), const SizedBox(height: 80)],
          error: (e, _) => [
            DsErrorState(
              title: 'Could not load your profile',
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(staffProfileProvider),
            ),
          ],
          data: (_) => [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: switch (_step) {
                  0 => _aboutYou(),
                  1 => _whereYouLive(),
                  2 => _emergency(),
                  _ => _review(),
                },
              ),
            ),
            if (_serverError != null) ...[
              const SizedBox(height: 16),
              DsNote(text: _serverError!, tone: DsNoteTone.danger),
            ],
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  // ── step 1: about you ──

  List<Widget> _aboutYou() {
    final series = ref.watch(seriesCatalogProvider).active;
    final latest = DateTime.now().subtract(const Duration(days: 18 * 365 + 4));
    final earliest = DateTime.now().subtract(const Duration(days: 66 * 365 + 16));
    return [
      const OnboardingSectionHeader(icon: Icons.person_rounded, title: 'Personal details', hint: "As written on your Aadhaar card"),
      _lockedOr(
        'full_name',
        'Full name',
        _name.text,
        DsLabeledField(
          label: 'Full name',
          controller: _name,
          icon: Icons.person_rounded,
          textCapitalization: TextCapitalization.words,
          maxLength: 200,
          validator: (v) {
            final t = v?.trim() ?? '';
            if (t.length < 2) return 'Enter your full name';
            if (t.length > 200) return 'Name is too long';
            return null;
          },
        ),
      ),
      const SizedBox(height: 16),
      _lockedOr(
        'date_of_birth',
        'Date of birth',
        _dob == null ? '' : DateFormat('d MMM yyyy').format(_dob!),
        _PickerTile(
          label: 'Date of birth',
          icon: Icons.cake_rounded,
          value: _dob == null ? null : DateFormat('d MMM yyyy').format(_dob!),
          hint: 'Choose date',
          onTap: () async {
            final picked = await showDatePicker(
              context: context,
              initialDate: _dob ?? DateTime(latest.year - 7, latest.month, latest.day),
              firstDate: earliest,
              lastDate: latest,
              helpText: 'Date of birth',
            );
            if (picked != null) setState(() => _dob = picked);
          },
        ),
      ),
      const SizedBox(height: 16),
      _lockedOr(
        'gender',
        'Gender',
        _genders.where((g) => g.$1 == _gender).map((g) => g.$2).firstOrNull ?? '',
        _ChoiceGroup(
          label: 'Gender',
          children: [
            for (final (value, label) in _genders)
              DsChoiceChip(label: label, selected: _gender == value, onTap: () => setState(() => _gender = value)),
          ],
        ),
      ),
      const SizedBox(height: 16),
      // Printed on the client's monthly attendance sheet (muster roll).
      DsLabeledField(
        label: "Father's or husband's name",
        controller: _relation,
        icon: Icons.family_restroom_rounded,
        optional: true,
        textCapitalization: TextCapitalization.words,
        maxLength: 150,
        validator: (v) {
          final t = v?.trim() ?? '';
          if (t.isEmpty) return null;
          if (t.length < 2) return 'Enter at least 2 letters';
          if (!RegExp(r"^[\p{L} .'-]+$", unicode: true).hasMatch(t)) return 'Use letters only';
          return null;
        },
      ),
      const SizedBox(height: 16),
      _lockedOr(
        'series',
        'Work category',
        _series == null ? '' : SeriesDisplay.label(_series),
        Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            const OnboardingFieldLabel('What work do you do?'),
            for (final s in series)
              _SeriesTile(
                label: s.label,
                icon: SeriesDisplay.icon(s.short),
                color: SeriesDisplay.color(s.short),
                selected: _series == s.short,
                onTap: () => setState(() => _series = s.short),
              ),
          ],
        ),
      ),
    ];
  }

  // ── step 2: where you live ──

  List<Widget> _whereYouLive() {
    final cities = ref.watch(citiesProvider);
    final selected = cities.valueOrNull?.where((c) => c.city == _city).firstOrNull;
    return [
      const OnboardingSectionHeader(icon: Icons.home_work_rounded, title: 'Your address', hint: "Where you stay right now"),
      cities.when(
        loading: () => const _PickerTile(label: 'City', icon: Icons.location_city_rounded, hint: 'Loading cities…'),
        error: (e, _) => DsNote(
          tone: DsNoteTone.danger,
          text: 'Could not load the city list. Pull back and try again.',
          title: e.toString().replaceFirst('Exception: ', ''),
        ),
        data: (list) => CityDropdown(
          cities: list,
          value: _city,
          onChanged: (c) => setState(() {
            _city = c;
            _area = null;
          }),
        ),
      ),
      if (selected?.isOther ?? false) ...[
        const SizedBox(height: 8),
        const DsNote(text: 'That\'s fine — the HomeGenny office will assign you an RM.'),
      ],
      if (selected != null && selected.areas.isNotEmpty) ...[
        const SizedBox(height: 16),
        AreaDropdown(areas: selected.areas, value: _area, onChanged: (a) => setState(() => _area = a)),
      ],
      const SizedBox(height: 16),
      DsLabeledField(
        label: 'Address',
        controller: _address,
        icon: Icons.home_rounded,
        maxLines: 3,
        minLines: 2,
        textCapitalization: TextCapitalization.words,
        validator: (v) => (v?.trim().length ?? 0) < 5 ? 'Enter your full address' : null,
      ),
      const SizedBox(height: 16),
      DsLabeledField(
        label: 'Pincode',
        controller: _pincode,
        icon: Icons.pin_drop_rounded,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(6)],
        validator: (v) => RegExp(r'^[1-9][0-9]{5}$').hasMatch(v?.trim() ?? '') ? null : 'Enter a valid 6-digit pincode',
      ),
    ];
  }

  // ── step 3: emergency contact ──

  List<Widget> _emergency() {
    return [
      const OnboardingSectionHeader(icon: Icons.contact_emergency_rounded, title: 'Emergency contact', hint: "Must be someone else's number"),
      DsLabeledField(
        label: 'Emergency contact name',
        controller: _ecName,
        icon: Icons.person_pin_rounded,
        textCapitalization: TextCapitalization.words,
        validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Enter a name' : null,
      ),
      const SizedBox(height: 16),
      DsLabeledField(
        label: 'Emergency contact mobile',
        controller: _ecMobile,
        icon: Icons.phone_rounded,
        keyboardType: TextInputType.phone,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(10)],
        validator: (v) {
          final t = v?.trim() ?? '';
          if (!RegExp(r'^[0-9]{10}$').hasMatch(t)) return 'Enter a 10-digit mobile number';
          if (t == _ownMobile) return 'This must be someone else\'s number, not your own';
          return null;
        },
      ),
      const SizedBox(height: 16),
      _ChoiceGroup(
        label: 'Languages you speak',
        optional: true,
        children: [
          for (final lang in {..._languageOptions, ..._languages})
            DsChoiceChip(
              label: lang,
              selected: _languages.contains(lang),
              onTap: () => setState(() => _languages.contains(lang) ? _languages.remove(lang) : _languages.add(lang)),
            ),
        ],
      ),
      const SizedBox(height: 16),
      DsLabeledField(
        label: 'Experience in years',
        controller: _experience,
        icon: Icons.work_history_rounded,
        optional: true,
        keyboardType: TextInputType.number,
        inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
      ),
    ];
  }

  // ── review ──

  List<Widget> _review() {
    String or(String? v) => (v == null || v.trim().isEmpty) ? 'Not added' : v.trim();
    return [
      const OnboardingSectionHeader(icon: Icons.fact_check_rounded, title: 'Review your details', hint: 'Tap Edit to change anything'),
      _ReviewCard(
        title: 'About you',
        onEdit: () => setState(() => _step = 0),
        rows: [
          ('Full name', or(_name.text)),
          ('Date of birth', _dob == null ? 'Not added' : DateFormat('d MMM yyyy').format(_dob!)),
          ('Gender', or(_genders.where((g) => g.$1 == _gender).map((g) => g.$2).firstOrNull)),
          ("Father's / husband's name", or(_relation.text)),
          ('Work category', _series == null ? 'Not added' : SeriesDisplay.label(_series)),
        ],
      ),
      const SizedBox(height: 12),
      _ReviewCard(
        title: 'Where you live',
        onEdit: () => setState(() => _step = 1),
        rows: [
          ('City', or([_city, _area].whereType<String>().join(' · '))),
          ('Address', or(_address.text)),
          ('Pincode', or(_pincode.text)),
        ],
      ),
      const SizedBox(height: 12),
      _ReviewCard(
        title: 'Emergency contact',
        onEdit: () => setState(() => _step = 2),
        rows: [
          ('Name', or(_ecName.text)),
          ('Mobile', or(_ecMobile.text)),
          ('Languages', _languages.isEmpty ? 'Not added' : _languages.join(', ')),
          ('Experience', _experience.text.trim().isEmpty ? 'Not added' : '${_experience.text.trim()} years'),
        ],
      ),
      if (!_alreadySubmitted) ...[
        const SizedBox(height: 16),
        const DsNote(
          text: 'After you submit, your name, date of birth, gender and work category can only be changed by your RM.',
        ),
      ],
    ];
  }

  /// A locked field is shown read-only with "Ask your RM to change this".
  Widget _lockedOr(String field, String label, String value, Widget editable) {
    if (!_lockable.contains(field) || !_locked(field)) return editable;
    return _LockedField(label: label, value: value.trim().isEmpty ? 'Not added' : value);
  }
}

// ---------------------------------------------------------------------------
// Pieces
// ---------------------------------------------------------------------------

class _ChoiceGroup extends StatelessWidget {
  const _ChoiceGroup({required this.label, required this.children, this.optional = false});
  final String label;
  final List<Widget> children;
  final bool optional;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        OnboardingFieldLabel(label, optional: optional),
        Wrap(spacing: 8, runSpacing: 8, children: children),
      ],
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({required this.label, required this.icon, this.value, this.hint, this.onTap});
  final String label;
  final IconData icon;
  final String? value;
  final String? hint;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingFieldLabel(label),
        Material(
          color: AppColors.lightSurfaceVariant,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 16),
              child: Row(
                children: [
                  Icon(icon, color: AppColors.iconAccent, size: 21),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      value ?? hint ?? '',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: value == null ? AppColors.lightTextHint : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down_rounded, color: AppColors.lightTextSecondary),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

class _LockedField extends StatelessWidget {
  const _LockedField({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        OnboardingFieldLabel(label),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          decoration: BoxDecoration(
            color: AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.lightTextSecondary, size: 19),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(value, style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
                    const SizedBox(height: 2),
                    Text('Ask your RM to change this', style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ReviewCard extends StatelessWidget {
  const _ReviewCard({required this.title, required this.rows, required this.onEdit});
  final String title;
  final List<(String, String)> rows;
  final VoidCallback onEdit;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 8, 8, 12),
      decoration: dsCardDecoration(radius: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title, style: GoogleFonts.plusJakartaSans(fontSize: 15.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
              ),
              TextButton.icon(onPressed: onEdit, icon: const Icon(Icons.edit_rounded, size: 16), label: const Text('Edit')),
            ],
          ),
          for (final (label, value) in rows)
            Padding(
              padding: const EdgeInsets.only(top: 6, right: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 110,
                    child: Text(label, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary)),
                  ),
                  Expanded(
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: value == 'Not added' ? AppColors.lightTextHint : AppColors.lightTextPrimary,
                      ),
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

/// §6.4 — "You're in!" (or "We'll assign your RM soon"), then the home.
/// `RESTRICTED` shows the server's message and stops.
class _SubmitSuccess extends StatelessWidget {
  const _SubmitSuccess({required this.result, required this.mobile});
  final StaffProfileSubmitResult result;
  final String mobile;

  @override
  Widget build(BuildContext context) {
    if (result.isRestricted) {
      return OnboardingSuccessView(
        warning: true,
        icon: Icons.info_rounded,
        title: 'We need to talk',
        message: result.message ?? 'We could not complete your registration. Please contact HomeGenny.',
        primaryLabel: 'OK',
        onPrimary: null,
      );
    }
    final rm = result.onboarding.rm;
    final waiting = result.onboarding.nextStep == OnboardingNextStep.waitForRm || rm == null;
    return OnboardingSuccessView(
      icon: waiting ? Icons.check_rounded : Icons.celebration_rounded,
      title: waiting ? 'Profile submitted' : 'You\'re in!',
      message: waiting
          ? 'Profile submitted. We\'ll assign your RM soon.'
          : 'Your RM ${rm.name} will call you on $mobile to verify your documents.',
      nextSteps: [
        if (waiting)
          (Icons.support_agent_rounded, 'The HomeGenny office assigns you a Relationship Manager.')
        else
          (Icons.phone_in_talk_rounded, '${rm.name} calls you${rm.phone.isEmpty ? '' : ' from ${rm.phone}'}.'),
        (Icons.verified_user_rounded, 'Keep your Aadhaar card ready for verification.'),
        (Icons.school_rounded, 'Then training, and your first placement.'),
      ],
      primaryLabel: 'Go to home',
      onPrimary: () => context.go(StaffRoutes.home),
    );
  }
}

/// A work category as a full-width selectable row.
class _SeriesTile extends StatelessWidget {
  const _SeriesTile({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          onTap();
        },
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
          decoration: BoxDecoration(
            color: selected ? color.withValues(alpha: 0.08) : AppColors.lightSurfaceVariant,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: selected ? color : Colors.transparent, width: 1.6),
          ),
          child: Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: selected ? color : Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, size: 20, color: selected ? Colors.white : color),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                ),
              ),
              Icon(
                selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded,
                color: selected ? color : AppColors.lightTextHint,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

