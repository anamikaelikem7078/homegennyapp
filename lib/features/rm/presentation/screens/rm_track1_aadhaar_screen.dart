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

/// Aadhaar eKYC track — `POST /verification/aadhaar` (UIDAI API).
class RmTrack1AadhaarScreen extends ConsumerStatefulWidget {
  const RmTrack1AadhaarScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmTrack1AadhaarScreen> createState() => _RmTrack1AadhaarScreenState();
}

class _RmTrack1AadhaarScreenState extends ConsumerState<RmTrack1AadhaarScreen> {
  final _formKey = GlobalKey<FormState>();
  final _aadhaarController = TextEditingController();
  final _otpController = TextEditingController();
  bool _submitting = false;
  AadhaarResult? _result;

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

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final result = await ref.read(rmRepositoryProvider).verifyAadhaar(
          aadhaarNumber: _aadhaarController.text.trim(),
          otp: _otpController.text.trim(),
          staffId: widget.staffId,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      onSuccess: (data) {
        setState(() => _result = data);
        ref.invalidate(rmVerificationStatusProvider(widget.staffId));
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

  @override
  Widget build(BuildContext context) {
    return VerificationFormScaffold(
      title: 'Aadhaar eKYC',
      staffId: widget.staffId,
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Description Header ──
              Text(
                'Enter Aadhaar Details',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                  color: RmTheme.textPrimary,
                ),
              )
                  .animate()
                  .fadeIn(duration: 300.ms)
                  .slideY(begin: 0.05, end: 0, duration: 300.ms),
              const SizedBox(height: 12),

              // ── Aadhaar Number Field ──
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
              )
                  .animate()
                  .fadeIn(delay: 80.ms, duration: 350.ms)
                  .slideY(begin: 0.04, end: 0, delay: 80.ms, duration: 300.ms),
              const SizedBox(height: 16),

              // ── OTP Field ──
              VerificationTextField(
                label: 'OTP',
                controller: _otpController,
                keyboardType: TextInputType.number,
                maxLength: 6,
                validator: (v) {
                  final value = v?.trim() ?? '';
                  if (value.isEmpty) return 'Enter the OTP sent to the Aadhaar-linked number';
                  return null;
                },
              )
                  .animate()
                  .fadeIn(delay: 140.ms, duration: 350.ms)
                  .slideY(begin: 0.04, end: 0, delay: 140.ms, duration: 300.ms),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // ── Submit Action Button ──
        VerificationSubmitButton(
          label: 'Verify Aadhaar',
          submitting: _submitting,
          onPressed: _submit,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 350.ms)
            .slideY(begin: 0.03, end: 0, delay: 200.ms, duration: 300.ms),

        // ── Result Summary Card ──
        if (_result != null) ...[
          const SizedBox(height: 24),
          VerificationResultCard(
            success: _result!.verified,
            rows: {
              'Name': _result!.name,
              'Aadhaar (last 4)': _result!.nameLast4,
              'Status': _result!.verified ? 'VERIFIED' : 'NOT VERIFIED',
            },
          ),
        ],
      ],
    );
  }
}
