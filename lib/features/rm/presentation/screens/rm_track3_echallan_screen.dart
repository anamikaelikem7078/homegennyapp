import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/verification_form_scaffold.dart';

/// eChallan track — `POST /verification/echallan/{dlNumber}`. Run after the
/// DL track since it needs a DL number, but kept as its own screen since the
/// backend treats it as an independent check (its own `VerificationTrack`
/// row), not a DL sub-step.
class RmTrack3EChallanScreen extends ConsumerStatefulWidget {
  const RmTrack3EChallanScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmTrack3EChallanScreen> createState() => _RmTrack3EChallanScreenState();
}

class _RmTrack3EChallanScreenState extends ConsumerState<RmTrack3EChallanScreen> {
  final _formKey = GlobalKey<FormState>();
  final _dlController = TextEditingController();
  bool _submitting = false;
  EchallanResult? _result;

  @override
  void dispose() {
    _dlController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _submitting = true);

    final result = await ref.read(rmRepositoryProvider).verifyEchallan(
          _dlController.text.trim(),
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
            content: Text('${data.count} outstanding violation(s) found.'),
            backgroundColor: data.count == 0 ? RmTheme.emeraldGreen : RmTheme.amberWarning,
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
      title: 'eChallan Check',
      staffId: widget.staffId,
      onBack: () => context.pop(),
      children: [
        Form(
          key: _formKey,
          child: VerificationTextField(
            label: 'DL number',
            controller: _dlController,
            hint: 'Same DL number verified in the DL track',
            validator: (v) => (v == null || v.trim().isEmpty) ? 'Enter the DL number' : null,
          ),
        ),
        const SizedBox(height: 24),
        VerificationSubmitButton(label: 'Check eChallan', submitting: _submitting, onPressed: _submit),
        if (_result != null) ...[
          const SizedBox(height: 24),
          VerificationResultCard(
            success: _result!.count == 0,
            headline: _result!.count == 0 ? 'No outstanding violations' : '${_result!.count} violation(s) found',
            rows: {'Violation count': _result!.count.toString()},
          ),
        ],
      ],
    );
  }
}
