import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../../care/domain/instruction_models.dart';
import '../../../../care/presentation/care_providers.dart';
import '../../../../care/presentation/care_voice.dart';
import '../../../../care/presentation/care_widgets.dart';
import '../../navigation/client_routes.dart';

void _backOrHome(BuildContext context) {
  if (context.canPop()) {
    context.pop();
  } else {
    context.go(ClientRoutes.dashboard);
  }
}

String _when(DateTime t) {
  const m = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
  return '${t.day} ${m[t.month - 1]}, ${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
}

const _allDays = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

/// "Every day at 08:00" / "Mon, Wed at 08:00".
String instructionSchedule(Instruction i) {
  if (!i.isRecurring) return i.dueAt == null ? 'One time' : 'By ${_when(i.dueAt!)}';
  final days = i.days.isEmpty || i.days.length == 7 ? 'Every day' : i.days.map(carePretty).join(', ');
  return i.times.isEmpty ? days : '$days at ${i.times.join(', ')}';
}

/// What the family sees for each status.
(String, Color) _clientLook(Instruction i) => switch (i.status) {
      InstructionStatus.acknowledged when i.rmDecision == 'OVERTURNED' => ('RM: part of the job', AppColors.primary),
      InstructionStatus.acknowledged => ('Read ✓', AppColors.primary),
      InstructionStatus.done => ('Done ✓', AppColors.success),
      InstructionStatus.refused when i.rmDecision == 'UPHELD' => ('RM: outside the job', AppColors.lightTextSecondary),
      InstructionStatus.refused => ('Not my job — RM deciding', AppColors.warning),
      InstructionStatus.cancelled => ('Cancelled', AppColors.lightTextSecondary),
      _ => ('Sent', AppColors.lightTextSecondary),
    };

// ---------------------------------------------------------------------------
// List
// ---------------------------------------------------------------------------

class ClientInstructionsScreen extends ConsumerWidget {
  const ClientInstructionsScreen({super.key, required this.placementId, this.staffName});
  final String placementId;
  final String? staffName;

  Future<void> _cancel(BuildContext context, WidgetRef ref, Instruction i) async {
    final ok = await DsConfirmationDialog.show(
      context: context,
      title: 'Cancel this instruction?',
      message: '${staffName?.split(' ').first ?? 'Your staff'} will be told it is no longer needed.',
      confirmLabel: 'Cancel instruction',
      cancelLabel: 'Keep it',
      isDestructive: true,
    );
    if (ok != true || !context.mounted) return;
    final r = await ref.read(careApiProvider).cancelInstruction(i.id);
    if (!context.mounted) return;
    r.fold(
      onSuccess: (_) => ref.invalidate(placementInstructionsProvider(placementId)),
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final async = ref.watch(placementInstructionsProvider(placementId));
    return DsPage(
      title: 'Instructions',
      subtitle: staffName,
      onBack: () => _backOrHome(context),
      onRefresh: () async => ref.invalidate(placementInstructionsProvider(placementId)),
      bottom: DsGradientButton(
        label: 'New instruction',
        icon: Icons.add_comment_rounded,
        onPressed: () => context.push(ClientRoutes.instructionNew(placementId), extra: staffName),
      ),
      body: dsAsyncBody(
        async,
        onRetry: () => ref.invalidate(placementInstructionsProvider(placementId)),
        builder: (items) {
          if (items.isEmpty) {
            return const [
              DsEmptyBlock(
                icon: Icons.record_voice_over_rounded,
                title: 'No instructions yet',
                message: 'Tell your staff something by text or a voice note — once, or as a standing daily order.',
              ),
            ];
          }
          return [for (final i in items) _ClientInstructionCard(instruction: i, onCancel: () => _cancel(context, ref, i))];
        },
      ),
    );
  }
}

class _ClientInstructionCard extends StatelessWidget {
  const _ClientInstructionCard({required this.instruction, required this.onCancel});
  final Instruction instruction;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) {
    final i = instruction;
    final (label, color) = _clientLook(i);
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              DsPill(i.isRecurring ? 'Standing order' : 'One time', icon: i.isRecurring ? Icons.repeat_rounded : Icons.looks_one_rounded),
              const Spacer(),
              DsPill(label, color: color),
            ],
          ),
          if (i.text != null) ...[
            const SizedBox(height: 10),
            Text(i.text!, style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w600, color: AppColors.lightTextPrimary)),
          ],
          if (i.voiceFileId != null) ...[
            const SizedBox(height: 10),
            VoiceNotePlayer(fileId: i.voiceFileId),
          ],
          const SizedBox(height: 8),
          Text(
            [instructionSchedule(i), if (i.createdAt != null) 'sent ${_when(i.createdAt!)}'].join(' · '),
            style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
          ),
          if (i.acknowledgedAt != null)
            _line(Icons.done_all_rounded, 'Read ${_when(i.acknowledgedAt!)}', AppColors.primary),
          if (i.doneAt != null) _line(Icons.check_circle_rounded, 'Done ${_when(i.doneAt!)}', AppColors.success),
          if (i.staffNote != null)
            _line(Icons.chat_bubble_rounded, i.status == InstructionStatus.refused || i.refusedAt != null ? 'Staff: "${i.staffNote}"' : 'Note: "${i.staffNote}"',
                AppColors.lightTextPrimary),
          if (i.rmNote != null) ...[
            const SizedBox(height: 8),
            DsNote(
              title: i.rmDecision == 'OVERTURNED' ? 'RM: this is part of the job' : 'RM: this is outside the job',
              text: i.rmNote!,
            ),
          ],
          if (i.canCancel)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: onCancel,
                child: Text('Cancel', style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700, color: AppColors.error)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _line(IconData icon, String text, Color color) => Padding(
        padding: const EdgeInsets.only(top: 6),
        child: Row(
          children: [
            Icon(icon, size: 15, color: color),
            const SizedBox(width: 6),
            Expanded(child: Text(text, style: GoogleFonts.plusJakartaSans(fontSize: 12.5, fontWeight: FontWeight.w600, color: color))),
          ],
        ),
      );
}

