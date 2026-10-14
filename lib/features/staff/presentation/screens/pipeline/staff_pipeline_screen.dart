import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

DsStepState _stepState(PipelineStageStatus s) => switch (s) {
      PipelineStageStatus.completed => DsStepState.done,
      PipelineStageStatus.current => DsStepState.active,
      PipelineStageStatus.pending => DsStepState.locked,
    };

String _subtitle(PipelineStage stage) => switch (stage.status) {
      PipelineStageStatus.completed => 'Completed — ${stage.completedAt ?? 'recently'}',
      PipelineStageStatus.current => stage.description.isNotEmpty ? stage.description : 'In progress',
      PipelineStageStatus.pending => stage.description.isNotEmpty ? stage.description : 'Locked',
    };

/// Pipeline timeline tab.
class StaffPipelineScreen extends ConsumerWidget {
  const StaffPipelineScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(staffPipelineProvider);

    return DsPage(
      title: 'Pipeline',
      subtitle: 'Your onboarding journey',
      showBack: false,
      extraBottomPadding: 90,
      onRefresh: () async => ref.invalidate(staffPipelineProvider),
      actions: [
        DsPageAction(
          icon: Icons.settings_rounded,
          tooltip: 'Settings',
          onPressed: () => context.push(StaffRoutes.settings),
        ),
      ],
      body: dsAsyncBody(
        pipeline,
        onRetry: () => ref.invalidate(staffPipelineProvider),
        builder: (stages) {
          final completed = stages.where((s) => s.status == PipelineStageStatus.completed).length;
          final current = stages.where((s) => s.status == PipelineStageStatus.current).firstOrNull;
          final pending = stages.where((s) => s.status == PipelineStageStatus.pending).length;
          final progress = stages.isEmpty ? 0.0 : completed / stages.length;

          return [
            DsGradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            DsGlassPill(
                              current == null ? 'ALL DONE' : 'CURRENT STAGE',
                              icon: current == null ? Icons.celebration_rounded : Icons.play_arrow_rounded,
                            ),
                            const SizedBox(height: 12),
                            Text(
                              current?.title ?? 'Onboarding complete',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 21,
                                height: 1.2,
                                fontWeight: FontWeight.w800,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      const DsFloatingIconTile(icon: Icons.route_rounded),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Row(
                    children: [
                      Expanded(
                        child: ClipRRect(
                          borderRadius: BorderRadius.circular(5),
                          child: TweenAnimationBuilder<double>(
                            tween: Tween(begin: 0, end: progress),
                            duration: 1000.ms,
                            curve: Curves.easeOutCubic,
                            builder: (_, v, _) => LinearProgressIndicator(
                              value: v,
                              minHeight: 9,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: AppColors.sunYellow,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        '${(progress * 100).round()}%',
                        style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: Colors.white),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(child: DsGlassStat(value: '$completed', label: 'Completed', icon: Icons.check_circle_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: DsGlassStat(value: current == null ? '0' : '1', label: 'Current', icon: Icons.play_circle_rounded)),
                      const SizedBox(width: 10),
                      Expanded(child: DsGlassStat(value: '$pending', label: 'Upcoming', icon: Icons.lock_clock_rounded)),
                    ],
                  ),
                ],
              ),
            ),
            DsSection('Stages', trailing: DsPill('${stages.length}')),
            if (stages.isEmpty)
              const DsEmptyBlock(
                icon: Icons.route_rounded,
                title: 'No stages yet',
                message: 'Your onboarding stages will appear here.',
              )
            else
              DsStepList(
                steps: [
                  for (final s in stages)
                    DsStep(
                      title: s.title,
                      subtitle: _subtitle(s),
                      state: _stepState(s.status),
                      icon: Icons.play_arrow_rounded,
                      onTap: () => context.push(StaffRoutes.pipelineStage(s.id)),
                    ),
                ],
              ),
          ];
        },
      ),
    );
  }
}

/// Single pipeline stage.
class StaffPipelineStageScreen extends ConsumerWidget {
  const StaffPipelineStageScreen({super.key, required this.stageId});

  final String stageId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pipeline = ref.watch(staffPipelineProvider);

    return DsPage(
      title: 'Stage details',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.pipeline),
      onRefresh: () async => ref.invalidate(staffPipelineProvider),
      bottom: DsOutlineButton(
        label: 'Back to pipeline',
        icon: Icons.route_rounded,
        onPressed: () => context.go(StaffRoutes.pipeline),
      ),
      body: dsAsyncBody(
        pipeline,
        onRetry: () => ref.invalidate(staffPipelineProvider),
        builder: (stages) {
          final index = stages.indexWhere((s) => s.id == stageId);
          if (index < 0) {
            return const [
              DsEmptyBlock(
                icon: Icons.search_off_rounded,
                title: 'Stage not found',
                message: 'This stage may have been updated. Pull to refresh.',
              ),
            ];
          }
          final stage = stages[index];
          final (gradient, label, icon) = switch (stage.status) {
            PipelineStageStatus.completed => (DsGradientCard.green, 'Completed', Icons.check_circle_rounded),
            PipelineStageStatus.current => (DsGradientCard.blue, 'In progress', Icons.play_circle_rounded),
            PipelineStageStatus.pending => (const [Color(0xFF334155), Color(0xFF475569), Color(0xFF64748B)], 'Upcoming', Icons.lock_rounded),
          };
          return [
            DsGradientCard(
              colors: gradient,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsGlassPill('STAGE ${index + 1} OF ${stages.length}'),
                        const SizedBox(height: 12),
                        Text(
                          stage.title,
                          style: GoogleFonts.plusJakartaSans(fontSize: 22, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                        const SizedBox(height: 6),
                        DsGlassPill(label.toUpperCase(), icon: icon),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  DsFloatingIconTile(icon: icon),
                ],
              ),
            ),
            const DsSection('About this stage'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(),
              child: Text(
                stage.description.isEmpty ? 'No further details for this stage.' : stage.description,
                style: GoogleFonts.plusJakartaSans(fontSize: 14, height: 1.55, color: const Color(0xFF374151)),
              ),
            ),
            if (stage.completedAt != null) ...[
              const SizedBox(height: 14),
              DsListCard(
                icon: Icons.event_available_rounded,
                iconColor: AppColors.success,
                title: 'Completed',
                subtitle: stage.completedAt,
              ),
            ],
            if (stage.status == PipelineStageStatus.current) ...[
              const SizedBox(height: 14),
              const DsNote(
                title: 'You\'re here',
                text: 'Your Relationship Manager will guide you through this stage. Check notifications for updates.',
              ),
            ],
          ];
        },
      ),
    );
  }
}
