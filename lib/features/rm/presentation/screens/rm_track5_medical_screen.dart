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

/// Medical/sobriety screening track — `POST /verification/medical/submit/{staffId}`.
/// Unlike PV, this is a real pass/fail submitted by the RM on the spot
/// (e.g. after a clinic report comes back), so the outcome is returned
/// immediately as CLEAR/FAILED based on the `passed` flag sent.
class RmTrack5MedicalScreen extends ConsumerStatefulWidget {
  const RmTrack5MedicalScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmTrack5MedicalScreen> createState() => _RmTrack5MedicalScreenState();
}

class _RmTrack5MedicalScreenState extends ConsumerState<RmTrack5MedicalScreen> {
  final _notesController = TextEditingController();
  bool _passed = true;
  bool _submitting = false;
  MedicalResult? _result;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    setState(() => _submitting = true);

    final result = await ref.read(rmRepositoryProvider).submitMedical(
          widget.staffId,
          passed: _passed,
          notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        );

    if (!mounted) return;
    setState(() => _submitting = false);

    result.fold(
      onSuccess: (data) {
        setState(() => _result = data);
        ref.invalidate(rmVerificationStatusProvider(widget.staffId));
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Medical screening recorded: ${data.status}'),
            backgroundColor: data.status.toUpperCase() == 'CLEAR' ? RmTheme.emeraldGreen : RmTheme.crimsonDanger,
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
      title: 'Medical Screening',
      staffId: widget.staffId,
      onBack: () => context.pop(),
      children: [
        // ── Form Label ──
        Text(
          'Select Result Verdict',
          style: GoogleFonts.libreCaslonText(
            fontSize: 15,
            fontWeight: FontWeight.bold,
            color: RmTheme.textPrimary,
          ),
        ),
        const SizedBox(height: 10),

        // ── Choice Action Cards ──
        Row(
          children: [
            Expanded(
              child: _ResultChoiceTile(
                label: 'CLEAR',
                subtitle: 'Passed all parameters',
                icon: Icons.check_circle_outline_rounded,
                color: RmTheme.emeraldGreen,
                selected: _passed,
                onTap: () => setState(() => _passed = true),
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: _ResultChoiceTile(
                label: 'FAILED',
                subtitle: 'Failed parameters',
                icon: Icons.cancel_outlined,
                color: RmTheme.crimsonDanger,
                selected: !_passed,
                onTap: () => setState(() => _passed = false),
              ),
            ),
          ],
        )
            .animate()
            .fadeIn(delay: 80.ms, duration: 350.ms)
            .slideY(begin: 0.05, end: 0, delay: 80.ms, duration: 300.ms),

        const SizedBox(height: 20),

        // ── Notes TextField ──
        VerificationTextField(
          label: 'Notes (optional)',
          controller: _notesController,
          hint: 'e.g. clinic name, health certificate ref no',
        )
            .animate()
            .fadeIn(delay: 150.ms, duration: 350.ms)
            .slideY(begin: 0.04, end: 0, delay: 150.ms, duration: 300.ms),

        const SizedBox(height: 24),

        // ── Submit Button ──
        VerificationSubmitButton(
          label: 'Submit Medical Result',
          submitting: _submitting,
          onPressed: _submit,
        )
            .animate()
            .fadeIn(delay: 200.ms, duration: 350.ms)
            .slideY(begin: 0.03, end: 0, delay: 200.ms, duration: 300.ms),

        if (_result != null) ...[
          const SizedBox(height: 24),
          VerificationResultCard(
            success: _result!.status.toUpperCase() == 'CLEAR',
            headline: 'Recorded Outcome: ${_result!.status}',
            rows: {
              if (_result!.notes.isNotEmpty) 'Notes': _result!.notes,
              if (_result!.date.isNotEmpty) 'Date recorded': _result!.date,
            },
          ),
        ],
      ],
    );
  }
}

class _ResultChoiceTile extends StatelessWidget {
  const _ResultChoiceTile({
    required this.label,
    required this.subtitle,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: selected ? color.withValues(alpha: 0.08) : RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: selected ? color : RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: selected ? 1.8 : 1.2,
        ),
        boxShadow: selected
            ? [
                BoxShadow(
                  color: color.withValues(alpha: 0.15),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                )
              ]
            : const [
                BoxShadow(
                  color: Color(0x02000000),
                  blurRadius: 6,
                  offset: Offset(0, 2),
                )
              ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
            child: Column(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: selected ? color.withValues(alpha: 0.12) : RmTheme.borderSubtle.withValues(alpha: 0.25),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    icon,
                    color: selected ? color : RmTheme.textSecondary,
                    size: 24,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  label,
                  style: GoogleFonts.inter(
                    color: selected ? color : RmTheme.textPrimary,
                    fontWeight: FontWeight.w700,
                    fontSize: 15,
                    letterSpacing: 0.3,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontWeight: FontWeight.w500,
                    fontSize: 10.5,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
