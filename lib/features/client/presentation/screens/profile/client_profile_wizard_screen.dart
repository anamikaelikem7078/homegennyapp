import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../common/presentation/providers/auth_provider.dart';
import '../../../../../core/onboarding/city_fields.dart';
import '../../../../../core/onboarding/onboarding_providers.dart';
import '../../../../../core/onboarding/onboarding_wizard_scaffold.dart';
import '../../../../../core/utils/validators.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/map_pin_picker.dart';

/// Client "Complete your profile" wizard — 1. your name, 2. your home. Each
/// step saves with `PATCH /client/profile`; once both are in, "Request
/// staff" unlocks. No PAN or GST here — the RM or Finance collects them.
class ClientProfileWizardScreen extends ConsumerStatefulWidget {
  const ClientProfileWizardScreen({super.key, this.initialStep = 0});

  final int initialStep;

  @override
  ConsumerState<ClientProfileWizardScreen> createState() => _ClientProfileWizardScreenState();
}

class _ClientProfileWizardScreenState extends ConsumerState<ClientProfileWizardScreen> {
  final _formKey = GlobalKey<FormState>();
  late int _step = widget.initialStep.clamp(0, 1);

  final _name = TextEditingController();
  final _email = TextEditingController();
  final _address = TextEditingController();
  final _pincode = TextEditingController();
  String? _city;
  LatLng? _pin;

  bool _initialized = false;
  bool _busy = false;

  /// Profile complete — show the "You're all set" screen.
  bool _done = false;
  String? _serverError;

  @override
  void dispose() {
    for (final c in [_name, _email, _address, _pincode]) {
      c.dispose();
    }
    super.dispose();
  }

  void _prefill(ClientProfile p) {
    _initialized = true;
    _name.text = p.name;
    _email.text = p.email;
    _address.text = p.address;
    _pincode.text = p.pincode;
    _city = p.city.isEmpty ? null : p.city;
    if (p.lat != null && p.lng != null) _pin = LatLng(p.lat!, p.lng!);
  }

  Map<String, dynamic> get _fields => _step == 0
      ? {
          'full_name': _name.text.trim(),
          if (_email.text.trim().isNotEmpty) 'email': _email.text.trim(),
        }
      : {
          'city': _city,
          'address': _address.text.trim(),
          'pincode': _pincode.text.trim(),
          if (_pin != null) 'lat': _pin!.latitude,
          if (_pin != null) 'lng': _pin!.longitude,
        };

