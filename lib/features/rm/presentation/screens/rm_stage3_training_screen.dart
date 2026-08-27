import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../navigation/rm_routes.dart';
import '../providers/rm_providers.dart';
import '../widgets/advance_stage_action.dart';

/// S3 Training. No dedicated RM-facing training-completion endpoint exists
/// on the backend (verified against live Swagger — see the plan's
/// "Architecture decisions #6"), so this screen does not fabricate a
/// completion status. Advancing to S4 requires an explicit RM attestation
/// checkbox rather than a fake automated "complete" signal. Video
/// certification — the one part of this stage with real backend support —
/// is linked out to its own read-only monitoring screen.
class RmStage3TrainingScreen extends ConsumerStatefulWidget {
  const RmStage3TrainingScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmStage3TrainingScreen> createState() =>
      _RmStage3TrainingScreenState();
}

class _RmStage3TrainingScreenState extends ConsumerState<RmStage3TrainingScreen> {
  bool _attested = false;

  @override
  Widget build(BuildContext context) {
    final staffAsync = ref.watch(staffByIdProvider(widget.staffId));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Training (S3)',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
      ),
      body: AsyncValueWidget<StaffRow?>(
        value: staffAsync,
        onRetry: () => ref.invalidate(staffByIdProvider(widget.staffId)),
        builder: (staff) {
          if (staff == null) {
            return Center(
              child: Text(
                'Staff not found',
                style: GoogleFonts.inter(color: RmTheme.textSecondary),
              ),
            );
          }
          return SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Profile Header ──
                _buildProfileHeader(staff),

                const SizedBox(height: 20),

                // ── Info Warning Banner ──
                _buildWarningBanner()
                    .animate()
                    .fadeIn(delay: 50.ms, duration: 350.ms)
                    .slideY(begin: 0.05, end: 0, delay: 50.ms, duration: 350.ms),

                const SizedBox(height: 16),

                // ── Video Certification Card ──
                _buildVideoCertCard(staff.id, staff.series)
                    .animate()
                    .fadeIn(delay: 100.ms, duration: 350.ms)
                    .slideY(begin: 0.04, end: 0, delay: 100.ms, duration: 350.ms),

                const SizedBox(height: 16),

                // ── Attestation Choice Card ──
                _buildAttestationCard()
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 350.ms)
                    .slideY(begin: 0.03, end: 0, delay: 150.ms, duration: 350.ms),

                const SizedBox(height: 24),

                // ── Advance Action Button ──
                AdvanceStageButton(
                  staffId: staff.id,
                  fromStage: staff.pipelineStage,
                  toStage: PipelineStages.s4Agreements,
                  label: 'Advance to Agreements (S4)',
                  reasonCode: 'TRAINING_ATTESTED',
                  enabled: _attested,
                ).animate().fadeIn(delay: 200.ms, duration: 350.ms),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(StaffRow staff) {
    final firstLetter =
        staff.fullName.isNotEmpty ? staff.fullName[0].toUpperCase() : '?';

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
                  staff.fullName,
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 18,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '${staff.staffCode} • ${StaffSeries.label(staff.series).toUpperCase()}',
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

  Widget _buildWarningBanner() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.amberWarning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RmTheme.amberWarning.withValues(alpha: 0.2),
          width: 1.2,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: RmTheme.amberWarning,
            size: 22,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              'No training-completion API exists on the backend yet. Video certification is the only part of this stage with real backend support — check it, then attest completion below.',
              style: GoogleFonts.inter(
                color: const Color(0xFFB45309), // Warm dark amber
                fontSize: 13,
                fontWeight: FontWeight.w500,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVideoCertCard(String staffId, String series) {
    final promptsAsync = ref.watch(rmVideoCertPromptsProvider(series));
    final itemsAsync = ref.watch(rmVideoCertsProvider(staffId));

    // Complete only once every required prompt has a submitted item that a
    // trainer has approved — a PENDING/REJECTED or missing item still counts
    // as incomplete.
    bool? complete;
    String subtitle = 'View submitted prompts and trainer review status';
    final prompts = promptsAsync.valueOrNull;
    final items = itemsAsync.valueOrNull;
    if (prompts != null && items != null) {
      final approvedKeys = items
          .where((i) => i.reviewStatus == 'APPROVED')
          .map((i) => i.promptKey)
          .toSet();
      complete = prompts.prompts.isNotEmpty &&
          prompts.prompts.every(approvedKeys.contains);
      final approvedCount = prompts.prompts.where(approvedKeys.contains).length;
      subtitle = complete
          ? 'All $approvedCount/${prompts.prompts.length} prompts trainer-approved'
          : '$approvedCount/${prompts.prompts.length} prompts trainer-approved';
    }
    final color = complete == true ? RmTheme.emeraldGreen : RmTheme.electricBlue;

    return Container(
      decoration: BoxDecoration(
        color: complete == true ? RmTheme.emeraldGreen.withValues(alpha: 0.06) : RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: complete == true ? RmTheme.emeraldGreen : RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: complete == true ? 1.8 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => context.push(RmRoutes.stage3VideoReview(staffId)),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                // ── Circle Lead Icon ──
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.08),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    complete == true ? Icons.check_circle : Icons.videocam_outlined,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Title & Description ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Video Certification',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: complete == true ? RmTheme.emeraldGreen : RmTheme.textSecondary,
                          fontWeight: complete == true ? FontWeight.w600 : FontWeight.w400,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                const Icon(
                  Icons.chevron_right_rounded,
                  color: RmTheme.textSecondary,
                  size: 20,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildAttestationCard() {
    return Container(
      decoration: BoxDecoration(
        color: _attested ? RmTheme.emeraldGreen.withValues(alpha: 0.06) : RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: _attested ? RmTheme.emeraldGreen : RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: _attested ? 1.8 : 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x02000000),
            blurRadius: 8,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: () => setState(() => _attested = !_attested),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── custom Styled Checkbox ──
                Padding(
                  padding: const EdgeInsets.only(top: 2),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    curve: Curves.easeOutCubic,
                    width: 22,
                    height: 22,
                    decoration: BoxDecoration(
                      color: _attested ? RmTheme.emeraldGreen : Colors.transparent,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: _attested ? RmTheme.emeraldGreen : RmTheme.textSecondary.withValues(alpha: 0.5),
                        width: 1.8,
                      ),
                    ),
                    child: _attested
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 16,
                          )
                        : null,
                  ),
                ),
                const SizedBox(width: 14),

                // ── Attestation Text ──
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'I attest training requirements are complete',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 14.5,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manual RM sign-off — the backend has no automated completion check for this stage.',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: RmTheme.textSecondary,
                          height: 1.35,
                        ),
                      ),
                    ],
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
