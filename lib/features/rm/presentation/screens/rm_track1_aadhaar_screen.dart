import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/verification_form_scaffold.dart';

/// Aadhaar eKYC track — real UIDAI OTP via Sandbox KYC, a genuine 2-step flow:
/// `POST /verification/aadhaar/generate-otp` (sends a real OTP to the
/// Aadhaar-linked mobile, returns a reference_id) then
/// `POST /verification/aadhaar/verify-otp` (reference_id + the OTP the staff
/// received). You cannot submit an OTP before one has been requested, so this
/// is two screens-in-one rather than a single form.
class RmTrack1AadhaarScreen extends ConsumerStatefulWidget {
  const RmTrack1AadhaarScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmTrack1AadhaarScreen> createState() => _RmTrack1AadhaarScreenState();
}

class _RmTrack1AadhaarScreenState extends ConsumerState<RmTrack1AadhaarScreen> {
  final _aadhaarFormKey = GlobalKey<FormState>();
  final _otpFormKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();

  bool _sendingOtp = false;
  bool _verifying = false;
  String? _referenceId;
  AadhaarResult? _result;

  /// Set once the RM explicitly taps "Re-verify" on an already-cleared
  /// Aadhaar track — overrides `rmAadhaarVerificationResultProvider`'s
  /// fetched result so the entry form shows again instead of the
  /// already-verified summary.
  bool _reVerifying = false;

  @override
  void initState() {
    super.initState();
    // Pre-fill with the Aadhaar number entered at S1 intake, if this is the
    // same session — the backend never stores/returns the raw number, so
    // there's nothing to fetch here (see `intakeAadhaarProvider`).
    final fromIntake = ref.read(intakeAadhaarProvider(widget.staffId));
    if (fromIntake != null && fromIntake.isNotEmpty) {
      _aadhaarController.text = fromIntake;
    }
  }

  @override
  void dispose() {
    _aadhaarController.dispose();
    _otpController.dispose();
    super.dispose();
  }

