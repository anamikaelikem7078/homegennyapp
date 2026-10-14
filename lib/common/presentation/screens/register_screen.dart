import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/series/series_catalog.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/register_viewmodel.dart';
enum _RegisterRole { client, staff }

const _genderOptions = ['MALE', 'FEMALE', 'OTHER'];
/// Friendlier picker text for known series; anything else uses the label
/// from GET /meta/series.
const _seriesDescriptions = <String, String>{
  'UC': 'Unskilled Caretaker (Helper, Attendant)',
  'SC': 'Skilled Caretaker (Nurse)',
  'CK': 'Cook',
};

// --- Palette (matches the login screen: blue brand, orange icons) ---
const Color _brand = Color(0xFF1A56FF);
const Color _brandLight = Color(0xFF2F6BFF);
const Color _brandDark = Color(0xFF1238B8);
const Color _brandSoft = Color(0xFFE8EEFF);
const Color _deepNavy = Color(0xFF0B1B4D);
const Color _iconAccent = AppColors.secondary;
const Color _iconAccentSoft = AppColors.secondaryContainer;
const Color _sunYellow = Color(0xFFFFD84D);
const Color _ink = Color(0xFF111827);
const Color _muted = Color(0xFF6B7280);
const Color _hint = Color(0xFF9CA3AF);
const Color _fieldFill = Color(0xFFF3F5FA);
const Color _error = Color(0xFFE5484D);

const double _heroHeight = 290;
const double _sheetOverlap = 36;
final _fieldRadius = BorderRadius.circular(16);

