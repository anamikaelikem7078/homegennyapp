import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
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
      builder: (dialogContext) {
        final controller = TextEditingController();
        return AlertDialog(
          title: const Text('Enter OTP'),
          content: TextField(controller: controller, keyboardType: TextInputType.number, decoration: const InputDecoration(hintText: '6-digit code')),
          actions: [
            TextButton(onPressed: () => Navigator.of(dialogContext).pop(), child: const Text('Cancel')),
            FilledButton(onPressed: () => Navigator.of(dialogContext).pop(controller.text.trim()), child: const Text('Verify & Sign')),
          ],
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

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(backgroundColor: RmTheme.offWhite, elevation: 0, title: Text(widget.title)),
      body: staffAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('$e')),
        data: (staff) => agreementsAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('$e')),
          data: (agreements) {
            final agreement = _findAgreement(agreements);
            final staffName = staff?.fullName ?? widget.staffId;
            return Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(staffName, style: RmTheme.headline(context).copyWith(fontSize: 20)),
                  const SizedBox(height: 4),
                  Text('${widget.type} agreement for client ${widget.clientId}', style: RmTheme.body(context).copyWith(fontSize: 12)),
                  const SizedBox(height: 20),
                  if (agreement == null)
                    _buildCreateStep()
                  else
                    _buildStatusStep(agreement, staffName),
                  if (_error != null) ...[
                    const SizedBox(height: 16),
                    Text(_error!, style: TextStyle(color: RmTheme.crimsonDanger)),
                  ],
                  if (_pdfUrl != null) ...[
                    const SizedBox(height: 16),
                    const Text('PDF generated:', style: TextStyle(fontWeight: FontWeight.w600)),
                    SelectableText(_pdfUrl!, maxLines: 3),
                  ],
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCreateStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('No agreement record exists yet for this instrument.'),
        const SizedBox(height: 12),
        FilledButton(
          onPressed: _busy ? null : _createAgreement,
          style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
          child: _busy ? const _Spinner() : const Text('Create Agreement'),
        ),
      ],
    );
  }

  Widget _buildStatusStep(Agreement agreement, String staffName) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: agreement.isSigned ? RmTheme.emeraldGreen.withOpacity(0.1) : RmTheme.amberWarning.withOpacity(0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(agreement.status, style: TextStyle(color: agreement.isSigned ? RmTheme.emeraldGreen : RmTheme.amberWarning, fontWeight: FontWeight.w700)),
        ),
        const SizedBox(height: 16),
        if (!agreement.isSigned) ...[
          FilledButton.icon(
            onPressed: _busy ? null : () => _sendOtp(staffName),
            icon: const Icon(Icons.sms_outlined),
            label: const Text('Send OTP'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _verifyAndSign(agreement),
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Verify OTP & Sign'),
          ),
        ] else ...[
          OutlinedButton.icon(
            onPressed: _busy ? null : () => _generatePdf(agreement),
            icon: const Icon(Icons.picture_as_pdf_outlined),
            label: const Text('Generate PDF'),
          ),
        ],
      ],
    );
  }
}

class _Spinner extends StatelessWidget {
  const _Spinner();
  @override
  Widget build(BuildContext context) => const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white));
}
