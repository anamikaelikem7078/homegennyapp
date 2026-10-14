/// Client instructions to their staff (text and/or a voice note).
///
/// SENT ─"Got it"→ ACKNOWLEDGED ─"Done"→ DONE
///   └─"Not my job" (reason)→ REFUSED → RM decides: UPHELD (stays refused)
///                                     or OVERTURNED (back to ACKNOWLEDGED).
/// The client can cancel while SENT / ACKNOWLEDGED. A RECURRING one (a
/// standing order) is acknowledged once and never "done".
library;

String? _str(Object? v) => v == null || '$v'.trim().isEmpty ? null : '$v';
DateTime? _date(Object? v) => DateTime.tryParse('${v ?? ''}')?.toLocal();
List<String> _strings(Object? v) => [for (final e in (v is List ? v : const [])) '$e'];

abstract final class InstructionStatus {
  static const sent = 'SENT';
  static const acknowledged = 'ACKNOWLEDGED';
  static const done = 'DONE';
  static const refused = 'REFUSED';
  static const cancelled = 'CANCELLED';
}

abstract final class InstructionKind {
  static const oneTime = 'ONE_TIME';
  static const recurring = 'RECURRING';
}

class Instruction {
  const Instruction({
    required this.id,
    required this.placementId,
    required this.kind,
    required this.status,
    this.text,
    this.voiceFileId,
    this.dueAt,
    this.times = const [],
    this.days = const [],
    this.staffNote,
    this.acknowledgedAt,
    this.doneAt,
    this.refusedAt,
    this.rmDecision,
    this.rmNote,
    this.createdAt,
    this.clientName,
  });

  factory Instruction.fromJson(Map<String, dynamic> j) {
    final r = j['recurrence'] is Map<String, dynamic> ? j['recurrence'] as Map<String, dynamic> : const <String, dynamic>{};
    return Instruction(
      id: '${j['id'] ?? ''}',
      placementId: '${j['placement_id'] ?? ''}',
      kind: _str(j['kind']) ?? InstructionKind.oneTime,
      status: _str(j['status']) ?? InstructionStatus.sent,
      text: _str(j['text']),
      voiceFileId: _str(j['voice_file_id']),
      dueAt: _date(j['due_at']),
      times: _strings(r['times']),
      days: _strings(r['days']),
      staffNote: _str(j['staff_note']),
      acknowledgedAt: _date(j['acknowledged_at']),
      doneAt: _date(j['done_at']),
      refusedAt: _date(j['refused_at']),
      rmDecision: _str(j['rm_decision']),
      rmNote: _str(j['rm_note']),
      createdAt: _date(j['created_at']),
      clientName: _str(j['client_name']),
    );
  }

  final String id;
  final String placementId;
  final String kind;
  final String status;
  final String? text;

  /// Play with the Bearer token through `GET /care-files/:id`.
  final String? voiceFileId;
  final DateTime? dueAt;

  /// Standing order schedule (RECURRING only).
  final List<String> times;
  final List<String> days;

  /// The staff member's "Done" note or refusal reason.
  final String? staffNote;
  final DateTime? acknowledgedAt;
  final DateTime? doneAt;
  final DateTime? refusedAt;

  /// UPHELD / OVERTURNED, once the RM has decided a refusal.
  final String? rmDecision;

  /// Shown to both sides.
  final String? rmNote;
  final DateTime? createdAt;

  /// Staff list only.
  final String? clientName;

  bool get isRecurring => kind == InstructionKind.recurring;
  bool get isOpen => status == InstructionStatus.sent || status == InstructionStatus.acknowledged;
  bool get canCancel => isOpen;
  bool get canAcknowledge => status == InstructionStatus.sent;
  bool get canMarkDone => isOpen && !isRecurring;

  /// "Not my job" — not once the RM has said it is part of the job.
  bool get canRefuse => isOpen && rmDecision != 'OVERTURNED';
  bool get awaitingRm => status == InstructionStatus.refused && rmDecision == null;
}
