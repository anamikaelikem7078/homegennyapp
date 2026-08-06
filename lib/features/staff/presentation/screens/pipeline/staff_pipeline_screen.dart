import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/staff_scaffold.dart';

/// Pipeline timeline tab.
class StaffPipelineScreen extends ConsumerWidget {
  const StaffPipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(staffPipelineProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const CircleAvatar(
                    backgroundImage: NetworkImage('https://i.pravatar.cc/150?img=47'),
                    radius: 18,
                  ),
                  Text(
                    'HOMEGENNY',
                    style: GoogleFonts.libreCaslonText(
                      color: const Color(0xFF1A56FF),
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const Icon(Icons.settings_outlined, color: Color(0xFF4B5563), size: 24),
                ],
              ),
            ),
            
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 8.0),
              child: Column(
                children: [
                  Text(
                    'Pipeline',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Your onboarding journey',
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),

            Expanded(
              child: pipeline.when(
                loading: () => const DsLoadingWidget(message: 'Loading pipeline...'),
                error: (e, _) => DsErrorState(
                  title: 'Failed to load pipeline',
                  onRetry: () => ref.invalidate(staffPipelineProvider),
                ),
                data: (stages) => DsRefreshIndicator(
                  onRefresh: () async => ref.invalidate(staffPipelineProvider),
                  child: ListView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
                    children: [
                      _StageSummary(stages: stages),
                      const SizedBox(height: 48),
                      _EditorialTimeline(stages: stages),
                      const SizedBox(height: 100),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StageSummary extends StatelessWidget {
  const _StageSummary({required this.stages});
  final List<PipelineStage> stages;

  @override
  Widget build(BuildContext context) {
    final completed = stages.where((s) => s.status == PipelineStageStatus.completed).length;
    final current = stages.where((s) => s.status == PipelineStageStatus.current).length;
    final pending = stages.where((s) => s.status == PipelineStageStatus.pending).length;

    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Expanded(
            child: _SummaryCard(
              label: 'COMPLETED',
              count: completed,
              countColor: const Color(0xFF1A56FF),
              icon: Icons.check_circle_outline,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'CURRENT',
              count: current,
              countColor: const Color(0xFFF59E0B),
              icon: Icons.more_horiz,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: _SummaryCard(
              label: 'PENDING',
              count: pending,
              countColor: const Color(0xFF334155),
              icon: Icons.schedule_outlined,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryCard extends StatelessWidget {
  const _SummaryCard({
    required this.label,
    required this.count,
    required this.countColor,
    required this.icon,
  });

  final String label;
  final int count;
  final Color countColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.2,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                '$count',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                  height: 1,
                  color: countColor,
                ),
              ),
              Icon(icon, size: 16, color: const Color(0xFF94A3B8)),
            ],
          ),
        ],
      ),
    );
  }
}

class _EditorialTimeline extends StatelessWidget {
  const _EditorialTimeline({required this.stages});
  final List<PipelineStage> stages;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(stages.length, (index) {
        final stage = stages[index];
        final isLast = index == stages.length - 1;
        
        final isCompleted = stage.status == PipelineStageStatus.completed;
        final isActive = stage.status == PipelineStageStatus.current;
        final isPending = stage.status == PipelineStageStatus.pending;
        
        return IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Column(
                children: [
                  _buildBadge(isCompleted, isActive, isPending),
                  if (!isLast)
                    Expanded(
                      child: Container(
                        width: 1.5,
                        color: const Color(0xFFE2E8F0),
                        margin: const EdgeInsets.symmetric(vertical: 8),
                      ),
                    ),
                ],
              ),
              const SizedBox(width: 20),
              Expanded(
                child: Padding(
                  padding: EdgeInsets.only(bottom: isLast ? 0 : 36.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage.title,
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 22,
                          color: isPending ? const Color(0xFF94A3B8) : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        _getSubtitle(stage),
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          color: isActive ? const Color(0xFF1A56FF) : const Color(0xFF64748B),
                          fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
                        ),
                      ),
                      if (isActive) ...[
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(
                              flex: 3,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFF1A56FF),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                            Expanded(
                              flex: 4,
                              child: Container(
                                height: 4,
                                decoration: BoxDecoration(
                                  color: const Color(0xFFE2E8F0),
                                  borderRadius: BorderRadius.circular(2),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }),
    );
  }
  
  String _getSubtitle(PipelineStage stage) {
    if (stage.status == PipelineStageStatus.completed) {
      return 'Completed — ${stage.completedAt ?? 'recently'}';
    } else if (stage.status == PipelineStageStatus.current) {
      return stage.description.isNotEmpty ? stage.description : 'Active Session';
    } else {
      return stage.description.isNotEmpty ? stage.description : 'Locked';
    }
  }

  Widget _buildBadge(bool isCompleted, bool isActive, bool isPending) {
    if (isCompleted) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFFDCFCE7).withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFF86EFAC).withValues(alpha: 0.5)),
        ),
        child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 20),
      );
    } else if (isActive) {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: const Color(0xFF1A56FF),
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF1A56FF).withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: const Icon(Icons.play_arrow_rounded, color: Colors.white, size: 24),
      );
    } else {
      return Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE2E8F0)),
        ),
        child: const Icon(Icons.lock_outline, color: Color(0xFFCBD5E1), size: 20),
      );
    }
  }
}

class StaffPipelineStageScreen extends ConsumerWidget {
  const StaffPipelineStageScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(staffPipelineProvider);

    return StaffPageScaffold(
      title: 'Stage Details',
      body: pipeline.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (stages) {
          final stage = stages.cast<PipelineStage?>().firstWhere(
                (s) => s!.id == stageId,
                orElse: () => null,
              );
          if (stage == null) {
            return const DsEmptyState(title: 'Stage not found');
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(stage.title, style: Theme.of(context).textTheme.headlineSmall),
              SizedBox(height: AppSpacing.sm),
              DsStatusChip(
                label: stage.status.name,
                type: switch (stage.status) {
                  PipelineStageStatus.completed => DsStatusType.success,
                  PipelineStageStatus.current => DsStatusType.primary,
                  PipelineStageStatus.pending => DsStatusType.neutral,
                },
              ),
              SizedBox(height: AppSpacing.lg),
              Text(stage.description, style: Theme.of(context).textTheme.bodyLarge),
              if (stage.completedAt != null) ...[
                SizedBox(height: AppSpacing.md),
                Text('Completed: ${stage.completedAt}'),
              ],
              const Spacer(),
              DsPrimaryButton(
                label: 'Back to Pipeline',
                onPressed: () => context.go(StaffRoutes.pipeline),
              ),
            ],
          );
        },
      ),
    );
  }
}