/// Sign-up screen: orange gradient hero with floating icons and a slide-up
/// form sheet, matching the login screen.
class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key, this.initialRole});

  /// 'staff' or 'client' — defaults to client.
  final String? initialRole;

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();

  late _RegisterRole _role;

  // Shared fields
  final _fullNameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _addressController = TextEditingController();
  final _cityController = TextEditingController();
  final _stateController = TextEditingController();
  final _pincodeController = TextEditingController();
  bool _obscurePassword = true;

  // Client-only fields
  final _businessNameController = TextEditingController();
  final _panCardController = TextEditingController();
  final _gstnController = TextEditingController();

  // Staff-only fields
  final _alternatePhoneController = TextEditingController();
  DateTime? _dateOfBirth;
  String? _gender;
  String? _series;

  @override
  void initState() {
    super.initState();
    _role = widget.initialRole == 'staff'
        ? _RegisterRole.staff
        : _RegisterRole.client;
  }

  @override
  void dispose() {
    _fullNameController.dispose();
    _phoneController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    _addressController.dispose();
    _cityController.dispose();
    _stateController.dispose();
    _pincodeController.dispose();
    _businessNameController.dispose();
    _panCardController.dispose();
    _gstnController.dispose();
    _alternatePhoneController.dispose();
    super.dispose();
  }

  String? _localizedValidator(String? key) {
    if (key == null) return null;
    return switch (key) {
      'emailRequired' || 'phoneRequired' => 'Mobile number is required',
      'emailInvalid' ||
      'phoneInvalid' => 'Enter a valid 10-digit mobile number',
      'passwordRequired' => context.l10n.passwordRequired,
      'passwordTooShort' => context.l10n.passwordTooShort,
      'passwordWeak' =>
        'Use 8+ characters with upper & lower case, a number, and a symbol (@ \$ ! % * ? & # - _)',
      'nameRequired' => 'Full name is required',
      'nameTooShort' => 'Name is too short',
      'addressRequired' => 'Address is required',
      'panCardRequired' => 'PAN card number is required',
      _ => key,
    };
  }

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _dateOfBirth ?? DateTime(now.year - 25, now.month, now.day),
      firstDate: DateTime(now.year - 100),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
              primary: _brand,
              onPrimary: Colors.white,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() => _dateOfBirth = picked);
    }
  }

  Future<void> _onSubmit() async {
    if (!_formKey.currentState!.validate()) {
      HapticFeedback.mediumImpact();
      return;
    }

    if (_role == _RegisterRole.staff) {
      if (_dateOfBirth == null) {
        context.showAppSnackBar(
          'Please select your date of birth',
          isError: true,
        );
        return;
      }
      if (_gender == null) {
        context.showAppSnackBar('Please select your gender', isError: true);
        return;
      }
      if (_series == null) {
        context.showAppSnackBar(
          'Please select your work category',
          isError: true,
        );
        return;
      }
    }
    HapticFeedback.lightImpact();

    final phone = _phoneController.text.trim();
    final notifier = ref.read(registerViewModelProvider.notifier);

    final success = _role == _RegisterRole.client
        ? await notifier.registerCustomer(
            fullName: _fullNameController.text.trim(),
            phone: phone,
            email: _emailController.text.trim(),
            password: _passwordController.text,
            businessName: _businessNameController.text.trim(),
            panCard: _panCardController.text.trim(),
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            stateName: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            gstn: _gstnController.text.trim(),
          )
        : await notifier.registerStaff(
            fullName: _fullNameController.text.trim(),
            phone: phone,
            alternatePhone: _alternatePhoneController.text.trim(),
            email: _emailController.text.trim(),
            password: _passwordController.text,
            dateOfBirth:
                '${_dateOfBirth!.year.toString().padLeft(4, '0')}-${_dateOfBirth!.month.toString().padLeft(2, '0')}-${_dateOfBirth!.day.toString().padLeft(2, '0')}',
            gender: _gender!,
            address: _addressController.text.trim(),
            city: _cityController.text.trim(),
            stateName: _stateController.text.trim(),
            pincode: _pincodeController.text.trim(),
            series: _series!,
          );

    if (!mounted || !success) return;

    final user = ref.read(registerViewModelProvider).user;
    if (user == null) return;

    ref.read(authProvider.notifier).setAuthenticated(user);
    context.go(user.role.dashboardRoute);
  }

  @override
  Widget build(BuildContext context) {
    final registerState = ref.watch(registerViewModelProvider);

    ref.listen(registerViewModelProvider, (prev, next) {
      if (next.errorMessage != null &&
          next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SingleChildScrollView(
          physics: const ClampingScrollPhysics(),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 540),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _Hero(onBack: () => context.go(AppRoutes.login)),
                  Transform.translate(
                    offset: const Offset(0, -_sheetOverlap),
                    child: _buildSheet(registerState.isLoading),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSheet(bool isLoading) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 14, 24, 8),
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 22),
            Text(
              'I want to join as',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: _muted,
              ),
            ),
            const SizedBox(height: 10),
            _RoleToggle(
              role: _role,
              onChanged: (r) {
                HapticFeedback.selectionClick();
                setState(() => _role = r);
              },
            ),
            const SizedBox(height: 28),
            ..._buildFormSections(isLoading),
            const SizedBox(height: 26),
            _buildFooter(),
            const SizedBox(height: 12),
          ]
              .animate(interval: 60.ms, delay: 250.ms)
              .fadeIn(duration: 420.ms)
              .slideY(begin: 0.2, end: 0, curve: Curves.easeOutCubic),
        ),
      ),
    )
        .animate()
        .slideY(
          begin: 0.3,
          end: 0,
          duration: 650.ms,
          curve: Curves.easeOutQuart,
        )
        .fadeIn(duration: 400.ms);
  }

  List<Widget> _buildFormSections(bool isLoading) {
    final isStaff = _role == _RegisterRole.staff;

    return [
      // 1 · Personal information
      const _SectionHeader(
        step: 1,
        title: 'Personal details',
        icon: Icons.person_rounded,
      ),
      const SizedBox(height: 16),
      _buildField(
        label: 'Full Name',
        isRequired: true,
        child: _textField(
          controller: _fullNameController,
          hint: 'Anita Sharma',
          prefixIcon: Icons.person_outline_rounded,
          validator: (v) => _localizedValidator(Validators.name(v)),
          textCapitalization: TextCapitalization.words,
          textInputAction: TextInputAction.next,
        ),
      ),
      const SizedBox(height: 16),
      _buildField(
        label: 'Mobile Number',
        isRequired: true,
        child: _textField(
          controller: _phoneController,
          hint: '9876543210',
          prefix: const _CountryPrefix(),
          keyboardType: TextInputType.phone,
          maxLength: 10,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.next,
          validator: (v) => _localizedValidator(Validators.phone(v)),
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 16),
      _RoleSwitcher(
        child: isStaff
            ? Padding(
                key: const ValueKey('alt-phone'),
                padding: const EdgeInsets.only(bottom: 16),
                child: _buildField(
                  label: 'Alternate Number',
                  isOptional: true,
                  child: _textField(
                    controller: _alternatePhoneController,
                    hint: '9876543211',
                    prefix: const _CountryPrefix(),
                    keyboardType: TextInputType.phone,
                    maxLength: 10,
                    inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                    textInputAction: TextInputAction.next,
                    letterSpacing: 1,
                  ),
                ),
              )
            : const SizedBox.shrink(key: ValueKey('no-alt-phone')),
      ),
      _buildField(
        label: 'Email Address',
        isOptional: true,
        child: _textField(
          controller: _emailController,
          hint: 'you@example.com',
          prefixIcon: Icons.mail_outline_rounded,
          keyboardType: TextInputType.emailAddress,
          textInputAction: TextInputAction.next,
          validator: (v) {
            if (v == null || v.trim().isEmpty) return null;
            return _localizedValidator(Validators.email(v));
          },
        ),
      ),
      const SizedBox(height: 30),

      // 2 · Security
      const _SectionHeader(
        step: 2,
        title: 'Secure your account',
        icon: Icons.lock_rounded,
      ),
      const SizedBox(height: 16),
      _buildField(
        label: 'Password',
        isRequired: true,
        child: _textField(
          controller: _passwordController,
          hint: 'Create a strong password',
          prefixIcon: Icons.lock_outline_rounded,
          obscureText: _obscurePassword,
          textInputAction: TextInputAction.next,
          letterSpacing: _obscurePassword ? 3 : 0.2,
          suffix: IconButton(
            splashRadius: 20,
            onPressed: () =>
                setState(() => _obscurePassword = !_obscurePassword),
            icon: AnimatedSwitcher(
              duration: 250.ms,
              transitionBuilder: (child, anim) => RotationTransition(
                turns: Tween(begin: 0.75, end: 1.0).animate(anim),
                child: FadeTransition(opacity: anim, child: child),
              ),
              child: Icon(
                _obscurePassword
                    ? Icons.visibility_off_rounded
                    : Icons.visibility_rounded,
                key: ValueKey(_obscurePassword),
                color: _muted,
                size: 20,
              ),
            ),
          ),
          validator: (v) => _localizedValidator(Validators.registerPassword(v)),
        ),
      ),
      const SizedBox(height: 10),
      _PasswordStrength(controller: _passwordController),
      const SizedBox(height: 30),

      // 3 · Role-specific
      _RoleSwitcher(
        child: isStaff
            ? Column(
                key: const ValueKey('staff'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(
                    step: 3,
                    title: 'Professional profile',
                    icon: Icons.work_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Date of Birth',
                    isRequired: true,
                    child: _buildDateOfBirthField(),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Gender',
                    isRequired: true,
                    child: _GenderChips(
                      value: _gender,
                      onChanged: (v) {
                        HapticFeedback.selectionClick();
                        setState(() => _gender = v);
                      },
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Work Category',
                    isRequired: true,
                    child: Builder(builder: (context) {
                      // Only series taken on right now (GET /meta/series).
                      final active = ref.watch(seriesCatalogProvider).active;
                      final items = [for (final s in active) s.short];
                      return _buildDropdownField(
                        value: items.contains(_series) ? _series : null,
                        hint: 'Select work specialization',
                        prefixIcon: Icons.category_outlined,
                        items: items,
                        labelBuilder: (v) => _seriesDescriptions[v] ??
                            active.firstWhere((s) => s.short == v).label,
                        onChanged: (v) => setState(() => _series = v),
                      );
                    }),
                  ),
                  const SizedBox(height: 30),
                ],
              )
            : Column(
                key: const ValueKey('client'),
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const _SectionHeader(
                    step: 3,
                    title: 'Account & tax details',
                    icon: Icons.business_rounded,
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'Residence / Business Name',
                    isOptional: true,
                    child: _textField(
                      controller: _businessNameController,
                      hint: 'Sharma Residence',
                      prefixIcon: Icons.storefront_outlined,
                      textCapitalization: TextCapitalization.words,
                      textInputAction: TextInputAction.next,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'PAN Card Number',
                    isRequired: true,
                    child: _textField(
                      controller: _panCardController,
                      hint: 'ABCDE1234F',
                      prefixIcon: Icons.credit_card_outlined,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textInputAction: TextInputAction.next,
                      letterSpacing: 1,
                      validator: (v) => _localizedValidator(
                        Validators.required(v, 'panCard'),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildField(
                    label: 'GSTIN',
                    isOptional: true,
                    child: _textField(
                      controller: _gstnController,
                      hint: '09ABCDE1234F1Z5',
                      prefixIcon: Icons.receipt_long_outlined,
                      textCapitalization: TextCapitalization.characters,
                      inputFormatters: [UpperCaseTextFormatter()],
                      textInputAction: TextInputAction.next,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
      ),

      // 4 · Address
      const _SectionHeader(
        step: 4,
        title: 'Where are you located?',
        icon: Icons.location_on_rounded,
      ),
      const SizedBox(height: 16),
      _buildField(
        label: 'Address',
        isRequired: true,
        child: _textField(
          controller: _addressController,
          hint: 'House / Flat No., Street, Locality',
          prefixIcon: Icons.home_outlined,
          maxLines: 2,
          textInputAction: TextInputAction.next,
          validator: (v) =>
              _localizedValidator(Validators.required(v, 'address')),
        ),
      ),
      const SizedBox(height: 16),
      Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: _buildField(
              label: 'City',
              child: _textField(
                controller: _cityController,
                hint: 'Noida',
                prefixIcon: Icons.location_city_outlined,
                textInputAction: TextInputAction.next,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _buildField(
              label: 'State',
              child: _textField(
                controller: _stateController,
                hint: 'Uttar Pradesh',
                prefixIcon: Icons.map_outlined,
                textInputAction: TextInputAction.next,
              ),
            ),
          ),
        ],
      ),
      const SizedBox(height: 16),
      _buildField(
        label: 'Pincode',
        child: _textField(
          controller: _pincodeController,
          hint: '201301',
          prefixIcon: Icons.pin_drop_outlined,
          keyboardType: TextInputType.number,
          maxLength: 6,
          inputFormatters: [FilteringTextInputFormatter.digitsOnly],
          textInputAction: TextInputAction.done,
          onFieldSubmitted: (_) => _onSubmit(),
          letterSpacing: 1,
        ),
      ),
      const SizedBox(height: 30),

      _PrimaryButton(isLoading: isLoading, onPressed: _onSubmit),
      const SizedBox(height: 14),
      Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.verified_user_rounded, size: 14, color: _hint),
          const SizedBox(width: 6),
          Text(
            'Your details are encrypted and kept private',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _hint,
            ),
          ),
        ],
      ),
    ];
  }

  Widget _buildField({
    required String label,
    required Widget child,
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Flexible(
              child: Text(
                label,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: _ink,
                ),
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 3),
              Text(
                '*',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: _error,
                ),
              ),
            ],
            if (isOptional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                decoration: BoxDecoration(
                  color: _brandSoft,
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _brand,
                  ),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 8),
        child,
      ],
    );
  }

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    IconData? prefixIcon,
    Widget? prefix,
    Widget? suffix,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
    double letterSpacing = 0,
  }) {
    return _GlowField(
      child: TextFormField(
        controller: controller,
        obscureText: obscureText,
        keyboardType: keyboardType,
        maxLength: maxLength,
        maxLines: obscureText ? 1 : maxLines,
        inputFormatters: inputFormatters,
        textCapitalization: textCapitalization,
        textInputAction: textInputAction,
        onFieldSubmitted: onFieldSubmitted,
        cursorColor: _brand,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: _ink,
          letterSpacing: letterSpacing,
        ),
        decoration: _inputDecoration(
          hint: hint,
          prefix:
              prefix ??
              Padding(
                padding: const EdgeInsets.only(left: 16, right: 10),
                child: Icon(prefixIcon, color: _iconAccent, size: 20),
              ),
          suffix: suffix,
        ),
        validator: validator,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: GoogleFonts.plusJakartaSans(
        color: _hint,
        fontSize: 14.5,
        fontWeight: FontWeight.w500,
        letterSpacing: 0,
      ),
      errorStyle: GoogleFonts.plusJakartaSans(
        color: _error,
        fontSize: 12,
        fontWeight: FontWeight.w600,
      ),
      errorMaxLines: 3,
      filled: true,
      fillColor: _fieldFill,
      counterText: '',
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
      prefixIcon: prefix,
      prefixIconConstraints: const BoxConstraints(minWidth: 0, minHeight: 0),
      suffixIcon: suffix,
      border: OutlineInputBorder(
        borderSide: BorderSide.none,
        borderRadius: _fieldRadius,
      ),
      enabledBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.transparent),
        borderRadius: _fieldRadius,
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _brand, width: 1.6),
        borderRadius: _fieldRadius,
      ),
      errorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _error),
        borderRadius: _fieldRadius,
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: _error, width: 1.6),
        borderRadius: _fieldRadius,
      ),
    );
  }

  Widget _buildDateOfBirthField() {
    final hasValue = _dateOfBirth != null;
    return Material(
      color: _fieldFill,
      borderRadius: _fieldRadius,
      child: InkWell(
        onTap: _pickDateOfBirth,
        borderRadius: _fieldRadius,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 17),
          child: Row(
            children: [
              const Icon(Icons.cake_outlined, color: _iconAccent, size: 20),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  hasValue
                      ? '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}'
                      : 'DD / MM / YYYY',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: hasValue ? 15 : 14.5,
                    color: hasValue ? _ink : _hint,
                    fontWeight: hasValue ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
              const Icon(
                Icons.calendar_month_rounded,
                color: _iconAccent,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDropdownField({
    required String? value,
    required String hint,
    required IconData prefixIcon,
    required List<String> items,
    required String Function(String) labelBuilder,
    required ValueChanged<String?> onChanged,
  }) {
    return DropdownButtonFormField<String>(
      initialValue: value,
      isExpanded: true,
      items: items
          .map(
            (v) => DropdownMenuItem(
              value: v,
              child: Text(
                labelBuilder(v),
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w600,
                  color: _ink,
                ),
              ),
            ),
          )
          .toList(),
      onChanged: onChanged,
      icon: const Icon(
        Icons.keyboard_arrow_down_rounded,
        color: _iconAccent,
        size: 24,
      ),
      dropdownColor: Colors.white,
      borderRadius: BorderRadius.circular(16),
      decoration: _inputDecoration(
        hint: hint,
        prefix: Padding(
          padding: const EdgeInsets.only(left: 16, right: 10),
          child: Icon(prefixIcon, color: _iconAccent, size: 20),
        ),
      ),
    );
  }

  Widget _buildFooter() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: _muted,
          ),
        ),
        GestureDetector(
          onTap: () => context.go(AppRoutes.login),
          child: Text(
            'Sign in',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: _brand,
              decoration: TextDecoration.underline,
              decorationColor: _brand.withValues(alpha: 0.35),
              decorationThickness: 2,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Hero
// ---------------------------------------------------------------------------

class _Hero extends StatelessWidget {
  const _Hero({required this.onBack});

  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    final topInset = MediaQuery.paddingOf(context).top;

    return Container(
      height: _heroHeight + topInset,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [_deepNavy, _brandDark, _brand],
        ),
      ),
      child: Stack(
        clipBehavior: Clip.hardEdge,
        children: [
          Positioned(
            top: -70,
            right: -50,
            child: _Blob(size: 230, color: _sunYellow.withValues(alpha: 0.22)),
          ),
          Positioned(
            bottom: 0,
            left: -80,
            child: _Blob(
              size: 210,
              color: Colors.white.withValues(alpha: 0.08),
            ),
          ),

          // Floating icons
          Positioned(
            top: topInset + 64,
            right: 26,
            child: const _FloatingIcon(
              icon: Icons.home_rounded,
              color: _iconAccent,
              delay: 0,
            ),
          ),
          Positioned(
            top: topInset + 140,
            right: 92,
            child: const _FloatingIcon(
              icon: Icons.verified_rounded,
              color: _iconAccent,
              delay: 400,
              size: 44,
            ),
          ),
          Positioned(
            top: topInset + 178,
            right: 22,
            child: const _FloatingIcon(
              icon: Icons.handshake_rounded,
              color: _iconAccent,
              delay: 800,
              size: 48,
            ),
          ),

          Positioned(
            left: 20,
            right: 24,
            top: topInset + 12,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _BackButton(onTap: onBack)
                    .animate()
                    .fadeIn(duration: 400.ms)
                    .slideX(begin: -0.4, end: 0, curve: Curves.easeOutCubic),
                const SizedBox(height: 34),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.16),
                    borderRadius: BorderRadius.circular(30),
                    border: Border.all(
                      color: Colors.white.withValues(alpha: 0.25),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.auto_awesome_rounded,
                        color: _sunYellow,
                        size: 14,
                      ),
                      const SizedBox(width: 5),
                      Text(
                        'Takes under 2 minutes',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                )
                    .animate(delay: 150.ms)
                    .fadeIn(duration: 400.ms)
                    .scaleXY(begin: 0.8, end: 1, curve: Curves.easeOutBack),
                const SizedBox(height: 14),
                const _Headline(),
                const SizedBox(height: 10),
                Text(
                  'Tell us a little about yourself\nto get started.',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    height: 1.4,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                )
                    .animate(delay: 450.ms)
                    .fadeIn(duration: 500.ms)
                    .slideY(begin: 0.4, end: 0),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _BackButton extends StatelessWidget {
  const _BackButton({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.16),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(14),
        child: const SizedBox(
          width: 42,
          height: 42,
          child: Icon(
            Icons.arrow_back_ios_new_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
      ),
    );
  }
}

class _Headline extends StatelessWidget {
  const _Headline();

  @override
  Widget build(BuildContext context) {
    final base = GoogleFonts.plusJakartaSans(
      fontSize: 32,
      fontWeight: FontWeight.w800,
      color: Colors.white,
      height: 1.1,
      letterSpacing: -1,
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Create your', style: base)
            .animate(delay: 250.ms)
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
        Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned(
              left: -2,
              right: -4,
              bottom: 2,
              height: 10,
              child: Container(
                decoration: BoxDecoration(
                  color: _sunYellow.withValues(alpha: 0.85),
                  borderRadius: BorderRadius.circular(4),
                ),
              ).animate(delay: 750.ms).scaleX(
                begin: 0,
                end: 1,
                alignment: Alignment.centerLeft,
                duration: 500.ms,
                curve: Curves.easeOutCubic,
              ),
            ),
            Text('account.', style: base),
          ],
        )
            .animate(delay: 350.ms)
            .fadeIn(duration: 450.ms)
            .slideY(begin: 0.5, end: 0, curve: Curves.easeOutCubic),
      ],
    );
  }
}

class _Blob extends StatelessWidget {
  const _Blob({required this.size, required this.color});

  final double size;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(shape: BoxShape.circle, color: color),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .scaleXY(
          begin: 0.9,
          end: 1.1,
          duration: 4.seconds,
          curve: Curves.easeInOut,
        );
  }
}

class _FloatingIcon extends StatelessWidget {
  const _FloatingIcon({
    required this.icon,
    required this.color,
    required this.delay,
    this.size = 56,
  });

  final IconData icon;
  final Color color;
  final int delay;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(size * 0.32),
        border: Border.all(color: Colors.white.withValues(alpha: 0.25)),
      ),
      child: Icon(icon, color: color, size: size * 0.46),
    )
        .animate(delay: (300 + delay).ms)
        .fadeIn(duration: 500.ms)
        .scaleXY(begin: 0.4, end: 1, curve: Curves.easeOutBack, duration: 600.ms)
        .then()
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .moveY(begin: -6, end: 6, duration: 2200.ms, curve: Curves.easeInOut)
        .rotate(begin: -0.015, end: 0.015, duration: 2200.ms);
  }
}

