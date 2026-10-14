import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../../../design_system/widgets/navigation/ds_navigation.dart';
import '../widgets/rm_stage_ui.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/series/series_catalog.dart';
import '../../../../core/utils/result.dart';
import '../../../../core/utils/validators.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';

/// S1 intake — the backend runs the restricted-list check *inside*
/// `POST /rm/intake` itself (no separate pre-check endpoint exists), so this
/// wizard collects every field across its steps and submits once at the
/// end; the outcome (`RESTRICTED` vs `ADVANCE_S2`) determines which result
/// screen is shown, instead of a fake pre-check.
class RmStaffIntakeScreen extends ConsumerStatefulWidget {
  const RmStaffIntakeScreen({super.key});

  @override
  ConsumerState<RmStaffIntakeScreen> createState() => _RmStaffIntakeScreenState();
}

class _RmStaffIntakeScreenState extends ConsumerState<RmStaffIntakeScreen> {
  final PageController _pageController = PageController();
  bool _submitting = false;

  String? _pickedSeries;

  /// The picked series, or the first active one until the RM picks.
  String get _selectedSeries {
    final active = _activeSeries;
    final picked = _pickedSeries;
    if (picked != null && active.contains(picked)) return picked;
    return active.isEmpty ? StaffSeries.unskilledCare : active.first;
  }

  set _selectedSeries(String value) => _pickedSeries = value;
  String _selectedPayment = 'Cash (Collected)';

  final _aadhaarController = TextEditingController();
  final _phoneController = TextEditingController();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  final _emailController = TextEditingController();
  final _dobController = TextEditingController();

  IntakeResult? _result;
  String? _submitError;

  @override
  void dispose() {
    _pageController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _addressController.dispose();
    _emailController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  void _goToPage(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _submitError = null;
    });

    final body = <String, dynamic>{
      'aadhaar_number': _aadhaarController.text.trim(),
      'mobile': _phoneController.text.trim(),
      'full_name': _nameController.text.trim(),
      'series': _selectedSeries,
      'deposit_amount': StaffSeries.depositFor(_selectedSeries),
      'deposit_collected': _selectedPayment.startsWith('Cash'),
      if (_dobController.text.trim().isNotEmpty) 'date_of_birth': _dobController.text.trim(),
      if (_addressController.text.trim().isNotEmpty) 'address': _addressController.text.trim(),
      if (_emailController.text.trim().isNotEmpty) 'email': _emailController.text.trim(),
    };

    final result = await ref.read(rmRepositoryProvider).submitIntake(body);
    if (!mounted) return;

