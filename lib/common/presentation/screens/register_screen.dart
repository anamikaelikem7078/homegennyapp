import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/utils/validators.dart';
import '../providers/auth_provider.dart';
import '../viewmodels/register_viewmodel.dart';

enum _RegisterRole { client, staff }  

const _genderOptions = ['MALE', 'FEMALE', 'OTHER'];
const _seriesOptions = <String, String>{
  'MAID': 'Maid / Domestic Help',
  'SC': 'Skilled Care (Nurse, Attendant)',
  'UC': 'Unskilled Care (Helper, Security)',
  'DR': 'Driver',
};

/// Premium sign-up screen redesigned with HomeGenny's design system tokens,
/// Plus Jakarta Sans typography, and modern form components.
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
    _role = widget.initialRole == 'staff' ? _RegisterRole.staff : _RegisterRole.client;
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
      'emailInvalid' || 'phoneInvalid' => 'Enter a valid 10-digit mobile number',
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
                  primary: AppColors.primary,
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
    if (!_formKey.currentState!.validate()) return;

    if (_role == _RegisterRole.staff) {
      if (_dateOfBirth == null) {
        context.showAppSnackBar('Please select your date of birth', isError: true);
        return;
      }
      if (_gender == null) {
        context.showAppSnackBar('Please select your gender', isError: true);
        return;
      }
      if (_series == null) {
        context.showAppSnackBar('Please select your work category', isError: true);
        return;
      }
    }

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
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final registerState = ref.watch(registerViewModelProvider);

    ref.listen(registerViewModelProvider, (prev, next) {
      if (next.errorMessage != null && next.errorMessage != prev?.errorMessage) {
        context.showAppSnackBar(next.errorMessage!, isError: true);
      }
    });

    return Scaffold(
      backgroundColor: isDark ? AppColors.darkBackground : AppColors.lightBackground,
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Center(
            child: ResponsiveLayout(
              maxWidth: 540,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildTopNav(isDark),
                  const SizedBox(height: 16),
                  _buildHeader(isDark).animate().fadeIn(duration: 300.ms).slideY(begin: -0.05, end: 0),
                  const SizedBox(height: 28),
                  _buildRoleToggle(isDark).animate().fadeIn(duration: 350.ms),
                  const SizedBox(height: 28),
                  _buildForm(registerState.isLoading, isDark)
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.04, end: 0),
                  const SizedBox(height: 32),
                  _buildFooter(isDark),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopNav(bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => context.go(AppRoutes.login),
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkSurface : AppColors.lightSurface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
                width: 1,
              ),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withValues(alpha: isDark ? 0.2 : 0.04),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 18,
              color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Column(
      children: [
        // Brand icon badge with soft container & subtle glow
        Container(
          width: 64,
          height: 64,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColors.primary.withValues(alpha: 0.15),
                AppColors.primaryContainer.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: AppColors.primary.withValues(alpha: 0.25),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: AppColors.primary.withValues(alpha: 0.12),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Icon(
              Icons.person_add_rounded,
              color: AppColors.primary,
              size: 30,
            ),
          ),
        ),
        const SizedBox(height: 18),
        Text(
          'Create your account',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 26,
            fontWeight: FontWeight.w700,
            color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
            letterSpacing: -0.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Tell us a little about yourself to get started.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _buildRoleToggle(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark ? AppColors.darkBorder : AppColors.lightBorder,
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: _roleSegment(
              title: 'Client',
              subtitle: 'Hire verified help',
              icon: Icons.person_outline_rounded,
              role: _RegisterRole.client,
              isDark: isDark,
            ),
          ),
          Expanded(
            child: _roleSegment(
              title: 'Staff',
              subtitle: 'Join as service professional',
              icon: Icons.badge_outlined,
              role: _RegisterRole.staff,
              isDark: isDark,
            ),
          ),
        ],
      ),
    );
  }

  Widget _roleSegment({
    required String title,
    required String subtitle,
    required IconData icon,
    required _RegisterRole role,
    required bool isDark,
  }) {
    final isSelected = _role == role;
    return GestureDetector(
      onTap: () => setState(() => _role = role),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 220),
        curve: Curves.easeInOut,
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? (isDark ? AppColors.primary : AppColors.primary)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.28),
                    blurRadius: 10,
                    offset: const Offset(0, 3),
                  ),
                ]
              : null,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected
                  ? Colors.white
                  : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
            ),
            const SizedBox(width: 8),
            Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected
                    ? Colors.white
                    : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildForm(bool isLoading, bool isDark) {
    return Form(
      key: _formKey,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Basic Information
          _buildSectionHeader('PERSONAL INFORMATION', Icons.badge_outlined, isDark),
          const SizedBox(height: 14),

          _buildField(
            label: 'Full Name',
            isRequired: true,
            isDark: isDark,
            child: _buildStyledTextField(
              controller: _fullNameController,
              hint: 'Anita Sharma',
              prefixIcon: Icons.person_outline_rounded,
              validator: (v) => _localizedValidator(Validators.name(v)),
              textCapitalization: TextCapitalization.words,
              textInputAction: TextInputAction.next,
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),

          _buildField(
            label: 'Mobile Number',
            isRequired: true,
            isDark: isDark,
            child: _buildStyledTextField(
              controller: _phoneController,
              hint: '9876543210',
              prefixIcon: Icons.phone_android_rounded,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.next,
              validator: (v) => _localizedValidator(Validators.phone(v)),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),

          if (_role == _RegisterRole.staff) ...[
            _buildField(
              label: 'Alternate Number',
              isOptional: true,
              isDark: isDark,
              child: _buildStyledTextField(
                controller: _alternatePhoneController,
                hint: '9876543211',
                prefixIcon: Icons.phone_outlined,
                keyboardType: TextInputType.phone,
                maxLength: 10,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textInputAction: TextInputAction.next,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),
          ],

          _buildField(
            label: 'Email Address',
            isOptional: true,
            isDark: isDark,
            child: _buildStyledTextField(
              controller: _emailController,
              hint: 'you@example.com',
              prefixIcon: Icons.mail_outline_rounded,
              keyboardType: TextInputType.emailAddress,
              textInputAction: TextInputAction.next,
              validator: (v) {
                if (v == null || v.trim().isEmpty) return null;
                return _localizedValidator(Validators.email(v));
              },
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 24),

          // Section 2: Security
          _buildSectionHeader('SECURITY', Icons.lock_outline_rounded, isDark),
          const SizedBox(height: 14),

          _buildField(
            label: 'Password',
            isRequired: true,
            isDark: isDark,
            child: _buildStyledTextField(
              controller: _passwordController,
              hint: '••••••••',
              prefixIcon: Icons.lock_outline_rounded,
              obscureText: _obscurePassword,
              textInputAction: TextInputAction.next,
              suffixIcon: IconButton(
                icon: Icon(
                  _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                  color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  size: 20,
                ),
                onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
              ),
              validator: (v) => _localizedValidator(Validators.registerPassword(v)),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              'Minimum 8 characters with upper & lower case, number & symbol.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Section 3: Role Specific
          if (_role == _RegisterRole.staff) ...[
            _buildSectionHeader('PROFESSIONAL PROFILE', Icons.work_outline_rounded, isDark),
            const SizedBox(height: 14),

            _buildField(
              label: 'Date of Birth',
              isRequired: true,
              isDark: isDark,
              child: _buildDateOfBirthField(isDark),
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'Gender',
              isRequired: true,
              isDark: isDark,
              child: _buildDropdownField(
                value: _gender,
                hint: 'Select gender',
                prefixIcon: Icons.wc_rounded,
                items: _genderOptions,
                labelBuilder: (v) => v[0] + v.substring(1).toLowerCase(),
                onChanged: (v) => setState(() => _gender = v),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'Work Category',
              isRequired: true,
              isDark: isDark,
              child: _buildDropdownField(
                value: _series,
                hint: 'Select work specialization',
                prefixIcon: Icons.category_outlined,
                items: _seriesOptions.keys.toList(),
                labelBuilder: (v) => _seriesOptions[v]!,
                onChanged: (v) => setState(() => _series = v),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 24),
          ],

          if (_role == _RegisterRole.client) ...[
            _buildSectionHeader('ACCOUNT & TAX DETAILS', Icons.business_outlined, isDark),
            const SizedBox(height: 14),

            _buildField(
              label: 'Residence / Business Name',
              isOptional: true,
              isDark: isDark,
              child: _buildStyledTextField(
                controller: _businessNameController,
                hint: 'Sharma Residence',
                prefixIcon: Icons.storefront_outlined,
                textCapitalization: TextCapitalization.words,
                textInputAction: TextInputAction.next,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'PAN Card Number',
              isRequired: true,
              isDark: isDark,
              child: _buildStyledTextField(
                controller: _panCardController,
                hint: 'ABCDE1234F',
                prefixIcon: Icons.credit_card_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                textInputAction: TextInputAction.next,
                validator: (v) => _localizedValidator(Validators.required(v, 'panCard')),
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 16),

            _buildField(
              label: 'GSTIN',
              isOptional: true,
              isDark: isDark,
              child: _buildStyledTextField(
                controller: _gstnController,
                hint: '09ABCDE1234F1Z5',
                prefixIcon: Icons.receipt_long_outlined,
                textCapitalization: TextCapitalization.characters,
                inputFormatters: [UpperCaseTextFormatter()],
                textInputAction: TextInputAction.next,
                isDark: isDark,
              ),
            ),
            const SizedBox(height: 24),
          ],

          // Section 4: Address
          _buildSectionHeader('ADDRESS DETAILS', Icons.location_on_outlined, isDark),
          const SizedBox(height: 14),

          _buildField(
            label: 'Address',
            isRequired: true,
            isDark: isDark,
            child: _buildStyledTextField(
              controller: _addressController,
              hint: 'House / Flat No., Street, Locality',
              prefixIcon: Icons.home_outlined,
              maxLines: 2,
              textInputAction: TextInputAction.next,
              validator: (v) => _localizedValidator(Validators.required(v, 'address')),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 16),

          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: _buildField(
                  label: 'City',
                  isDark: isDark,
                  child: _buildStyledTextField(
                    controller: _cityController,
                    hint: 'Noida',
                    prefixIcon: Icons.location_city_outlined,
                    textInputAction: TextInputAction.next,
                    isDark: isDark,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: _buildField(
                  label: 'State',
                  isDark: isDark,
                  child: _buildStyledTextField(
                    controller: _stateController,
                    hint: 'Uttar Pradesh',
                    prefixIcon: Icons.map_outlined,
                    textInputAction: TextInputAction.next,
                    isDark: isDark,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          _buildField(
            label: 'Pincode',
            isDark: isDark,
            child: _buildStyledTextField(
              controller: _pincodeController,
              hint: '201301',
              prefixIcon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              maxLength: 6,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) => _onSubmit(),
              isDark: isDark,
            ),
          ),
          const SizedBox(height: 28),

          // Submit CTA Button
          Container(
            width: double.infinity,
            height: 52,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(14),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.35),
                  blurRadius: 14,
                  offset: const Offset(0, 5),
                ),
              ],
            ),
            child: ElevatedButton(
              onPressed: isLoading ? null : _onSubmit,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                elevation: 0,
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
              child: isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.4,
                        color: Colors.white,
                      ),
                    )
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Create Account',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 0.3,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward_rounded, size: 18),
                      ],
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon, bool isDark) {
    return Row(
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.8,
            color: AppColors.primary,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Container(
            height: 1,
            color: isDark
                ? AppColors.darkBorder.withValues(alpha: 0.5)
                : AppColors.lightBorder,
          ),
        ),
      ],
    );
  }

  Widget _buildField({
    required String label,
    required Widget child,
    required bool isDark,
    bool isRequired = false,
    bool isOptional = false,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
              ),
            ),
            if (isRequired) ...[
              const SizedBox(width: 4),
              Text(
                '*',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppColors.error,
                ),
              ),
            ],
            if (isOptional) ...[
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1.5),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurfaceVariant : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'Optional',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
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

  Widget _buildStyledTextField({
    required TextEditingController controller,
    required String hint,
    required IconData prefixIcon,
    required bool isDark,
    Widget? suffixIcon,
    bool obscureText = false,
    TextInputType? keyboardType,
    int? maxLength,
    int maxLines = 1,
    List<TextInputFormatter>? inputFormatters,
    TextCapitalization textCapitalization = TextCapitalization.none,
    TextInputAction? textInputAction,
    void Function(String)? onFieldSubmitted,
    String? Function(String?)? validator,
  }) {
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return TextFormField(
      controller: controller,
      obscureText: obscureText,
      keyboardType: keyboardType,
      maxLength: maxLength,
      maxLines: obscureText ? 1 : maxLines,
      inputFormatters: inputFormatters,
      textCapitalization: textCapitalization,
      textInputAction: textInputAction,
      onFieldSubmitted: onFieldSubmitted,
      cursorColor: AppColors.primary,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        ),
        filled: true,
        fillColor: surfaceColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        prefixIcon: Icon(prefixIcon, color: iconColor, size: 20),
        suffixIcon: suffixIcon,
        counterText: '',
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.8),
        ),
        errorStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
          color: AppColors.error,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildDateOfBirthField(bool isDark) {
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: _pickDateOfBirth,
        borderRadius: BorderRadius.circular(12),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            color: surfaceColor,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: borderColor, width: 1),
          ),
          child: Row(
            children: [
              Icon(Icons.calendar_today_outlined, color: iconColor, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _dateOfBirth == null
                      ? 'Select date of birth (DD/MM/YYYY)'
                      : '${_dateOfBirth!.day.toString().padLeft(2, '0')}/${_dateOfBirth!.month.toString().padLeft(2, '0')}/${_dateOfBirth!.year}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    color: _dateOfBirth == null
                        ? (isDark ? AppColors.darkTextHint : AppColors.lightTextHint)
                        : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                    fontWeight: _dateOfBirth == null ? FontWeight.w400 : FontWeight.w500,
                  ),
                ),
              ),
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: iconColor,
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
    required bool isDark,
  }) {
    final surfaceColor = isDark ? AppColors.darkSurface : Colors.white;
    final borderColor = isDark ? AppColors.darkBorder : AppColors.lightBorder;
    final iconColor = isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary;

    return DropdownButtonFormField<String>(
      initialValue: value,
      items: items
          .map((v) => DropdownMenuItem(
                value: v,
                child: Text(
                  labelBuilder(v),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
                  ),
                ),
              ))
          .toList(),
      onChanged: onChanged,
      icon: Icon(Icons.keyboard_arrow_down_rounded, color: iconColor, size: 22),
      dropdownColor: isDark ? AppColors.darkSurface : Colors.white,
      borderRadius: BorderRadius.circular(14),
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w500,
        color: isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
          color: isDark ? AppColors.darkTextHint : AppColors.lightTextHint,
        ),
        filled: true,
        fillColor: surfaceColor,
        isDense: true,
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        prefixIcon: Icon(prefixIcon, color: iconColor, size: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 1),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.primary, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.error, width: 1.2),
        ),
      ),
    );
  }

  Widget _buildFooter(bool isDark) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          'Already have an account? ',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w400,
            color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
          ),
        ),
        InkWell(
          onTap: () => context.go(AppRoutes.login),
          borderRadius: BorderRadius.circular(4),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
            child: Text(
              'Sign In',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Forces PAN/GSTN input to uppercase as the user types.
class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    return newValue.copyWith(text: newValue.text.toUpperCase());
  }
}
