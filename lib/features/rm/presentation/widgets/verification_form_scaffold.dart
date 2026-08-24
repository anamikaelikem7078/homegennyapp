import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../providers/rm_providers.dart';

/// Shared scaffold for the 5 verification-track screens: shows the staff
/// header, then whatever form/result widgets the track passes in.
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
    final staffAsync = ref.watch(staffByIdProvider(staffId));
    final staffName = staffAsync.maybeWhen(data: (s) => s?.fullName, orElse: () => null);
    final staffCode = staffAsync.maybeWhen(data: (s) => s?.staffCode, orElse: () => null);
    final staffSeries = staffAsync.maybeWhen(
      data: (s) => s == null ? null : StaffSeries.label(s.series).toUpperCase(),
      orElse: () => null,
    );

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: Text(
          title,
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: onBack,
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Premium Profile Summary Header ──
            if (staffName != null)
              _buildStaffProfileHeader(staffName, staffCode, staffSeries)
            else
              _buildStaffProfileHeader(staffId, null, null),

            const SizedBox(height: 24),

            // ── Children Content Form Fields & Results ──
            ...children,
          ],
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
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
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
            backgroundColor: RmTheme.electricBlue.withValues(alpha: 0.1),
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
                    fontSize: 18,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${code ?? "..."}${series != null ? " • $series" : ""}',
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: RmTheme.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideX(begin: -0.02, end: 0, duration: 400.ms);
  }
}

/// Text field styled consistently for the verification forms.
class VerificationTextField extends StatelessWidget {
  const VerificationTextField({
    super.key,
    required this.label,
    required this.controller,
    this.keyboardType,
    this.maxLength,
    this.validator,
    this.hint,
  });

  final String label;
  final TextEditingController controller;
  final TextInputType? keyboardType;
  final int? maxLength;
  final String? Function(String?)? validator;
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLength: maxLength,
      validator: validator,
      style: GoogleFonts.inter(
        fontSize: 15,
        fontWeight: FontWeight.w500,
        color: RmTheme.textPrimary,
      ),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w500,
          color: RmTheme.textSecondary,
        ),
        hintText: hint,
        hintStyle: GoogleFonts.inter(
          fontSize: 14,
          color: RmTheme.textSecondary.withValues(alpha: 0.6),
        ),
        filled: true,
        fillColor: RmTheme.cardSurface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: RmTheme.borderSubtle.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: BorderSide(
            color: RmTheme.borderSubtle.withValues(alpha: 0.5),
            width: 1.2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RmTheme.electricBlue, width: 1.8),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(14),
          borderSide: const BorderSide(color: RmTheme.crimsonDanger, width: 1.2),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
        counterText: '',
      ),
    );
  }
}

/// Primary submit button with an in-flight spinner, matching
/// `AdvanceStageButton`'s look.
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
    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: (!enabled || submitting) ? null : onPressed,
        style: FilledButton.styleFrom(
          backgroundColor: RmTheme.electricBlue,
          disabledBackgroundColor: RmTheme.borderSubtle.withValues(alpha: 0.8),
          disabledForegroundColor: RmTheme.textSecondary,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: submitting
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                label,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
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

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.25), width: 1.2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  pending
                      ? Icons.hourglass_top_rounded
                      : (success ? Icons.check_rounded : Icons.close_rounded),
                  color: color,
                  size: 16,
                ),
              ),
              const SizedBox(width: 10),
              Text(
                headline ?? (success ? 'PASSED' : 'NOT CLEARED'),
                style: GoogleFonts.inter(
                  color: color,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                  letterSpacing: 0.3,
                ),
              ),
            ],
          ),
          if (rows.isNotEmpty) ...[
            const SizedBox(height: 14),
            for (final entry in rows.entries) ...[
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      entry.key,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                    Flexible(
                      child: Text(
                        entry.value,
                        textAlign: TextAlign.right,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 13.5,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.04, end: 0, duration: 300.ms);
  }
}
