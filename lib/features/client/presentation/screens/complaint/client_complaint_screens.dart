import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

/// Raise complaint form.
class ClientRaiseComplaintScreen extends ConsumerStatefulWidget {
  const ClientRaiseComplaintScreen({super.key});

  @override
  ConsumerState<ClientRaiseComplaintScreen> createState() => _ClientRaiseComplaintScreenState();
}

class _ClientRaiseComplaintScreenState extends ConsumerState<ClientRaiseComplaintScreen> {
  final _description = TextEditingController();
  bool _loading = false;
  String _urgency = 'STANDARD';

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_description.text.trim().isEmpty) {
      context.showDsSnackBar(context.l10n.pleaseDescribeIssue, type: DsSnackBarType.warning);
      return;
    }
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).raiseComplaint(
          subject: 'Support Request - $_urgency',
          description: _description.text,
        );
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(clientComplaintsProvider);
        context.showDsSnackBar(context.l10n.issueSubmittedSuccess, type: DsSnackBarType.success);
        context.go(ClientRoutes.complaintHistory);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final levels = [
      ('LOW', l10n.urgencyLow, Icons.south_rounded, AppColors.success),
      ('STANDARD', l10n.urgencyStandard, Icons.remove_rounded, AppColors.primary),
      ('CRITICAL', l10n.urgencyCritical, Icons.priority_high_rounded, AppColors.error),
    ];

    return DsPage(
      title: 'Report an issue',
      onBack: () {
        if (context.canPop()) context.pop();
      },
      actions: [
        DsPageAction(
          icon: Icons.history_rounded,
          tooltip: l10n.complaintHistoryTitle,
          onPressed: () => context.push(ClientRoutes.complaintHistory),
        ),
      ],
      bottom: DsGradientButton(
        label: l10n.submitIssue,
        icon: Icons.send_rounded,
        isLoading: _loading,
        onPressed: _loading ? null : _submit,
      ),
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.experienceIssue,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.5,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      l10n.supportTeamDesc,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const DsFloatingIconTile(icon: Icons.support_agent_rounded),
            ],
          ),
        ),
        DsSection(l10n.describeIssue),
        DsLabeledField(
          label: 'What happened?',
          controller: _description,
          icon: Icons.edit_note_rounded,
          hint: l10n.detailProblemHint,
          maxLines: 5,
          minLines: 4,
          textCapitalization: TextCapitalization.sentences,
        ),
        DsSection(l10n.urgencyLevel),
        Row(
          children: [
            for (var i = 0; i < levels.length; i++) ...[
              if (i > 0) const SizedBox(width: 10),
              Expanded(
                child: _UrgencyCard(
                  label: levels[i].$2,
                  icon: levels[i].$3,
                  color: levels[i].$4,
                  selected: _urgency == levels[i].$1,
                  onTap: () => setState(() => _urgency = levels[i].$1),
                ),
              ),
            ],
          ],
        ),
        const SizedBox(height: 18),
        DsNote(title: l10n.priorityHandling, text: l10n.priorityHandlingDesc),
      ],
    );
  }
}

class _UrgencyCard extends StatelessWidget {
  const _UrgencyCard({
    required this.label,
    required this.icon,
    required this.color,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final Color color;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 250.ms,
        curve: Curves.easeOutCubic,
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        decoration: BoxDecoration(
          color: selected ? color.withValues(alpha: 0.08) : Colors.white,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: selected ? color : AppColors.lightBorder, width: selected ? 1.8 : 1),
          boxShadow: selected
              ? [BoxShadow(color: color.withValues(alpha: 0.2), blurRadius: 14, offset: const Offset(0, 6))]
              : dsCardShadow,
        ),
        child: Column(
          children: [
            AnimatedContainer(
              duration: 250.ms,
              width: 38,
              height: 38,
              decoration: BoxDecoration(
                color: selected ? color : color.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 20, color: selected ? Colors.white : color),
            ),
            const SizedBox(height: 8),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: selected ? color : AppColors.lightTextPrimary,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Complaint history.
class ClientComplaintHistoryScreen extends ConsumerWidget {
  const ClientComplaintHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final complaints = ref.watch(clientComplaintsProvider);
    final l10n = context.l10n;

    return DsPage(
      title: l10n.complaintHistoryTitle,
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(clientComplaintsProvider),
      bottom: DsGradientButton(
        label: l10n.newComplaintBtn,
        icon: Icons.add_rounded,
        onPressed: () => context.push(ClientRoutes.complaintRaise),
      ),
      body: dsAsyncBody(
        complaints,
        onRetry: () => ref.invalidate(clientComplaintsProvider),
        builder: (list) {
          final open = list
              .where((c) =>
                  c.status == ClientComplaintStatus.open || c.status == ClientComplaintStatus.inProgress)
              .length;
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(child: DsGlassStat(value: '${list.length}', label: 'Total', icon: Icons.forum_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: '$open', label: 'Open', icon: Icons.pending_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DsGlassStat(
                      value: '${list.length - open}',
                      label: 'Closed',
                      icon: Icons.task_alt_rounded,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 18),
            if (list.isEmpty)
              DsEmptyBlock(
                icon: Icons.sentiment_satisfied_alt_rounded,
                color: AppColors.success,
                title: 'No complaints',
                message: l10n.noComplaintsFound,
              )
            else
              for (final c in list) _ComplaintCard(complaint: c),
          ];
        },
      ),
    );
  }
}

class _ComplaintCard extends StatelessWidget {
  const _ComplaintCard({required this.complaint});
  final ClientComplaint complaint;

  @override
  Widget build(BuildContext context) {
    final c = complaint;
    final (color, icon) = switch (c.status) {
      ClientComplaintStatus.resolved => (AppColors.success, Icons.check_circle_rounded),
      ClientComplaintStatus.closed => (AppColors.lightTextSecondary, Icons.lock_rounded),
      ClientComplaintStatus.inProgress => (AppColors.primary, Icons.autorenew_rounded),
      ClientComplaintStatus.open => (AppColors.warning, Icons.schedule_rounded),
    };
    final ref = c.id.hashCode.abs().toString().padLeft(4, '0').substring(0, 4);

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: dsCardDecoration(),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(width: 5, color: color),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(14, 14, 16, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Text(
                            c.subject,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        const SizedBox(width: 8),
                        DsPill(clientComplaintStatusLabel(c.status), color: color, icon: icon),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${c.createdAt} · ${context.l10n.ref(ref)}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      c.description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.5,
                        color: const Color(0xFF374151),
                      ),
                    ),
                    if (c.imageCount > 0) ...[
                      const SizedBox(height: 10),
                      DsPill('${c.imageCount} attachments', color: AppColors.iconAccent, icon: Icons.attach_file_rounded),
                    ],
                    if (c.resolution != null && c.resolution!.isNotEmpty) ...[
                      const SizedBox(height: 12),
                      DsNote(
                        tone: DsNoteTone.success,
                        title: context.l10n.resolutionDetails,
                        text: c.resolution!,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
