import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/care/domain/care_models.dart';

void main() {
  group('CarePlan', () {
    // Plan body from the mobile brief.
    final json = <String, dynamic>{
      'id': 'plan-1',
      'version': 3,
      'patient': {'name': 'Ramesh Kumar', 'age': 78, 'conditions': ['Diabetes'], 'allergies': ['Penicillin'], 'mobility': 'ASSISTED'},
      'medications': [
        {'id': 'med-1', 'name': 'Metformin', 'dose': '500', 'unit': 'mg', 'route': 'ORAL', 'times': ['08:00', '20:00'], 'food_relation': 'AFTER', 'end_date': null},
      ],
      'vitals': [
        {'id': 'v-1', 'type': 'BP', 'times': ['08:00'], 'systolic_min': 90, 'systolic_max': 140, 'diastolic_min': 60, 'diastolic_max': 90},
        {'id': 'v-2', 'type': 'SUGAR_FASTING', 'times': ['07:30'], 'min': 70, 'max': 130},
      ],
      'activities': [
        {'id': 'a-1', 'type': 'WALK', 'title': 'Evening walk', 'times': ['17:30'], 'duration_min': 20},
      ],
      'diet_notes': 'Low salt',
      'changes': [
        {'type': 'MEDICATION_ADDED', 'text': 'Medicine added: Amlodipine 5 mg at 21:00'},
      ],
    };

    test('round-trips and keeps item ids so ticks stay attached', () {
      final body = CarePlan.fromJson(json).toJson();
      expect((body['medications'] as List).single['id'], 'med-1');
      expect((body['vitals'] as List).first['id'], 'v-1');
      expect((body['activities'] as List).single['id'], 'a-1');
      // Null end_date is left out rather than sent as null.
      expect((body['medications'] as List).single.containsKey('end_date'), isFalse);
      expect(body['diet_notes'], 'Low salt');
    });

    test('BP sends systolic/diastolic ranges, other checks min/max', () {
      final vitals = CarePlan.fromJson(json).toJson()['vitals'] as List;
      expect(vitals[0], containsPair('systolic_max', 140));
      expect((vitals[0] as Map).containsKey('min'), isFalse);
      expect(vitals[1], containsPair('max', 130));
    });

    test('a new item has no id', () {
      final plan = CarePlan()..activities.add(CareActivity(type: 'BATH', title: 'Bath', times: ['09:00']));
      expect((plan.toJson()['activities'] as List).single.containsKey('id'), isFalse);
    });

    test('changes are kept as written by the backend', () {
      expect(CarePlan.fromJson(json).changes.single.text, 'Medicine added: Amlodipine 5 mg at 21:00');
    });
  });

  group('CareTask', () {
    // Task from the mobile brief.
    final bp = CareTask.fromJson({
      'id': 't-1', 'date': '2026-10-12', 'type': 'VITAL', 'item_id': 'v-1', 'title': 'Check Blood pressure', 'time': '08:00',
      'status': 'DONE', 'value': {'systolic': 190, 'diastolic': 125, 'unit': 'mmHg'}, 'out_of_range': true,
      'skip_reason': null, 'notes': 'Felt dizzy', 'photo_file_ids': <String>[],
      'target': {'type': 'BP', 'unit': 'mmHg', 'systolic_min': 90, 'systolic_max': 140, 'diastolic_min': 60, 'diastolic_max': 90},
    });

    test('decodes the brief example', () {
      expect(bp.isVital, isTrue);
      expect(bp.isBp, isTrue);
      expect(bp.outOfRange, isTrue);
      expect(bp.reading, '190/125 mmHg');
    });

    test('colours a reading before it is sent', () {
      expect(bp.isOutside(sys: 120, dia: 80), isFalse);
      expect(bp.isOutside(sys: 150, dia: 80), isTrue);
      expect(bp.isOutside(sys: 120, dia: 50), isTrue);
      final sugar = CareTask.fromJson({
        'id': 't-2', 'type': 'VITAL', 'title': 'Check Sugar', 'time': '07:30', 'status': 'PENDING',
        'target': {'type': 'SUGAR_FASTING', 'unit': 'mg/dL', 'min': 70, 'max': 130},
      });
      expect(sugar.isOutside(v: 100), isFalse);
      expect(sugar.isOutside(v: 140), isTrue);
      expect(sugar.isOutside(v: null), isFalse);
    });

    test('a missed dose marked done is late', () {
      final t = CareTask.fromJson({'id': 'x', 'type': 'MEDICATION', 'status': 'DONE', 'value': {'late': true}});
      expect(t.isLate, isTrue);
      expect(t.reading, isNull);
    });
  });

  test('staff today: unread plan shows its changes; no plan = nothing to read', () {
    final today = StaffCareToday.fromJson({
      'date': '2026-10-13',
      'placements': [
        {
          'placement_id': 'p-1',
          'client': {'name': 'Kumar family'},
          'plan': {'id': 'plan-1', 'version': 2, 'acknowledged': false, 'changes': [{'type': 'X', 'text': 'Check added: Pulse at 09:00'}]},
          'summary': {'total': 4, 'done': 1, 'pending': 2, 'missed': 1},
          'tasks': <Map<String, dynamic>>[],
          'report': null,
        },
        {'placement_id': 'p-2', 'client': {'name': null}, 'plan': null, 'summary': <String, dynamic>{}, 'tasks': <Map<String, dynamic>>[]},
      ],
    });
    final p = today.placements.first;
    expect(p.planAcknowledged, isFalse);
    expect(p.planId, 'plan-1');
    expect(p.planChanges.single.text, 'Check added: Pulse at 09:00');
    expect(p.summary.missed, 1);
    final noPlan = today.placements.last;
    expect(noPlan.hasPlan, isFalse);
    expect(noPlan.planAcknowledged, isTrue);
    expect(noPlan.clientName, 'Family');
  });
}
