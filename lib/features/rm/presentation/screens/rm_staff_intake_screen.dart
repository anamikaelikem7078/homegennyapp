import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
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

  String _selectedSeries = StaffSeries.driver;
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: RmTheme.crimsonDanger),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
    );
  }

  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(24), boxShadow: RmTheme.glassmorphismShadow),
      child: child,
    );
  }

  Widget _buildHeaderLogo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(fontSize: 28, fontWeight: FontWeight.w700, color: RmTheme.electricBlue, fontStyle: FontStyle.italic),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback? onPressed, {bool isOutlined = false, bool loading = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(side: const BorderSide(color: RmTheme.crimsonDanger, width: 1.5), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12))),
              child: Text(text.toUpperCase(), style: GoogleFonts.inter(color: RmTheme.crimsonDanger, fontWeight: FontWeight.w600, letterSpacing: 1.2)),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(backgroundColor: RmTheme.electricBlue, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)), elevation: 0),
              child: loading
                  ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(text, style: GoogleFonts.inter(color: Colors.white, fontWeight: FontWeight.w600, fontSize: 16)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                      ],
                    ),
            ),
    );
  }

  Widget _buildFloatingInput(String label, String hint, {TextEditingController? controller, TextInputType? keyboardType}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: GoogleFonts.inter(color: RmTheme.textSecondary.withOpacity(0.5)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: RmTheme.borderSubtle)),
            enabledBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: RmTheme.borderSubtle)),
            focusedBorder: OutlineInputBorder(borderRadius: BorderRadius.circular(8), borderSide: const BorderSide(color: RmTheme.electricBlue)),
          ),
        ),
      ],
    );
  }

  // 0. Identity inputs — collected up front, submitted together with
  // everything else; the backend does the restricted-list check server-side
  // when the full form is submitted on the deposit page.
  Widget _buildIdentityScreen() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            const Spacer(),
            _buildHeaderLogo(),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(color: RmTheme.offWhite, shape: BoxShape.circle, border: Border.all(color: RmTheme.borderSubtle)),
          child: const Icon(Icons.admin_panel_settings_outlined, color: RmTheme.electricBlue, size: 32),
        ),
        const SizedBox(height: 24),
        Text('New Staff Intake', style: RmTheme.headline(context).copyWith(fontSize: 28)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'The backend checks this Aadhaar + phone against the restricted list when the form is submitted — no separate pre-check step exists.',
            textAlign: TextAlign.center,
            style: RmTheme.body(context),
          ),
        ),
        const SizedBox(height: 32),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: _buildGlassCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildFloatingInput('AADHAAR NUMBER', '999988887777', controller: _aadhaarController, keyboardType: TextInputType.number),
                  const SizedBox(height: 16),
                  _buildFloatingInput('PHONE NUMBER', '9911100001', controller: _phoneController, keyboardType: TextInputType.phone),
                  const SizedBox(height: 32),
                  _buildButton('Continue', () {
                    final phoneError = Validators.phone(_phoneController.text);
                    if (_aadhaarController.text.trim().isEmpty || phoneError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text(phoneError != null ? 'Please enter a valid phone number' : 'Please enter Aadhaar number')),
                      );
                      return;
                    }
                    _goToPage(1);
                  }),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  // 1. Personal details + series
  Widget _buildPersonalDetailsScreen() {
    return _buildFormPage(
      step: 2,
      title: 'Personal Details',
      subtitle: "Enter the staff member's information exactly as it appears on their official ID.",
      onBack: () => _goToPage(0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFloatingInput('Full Legal Name', 'e.g., Ramesh Kumar Singh', controller: _nameController),
          const SizedBox(height: 20),
          _buildFloatingInput('Date of Birth (YYYY-MM-DD)', '1998-04-12', controller: _dobController),
          const SizedBox(height: 20),
          _buildFloatingInput('Address', 'Sector 12, Noida', controller: _addressController),
          const SizedBox(height: 20),
          _buildFloatingInput('Email (optional)', 'name@example.com', controller: _emailController, keyboardType: TextInputType.emailAddress),
          const SizedBox(height: 32),
          Text('Staff Series', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary)),
          const SizedBox(height: 16),
          for (final series in StaffSeries.all) ...[
            _buildSeriesCard(series),
            const SizedBox(height: 12),
          ],
          const SizedBox(height: 20),
          _buildButton('Next Step', () {
            if (_nameController.text.trim().isEmpty) {
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Please enter the full name')));
              return;
            }
            _goToPage(2);
          }),
        ],
      ),
    );
  }

  Widget _buildSeriesCard(String series) {
    final isSelected = _selectedSeries == series;
    return GestureDetector(
      onTap: () => setState(() => _selectedSeries = series),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? RmTheme.electricBlue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle, width: isSelected ? 1.5 : 1.0),
          boxShadow: isSelected ? RmTheme.sophisticatedShadow : null,
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(StaffSeries.label(series), style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: RmTheme.textPrimary, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Deposit ₹${StaffSeries.depositFor(series)}', style: GoogleFonts.inter(fontSize: 11, color: RmTheme.textSecondary)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle, size: 22),
          ],
        ),
      ),
    );
  }

  // 2. Deposit collection — final submit
  Widget _buildDepositScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: _submitting ? null : () => _goToPage(1)),
              const Spacer(),
              _buildStepper(3),
              const Spacer(),
              const SizedBox(width: 48),
            ],
          ),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Deposit Collection', style: RmTheme.headline(context).copyWith(fontSize: 32, color: RmTheme.electricBlue)),
                const SizedBox(height: 4),
                Text('Step 3 of 3 — submits the intake to the backend', style: RmTheme.body(context)),
                const SizedBox(height: 32),
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: RmTheme.borderSubtle.withOpacity(0.3),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('SERIES', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Text(StaffSeries.label(_selectedSeries), style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500)),
                      const Padding(padding: EdgeInsets.symmetric(vertical: 16), child: Divider(height: 1, color: Colors.white)),
                      Text('REFUNDABLE DEPOSIT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                      const SizedBox(height: 8),
                      Text('₹${StaffSeries.depositFor(_selectedSeries)}', style: GoogleFonts.libreCaslonText(fontSize: 36, fontWeight: FontWeight.w700, color: RmTheme.electricBlue)),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                Text('PAYMENT METHOD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary, letterSpacing: 1.0)),
                const SizedBox(height: 16),
                _buildPaymentTile('Cash (Collected)', Icons.money),
                const SizedBox(height: 12),
                _buildPaymentTile('Pending Collection', Icons.schedule),
                if (_submitError != null) ...[
                  const SizedBox(height: 20),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(color: RmTheme.crimsonDanger.withOpacity(0.08), borderRadius: BorderRadius.circular(8)),
                    child: Text(_submitError!, style: TextStyle(color: RmTheme.crimsonDanger)),
                  ),
                ],
                const SizedBox(height: 32),
                _buildButton('Complete Intake', _submitting ? null : _submit, loading: _submitting),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTile(String method, IconData icon) {
    final isSelected = _selectedPayment == method;
    return GestureDetector(
      onTap: () => setState(() => _selectedPayment = method),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isSelected ? RmTheme.electricBlue.withOpacity(0.05) : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: isSelected ? RmTheme.electricBlue : Colors.white, width: 1.5),
          boxShadow: RmTheme.sophisticatedShadow,
        ),
        child: Row(
          children: [
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? RmTheme.electricBlue : RmTheme.textSecondary.withOpacity(0.3), size: 20),
            const SizedBox(width: 16),
            Expanded(child: Text(method, style: GoogleFonts.inter(fontWeight: FontWeight.w500, color: RmTheme.textPrimary))),
            Icon(icon, color: RmTheme.electricBlue, size: 20),
          ],
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

  Widget _buildRestrictedResult(IntakeResult result) {
    return Column(
      children: [
        Row(children: [IconButton(icon: const Icon(Icons.close), onPressed: () => context.pop()), const Spacer(), _buildHeaderLogo(), const Spacer(), const SizedBox(width: 48)]),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(padding: const EdgeInsets.all(24), decoration: BoxDecoration(color: RmTheme.crimsonDanger.withOpacity(0.1), shape: BoxShape.circle), child: const Icon(Icons.block, color: RmTheme.crimsonDanger, size: 64)),
                const SizedBox(height: 24),
                Text('RESTRICTED', style: GoogleFonts.libreCaslonText(fontSize: 32, fontWeight: FontWeight.w700, color: RmTheme.crimsonDanger)),
                const SizedBox(height: 16),
                Text('${result.staff.fullName} matches the restricted database.', style: RmTheme.body(context), textAlign: TextAlign.center),
                const SizedBox(height: 16),
                Text('Record created at TERMINAL — staff code ${result.staff.staffCode}.', style: RmTheme.body(context).copyWith(fontSize: 12)),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(color: RmTheme.offWhite, borderRadius: BorderRadius.circular(12), border: Border.all(color: RmTheme.borderSubtle)),
                  child: Row(
                    children: [
                      Container(padding: const EdgeInsets.all(8), decoration: BoxDecoration(color: RmTheme.crimsonDanger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)), child: const Icon(Icons.warning_amber_rounded, color: RmTheme.crimsonDanger, size: 20)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: RmTheme.body(context).copyWith(color: RmTheme.textPrimary),
                            children: [
                              TextSpan(text: 'Do NOT disclose reason. ', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: RmTheme.crimsonDanger)),
                              const TextSpan(text: 'Log exit immediately.'),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildButton('LOG EXIT', () => context.pop(), isOutlined: true),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  Widget _buildSuccessResult(IntakeResult result) {
    final staff = result.staff;
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight),
          child: IntrinsicHeight(
            child: Column(
              children: [
                const SizedBox(height: 16),
                Row(children: [IconButton(icon: const Icon(Icons.close, color: RmTheme.textPrimary), onPressed: () => context.pop()), const Spacer(), Text('RM', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: RmTheme.electricBlue)), const SizedBox(width: 24)]),
                const Spacer(),
                Container(padding: const EdgeInsets.all(32), decoration: BoxDecoration(color: RmTheme.electricBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(32)), child: const Icon(Icons.celebration, color: RmTheme.electricBlue, size: 80)),
                const SizedBox(height: 32),
                Text('Record Created!', style: GoogleFonts.libreCaslonText(fontSize: 36, fontWeight: FontWeight.w700, color: RmTheme.electricBlue)),
                const SizedBox(height: 16),
                Padding(padding: const EdgeInsets.symmetric(horizontal: 40), child: Text('The intake was submitted to the backend and the record is now live.', textAlign: TextAlign.center, style: RmTheme.body(context).copyWith(fontSize: 16))),
                const SizedBox(height: 48),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Container(
                    decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(16), boxShadow: RmTheme.glassmorphismShadow),
                    child: Row(
                      children: [
                        Container(width: 6, height: 120, decoration: const BoxDecoration(color: RmTheme.emeraldGreen, borderRadius: BorderRadius.horizontal(left: Radius.circular(16)))),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('STAFF ID', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                                const SizedBox(height: 4),
                                Text(staff.staffCode, style: GoogleFonts.libreCaslonText(fontSize: 22, fontWeight: FontWeight.w700, color: RmTheme.electricBlue)),
                                const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                Text('CURRENT STAGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(color: RmTheme.electricBlue, borderRadius: BorderRadius.circular(8)),
                                  child: Text(PipelineStages.label(staff.pipelineStage), style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white)),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const Spacer(),
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: _buildButton(
                    staff.pipelineStage == PipelineStages.s2Verify ? 'Go to Verification' : 'View Staff',
                    () => context.pushReplacement(RmRoutes.staffDetail(staff.id)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildFormPage({required int step, required String title, required String subtitle, required Widget child, required VoidCallback onBack}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(children: [IconButton(icon: const Icon(Icons.arrow_back), onPressed: onBack), const Spacer(), _buildStepper(step), const Spacer(), const SizedBox(width: 48)]),
        ),
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Text(title, style: RmTheme.headline(context).copyWith(fontSize: 32)),
                const SizedBox(height: 12),
                Text(subtitle, textAlign: TextAlign.center, style: RmTheme.body(context)),
                const SizedBox(height: 32),
                _buildGlassCard(child: child),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStepper(int currentStep) {
    return Row(
      children: List.generate(3, (index) {
        final step = index + 1;
        final isActive = step == currentStep;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(color: isActive ? RmTheme.electricBlue : Colors.white, shape: BoxShape.circle, border: Border.all(color: isActive ? RmTheme.electricBlue : RmTheme.borderSubtle)),
              child: Text('$step', style: GoogleFonts.inter(color: isActive ? Colors.white : RmTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
            if (step < 3) Container(width: 16, height: 1, color: RmTheme.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 4)),
          ],
        );
      }),
    );
  }
}