  Future<void> _next() async {
    setState(() => _serverError = null);
    if (!(_formKey.currentState?.validate() ?? false)) {
      HapticFeedback.mediumImpact();
      return;
    }
    if (_step == 1 && _city == null) {
      setState(() => _serverError = 'Choose your city');
      return;
    }
    setState(() => _busy = true);
    final result = await ref.read(clientRepositoryProvider).updateProfile(_fields);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (profile) {
        ref.invalidate(clientProfileProvider);
        ref.invalidate(onboardingProvider);
        if (_step == 0) {
          setState(() => _step = 1);
          return;
        }
        // The cached login user still has no name.
        ref.read(authProvider.notifier).fetchProfile();
        if (profile.profileComplete) {
          setState(() => _done = true);
        } else {
          context.showDsSnackBar('Profile saved', type: DsSnackBarType.success);
          _close();
        }
      },
      onError: (f) => setState(() => _serverError = f.message),
    );
  }

  void _close() => context.canPop() ? context.pop() : context.go(ClientRoutes.dashboard);

  void _back() {
    if (_step == 0) return _close();
    setState(() {
      _step = 0;
      _serverError = null;
    });
  }

  Future<void> _pickPin() async {
    final pin = await pickMapPin(context, initial: _pin);
    if (pin != null && mounted) setState(() => _pin = pin);
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(clientProfileProvider);
    if (!_initialized && profile.hasValue) _prefill(profile.value!);

    if (_done) {
      final first = _name.text.trim().split(RegExp(r'\s+')).first;
      return OnboardingSuccessView(
        icon: Icons.home_rounded,
        title: first.isEmpty ? 'You\'re all set!' : 'You\'re all set, $first!',
        message: 'Your profile is complete. Tell us who you need and your RM will find the right person.',
        nextSteps: const [
          (Icons.person_add_alt_1_rounded, 'Request a caretaker, nurse or cook.'),
          (Icons.how_to_reg_rounded, 'Your RM shortlists verified staff for you to choose.'),
          (Icons.event_available_rounded, 'Track attendance and daily care right here.'),
        ],
        primaryLabel: 'Request staff',
        onPrimary: () => context.go(ClientRoutes.staffRequestNew),
        secondaryLabel: 'Go to home',
        onSecondary: () => context.go(ClientRoutes.dashboard),
      );
    }

    final (line1, highlight, subtitle, icon) = _step == 0
        ? ('Welcome to', 'HomeGenny.', 'First, what should we call you?', Icons.waving_hand_rounded)
        : ('Where is', 'your home?', 'Your city decides your HomeGenny branch and RM.', Icons.home_rounded);

    return PopScope(
      canPop: _step == 0,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _back();
      },
      child: OnboardingWizardScaffold(
        steps: const ['Your name', 'Your home'],
        currentStep: _step,
        titleLine1: line1,
        titleHighlight: highlight,
        subtitle: subtitle,
        icon: icon,
        onBack: _back,
        bottom: profile.hasValue
            ? Row(
                children: [
                  if (_step > 0) ...[
                    Expanded(flex: 2, child: DsOutlineButton(label: 'Back', onPressed: _busy ? null : _back)),
                    const SizedBox(width: 12),
                  ],
                  Expanded(
                    flex: 3,
                    child: DsGradientButton(
                      label: _step == 0 ? 'Next' : 'Finish',
                      icon: _step == 0 ? Icons.arrow_forward_rounded : Icons.check_rounded,
                      isLoading: _busy,
                      onPressed: _busy ? null : _next,
                    ),
                  ),
                ],
              )
            : null,
        children: profile.when(
          loading: () => [const SizedBox(height: 80), const DsLoadingWidget(), const SizedBox(height: 80)],
          error: (e, _) => [
            DsErrorState(
              title: 'Could not load your profile',
              message: e.toString().replaceFirst('Exception: ', ''),
              onRetry: () => ref.invalidate(clientProfileProvider),
            ),
          ],
          data: (p) => [
            Form(
              key: _formKey,
              autovalidateMode: AutovalidateMode.onUserInteraction,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: _step == 0 ? _nameStep(p) : _homeStep(),
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

  List<Widget> _nameStep(ClientProfile p) => [
        const OnboardingSectionHeader(icon: Icons.person_rounded, title: 'About you', hint: 'Your RM will use this name'),
        DsLabeledField(
          label: 'Your name',
          controller: _name,
          icon: Icons.person_rounded,
          hint: 'Add your name',
          textCapitalization: TextCapitalization.words,
          validator: (v) => (v?.trim().length ?? 0) < 2 ? 'Enter your name' : null,
        ),
        const SizedBox(height: 16),
        DsLabeledField(
          label: 'Email',
          controller: _email,
          icon: Icons.mail_rounded,
          optional: true,
          keyboardType: TextInputType.emailAddress,
          validator: (v) => (v == null || v.trim().isEmpty || Validators.email(v) == null) ? null : 'Enter a valid email',
        ),
        const SizedBox(height: 16),
        DsNote(text: 'Signed in as +91 ${p.phone}. Your mobile number is your login and can\'t be changed.'),
      ];

  List<Widget> _homeStep() => [
        const OnboardingSectionHeader(icon: Icons.home_rounded, title: 'Your home', hint: 'Where your staff will work'),
        ref.watch(citiesProvider).when(
              loading: () => const DsLoadingWidget(),
              error: (e, _) => const DsNote(
                tone: DsNoteTone.danger,
                text: 'Could not load the city list. Go back and try again.',
              ),
              data: (cities) => CityDropdown(
                cities: cities,
                value: _city,
                onChanged: (c) => setState(() => _city = c),
              ),
            ),
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
        const SizedBox(height: 16),
        DsListCard(
          icon: _pin == null ? Icons.add_location_alt_rounded : Icons.location_on_rounded,
          title: _pin == null ? 'Pin your home on the map' : 'Home pinned',
          subtitle: _pin == null
              ? 'Optional — helps staff check in at the right place'
              : '${_pin!.latitude.toStringAsFixed(5)}, ${_pin!.longitude.toStringAsFixed(5)} · tap to change',
          trailing: const Icon(Icons.chevron_right_rounded),
          onTap: _pickPin,
        ),
      ];
}