    result.fold(
      onSuccess: (intake) {
        setState(() {
          _submitting = false;
          _result = intake;
        });
        if (!intake.isRestricted) {
          ref.read(intakeAadhaarProvider(intake.staff.id).notifier).state = _aadhaarController.text.trim();
        }
        ref.invalidate(rmKanbanProvider);
        ref.invalidate(rmDashboardProvider);
        _goToPage(3);
      },
      onError: (failure) {
        setState(() {
          _submitting = false;
          _submitError = failure.message;
        });
        _toast(failure.message);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    ref.watch(seriesCatalogProvider);
    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.dark,
      child: Scaffold(
        backgroundColor: RmTheme.offWhite,
        body: SafeArea(
          child: PageView(
            controller: _pageController,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildIdentityScreen(), // 0
              _buildPersonalDetailsScreen(), // 1
              _buildDepositScreen(), // 2
              _buildResultScreen(), // 3
            ],
          ),
        ),
      ),
    );
  }

  void _toast(String message, {bool error = true}) {
    HapticFeedback.mediumImpact();
    DsSnackBar.show(
      context,
      message: message,
      type: error ? DsSnackBarType.error : DsSnackBarType.warning,
    );
  }

  /// Shared step layout: back + step pill, progress, title, content card,
  /// and a pinned CTA.
  Widget _buildFormPage({
    required int step,
    required String title,
    required String subtitle,
    required IconData icon,
    required List<Widget> children,
    required Widget cta,
    required VoidCallback? onBack,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              DsBackButton(onPressed: onBack),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'New staff intake',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
              ),
              RmStatusPill(label: 'Step $step of 3', color: RmTheme.electricBlue),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
          child: _buildStepper(step),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(
                        color: RmTheme.iconAccentSoft,
                        borderRadius: BorderRadius.circular(17),
                      ),
                      child: Icon(icon, color: RmTheme.iconAccent, size: 26),
                    ).animate().scaleXY(
                          begin: 0.5,
                          end: 1,
                          duration: 550.ms,
                          curve: Curves.elasticOut,
                        ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 24,
                              fontWeight: FontWeight.w800,
                              letterSpacing: -0.6,
                              color: RmTheme.textPrimary,
                            ),
                          ),
                          Text(
                            subtitle,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.4,
                              fontWeight: FontWeight.w500,
                              color: RmTheme.textSecondary,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                ...children,
              ]
                  .animate(interval: 50.ms)
                  .fadeIn(duration: 350.ms)
                  .slideY(begin: 0.1, end: 0, curve: Curves.easeOutCubic),
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 14),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
            boxShadow: [
              BoxShadow(
                color: RmTheme.navy.withValues(alpha: 0.08),
                blurRadius: 24,
                offset: const Offset(0, -6),
              ),
            ],
          ),
          child: cta,
        ),
      ],
    );
  }

  /// Three-segment animated progress bar.
  Widget _buildStepper(int currentStep) {
    return Row(
      children: [
        for (var i = 1; i <= 3; i++) ...[
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: Stack(
                children: [
                  Container(height: 6, color: RmTheme.borderSubtle),
                  if (i <= currentStep)
                    Container(
                      height: 6,
                      decoration: const BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Color(0xFF2F6BFF), Color(0xFF1238B8)],
                        ),
                      ),
                    ).animate().scaleX(
                          begin: 0,
                          end: 1,
                          alignment: Alignment.centerLeft,
                          duration: 450.ms,
                          curve: Curves.easeOutCubic,
                        ),
                ],
              ),
            ),
          ),
          if (i < 3) const SizedBox(width: 6),
        ],
      ],
    );
  }

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: children,
      ),
    );
  }

  Widget _buildInput(
    String label,
    String hint, {
    required IconData icon,
    TextEditingController? controller,
    TextInputType? keyboardType,
    int? maxLength,
    List<TextInputFormatter>? inputFormatters,
    bool optional = false,
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
                fontWeight: FontWeight.w700,
                color: RmTheme.textPrimary,
              ),
            ),
            if (optional) ...[
              const SizedBox(width: 6),
              const RmStatusPill(label: 'Optional', color: RmTheme.electricBlue),
            ],
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          inputFormatters: inputFormatters,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: RmTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint,
            prefixIcon: Icon(icon, color: RmTheme.iconAccent, size: 20),
            counterText: '',
          ),
        ),
      ],
    );
  }

  // 0. Identity inputs — collected up front, submitted together with
  // everything else; the backend does the restricted-list check server-side
  // when the full form is submitted on the deposit page.
  Widget _buildIdentityScreen() {
    return _buildFormPage(
      step: 1,
      icon: Icons.fingerprint_rounded,
      title: 'Identity',
      subtitle: 'Aadhaar and phone are checked against the restricted list on submit.',
      onBack: () => context.pop(),
      cta: DsGradientButton(
        label: 'Continue',
        onPressed: () {
          final aadhaarError = Validators.aadhaar(_aadhaarController.text);
          final phoneError = Validators.phone(_phoneController.text);
          if (aadhaarError != null || phoneError != null) {
            _toast(aadhaarError != null
                ? 'Enter a valid 12-digit Aadhaar number'
                : 'Enter a valid 10-digit phone number');
            return;
          }
          _goToPage(1);
        },
      ),
      children: [
        _buildCard(
          children: [
            _buildInput(
              'Aadhaar number',
              '12-digit Aadhaar',
              icon: Icons.badge_rounded,
              controller: _aadhaarController,
              keyboardType: TextInputType.number,
              maxLength: 12,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 16),
            _buildInput(
              'Phone number',
              '10-digit mobile',
              icon: Icons.phone_rounded,
              controller: _phoneController,
              keyboardType: TextInputType.phone,
              maxLength: 10,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
          ],
        ),
        const SizedBox(height: 14),
        const RmNote(
          text: 'No separate pre-check — the backend verifies these details when '
              'you complete the intake.',
        ),
      ],
    );
  }

  // 1. Personal details + series
  Widget _buildPersonalDetailsScreen() {
    return _buildFormPage(
      step: 2,
      icon: Icons.person_rounded,
      title: 'Personal details',
      subtitle: 'Enter details exactly as they appear on the official ID.',
      onBack: () => _goToPage(0),
      cta: DsGradientButton(
        label: 'Next step',
        onPressed: () {
          if (_nameController.text.trim().isEmpty) {
            _toast('Please enter the full name', error: false);
            return;
          }
          _goToPage(2);
        },
      ),
      children: [
        _buildCard(
          children: [
            _buildInput('Full legal name', 'e.g. Ramesh Kumar Singh',
                icon: Icons.person_rounded, controller: _nameController),
            const SizedBox(height: 16),
            _buildInput('Date of birth', 'YYYY-MM-DD',
                icon: Icons.cake_rounded, controller: _dobController, optional: true),
            const SizedBox(height: 16),
            _buildInput('Address', 'Sector 12, Noida',
                icon: Icons.home_rounded, controller: _addressController, optional: true),
            const SizedBox(height: 16),
            _buildInput('Email', 'name@example.com',
                icon: Icons.mail_rounded,
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                optional: true),
          ],
        ),
        const RmSectionTitle(title: 'Staff series'),
        for (final series in _activeSeries) _buildSeriesCard(series),
      ],
    );
  }

  /// Short codes a new staff member may be created as (`GET /meta/series`).
  List<String> get _activeSeries =>
      [for (final s in ref.read(seriesCatalogProvider).active) s.short];

  IconData _seriesIcon(String series) => SeriesDisplay.icon(series);

  Widget _buildSeriesCard(String series) {
    final isSelected = _selectedSeries == series;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedSeries = series);
        },
        child: AnimatedContainer(
          duration: 220.ms,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8EEFF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(_seriesIcon(series), color: RmTheme.iconAccent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      StaffSeries.label(series),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      'Refundable deposit ₹${StaffSeries.depositFor(series)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              AnimatedContainer(
                duration: 200.ms,
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: isSelected ? RmTheme.electricBlue : Colors.transparent,
                  border: Border.all(
                    color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle,
                    width: 2,
                  ),
                ),
                child: isSelected
                    ? const Icon(Icons.check_rounded, size: 15, color: Colors.white)
                    : null,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 2. Deposit collection — final submit
  Widget _buildDepositScreen() {
    return _buildFormPage(
      step: 3,
      icon: Icons.account_balance_wallet_rounded,
      title: 'Deposit',
      subtitle: 'Collect the refundable deposit, then complete the intake.',
      onBack: _submitting ? null : () => _goToPage(1),
      cta: DsGradientButton(
        label: 'Complete intake',
        isLoading: _submitting,
        onPressed: _submitting ? null : _submit,
      ),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
            ),
            borderRadius: BorderRadius.circular(24),
            boxShadow: [
              BoxShadow(
                color: RmTheme.electricBlue.withValues(alpha: 0.28),
                blurRadius: 22,
                offset: const Offset(0, 10),
              ),
            ],
          ),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Refundable deposit',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                    Text(
                      '₹${StaffSeries.depositFor(_selectedSeries)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -1,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    RmBannerChip(
                      icon: _seriesIcon(_selectedSeries),
                      label: StaffSeries.label(_selectedSeries),
                    ),
                  ],
                ),
              ),
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(18),
                ),
                child: const Icon(
                  Icons.savings_rounded,
                  color: RmTheme.iconAccent,
                  size: 28,
                ),
              ),
            ],
          ),
        ),
        const RmSectionTitle(title: 'Payment method'),
        _buildPaymentTile('Cash (Collected)', Icons.payments_rounded, 'Deposit received now'),
        _buildPaymentTile('Pending Collection', Icons.schedule_rounded, 'Collect later'),
        if (_submitError != null) ...[
          const SizedBox(height: 8),
          RmNote(tone: RmNoteTone.danger, title: 'Could not submit', text: _submitError!)
              .animate()
              .shake(duration: 400.ms),
        ],
      ],
    );
  }

  Widget _buildPaymentTile(String method, IconData icon, String hint) {
    final isSelected = _selectedPayment == method;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: GestureDetector(
        onTap: () {
          HapticFeedback.selectionClick();
          setState(() => _selectedPayment = method);
        },
        child: AnimatedContainer(
          duration: 220.ms,
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: isSelected ? const Color(0xFFE8EEFF) : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle,
              width: isSelected ? 1.6 : 1,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: isSelected ? Colors.white : RmTheme.iconAccentSoft,
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Icon(icon, color: RmTheme.iconAccent, size: 21),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      method,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    Text(
                      hint,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                isSelected ? Icons.check_circle_rounded : Icons.circle_outlined,
                color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // 3. Result — branches on the real backend outcome.
  Widget _buildResultScreen() {
    final result = _result;
    if (result == null) return const SizedBox.shrink();
    if (result.isRestricted) return _buildRestrictedResult(result);
    return _buildSuccessResult(result);
  }

  Widget _resultLayout({
    required Color color,
    required IconData icon,
    required String title,
    required String message,
    required List<Widget> details,
    required Widget cta,
  }) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
          child: Row(
            children: [
              DsBackButton(onPressed: () => context.pop()),
              const Spacer(),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(24, 24, 24, 24),
            child: Column(
              children: [
                SizedBox(
                  width: 170,
                  height: 170,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      for (var i = 0; i < 2; i++)
                        Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: color.withValues(alpha: 0.25),
                              width: 2,
                            ),
                          ),
                        )
                            .animate(delay: (i * 900).ms, onPlay: (c) => c.repeat())
                            .scaleXY(begin: 0.55, end: 1, duration: 1800.ms)
                            .fadeOut(duration: 1800.ms),
                      Container(
                        width: 104,
                        height: 104,
                        decoration: BoxDecoration(
                          color: color,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: color.withValues(alpha: 0.4),
                              blurRadius: 30,
                              offset: const Offset(0, 12),
                            ),
                          ],
                        ),
                        child: Icon(icon, color: Colors.white, size: 52),
                      ).animate().scaleXY(
                            begin: 0.2,
                            end: 1,
                            duration: 800.ms,
                            curve: Curves.elasticOut,
                          ),
                    ],
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14.5,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
                const SizedBox(height: 24),
                ...details,
              ]
                  .animate(interval: 80.ms, delay: 200.ms)
                  .fadeIn(duration: 400.ms)
                  .slideY(begin: 0.15, end: 0),
            ),
          ),
        ),
        Padding(padding: const EdgeInsets.fromLTRB(20, 8, 20, 16), child: cta),
      ],
    );
  }

  Widget _buildRestrictedResult(IntakeResult result) {
    return _resultLayout(
      color: RmTheme.crimsonDanger,
      icon: Icons.block_rounded,
      title: 'Restricted',
      message: '${result.staff.fullName} matches the restricted database. '
          'The record was created as Terminal — staff code ${result.staff.staffCode}.',
      details: const [
        RmNote(
          tone: RmNoteTone.danger,
          title: 'Do NOT disclose the reason',
          text: 'Log the exit immediately and end the conversation politely.',
        ),
      ],
      cta: DsOutlineButton(
        label: 'Log exit',
        icon: Icons.logout_rounded,
        color: RmTheme.crimsonDanger,
        onPressed: () => context.pop(),
      ),
    );
  }

  Widget _buildSuccessResult(IntakeResult result) {
    final staff = result.staff;
    return _resultLayout(
      color: RmTheme.emeraldGreen,
      icon: Icons.check_rounded,
      title: 'Record created!',
      message: 'The intake was submitted and ${staff.fullName} is now in the pipeline.',
      details: [
        RmStaffBanner(staff: staff),
      ],
      cta: DsGradientButton(
        label: staff.pipelineStage == PipelineStages.s2Verify
            ? 'Go to verification'
            : 'View staff',
        onPressed: () => context.pushReplacement(RmRoutes.staffDetail(staff.id)),
      ),
    );
  }
}