// ---------------------------------------------------------------------------
// Form pieces
// ---------------------------------------------------------------------------

/// Segmented Client / Staff toggle with a sliding orange thumb.
class _RoleToggle extends StatelessWidget {
  const _RoleToggle({required this.role, required this.onChanged});

  final _RegisterRole role;
  final ValueChanged<_RegisterRole> onChanged;

  @override
  Widget build(BuildContext context) {
    final isClient = role == _RegisterRole.client;

    return Container(
      height: 64,
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: _fieldFill,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Stack(
        children: [
          AnimatedAlign(
            alignment: isClient ? Alignment.centerLeft : Alignment.centerRight,
            duration: 320.ms,
            curve: Curves.easeOutBack,
            child: FractionallySizedBox(
              widthFactor: 0.5,
              heightFactor: 1,
              child: Container(
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_brandLight, _brandDark],
                  ),
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: _brand.withValues(alpha: 0.35),
                      blurRadius: 14,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Row(
            children: [
              _segment(
                title: 'Client',
                subtitle: 'Hire verified help',
                icon: Icons.person_rounded,
                selected: isClient,
                onTap: () => onChanged(_RegisterRole.client),
              ),
              _segment(
                title: 'Staff',
                subtitle: 'Offer your services',
                icon: Icons.badge_rounded,
                selected: !isClient,
                onTap: () => onChanged(_RegisterRole.staff),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _segment({
    required String title,
    required String subtitle,
    required IconData icon,
    required bool selected,
    required VoidCallback onTap,
  }) {
    final fg = selected ? Colors.white : _ink;
    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: selected ? 1.1 : 1,
                duration: 250.ms,
                child: Icon(
                  icon,
                  size: 20,
                  color: selected ? fg : _iconAccent,
                ),
              ),
              const SizedBox(width: 8),
              Flexible(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    AnimatedDefaultTextStyle(
                      duration: 220.ms,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14.5,
                        fontWeight: FontWeight.w800,
                        color: fg,
                      ),
                      child: Text(title),
                    ),
                    AnimatedDefaultTextStyle(
                      duration: 220.ms,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10.5,
                        fontWeight: FontWeight.w600,
                        color: selected
                            ? Colors.white.withValues(alpha: 0.85)
                            : _muted,
                      ),
                      child: Text(
                        subtitle,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Animates size + crossfade/slide when role-specific content changes.
class _RoleSwitcher extends StatelessWidget {
  const _RoleSwitcher({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: 320.ms,
      curve: Curves.easeOutCubic,
      alignment: Alignment.topCenter,
      child: AnimatedSwitcher(
        duration: 320.ms,
        switchInCurve: Curves.easeOutCubic,
        switchOutCurve: Curves.easeInCubic,
        layoutBuilder: (current, previous) => Stack(
          alignment: Alignment.topCenter,
          children: [...previous, ?current],
        ),
        transitionBuilder: (child, anim) => FadeTransition(
          opacity: anim,
          child: SlideTransition(
            position: Tween(
              begin: const Offset(0, 0.06),
              end: Offset.zero,
            ).animate(anim),
            child: child,
          ),
        ),
        child: child,
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({
    required this.step,
    required this.title,
    required this.icon,
  });

  final int step;
  final String title;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: _iconAccentSoft,
            borderRadius: BorderRadius.circular(11),
          ),
          child: Icon(icon, size: 18, color: _iconAccent),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'STEP $step OF 4',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1,
                  color: _brand,
                ),
              ),
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 17,
                  fontWeight: FontWeight.w800,
                  color: _ink,
                  letterSpacing: -0.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

/// Live checklist that ticks off password rules as the user types.
class _PasswordStrength extends StatelessWidget {
  const _PasswordStrength({required this.controller});

  final TextEditingController controller;

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<TextEditingValue>(
      valueListenable: controller,
      builder: (context, value, _) {
        final p = value.text;
        final rules = <String, bool>{
          '8+ chars': p.length >= 8,
          'A-Z': p.contains(RegExp(r'[A-Z]')),
          'a-z': p.contains(RegExp(r'[a-z]')),
          '0-9': p.contains(RegExp(r'\d')),
          'Symbol': p.contains(RegExp(r'[^A-Za-z0-9]')),
        };
        final met = rules.values.where((v) => v).length;
        final color = switch (met) {
          <= 2 => _error,
          < 5 => const Color(0xFFF59E0B),
          _ => const Color(0xFF16A34A),
        };

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: List.generate(5, (i) {
                return Expanded(
                  child: AnimatedContainer(
                    duration: 250.ms,
                    height: 5,
                    margin: EdgeInsets.only(right: i == 4 ? 0 : 5),
                    decoration: BoxDecoration(
                      color: i < met ? color : const Color(0xFFE5E7EB),
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                );
              }),
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: rules.entries.map((e) {
                return AnimatedContainer(
                  duration: 220.ms,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: e.value
                        ? const Color(0xFFDCFCE7)
                        : const Color(0xFFF3F4F6),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        e.value
                            ? Icons.check_circle_rounded
                            : Icons.circle_outlined,
                        size: 12,
                        color: e.value ? const Color(0xFF16A34A) : _hint,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        e.key,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                          color: e.value ? const Color(0xFF15803D) : _muted,
                        ),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        );
      },
    );
  }
}

class _GenderChips extends StatelessWidget {
  const _GenderChips({required this.value, required this.onChanged});

  final String? value;
  final ValueChanged<String> onChanged;

  static const _icons = {
    'MALE': Icons.male_rounded,
    'FEMALE': Icons.female_rounded,
    'OTHER': Icons.transgender_rounded,
  };

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        for (final g in _genderOptions) ...[
          Expanded(
            child: GestureDetector(
              onTap: () => onChanged(g),
              child: AnimatedContainer(
                duration: 220.ms,
                curve: Curves.easeOut,
                height: 52,
                decoration: BoxDecoration(
                  color: value == g ? _brandSoft : _fieldFill,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: value == g ? _brand : Colors.transparent,
                    width: 1.6,
                  ),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _icons[g],
                      size: 18,
                      color: _iconAccent,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      g[0] + g.substring(1).toLowerCase(),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w700,
                        color: value == g ? _brand : _ink,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          if (g != _genderOptions.last) const SizedBox(width: 8),
        ],
      ],
    );
  }
}

/// Adds a soft brand-colored glow while the wrapped field has focus.
class _GlowField extends StatefulWidget {
  const _GlowField({required this.child});

  final Widget child;

  @override
  State<_GlowField> createState() => _GlowFieldState();
}

class _GlowFieldState extends State<_GlowField> {
  bool _focused = false;

  @override
  Widget build(BuildContext context) {
    return Focus(
      skipTraversal: true,
      onFocusChange: (f) => setState(() => _focused = f),
      child: AnimatedContainer(
        duration: 220.ms,
        curve: Curves.easeOut,
        decoration: BoxDecoration(
          borderRadius: _fieldRadius,
          boxShadow: [
            BoxShadow(
              color: _brand.withValues(alpha: _focused ? 0.18 : 0),
              blurRadius: _focused ? 18 : 0,
              offset: const Offset(0, 6),
            ),
          ],
        ),
        child: AnimatedScale(
          scale: _focused ? 1.012 : 1,
          duration: 220.ms,
          curve: Curves.easeOut,
          child: widget.child,
        ),
      ),
    );
  }
}

class _CountryPrefix extends StatelessWidget {
  const _CountryPrefix();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 16, right: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '+91',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: _ink,
            ),
          ),
          const SizedBox(width: 10),
          Container(width: 1.2, height: 22, color: const Color(0xFFD1D5DB)),
        ],
      ),
    );
  }
}

/// Pill CTA with press-scale, bouncing arrow and idle shimmer.
class _PrimaryButton extends StatefulWidget {
  const _PrimaryButton({required this.isLoading, required this.onPressed});

  final bool isLoading;
  final VoidCallback onPressed;

  @override
  State<_PrimaryButton> createState() => _PrimaryButtonState();
}

class _PrimaryButtonState extends State<_PrimaryButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = !widget.isLoading;

    final label = Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Create Account',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: Colors.white,
          ),
        ),
        const SizedBox(width: 10),
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: Colors.white.withValues(alpha: 0.22),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.arrow_forward_rounded,
            size: 18,
            color: Colors.white,
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .moveX(begin: 0, end: 4, duration: 700.ms, curve: Curves.easeInOut),
      ],
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapUp: enabled ? (_) => setState(() => _pressed = false) : null,
      onTapCancel: enabled ? () => setState(() => _pressed = false) : null,
      onTap: enabled ? widget.onPressed : null,
      child: AnimatedScale(
        scale: _pressed ? 0.96 : 1,
        duration: 120.ms,
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: 250.ms,
          height: 58,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(30),
            gradient: const LinearGradient(
              colors: [
                _brandLight,
                _brand,
                _brandDark,
              ],
            ),
            boxShadow: [
              BoxShadow(
                color: _brand.withValues(alpha: _pressed ? 0.25 : 0.4),
                blurRadius: _pressed ? 10 : 22,
                offset: Offset(0, _pressed ? 4 : 10),
              ),
            ],
          ),
          clipBehavior: Clip.antiAlias,
          child: Center(
            child: AnimatedSwitcher(
              duration: 250.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: ScaleTransition(scale: anim, child: child),
              ),
              child: widget.isLoading
                  ? const SizedBox(
                      key: ValueKey('loading'),
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.6,
                        color: Colors.white,
                      ),
                    )
                  : KeyedSubtree(key: const ValueKey('label'), child: label),
            ),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              delay: 1800.ms,
              duration: 1400.ms,
              color: Colors.white.withValues(alpha: 0.3),
            ),
      ),
    );
  }
}

/// Forces PAN/GSTN input to uppercase as the user types.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