  Future<void> _sendOtp() async {
    if (!_aadhaarFormKey.currentState!.validate()) return;
    setState(() => _sendingOtp = true);

    final result = await ref.read(rmRepositoryProvider).generateAadhaarOtp(
          aadhaarNumber: _aadhaarController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _sendingOtp = false);

    result.fold(
      onSuccess: (referenceId) {
        setState(() => _referenceId = referenceId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('OTP sent to the mobile number linked to this Aadhaar.'), backgroundColor: RmTheme.electricBlue),
        );
      },
      onError: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: RmTheme.crimsonDanger),
        );
      },
    );
  }

  Future<void> _verifyOtp() async {
    if (!_otpFormKey.currentState!.validate() || _referenceId == null) return;
    setState(() => _verifying = true);

    final result = await ref.read(rmRepositoryProvider).verifyAadhaarOtp(
          referenceId: _referenceId!,
          otp: _otpController.text.trim(),
          aadhaarNumber: _aadhaarController.text.trim(),
          staffId: widget.staffId,
        );

    if (!mounted) return;
    setState(() => _verifying = false);

    result.fold(
      onSuccess: (data) {
        setState(() => _result = data);
        ref.invalidate(rmVerificationStatusProvider(widget.staffId));
        ref.invalidate(rmAadhaarVerificationResultProvider(widget.staffId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data.verified ? 'Aadhaar verified successfully.' : 'Aadhaar verification did not pass.'),
            backgroundColor: data.verified ? RmTheme.emeraldGreen : RmTheme.crimsonDanger,
          ),
        );
      },
      onError: (failure) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(failure.message), backgroundColor: RmTheme.crimsonDanger),
        );
      },
    );
  }

  void _changeNumber() {
    setState(() {
      _referenceId = null;
      _result = null;
      _otpController.clear();
    });
  }

  void _startReVerify() {
    setState(() {
      _reVerifying = true;
      _referenceId = null;
      _result = null;
      _aadhaarController.clear();
      _otpController.clear();
    });
  }

  /// Order/case/whitespace-insensitive comparison — UIDAI records and the
  /// staff's own onboarding entry frequently differ in spacing, casing, or
  /// name-part order (e.g. "Pratik Sharad Indore" vs "INDORE PRATIK
  /// SHARAD") without actually being a different person, so this only
  /// flags genuinely different word sets rather than requiring an exact
  /// string match.
  bool _namesRoughlyMatch(String staffName, String aadhaarName) {
    Set<String> words(String s) =>
        s.toLowerCase().trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toSet();
    final a = words(staffName);
    final b = words(aadhaarName);
    if (a.isEmpty || b.isEmpty) return true;
    return a.containsAll(b) || b.containsAll(a);
  }

  Widget _buildNameMismatchWarning(String staffName, String aadhaarName) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: RmTheme.amberWarning.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.amberWarning.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.warning_amber_rounded, size: 18, color: RmTheme.amberWarning),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Name on Aadhaar ("$aadhaarName") doesn\'t match the staff record '
              '("$staffName"). Please confirm this is the same person before advancing.',
              style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: RmTheme.textPrimary),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 300.ms);
  }

  @override
  Widget build(BuildContext context) {
    final staffName = ref.watch(staffByIdProvider(widget.staffId)).valueOrNull?.fullName;
    final existingAsync =
        _reVerifying ? null : ref.watch(rmAadhaarVerificationResultProvider(widget.staffId));

    // A fresh verify in this session always wins over whatever was already
    // persisted for this staff.
    final existingResult = _result == null ? existingAsync?.valueOrNull : null;
    final alreadyVerified = _result == null && _referenceId == null && existingResult != null;
    final displayResult = _result ?? existingResult;

    return VerificationFormScaffold(
      title: 'Aadhaar eKYC',
      staffId: widget.staffId,
      onBack: () => context.pop(),
      children: [
        if (existingAsync != null && existingAsync.isLoading && _referenceId == null) ...[
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 40),
            child: Center(child: CircularProgressIndicator()),
          ),
        ] else if (alreadyVerified) ...[
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Aadhaar eKYC was already completed for this staff member.',
                  style: GoogleFonts.inter(fontSize: 13, fontWeight: FontWeight.w500, color: RmTheme.textSecondary),
                ),
              ),
              TextButton(
                onPressed: _startReVerify,
                child: Text('Re-verify', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RmTheme.electricBlue)),
              ),
            ],
          ).animate().fadeIn(duration: 300.ms),
        ] else if (_referenceId == null) ...[
          Form(
            key: _aadhaarFormKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Enter Aadhaar Number',
                  style: GoogleFonts.libreCaslonText(fontSize: 16, fontWeight: FontWeight.bold, color: RmTheme.textPrimary),
                ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0, duration: 300.ms),
                const SizedBox(height: 4),
                Text(
                  'A one-time password will be sent to the mobile number linked to this Aadhaar via UIDAI.',
                  style: GoogleFonts.inter(fontSize: 12.5, color: RmTheme.textSecondary),
                ),
                const SizedBox(height: 12),
                VerificationTextField(
                  label: 'Aadhaar number',
                  controller: _aadhaarController,
                  keyboardType: TextInputType.number,
                  maxLength: 12,
                  validator: (v) {
                    final value = v?.trim() ?? '';
                    if (value.length != 12 || int.tryParse(value) == null) {
                      return 'Enter a valid 12-digit Aadhaar number';
                    }
                    return null;
                  },
                ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.04, end: 0, delay: 80.ms, duration: 300.ms),
              ],
            ),
          ),
          const SizedBox(height: 24),
          VerificationSubmitButton(
            label: 'Send OTP',
            submitting: _sendingOtp,
            onPressed: _sendOtp,
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.03, end: 0, delay: 200.ms, duration: 300.ms),
        ] else ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: RmTheme.electricBlue.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: RmTheme.electricBlue.withValues(alpha: 0.2)),
            ),
            child: Row(
              children: [
                const Icon(Icons.sms_outlined, size: 18, color: RmTheme.electricBlue),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'OTP sent for Aadhaar ending ${_aadhaarController.text.trim().length >= 4 ? _aadhaarController.text.trim().substring(_aadhaarController.text.trim().length - 4) : ''}',
                    style: GoogleFonts.inter(fontSize: 12.5, fontWeight: FontWeight.w600, color: RmTheme.textPrimary),
                  ),
                ),
                TextButton(
                  onPressed: _sendingOtp || _verifying ? null : _changeNumber,
                  child: Text('Change', style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.bold, color: RmTheme.electricBlue)),
                ),
              ],
            ),
          ).animate().fadeIn(duration: 300.ms),
          const SizedBox(height: 16),
          Form(
            key: _otpFormKey,
            child: VerificationTextField(
              label: 'OTP',
              controller: _otpController,
              keyboardType: TextInputType.number,
              maxLength: 6,
              validator: (v) {
                final value = v?.trim() ?? '';
                if (value.isEmpty) return 'Enter the OTP sent to the Aadhaar-linked number';
                return null;
              },
            ),
          ).animate().fadeIn(delay: 80.ms, duration: 350.ms).slideY(begin: 0.04, end: 0, delay: 80.ms, duration: 300.ms),
          const SizedBox(height: 24),
          VerificationSubmitButton(
            label: 'Verify Aadhaar',
            submitting: _verifying,
            onPressed: _verifyOtp,
          ).animate().fadeIn(delay: 200.ms, duration: 350.ms).slideY(begin: 0.03, end: 0, delay: 200.ms, duration: 300.ms),
        ],

        // ── Result Summary Card ──
        if (displayResult != null) ...[
          const SizedBox(height: 24),
          if (staffName != null && !_namesRoughlyMatch(staffName, displayResult.name))
            _buildNameMismatchWarning(staffName, displayResult.name),
          VerificationResultCard(
            success: displayResult.verified,
            rows: {
              'Name': displayResult.name,
              'Aadhaar (last 4)': displayResult.nameLast4,
              'Status': displayResult.verified ? 'VERIFIED' : 'NOT VERIFIED',
            },
          ),
        ],
      ],
    );
  }
}
