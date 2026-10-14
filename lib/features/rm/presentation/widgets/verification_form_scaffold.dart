import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../domain/models/pipeline_stage.dart';
import '../providers/rm_providers.dart';
import 'rm_stage_ui.dart';

/// Shared scaffold for the 5 verification-track screens: shows the staff
/// banner, then whatever form/result widgets the track passes in.
class VerificationFormScaffold extends ConsumerWidget {
  const VerificationFormScaffold({
    super.key,
    required this.title,
    required this.staffId,
    required this.onBack,
    required this.children,
  });

  final String title;
  final String staffId;
  final VoidCallback onBack;
  final List<Widget> children;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(staffByIdProvider(staffId)).valueOrNull;

    return RmStageScaffold(
      title: title,
      stageCode: 'S2',
      stageColor: rmStageColor(PipelineStages.s2Verify),
      onBack: onBack,
      body: [
        if (staff != null)
          RmStaffBanner(staff: staff, showTracker: false)
        else
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(26),
            ),
          )
              .animate(onPlay: (c) => c.repeat())
              .shimmer(duration: 1200.ms, color: RmTheme.surfaceSecondary),
        const SizedBox(height: 20),
        ...children,
      ],
    );
  }
}

/// Labelled, filled text field for the verification forms.
class VerificationTextField extends StatelessWidget {
  const VerificationTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLength,
    this.validator,
    this.hint,
    this.icon,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final String? hint;
  final IconData? icon;

  IconData get _icon {
    if (icon != null) return icon!;
    final l = label.toLowerCase();
    if (l.contains('otp')) return Icons.sms_rounded;
    if (l.contains('aadhaar')) return Icons.badge_rounded;
    if (l.contains('licen')) return Icons.directions_car_rounded;
    if (l.contains('vehicle') || l.contains('registration')) {
      return Icons.local_shipping_rounded;
    }
    if (l.contains('date') || l.contains('dob')) return Icons.event_rounded;
    if (l.contains('phone') || l.contains('mobile')) return Icons.phone_rounded;
    if (l.contains('name')) return Icons.person_rounded;
    if (l.contains('remark') || l.contains('note')) return Icons.notes_rounded;
    return Icons.edit_rounded;
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 2, bottom: 8),
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: RmTheme.textPrimary,
            ),
          ),
        ),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          maxLength: maxLength,
          validator: validator,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15.5,
            fontWeight: FontWeight.w700,
            color: RmTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: hint ?? label,
            fillColor: Colors.white,
            prefixIcon: Icon(_icon, color: RmTheme.iconAccent, size: 20),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(16),
              borderSide: const BorderSide(color: RmTheme.borderSubtle),
            ),
            counterText: '',
          ),
        ),
      ],
    );
  }
}

/// Primary submit button — gradient pill, or a locked grey pill when
/// disabled (matches `AdvanceStageButton`).
class VerificationSubmitButton extends StatelessWidget {
  const VerificationSubmitButton({
    super.key,
    required this.label,
    required this.submitting,
    required this.onPressed,
    this.enabled = true,
  });

  final String label;
  final bool submitting;
  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return Container(
        height: 56,
        decoration: BoxDecoration(
          color: RmTheme.surfaceSecondary,
          borderRadius: BorderRadius.circular(30),
          border: Border.all(color: RmTheme.borderSubtle),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_rounded, size: 17, color: RmTheme.textSecondary),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.textSecondary,
                ),
              ),
            ),
          ],
        ),
      );
    }
    return DsGradientButton(
      label: label,
      isLoading: submitting,
      onPressed: submitting ? null : onPressed,
    );
  }
}

/// Result card shown after a track's API call returns, color-coded by
/// success/failure.
class VerificationResultCard extends StatelessWidget {
  const VerificationResultCard({
    super.key,
    required this.success,
    required this.rows,
    this.headline,
    this.pending = false,
  });

  final bool success;
  final Map<String, String> rows;
  final String? headline;
  final bool pending;

  @override
  Widget build(BuildContext context) {
    final color = pending
        ? RmTheme.amberWarning
        : (success ? RmTheme.emeraldGreen : RmTheme.crimsonDanger);
    final icon = pending
        ? Icons.hourglass_top_rounded
        : (success ? Icons.verified_rounded : Icons.gpp_bad_rounded);
    final title = headline ??
        (pending ? 'Pending' : (success ? 'Cleared' : 'Not cleared'));

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withValues(alpha: 0.3), width: 1.3),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(15),
                  boxShadow: [
                    BoxShadow(
                      color: color.withValues(alpha: 0.35),
                      blurRadius: 12,
                      offset: const Offset(0, 5),
                    ),
                  ],
                ),
                child: Icon(icon, color: Colors.white, size: 24),
              ).animate().scaleXY(
                    begin: 0.3,
                    end: 1,
                    duration: 600.ms,
                    curve: Curves.elasticOut,
                  ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      rmTitleCase(title),
                      style: GoogleFonts.plusJakartaSans(
                        color: color,
                        fontWeight: FontWeight.w800,
                        fontSize: 17,
                      ),
                    ),
                    Text(
                      'Verification result',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                children: [
                  for (var i = 0; i < rows.length; i++)
                    Container(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      decoration: BoxDecoration(
                        border: i == rows.length - 1
                            ? null
                            : const Border(
                                bottom: BorderSide(color: RmTheme.surfaceSecondary),
                              ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Text(
                              rows.keys.elementAt(i),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: RmTheme.textSecondary,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Flexible(
                            child: Text(
                              rows.values.elementAt(i),
                              textAlign: TextAlign.right,
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w700,
                                fontSize: 13.5,
                                color: RmTheme.textPrimary,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.06, end: 0, duration: 350.ms);
  }
}
