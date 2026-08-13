import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../../../common/domain/models/staff_entity.dart';
import '../../../../common/presentation/providers/auth_provider.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/utils/validators.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';

class RmStaffIntakeScreen extends ConsumerStatefulWidget {
  const RmStaffIntakeScreen({super.key});

  @override
  ConsumerState<RmStaffIntakeScreen> createState() => _RmStaffIntakeScreenState();
}

class _RmStaffIntakeScreenState extends ConsumerState<RmStaffIntakeScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  
  String? _selectedRole = 'Driver';
  String? _selectedPayment = 'Cash';
  String _selectedGender = 'Male';
  String? _generatedStaffId;

  final TextEditingController _dobController = TextEditingController();
  final TextEditingController _aadhaarController = TextEditingController();
  final TextEditingController _phoneController = TextEditingController();
  final TextEditingController _nameController = TextEditingController();
  final TextEditingController _receiptController = TextEditingController();

  @override
  void dispose() {
    _dobController.dispose();
    _aadhaarController.dispose();
    _phoneController.dispose();
    _nameController.dispose();
    _receiptController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  void _nextPage() {
    _pageController.nextPage(duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  void _goToPage(int index) {
    _pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: SafeArea(
        child: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          onPageChanged: (index) => setState(() => _currentIndex = index),
          children: [
            _buildRestrictedCheckScreen(), // 0
            _buildRestrictedResultScreen(), // 1
            _buildClearResultScreen(), // 2
            _buildPersonalDetailsScreen(), // 3
            _buildDepositCollectionScreen(), // 4
            _buildIntakeCompleteScreen(), // 5
          ],
        ),
      ),
    );
  }

  // --- Widgets for Styling ---
  Widget _buildGlassCard({required Widget child}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: RmTheme.glassmorphismShadow,
      ),
      child: child,
    );
  }

  Widget _buildHeaderLogo() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 24),
        child: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: RmTheme.electricBlue,
            fontStyle: FontStyle.italic,
          ),
        ),
      ),
    );
  }

  Widget _buildButton(String text, VoidCallback onPressed, {bool isOutlined = false}) {
    return SizedBox(
      width: double.infinity,
      height: 56,
      child: isOutlined
          ? OutlinedButton(
              onPressed: onPressed,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: RmTheme.crimsonDanger, width: 1.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
              child: Text(
                text.toUpperCase(),
                style: GoogleFonts.inter(
                  color: RmTheme.crimsonDanger,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 1.2,
                ),
              ),
            )
          : ElevatedButton(
              onPressed: onPressed,
              style: ElevatedButton.styleFrom(
                backgroundColor: RmTheme.electricBlue,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                elevation: 0,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    text,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                      fontSize: 16,
                    ),
                  ),
                  if (!text.toUpperCase().contains('FORM') && !text.toUpperCase().contains('EXIT')) ...[
                    const SizedBox(width: 8),
                    const Icon(Icons.arrow_forward, color: Colors.white, size: 20),
                  ]
                ],
              ),
            ),
    );
  }

  // --- Screens ---

  // 1. Restricted List Check
  Widget _buildRestrictedCheckScreen() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => context.pop()),
            const Spacer(),
            _buildHeaderLogo(),
            const Spacer(),
            const SizedBox(width: 48), // Balance for arrow
          ],
        ),
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: RmTheme.offWhite,
            shape: BoxShape.circle,
            border: Border.all(color: RmTheme.borderSubtle),
          ),
          child: const Icon(Icons.admin_panel_settings_outlined, color: RmTheme.electricBlue, size: 32),
        ),
        const SizedBox(height: 24),
        Text('Restricted List Check', style: RmTheme.headline(context).copyWith(fontSize: 28)),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            'Enter details to verify against the global restricted database. This check must be completed BEFORE creating any staff record.',
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
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: RmTheme.amberWarning.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: RmTheme.amberWarning.withOpacity(0.3)),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.error_outline, color: RmTheme.amberWarning, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'A restricted list check must pass BEFORE any record is created. No documents, no agreements, no tests at this stage.',
                            style: RmTheme.body(context).copyWith(color: RmTheme.textPrimary, fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  _buildFloatingInput('AADHAAR (LAST 4 DIGITS)', '•••• •••• 4821', controller: _aadhaarController),
                  const SizedBox(height: 16),
                  _buildFloatingInput('PHONE NUMBER', '+91 98765 43210', controller: _phoneController),
                  const SizedBox(height: 32),
                  _buildButton('Run Check', () {
                    String? phoneError = Validators.phone(_phoneController.text);
                    if (_aadhaarController.text.trim().isEmpty || phoneError != null) {
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(phoneError != null ? 'Please enter a valid Phone Number' : 'Please enter Aadhaar')));
                      return;
                    }
                    _goToPage(2);
                  }), // Go to Clear
                  const SizedBox(height: 16),
                  Center(
                    child: TextButton(
                      onPressed: () => _goToPage(1),
                      child: Text('Simulate Restricted (Demo)', style: GoogleFonts.inter(color: RmTheme.textSecondary)),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildFloatingInput(String label, String hint, {TextEditingController? controller, bool readOnly = false, VoidCallback? onTap}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          readOnly: readOnly,
          onTap: onTap,
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

  // 2. Check Result: Restricted
  Widget _buildRestrictedResultScreen() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _goToPage(0)),
            const Spacer(),
            _buildHeaderLogo(),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: RmTheme.crimsonDanger.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.block, color: RmTheme.crimsonDanger, size: 64),
                ),
                const SizedBox(height: 24),
                Text('RESTRICTED', style: GoogleFonts.libreCaslonText(fontSize: 32, fontWeight: FontWeight.w700, color: RmTheme.crimsonDanger)),
                const SizedBox(height: 16),
                Text('Applicant matches restricted database.', style: RmTheme.body(context), textAlign: TextAlign.center),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RmTheme.offWhite,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: RmTheme.borderSubtle),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(color: RmTheme.crimsonDanger.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                        child: const Icon(Icons.warning_amber_rounded, color: RmTheme.crimsonDanger, size: 20),
                      ),
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
                const SizedBox(height: 16),
                Center(
                  child: TextButton(
                    onPressed: () => _goToPage(0),
                    child: Text('Back to Demo', style: GoogleFonts.inter(color: RmTheme.textSecondary)),
                  ),
                ),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // 3. Check Result: Clear
  Widget _buildClearResultScreen() {
    return Column(
      children: [
        Row(
          children: [
            IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _goToPage(0)),
            const Spacer(),
            _buildHeaderLogo(),
            const Spacer(),
            const SizedBox(width: 48),
          ],
        ),
        const Spacer(),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: _buildGlassCard(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(color: RmTheme.emeraldGreen.withOpacity(0.1), shape: BoxShape.circle),
                  child: const Icon(Icons.check_circle_outline, color: RmTheme.emeraldGreen, size: 64),
                ),
                const SizedBox(height: 24),
                Text('CLEAR', style: GoogleFonts.libreCaslonText(fontSize: 32, fontWeight: FontWeight.w700, color: RmTheme.emeraldGreen)),
                const SizedBox(height: 16),
                RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: RmTheme.body(context).copyWith(fontSize: 16),
                    children: [
                      const TextSpan(text: 'No match found. Applicant is '),
                      TextSpan(text: 'eligible', style: GoogleFonts.inter(fontWeight: FontWeight.w700, color: RmTheme.textPrimary)),
                      const TextSpan(text: ' for registration.'),
                    ],
                  ),
                ),
                const SizedBox(height: 32),
                _buildButton('PROCEED TO INTAKE FORM', () => _goToPage(3)),
              ],
            ),
          ),
        ),
        const Spacer(),
      ],
    );
  }

  // 4. Personal Details
  Widget _buildPersonalDetailsScreen() {
    return _buildFormPage(
      step: 1,
      title: 'Personal Details',
      subtitle: 'Please enter the staff member\'s basic information exactly as it appears on their official ID.',
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildFloatingInput('Full Legal Name', 'e.g., Ramesh Kumar Singh', controller: _nameController),
          const SizedBox(height: 20),
          _buildFloatingInput(
            'Date of Birth',
            'mm/dd/yyyy',
            controller: _dobController,
            readOnly: true,
            onTap: () async {
              final DateTime? picked = await showDatePicker(
                context: context,
                initialDate: DateTime.now().subtract(const Duration(days: 365 * 18)),
                firstDate: DateTime(1900),
                lastDate: DateTime.now(),
                builder: (context, child) {
                  return Theme(
                    data: Theme.of(context).copyWith(
                      colorScheme: const ColorScheme.light(
                        primary: RmTheme.electricBlue, // header background color
                        onPrimary: Colors.white, // header text color
                        onSurface: RmTheme.textPrimary, // body text color
                      ),
                    ),
                    child: child!,
                  );
                },
              );
              if (picked != null) {
                setState(() {
                  _dobController.text = "${picked.month.toString().padLeft(2, '0')}/${picked.day.toString().padLeft(2, '0')}/${picked.year}";
                });
              }
            },
          ),
          const SizedBox(height: 20),
          Text('Gender', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary)),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildGenderChip('Male'),
              const SizedBox(width: 8),
              _buildGenderChip('Female'),
              const SizedBox(width: 8),
              _buildGenderChip('Other'),
            ],
          ),
          const SizedBox(height: 32),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Staff Series', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(color: RmTheme.borderSubtle, borderRadius: BorderRadius.circular(12)),
                child: Text('Select primary role', style: GoogleFonts.inter(fontSize: 10, color: RmTheme.textSecondary)),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildRoleCard('Driver', '(DR)', Icons.directions_car),
          const SizedBox(height: 12),
          _buildRoleCard('Caretaker', '(CT)', Icons.elderly),
          const SizedBox(height: 12),
          _buildRoleCard('Maid', '(MD)', Icons.cleaning_services),
          const SizedBox(height: 32),
          _buildButton('Next Step', () => _goToPage(4)),
        ],
      ),
    );
  }

  Widget _buildGenderChip(String label) {
    bool isSelected = _selectedGender == label;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _selectedGender = label),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? RmTheme.electricBlue.withOpacity(0.05) : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle),
            boxShadow: isSelected ? RmTheme.sophisticatedShadow : null,
          ),
          alignment: Alignment.center,
          child: Text(
            label,
            style: GoogleFonts.inter(
              color: isSelected ? RmTheme.electricBlue : RmTheme.textSecondary,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRoleCard(String role, String code, IconData icon) {
    bool isSelected = _selectedRole == role;
    return GestureDetector(
      onTap: () => setState(() => _selectedRole = role),
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
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: isSelected ? RmTheme.electricBlue : RmTheme.offWhite,
                shape: BoxShape.circle,
              ),
              child: Icon(icon, color: isSelected ? Colors.white : RmTheme.textSecondary, size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(role, style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: RmTheme.textPrimary, fontSize: 15)),
                  const SizedBox(height: 2),
                  Text('Series code $code', style: GoogleFonts.inter(fontSize: 11, color: RmTheme.textSecondary)),
                ],
              ),
            ),
            Icon(isSelected ? Icons.radio_button_checked : Icons.radio_button_unchecked, color: isSelected ? RmTheme.electricBlue : RmTheme.borderSubtle, size: 22),
          ],
        ),
      ),
    );
  }

  // 5. Deposit Collection
  Widget _buildDepositCollectionScreen() {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _goToPage(3)),
              const Spacer(),
              _buildStepper(4),
              const Spacer(),
              const SizedBox(width: 48), // Balance
            ],
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              SingleChildScrollView(
                padding: const EdgeInsets.all(24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Deposit Collection', style: RmTheme.headline(context).copyWith(fontSize: 32, color: RmTheme.electricBlue)),
                    const SizedBox(height: 4),
                    Text('Step 4 of 4 — Finalize intake', style: RmTheme.body(context)),
                    const SizedBox(height: 32),
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: RmTheme.borderSubtle.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: Colors.white, width: 2),
                        boxShadow: [
                          BoxShadow(color: Colors.black.withOpacity(0.02), blurRadius: 10, offset: const Offset(0, 4)),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('SERIES', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Icon(Icons.directions_car, color: RmTheme.electricBlue, size: 20),
                              const SizedBox(width: 8),
                              Text('Driver (DR)', style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w500, color: RmTheme.textPrimary)),
                            ],
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 16),
                            child: Divider(height: 1, color: Colors.white),
                          ),
                          Text('REFUNDABLE DEPOSIT', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                          const SizedBox(height: 8),
                          Text('₹2,000', style: GoogleFonts.libreCaslonText(fontSize: 36, fontWeight: FontWeight.w700, color: RmTheme.electricBlue)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text('PAYMENT METHOD', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary, letterSpacing: 1.0)),
                    const SizedBox(height: 16),
                    _buildPaymentTile('Cash (Collected)', Icons.money),
                    const SizedBox(height: 12),
                    _buildPaymentTile('UPI Transfer', Icons.qr_code_scanner),
                    const SizedBox(height: 12),
                    _buildPaymentTile('Bank Transfer', Icons.account_balance),
                    const SizedBox(height: 32),
                    Text('RECEIPT DETAILS', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary, letterSpacing: 1.0)),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _receiptController,
                      decoration: InputDecoration(
                        hintText: 'Enter receipt number or notes',
                        hintStyle: GoogleFonts.inter(color: RmTheme.textSecondary.withOpacity(0.5)),
                        filled: true,
                        fillColor: Colors.white,
                        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 120), // padding for floating button
                  ],
                ),
              ),
              Positioned(
                bottom: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [RmTheme.offWhite.withOpacity(0.0), RmTheme.offWhite],
                      stops: const [0.0, 0.3],
                    ),
                  ),
                  child: _buildButton('Complete Intake', () async {
                    String code = _selectedRole == 'Driver' ? 'DR' : (_selectedRole == 'Caretaker' ? 'CT' : 'MD');
                    String randomId = (1000 + DateTime.now().millisecondsSinceEpoch % 9000).toString();
                    
                    final newStaffId = 'HG-$code-2024-$randomId';
                    
                    final rmId = ref.read(authProvider).user?.id ?? 'rm-demo-1';
                    final staff = StaffEntity(
                      id: newStaffId,
                      staffCode: newStaffId,
                      name: _nameController.text.isEmpty ? 'New Staff' : _nameController.text,
                      phone: _phoneController.text.isEmpty ? '9999999999' : _phoneController.text,
                      status: 'PIPELINE',
                      pipelineStage: 'REGISTRATION',
                      createdAt: DateTime.now(),
                      updatedAt: DateTime.now(),
                      rmId: rmId,
                      clientId: 'client-demo-1', // Automatically assign to demo client for simplicity
                    );
                    
                    await ref.read(rmRepositoryProvider).createStaff(staff);

                    setState(() {
                      _generatedStaffId = newStaffId;
                    });
                    _goToPage(5);
                  }),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPaymentTile(String method, IconData icon) {
    bool isSelected = _selectedPayment == method;
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

  // 6. Intake Complete
  Widget _buildIntakeCompleteScreen() {
    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: IntrinsicHeight(
              child: Column(
                children: [
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      IconButton(icon: const Icon(Icons.close, color: RmTheme.textPrimary), onPressed: () => context.pop()),
                      const Spacer(),
                      Text('RM', style: GoogleFonts.inter(fontWeight: FontWeight.w600, color: RmTheme.electricBlue)),
                      const SizedBox(width: 24),
                    ],
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.all(32),
                    decoration: BoxDecoration(color: RmTheme.electricBlue.withOpacity(0.05), borderRadius: BorderRadius.circular(32)),
                    child: const Icon(Icons.celebration, color: RmTheme.electricBlue, size: 80),
                  ),
                  const SizedBox(height: 32),
                  Text('Record Created!', style: GoogleFonts.libreCaslonText(fontSize: 36, fontWeight: FontWeight.w700, color: RmTheme.electricBlue)),
                  const SizedBox(height: 16),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 40),
                    child: Text('The intake process has been successfully completed. The record is now securely stored.', textAlign: TextAlign.center, style: RmTheme.body(context).copyWith(fontSize: 16)),
                  ),
                  const SizedBox(height: 48),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: RmTheme.glassmorphismShadow,
                      ),
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
                                  Text(_generatedStaffId ?? 'HG-XX-2024-XXXX', style: GoogleFonts.libreCaslonText(fontSize: 22, fontWeight: FontWeight.w700, color: RmTheme.electricBlue)),
                                  const Padding(padding: EdgeInsets.symmetric(vertical: 12), child: Divider(height: 1)),
                                  Text('CURRENT STAGE', style: GoogleFonts.inter(fontSize: 10, fontWeight: FontWeight.w600, color: RmTheme.textSecondary, letterSpacing: 1.0)),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: [
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: RmTheme.offWhite, borderRadius: BorderRadius.circular(8)), child: Text('S1_INTAKE', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600))),
                                      const Padding(padding: EdgeInsets.symmetric(horizontal: 12), child: Icon(Icons.arrow_forward, size: 16, color: RmTheme.electricBlue)),
                                      Container(padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6), decoration: BoxDecoration(color: RmTheme.electricBlue, borderRadius: BorderRadius.circular(8)), child: Text('S2_VERIFY', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: Colors.white))),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: RmTheme.offWhite,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RmTheme.borderSubtle),
                      ),
                      child: Column(
                        children: [
                          _buildSummaryRow('Name', _nameController.text.isEmpty ? 'Not Provided' : _nameController.text),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Phone', _phoneController.text.isEmpty ? 'Not Provided' : _phoneController.text),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Role', _selectedRole ?? 'Not Selected'),
                          const SizedBox(height: 8),
                          _buildSummaryRow('Deposit', '₹2,000 ($_selectedPayment)'),
                        ],
                      ),
                    ),
                  ),
                  const Spacer(),
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: _buildButton('Go to Verification', () => context.pushReplacement(RmRoutes.verificationDashboard(_generatedStaffId ?? 'HG-XX-2024-XXXX'))),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: GoogleFonts.inter(fontSize: 12, color: RmTheme.textSecondary)),
        Text(value, style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600, color: RmTheme.textPrimary)),
      ],
    );
  }

  // --- Helpers ---
  Widget _buildFormPage({required int step, required String title, required String subtitle, required Widget child}) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              IconButton(icon: const Icon(Icons.arrow_back), onPressed: () => _goToPage(step == 1 ? 2 : (step == 4 ? 3 : step - 1))),
              const Spacer(),
              _buildStepper(step),
              const Spacer(),
              const SizedBox(width: 48), // Balance
            ],
          ),
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
      children: List.generate(4, (index) {
        int step = index + 1;
        bool isActive = step == currentStep;
        return Row(
          children: [
            Container(
              width: 32,
              height: 32,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                color: isActive ? RmTheme.electricBlue : Colors.white,
                shape: BoxShape.circle,
                border: Border.all(color: isActive ? RmTheme.electricBlue : RmTheme.borderSubtle),
              ),
              child: Text('$step', style: GoogleFonts.inter(color: isActive ? Colors.white : RmTheme.textSecondary, fontWeight: FontWeight.w600)),
            ),
            if (step < 4)
              Container(width: 16, height: 1, color: RmTheme.borderSubtle, margin: const EdgeInsets.symmetric(horizontal: 4)),
          ],
        );
      }),
    );
  }
}
