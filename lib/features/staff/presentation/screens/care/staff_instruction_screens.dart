import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/instruction_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../../../care/presentation/care_voice.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../navigation/staff_routes.dart';

String _when(DateTime t) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${t.day} ${m[t.month - 1]}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

String _schedule(Instruction i) {
  if (!i.isRecurring) return i.dueAt == null ? 'One time' : 'Do it by ${_when(i.dueAt!)}';
  final days = i.days.isEmpty || i.days.length == 7 ? 'Every day' : i.days.map(carePretty).join(', ');
  return i.times.isEmpty ? days : '$days at ${i.times.join(', ')}';
}

(String, Color) _staffLook(Instruction i) => switch (i.status) {
      InstructionStatus.sent => ('New', AppColors.error),
      InstructionStatus.acknowledged => (i.isRecurring ? 'Standing order' : 'To do', AppColors.primary),
      InstructionStatus.done => ('Done', AppColors.success),
      InstructionStatus.refused when i.rmDecision == 'UPHELD' => ('RM agreed', AppColors.lightTextSecondary),
      InstructionStatus.refused => ('Waiting for RM', AppColors.warning),
      _ => (carePretty(i.status), AppColors.lightTextSecondary),
    };

/// "Instructions from the family" on the staff home screen.
class StaffInstructionsHomeCard extends ConsumerWidget {
  const StaffInstructionsHomeCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(staffInstructionsProvider).valueOrNull;
    if (items == null || items.isEmpty) return const SizedBox.shrink();
    final fresh = items.where((i) => i.status == InstructionStatus.sent).length;
    final open = items.where((i) => i.isOpen).length;
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: DsListCard(
        icon: Icons.record_voice_over_rounded,
        iconColor: fresh > 0 ? AppColors.error : null,
        title: 'Instructions from the family',
        subtitle: fresh > 0 ? '$fresh new — tap to listen or read' : '$open open',
        margin: EdgeInsets.zero,
        onTap: () => context.push(StaffRoutes.instructions),
        trailing: fresh > 0 ? DsPill('$fresh', color: AppColors.error) : const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
      ),
    );
  }
}

class StaffInstructionsScreen extends ConsumerStatefulWidget {
  const StaffInstructionsScreen({super.key});

  @override
  ConsumerState<StaffInstructionsScreen> createState() => _StaffInstructionsScreenState();
}

class _StaffInstructionsScreenState extends ConsumerState<StaffInstructionsScreen> {
  String? _busy;

  Future<void> _run(Instruction i, Future<Result<void>> Function() call, String success) async {
    setState(() => _busy = i.id);
    final r = await call();
    if (!mounted) return;
    setState(() => _busy = null);
    r.fold(
      onSuccess: (_) {
        HapticFeedback.mediumImpact();
        context.showDsSnackBar(success, type: DsSnackBarType.success);
        invalidateAfterAck(ref);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  Future<void> _done(Instruction i) async {
    final note = await showModalBottomSheet<String>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const _DoneSheet(),
    );
    if (note == null || !mounted) return;
    await _run(i, () => ref.read(careApiProvider).completeInstruction(i.id, note: note), 'Done — the family has been told');
  }

  Future<void> _refuse(Instruction i) async {
    final reason = await careAskText(
      context,
      title: 'Not part of your work?',
      label: 'Why',
      hint: 'Your RM will look at it and decide',
      confirmLabel: 'Send to my RM',
    );
    if (reason == null || !mounted) return;
    await _run(i, () => ref.read(careApiProvider).refuseInstruction(i.id, reason), 'Sent to your RM');
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(staffInstructionsProvider);
    return DsPage(
      title: 'Instructions',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffInstructionsProvider),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(staffInstructionsProvider),
        builder: (items) {
          if (items.isEmpty) {
            return const [
              DsEmptyBlock(icon: Icons.record_voice_over_rounded, title: 'No instructions', message: 'When the family asks you to do something, it shows here.'),
            ];
          }
          final open = items.where((i) => i.isOpen).toList();
          final closed = items.where((i) => !i.isOpen).toList();
          return [
            for (final i in open) _card(i),
            if (closed.isNotEmpty) ...[
              const DsSection('Earlier'),
              for (final i in closed) _card(i),
            ],
          ];
        },
      ),
    );
  }

  Widget _card(Instruction i) {
    final (label, color) = _staffLook(i);
    final busy = _busy == i.id;
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(border: i.status == InstructionStatus.sent ? AppColors.error.withValues(alpha: 0.5) : null),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  i.clientName ?? 'Family',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary),
                ),
              ),
              DsPill(label, color: color),
            ],
          ),
          // For staff who find reading hard, Play is the biggest thing here.
          if (i.voiceFileId != null) ...[
            const SizedBox(height: 10),
            VoiceNotePlayer(fileId: i.voiceFileId, big: true),
          ],
          if (i.text != null) ...[
            const SizedBox(height: 10),
            Text(i.text!, style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary)),
          ],
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(i.isRecurring ? Icons.repeat_rounded : Icons.schedule_rounded, size: 15, color: AppColors.lightTextSecondary),
              const SizedBox(width: 6),
              Expanded(child: Text(_schedule(i), style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary))),
            ],
          ),
          if (i.staffNote != null)
            Padding(
              padding: const EdgeInsets.only(top: 6),
              child: Text('You: "${i.staffNote}"', style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary)),
            ),
          if (i.rmNote != null) ...[
            const SizedBox(height: 8),
            DsNote(
              tone: i.rmDecision == 'OVERTURNED' ? DsNoteTone.warning : DsNoteTone.info,
              title: i.rmDecision == 'OVERTURNED' ? 'RM: this is part of your job' : 'RM: you were right',
              text: i.rmNote!,
            ),
          ],
          if (i.isOpen) ...[
            const SizedBox(height: 12),
            if (i.canAcknowledge)
              DsGradientButton(
                label: 'Got it',
                icon: Icons.thumb_up_alt_rounded,
                isLoading: busy,
                onPressed: busy ? null : () => _run(i, () => ref.read(careApiProvider).acknowledgeInstruction(i.id), 'The family can see you read it'),
              ),
            if (i.canMarkDone) ...[
              const SizedBox(height: 8),
              i.canAcknowledge
                  ? DsOutlineButton(label: 'Done', icon: Icons.check_rounded, onPressed: busy ? null : () => _done(i))
                  : DsGradientButton(label: 'Done', icon: Icons.check_rounded, isLoading: busy, onPressed: busy ? null : () => _done(i)),
            ],
            if (i.canRefuse)
              TextButton(
                onPressed: busy ? null : () => _refuse(i),
                child: Text('Not my job', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.lightTextSecondary)),
              ),
          ],
        ],
      ),
    );
  }
}

/// "Done" with an optional note; returns '' for no note, null if cancelled.
class _DoneSheet extends StatefulWidget {
  const _DoneSheet();

  @override
  State<_DoneSheet> createState() => _DoneSheetState();
}

class _DoneSheetState extends State<_DoneSheet> {
  final _note = TextEditingController();

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          decoration: const BoxDecoration(color: Colors.white, borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 24),
          child: SafeArea(
            top: false,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text('Mark as done', style: GoogleFonts.plusJakartaSans(fontSize: 18, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary)),
                const SizedBox(height: 12),
                DsLabeledField(label: 'Note for the family', controller: _note, optional: true, textCapitalization: TextCapitalization.sentences),
                const SizedBox(height: 16),
                DsGradientButton(label: 'Done', icon: Icons.check_rounded, onPressed: () => Navigator.of(context).pop(_note.text.trim())),
              ],
            ),
          ),
        ),
      );
}