// ---------------------------------------------------------------------------
// New instruction
// ---------------------------------------------------------------------------

class ClientNewInstructionScreen extends ConsumerStatefulWidget {
  const ClientNewInstructionScreen({super.key, required this.placementId, this.staffName});
  final String placementId;
  final String? staffName;

  @override
  ConsumerState<ClientNewInstructionScreen> createState() => _ClientNewInstructionScreenState();
}

class _ClientNewInstructionScreenState extends ConsumerState<ClientNewInstructionScreen> {
  final _text = TextEditingController();
  String? _voicePath;
  bool _recurring = false;
  DateTime? _dueAt;
  final List<String> _times = [];
  final Set<String> _days = {..._allDays};
  bool _sending = false;

  @override
  void dispose() {
    _text.dispose();
    super.dispose();
  }

  Future<void> _pickDue() async {
    final now = DateTime.now();
    final d = await showDatePicker(context: context, initialDate: now, firstDate: now, lastDate: now.add(const Duration(days: 60)));
    if (d == null || !mounted) return;
    final t = await showTimePicker(context: context, initialTime: TimeOfDay.fromDateTime(now.add(const Duration(hours: 1))));
    if (t == null) return;
    setState(() => _dueAt = DateTime(d.year, d.month, d.day, t.hour, t.minute));
  }

  Future<void> _addTime() async {
    final t = await showTimePicker(
      context: context,
      initialTime: const TimeOfDay(hour: 8, minute: 0),
      builder: (c, child) => MediaQuery(data: MediaQuery.of(c).copyWith(alwaysUse24HourFormat: true), child: child!),
    );
    if (t == null) return;
    final s = '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';
    if (!_times.contains(s)) setState(() => _times..add(s)..sort());
  }

  Future<void> _send() async {
    final text = _text.text.trim();
    if (text.isEmpty && _voicePath == null) {
      context.showDsSnackBar('Write the instruction or record a voice note.', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _sending = true);
    final api = ref.read(careApiProvider);
    String? voiceId;
    if (_voicePath != null) {
      final up = await api.uploadFile(placementId: widget.placementId, kind: 'VOICE', path: _voicePath!, filename: 'instruction.m4a');
      if (!mounted) return;
      final failure = up.failureOrNull;
      if (failure != null) {
        setState(() => _sending = false);
        context.showDsSnackBar(failure.message, type: DsSnackBarType.error);
        return;
      }
      voiceId = up.dataOrNull!.id;
    }
    final result = await api.createInstruction(widget.placementId, {
      if (text.isNotEmpty) 'text': text,
      'voice_file_id': ?voiceId,
      'kind': _recurring ? InstructionKind.recurring : InstructionKind.oneTime,
      if (!_recurring && _dueAt != null) 'due_at': _dueAt!.toUtc().toIso8601String(),
      if (_recurring) 'recurrence': {'times': _times, 'days': [for (final d in _allDays) if (_days.contains(d)) d]},
    });
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      onSuccess: (_) {
        ref.invalidate(placementInstructionsProvider(widget.placementId));
        context.showDsSnackBar('Sent — you will see when it is read', type: DsSnackBarType.success);
        _backOrHome(context);
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) => DsPage(
        title: 'New instruction',
        subtitle: widget.staffName == null ? null : 'For ${widget.staffName}',
        onBack: () => _backOrHome(context),
        bottom: DsGradientButton(label: 'Send', icon: Icons.send_rounded, isLoading: _sending, onPressed: _sending ? null : _send),
        body: [
          DsLabeledField(
            label: 'Instruction',
            controller: _text,
            icon: Icons.edit_note_rounded,
            hint: 'e.g. Check his feet every morning',
            maxLines: 5,
            minLines: 3,
            optional: true,
            textCapitalization: TextCapitalization.sentences,
          ),
          const DsSection('Or say it'),
          VoiceNoteRecorder(onRecorded: (p) => setState(() => _voicePath = p)),
          const DsSection('How often'),
          Wrap(
            spacing: 8,
            children: [
              DsChoiceChip(label: 'One time', selected: !_recurring, onTap: () => setState(() => _recurring = false)),
              DsChoiceChip(label: 'Standing order', selected: _recurring, onTap: () => setState(() => _recurring = true)),
            ],
          ),
          const SizedBox(height: 12),
          if (!_recurring)
            DsListCard(
              icon: Icons.schedule_rounded,
              title: _dueAt == null ? 'No deadline' : 'By ${_when(_dueAt!)}',
              subtitle: 'Optional — tap to set when it should be done',
              onTap: _pickDue,
              trailing: _dueAt == null
                  ? null
                  : IconButton(tooltip: 'Clear', icon: const Icon(Icons.close_rounded), onPressed: () => setState(() => _dueAt = null)),
            )
          else ...[
            const DsNote(text: 'A standing order is read once and stays in place — it is never marked "done".'),
            const SizedBox(height: 12),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final d in _allDays)
                  DsChoiceChip(
                    label: carePretty(d),
                    selected: _days.contains(d),
                    onTap: () => setState(() => _days.contains(d) && _days.length > 1 ? _days.remove(d) : _days.add(d)),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                for (final t in _times) InputChip(label: Text(t), onDeleted: () => setState(() => _times.remove(t))),
                ActionChip(avatar: const Icon(Icons.add_rounded, size: 18), label: const Text('Add time (optional)'), onPressed: _addTime),
              ],
            ),
          ],
        ],
      );
}
