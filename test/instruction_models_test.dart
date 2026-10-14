import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/care/domain/instruction_models.dart';
import 'package:homegennyapp/features/care/presentation/care_voice.dart';

Instruction _i(Map<String, dynamic> extra) => Instruction.fromJson({
      'id': 'i-1',
      'placement_id': 'p-1',
      'kind': 'ONE_TIME',
      'status': 'SENT',
      ...extra,
    });

void main() {
  group('Instruction actions follow the backend rules', () {
    test('a new one-time instruction can be acknowledged, done, refused, cancelled', () {
      final i = _i({'text': 'Give him a bath', 'voice_file_id': 'f-1', 'client_name': 'Kumar family'});
      expect(i.canAcknowledge, isTrue);
      expect(i.canMarkDone, isTrue);
      expect(i.canRefuse, isTrue);
      expect(i.canCancel, isTrue);
      expect(i.clientName, 'Kumar family');
    });

    test('a standing order is never "done"', () {
      final i = _i({
        'kind': 'RECURRING',
        'status': 'ACKNOWLEDGED',
        'recurrence': {'times': ['08:00'], 'days': ['MON', 'TUE']},
      });
      expect(i.isRecurring, isTrue);
      expect(i.canMarkDone, isFalse);
      expect(i.canAcknowledge, isFalse);
      expect(i.times, ['08:00']);
      expect(i.days, ['MON', 'TUE']);
    });

    test('after the RM overturns a refusal it cannot be refused again', () {
      final i = _i({'status': 'ACKNOWLEDGED', 'rm_decision': 'OVERTURNED', 'rm_note': 'Bathing is part of care.'});
      expect(i.canRefuse, isFalse);
      expect(i.canMarkDone, isTrue);
      expect(i.rmNote, 'Bathing is part of care.');
    });

    test('refused and waiting for the RM; closed statuses allow nothing', () {
      final refused = _i({'status': 'REFUSED', 'staff_note': 'I am a cook'});
      expect(refused.awaitingRm, isTrue);
      expect(refused.isOpen, isFalse);
      expect(refused.canCancel, isFalse);
      for (final s in ['DONE', 'CANCELLED']) {
        final i = _i({'status': s});
        expect(i.canAcknowledge || i.canMarkDone || i.canRefuse || i.canCancel, isFalse, reason: s);
      }
    });
  });

  test('voice note format is detected from its bytes', () {
    expect(careAudioExtension([0, 0, 0, 0x20, ...'ftypM4A '.codeUnits]), 'm4a');
    expect(careAudioExtension([...'ID3'.codeUnits, 4, 0]), 'mp3');
    expect(careAudioExtension([0xFF, 0xFB, 0x90]), 'mp3');
    expect(careAudioExtension([0xFF, 0xF1, 0x50]), 'aac');
    expect(careAudioExtension([...'OggS'.codeUnits, 0]), 'ogg');
    expect(careAudioExtension([0x1A, 0x45, 0xDF, 0xA3, 1]), 'webm');
    expect(careAudioExtension([...'RIFF'.codeUnits, 0, 0]), 'wav');
  });
}
