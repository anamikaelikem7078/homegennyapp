import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/verification_form_scaffold.dart';

/// Driving license track — `POST /verification/dl` (Sarathi API).
class RmTrack2DlScreen extends ConsumerStatefulWidget {
  const RmTrack2DlScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmTrack2DlScreen> createState() => _RmTrack2DlScreenState();
}

class _RmTrack2DlScreenState extends ConsumerState<RmTrack2DlScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dlController = TextEditingController();
  final _dobController = TextEditingController();
  bool _submitting = false;
  DlResult? _result;

  @override
  void dispose() {
    _dlController.dispose();
    _dobController.dispose();
    super.dispose();
  }

  Future<void> _pickDob() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(1995, 1, 1),
      firstDate: DateTime(1940),
      lastDate: DateTime.now(),
    );
    if (picked != null) {
      _dobController.text =
          '${picked.year.toString().padLeft(4, '0')}-${picked.month.toString().padLeft(2, '0')}-${picked.day.toString().padLeft(2, '0')}';
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final result = await ref.read(rmRepositoryProvider).verifyDl(
          dlNumber: _dlController.text.trim(),
          dob: _dobController.text.trim(),
          staffId: widget.staffId,
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      onSuccess: (data) {
        setState(() => _result = data);
        ref.invalidate(rmVerificationStatusProvider(widget.staffId));
        final valid = data.status.toUpperCase() == 'VALID';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Driving licence status: ${data.status}'),
            backgroundColor: valid ? RmTheme.emeraldGreen : RmTheme.amberWarning,
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
      title: 'Driving License',
      staffId: widget.staffId,
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              VerificationTextField(
                label: 'DL number',
                controller: _dlController,
                hint: 'e.g. MH12 20230012345',
                validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the DL number' : null,
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _pickDob,
                child: AbsorbPointer(
                  child: VerificationTextField(
                    label: 'Date of birth',
                    controller: _dobController,
                    hint: 'YYYY-MM-DD',
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Select date of birth' : null,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        VerificationSubmitButton(label: 'Verify DL', submitting: _submitting, onPressed: _submit),
        if (_result != null) ...[
          const SizedBox(height: 24),
          VerificationResultCard(
            success: _result!.status.toUpperCase() == 'VALID',
            headline: 'DL status: ${_result!.status}',
            rows: {
              'DL number': _result!.dlNumber,
              'Name': _result!.name,
              if (_result!.vehicleClasses.isNotEmpty) 'Vehicle classes': _result!.vehicleClasses.join(', '),
            },
          ),
        ],
      ],
    );
  }
}
