import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Shared A1/A2/A3 e-sign flow: create (if missing) → send OTP → verify OTP
/// → sign → generate PDF. All three instruments follow the same sequence
/// against `/agreements`, so one screen parameterized by `type` replaces
/// what were three near-identical mockup screens plus a separate OTP page.
class RmAgreementInstrumentScreen extends ConsumerStatefulWidget {
  const RmAgreementInstrumentScreen({
    super.key,
    required this.staffId,
    required this.clientId,
    required this.type,
    required this.title,
  });

  final String staffId;
  final String clientId;
  final String type;
  final String title;

  @override
  ConsumerState<RmAgreementInstrumentScreen> createState() => _RmAgreementInstrumentScreenState();
}

class _RmAgreementInstrumentScreenState extends ConsumerState<RmAgreementInstrumentScreen> {
  bool _busy = false;
  String? _error;
  String? _pdfUrl;

  Future<T?> _run<T>(String busyLabel, Future<Result<T>> Function() action) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    final result = await action();
    if (!mounted) return null;
    setState(() => _busy = false);
    return result.fold(
      onSuccess: (data) => data,
      onError: (f) {
        setState(() => _error = f.message);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger));
        return null;
      },
    );
  }

  Agreement? _findAgreement(List<Agreement> agreements) {
    final matches = agreements.where((a) => a.type == widget.type && a.clientId == widget.clientId).toList()
      ..sort((a, b) => (b.createdAt ?? '').compareTo(a.createdAt ?? ''));
    return matches.isEmpty ? null : matches.first;
  }

  Future<void> _createAgreement() async {
    await _run('create', () => ref.read(rmRepositoryProvider).createAgreement(
          staffId: widget.staffId,
          clientId: widget.clientId,
          type: widget.type,
        ));
    ref.invalidate(rmAgreementsProvider(AgreementListParams(staffId: widget.staffId, clientId: widget.clientId)));
  }

  Future<void> _sendOtp(String staffName) async {
    await _run('send-otp', () => ref.read(rmRepositoryProvider).sendEsignOtp(
          staffId: widget.staffId,
          agreementType: widget.type,
          staffName: staffName,
        ));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('OTP sent')));
    }
  }

  Future<void> _verifyAndSign(Agreement agreement) async {
    final otp = await showDialog<String>(
      context: context,
      barrierDismissible: true,
      builder: (dialogContext) {
        String enteredOtp = '';
        return Theme(
          data: AppTheme.light(),
          child: Dialog(
            backgroundColor: Colors.transparent,
            insetPadding: const EdgeInsets.symmetric(horizontal: 24),
            child: Container(
              decoration: BoxDecoration(
                color: RmTheme.cardSurface,
                borderRadius: BorderRadius.circular(24),
                boxShadow: RmTheme.sophisticatedShadow,
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Top Lock Icon
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.1),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.lock_person_outlined,
                      color: AppColors.primary,
                      size: 28,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Enter OTP',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: RmTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Please enter the 6-digit code sent to the registered mobile number.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: RmTheme.textSecondary,
                      height: 1.4,
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Premium OTP input digit boxes
                  DsOtpField(
                    length: 6,
                    autoFocus: true,
                    onChanged: (v) => enteredOtp = v,
                    onCompleted: (v) {
                      enteredOtp = v;
                      Navigator.of(dialogContext).pop(v);
                    },
                  ),
                  const SizedBox(height: 28),
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: RmTheme.textSecondary,
                            side: const BorderSide(color: RmTheme.borderSubtle),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Cancel',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w600,
                              fontSize: 14.5,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: FilledButton(
                          onPressed: () {
                            if (enteredOtp.length == 6) {
                              Navigator.of(dialogContext).pop(enteredOtp);
                            }
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                          ),
                          child: Text(
                            'Verify & Sign',
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.bold,
                              fontSize: 14.5,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().scale(
                duration: 250.ms,
                curve: Curves.easeOutBack,
                begin: const Offset(0.9, 0.9),
              ),
        );
      },
    );
    if (otp == null || otp.isEmpty) return;

    setState(() {
      _busy = true;
      _error = null;
    });
    final verifyResult = await ref.read(rmRepositoryProvider).verifyEsignOtp(
          staffId: widget.staffId,
          agreementType: widget.type,
          otp: otp,
        );
    if (!mounted) return;
    setState(() => _busy = false);
    final verified = verifyResult.fold(
      onSuccess: (_) => true,
      onError: (f) {
        setState(() => _error = f.message);
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger));
        return false;
      },
    );
    if (!verified) return;

    final signResult = await _run('sign', () => ref.read(rmRepositoryProvider).signAgreement(agreement.id, otp: otp));
    if (signResult == null) return;

    ref.invalidate(rmAgreementsProvider(AgreementListParams(staffId: widget.staffId, clientId: widget.clientId)));
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Signed')));
    }
  }

  Future<void> _generatePdf(Agreement agreement) async {
    final pdf = await _run('generate-pdf', () => ref.read(rmRepositoryProvider).generateAgreementPdf(agreement.id));
    if (pdf != null && mounted) {
      setState(() => _pdfUrl = pdf.pdfUrl);
    }
  }

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));
    final agreementsAsync = ref.watch(rmAgreementsProvider(AgreementListParams(staffId: widget.staffId, clientId: widget.clientId)));
    final client = ref.watch(agreementClientProvider(widget.staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: () => context.pop(),
        ),
        title: Text(
          widget.title,
          style: RmTheme.headline(context).copyWith(fontSize: 18),
        ),
      ),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (staff) => agreementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (agreements) {
            final agreement = _findAgreement(agreements);
            final staffName = staff?.fullName ?? widget.staffId;
            final staffCode = staff?.staffCode;
            final staffSeries = staff != null ? StaffSeries.label(staff.series).toUpperCase() : null;

            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Premium Staff Profile Header Card
                  _buildStaffProfileHeader(staffName, staffCode, staffSeries),
                  const SizedBox(height: 20),

                  // Document Details Summary Card
                  _buildDocumentSummaryCard(agreement, client),
                  const SizedBox(height: 24),

                  // Step-by-step Execution Steps
                  if (agreement == null)
                    _buildCreateStep()
                  else
                    _buildInteractiveSteps(agreement, staffName),

                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: RmTheme.crimsonDanger.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: RmTheme.crimsonDanger.withOpacity(0.2)),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline, color: RmTheme.crimsonDanger, size: 20),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _error!,
                              style: GoogleFonts.inter(
                                fontSize: 13,
                                color: RmTheme.crimsonDanger,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ).animate().shake(duration: 400.ms),
                  ],

                  if (_pdfUrl != null) ...[
                    const SizedBox(height: 24),
                    _buildPdfResultCard(),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildStaffProfileHeader(String name, String? code, String? series) {
    final firstLetter = name.isNotEmpty ? name[0].toUpperCase() : '?';
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: RmTheme.electricBlue.withOpacity(0.1),
            child: Text(
              firstLetter,
              style: GoogleFonts.inter(
                color: RmTheme.electricBlue,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 17,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${code ?? "ID: " + widget.staffId}${series != null ? " • $series" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.02, end: 0, duration: 400.ms);
  }

  Widget _buildDocumentSummaryCard(Agreement? agreement, FinanceCustomer? client) {
    final isSigned = agreement?.isSigned ?? false;
    final statusColor = isSigned ? RmTheme.emeraldGreen : RmTheme.amberWarning;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withOpacity(0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: const Icon(
                      Icons.description_outlined,
                      color: AppColors.primary,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Document Info',
                    style: GoogleFonts.inter(
                      fontSize: 15.5,
                      fontWeight: FontWeight.bold,
                      color: RmTheme.textPrimary,
                    ),
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  agreement?.status ?? 'NOT YET CREATED',
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.bold,
                    fontSize: 11,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          _buildDetailRow(
            label: 'Instrument Type',
            value: '${widget.type} (Employment Agreement)',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Client Name',
            value: client?.customerName ?? 'Loading Client...',
          ),
          const SizedBox(height: 10),
          _buildDetailRow(
            label: 'Client ID',
            value: widget.clientId,
            isCode: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 400.ms).slideY(begin: 0.02, end: 0);
  }

  Widget _buildDetailRow({required String label, required String value, bool isCode = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: RmTheme.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(width: 20),
        Flexible(
          child: Text(
            value,
            textAlign: TextAlign.right,
            style: isCode
                ? const TextStyle(
                    fontFamily: 'Courier',
                    fontSize: 13.5,
                    color: RmTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  )
                : GoogleFonts.inter(
                    fontSize: 13.5,
                    color: RmTheme.textPrimary,
                    fontWeight: FontWeight.w600,
                  ),
          ),
        ),
      ],
    );
  }

  Widget _buildCreateStep() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5), width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Document Draft Generation',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w700,
              fontSize: 15.5,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'No e-sign record exists yet. Generate a new A1 employment agreement document to begin the signing workflow.',
            style: GoogleFonts.inter(
              color: RmTheme.textSecondary,
              fontSize: 13.5,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            height: 50,
            child: FilledButton(
              onPressed: _busy ? null : _createAgreement,
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _busy
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2.5, color: Colors.white),
                    )
                  : Text(
                      'Create Agreement Record',
                      style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 14.5),
                    ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildInteractiveSteps(Agreement agreement, String staffName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 12),
          child: Text(
            'E-Sign Progress Tracker',
            style: GoogleFonts.inter(
              fontWeight: FontWeight.bold,
              fontSize: 14,
              color: RmTheme.textSecondary,
              letterSpacing: 0.5,
            ),
          ),
        ),
        _buildTimelineStep(
          stepNumber: '1',
          title: 'Agreement Generated',
          subtitle: 'The legal A1 template record has been initialized.',
          isDone: true,
          isActive: false,
        ),
        _buildTimelineStep(
          stepNumber: '2',
          title: 'OTP Signature Verification',
          subtitle: agreement.isSigned
              ? 'Completed and secure signature applied.'
              : 'Requires dual authentication e-signature via OTP.',
          isDone: agreement.isSigned,
          isActive: !agreement.isSigned,
          child: agreement.isSigned
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Row(
                    children: [
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: FilledButton.icon(
                            onPressed: _busy ? null : () => _sendOtp(staffName),
                            icon: const Icon(Icons.sms_outlined, size: 18),
                            label: Text(
                              'Send OTP',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            style: FilledButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: SizedBox(
                          height: 48,
                          child: OutlinedButton.icon(
                            onPressed: _busy ? null : () => _verifyAndSign(agreement),
                            icon: const Icon(Icons.edit_outlined, size: 18),
                            label: Text(
                              'Verify & Sign',
                              style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                            ),
                            style: OutlinedButton.styleFrom(
                              foregroundColor: AppColors.primary,
                              side: const BorderSide(color: AppColors.primary, width: 1.5),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
        ),
        _buildTimelineStep(
          stepNumber: '3',
          title: 'PDF Document Archive',
          subtitle: agreement.isSigned
              ? 'Generate official signing verification PDF.'
              : 'Generate locked PDF (requires signature first).',
          isDone: _pdfUrl != null,
          isActive: agreement.isSigned && _pdfUrl == null,
          isLast: true,
          child: (!agreement.isSigned || _pdfUrl != null)
              ? null
              : Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: OutlinedButton.icon(
                      onPressed: _busy ? null : () => _generatePdf(agreement),
                      icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                      label: Text(
                        'Generate PDF Agreement',
                        style: GoogleFonts.inter(fontWeight: FontWeight.bold, fontSize: 13.5),
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: RmTheme.electricBlue,
                        side: const BorderSide(color: RmTheme.electricBlue, width: 1.5),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ),
        ),
      ],
    ).animate().fadeIn(delay: 200.ms, duration: 400.ms);
  }

  Widget _buildTimelineStep({
    required String stepNumber,
    required String title,
    required String subtitle,
    required bool isDone,
    required bool isActive,
    bool isLast = false,
    Widget? child,
  }) {
    final dotColor = isDone
        ? RmTheme.emeraldGreen
        : (isActive ? AppColors.primary : RmTheme.textSecondary.withOpacity(0.3));

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Timeline indicator line and bubble
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Column(
              children: [
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: dotColor.withOpacity(isDone || isActive ? 0.12 : 0.05),
                    shape: BoxShape.circle,
                    border: Border.all(color: dotColor, width: 2),
                  ),
                  child: Center(
                    child: isDone
                        ? const Icon(Icons.check, size: 13, color: RmTheme.emeraldGreen)
                        : Text(
                            stepNumber,
                            style: GoogleFonts.inter(
                              color: dotColor,
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 2,
                      margin: const EdgeInsets.symmetric(vertical: 4),
                      color: isDone ? RmTheme.emeraldGreen.withOpacity(0.4) : RmTheme.borderSubtle,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 14),
          // Content Card
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: 14.5,
                      color: isActive ? AppColors.primary : RmTheme.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 12.5,
                      height: 1.35,
                    ),
                  ),
                  if (child != null) child,
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPdfResultCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.electricBlue.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RmTheme.electricBlue.withOpacity(0.2), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: RmTheme.electricBlue.withOpacity(0.12),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.picture_as_pdf, color: RmTheme.electricBlue, size: 18),
              ),
              const SizedBox(width: 10),
              Text(
                'Signed Agreement PDF',
                style: GoogleFonts.inter(
                  color: RmTheme.electricBlue,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'The signed employment agreement has been compiled and is hosted at the following URL address:',
            style: GoogleFonts.inter(fontSize: 12.5, color: RmTheme.textSecondary, height: 1.4),
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.6),
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: RmTheme.borderSubtle),
            ),
            child: Row(
              children: [
                Expanded(
                  child: SelectableText(
                    _pdfUrl!,
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: RmTheme.textPrimary,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  icon: const Icon(Icons.copy_rounded, color: RmTheme.electricBlue, size: 18),
                  onPressed: () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('PDF Link copied to clipboard')),
                    );
                  },
                  constraints: const BoxConstraints(),
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0);
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
}
