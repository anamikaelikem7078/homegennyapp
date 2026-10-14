import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/series/series_catalog.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../../domain/models/pipeline_stage.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';
import '../widgets/rm_stage_ui.dart';

class RmDeferredScreen extends ConsumerWidget {
  const RmDeferredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deferredAsync = ref.watch(rmDeferredProvider);

    return RmStageScaffold(
      title: 'Deferred',
      stageColor: RmTheme.amberWarning,
      stageCode: deferredAsync.valueOrNull == null
          ? null
          : '${deferredAsync.valueOrNull!.length}',
      onRefresh: () async => ref.invalidate(rmDeferredProvider),
      body: rmAsyncBody<List<DeferredRow>>(
        deferredAsync,
        onRetry: () => ref.invalidate(rmDeferredProvider),
        builder: (rows) => [
          const RmNote(
            tone: RmNoteTone.warning,
            title: 'Paused cases',
            text: 'Resume a staff member to put them back into the pipeline '
                'at the stage you choose.',
          ),
          const RmSectionTitle(title: 'On hold'),
          if (rows.isEmpty)
            const RmEmptyBlock(
              icon: Icons.pause_circle_rounded,
              color: RmTheme.amberWarning,
              title: 'No deferred cases',
              message: 'Paused staff will appear here.',
            )
          else
            for (final r in rows) _DeferredCard(row: r),
        ],
      ),
    );
  }
}

class _DeferredCard extends ConsumerStatefulWidget {
  const _DeferredCard({required this.row});
  final DeferredRow row;

  @override
  ConsumerState<_DeferredCard> createState() => _DeferredCardState();
}

class _DeferredCardState extends ConsumerState<_DeferredCard> {
  bool _busy = false;

  Future<String?> _pickStage() {
    return showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) {
        final current = widget.row.resumeStage ?? PipelineStages.s1Intake;
        return Container(
          decoration: const BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
          ),
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: Container(
                    width: 40,
                    height: 4,
                    decoration: BoxDecoration(
                      color: RmTheme.borderSubtle,
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Resume to which stage?',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 19,
                    fontWeight: FontWeight.w800,
                    color: RmTheme.textPrimary,
                  ),
                ),
                const SizedBox(height: 14),
                // S2.5 only for someone deferred from it (they resume back into it).
                for (final s in PipelineStages.flowFor(current,
                    stage25Enabled: ref.read(seriesCatalogProvider).stage25Enabled))
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Material(
                      color: s == current
                          ? const Color(0xFFE8EEFF)
                          : RmTheme.surfaceSecondary,
                      borderRadius: BorderRadius.circular(16),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: () {
                          HapticFeedback.selectionClick();
                          Navigator.of(sheetContext).pop(s);
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                          child: Row(
                            children: [
                              Icon(rmStageIcon(s), size: 20, color: rmStageColor(s)),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  PipelineStages.label(s),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w700,
                                    color: RmTheme.textPrimary,
                                  ),
                                ),
                              ),
                              if (s == current)
                                const RmStatusPill(
                                  label: 'Suggested',
                                  color: RmTheme.electricBlue,
                                ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ).animate().fadeIn(duration: 250.ms).slideX(begin: 0.1, end: 0),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _resume() async {
    final toStage = await _pickStage();
    if (toStage == null || !mounted) return;
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Resume to ${PipelineStages.label(toStage)}?',
      message: '${widget.row.staff?.fullName ?? 'This staff member'} will re-enter the pipeline at this stage.',
      confirmLabel: 'Resume',
      icon: Icons.play_arrow_rounded,
    );
    if (ok != true || !mounted) return;

    setState(() => _busy = true);
    final result = await ref.read(rmRepositoryProvider).resumeDeferred(widget.row.staffId, toStage);
    if (!mounted) return;
    setState(() => _busy = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(rmDeferredProvider);
        ref.invalidate(rmKanbanProvider);
        ref.invalidate(rmDashboardProvider);
        DsSnackBar.show(
          context,
          message: 'Resumed to ${PipelineStages.label(toStage)}',
          type: DsSnackBarType.success,
        );
      },
      onError: (f) => DsSnackBar.show(context, message: f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final row = widget.row;
    final name = row.staff?.fullName ?? row.staffId;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
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
                  color: RmTheme.amberWarning.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(Icons.pause_circle_rounded, color: RmTheme.amberWarning),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w800,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    if (row.staff?.staffCode != null)
                      Text(
                        row.staff!.staffCode,
                        style: GoogleFonts.robotoMono(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                  ],
                ),
              ),
              RmStatusPill(label: rmTitleCase(row.reason), color: RmTheme.amberWarning),
            ],
          ),
          if (row.notes != null || row.deferredAt != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RmTheme.surfaceSecondary,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (row.deferredAt != null)
                    Text(
                      'Deferred ${row.deferredAt}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: RmTheme.textSecondary,
                      ),
                    ),
                  if (row.notes != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Text(
                        row.notes!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          height: 1.4,
                          fontWeight: FontWeight.w500,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 12),
          DsSecondaryButton(
            label: 'Resume to pipeline',
            icon: Icons.play_arrow_rounded,
            isLoading: _busy,
            onPressed: _busy ? null : _resume,
          ),
        ],
      ),
    );
  }
}
