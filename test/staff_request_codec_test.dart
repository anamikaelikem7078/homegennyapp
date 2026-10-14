import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/client/data/models/staff_request_dtos.dart';
import 'package:homegennyapp/features/client/domain/models/staff_request_models.dart';

void main() {
  // `data` of GET /client/staff-requests/:id, copied from the mobile brief
  // (a live call).
  final detail = <String, dynamic>{
    'id': '33d5114c-d135-4a5a-ab70-6d19d3753066',
    'request_no': 'SR-2026-0011',
    'status': 'SHORTLISTED',
    'source': 'CLIENT_APP',
    'series': 'UC',
    'series_db': 'UNSKILLED_CARE',
    'placement_type': 'PERMANENT',
    'shift_hours': 12,
    'start_date': '2026-10-20',
    'address': '1 Test Lane, New Delhi',
    'language': 'Hindi',
    'gender_pref': 'FEMALE',
    'budget_min': 15000,
    'budget_max': 20000,
    'headcount': 1,
    'requirements': {
      'mobility': 'ASSISTED',
      'conditions': ['DIABETES'],
      'night_care': true,
      'patient_age': 78,
      'medical_needs': <String>[],
    },
    'notes': 'Father needs help walking',
    'cancel_reason': null,
    'created_at': '2026-10-12T10:29:22.375Z',
    'rm': {'name': 'Ritu Sharma', 'phone': '98XXXXXXXX'},
    'candidates': [
      {
        'candidate_id': '9c32d12d-a6b8-4c6c-b9a0-78ed3b3cac18',
        'status': 'PROPOSED',
        'rm_note': 'Experienced with elderly, speaks Hindi',
        'client_note': null,
        'staff': {
          'id': 'f818b116-6b6f-4f6a-8b6c-35d0a4e44230',
          'first_name': 'Sunita',
          'series': 'UC',
          'series_db': 'UNSKILLED_CARE',
          'language_tier': 'T2',
          'gender': 'FEMALE',
          'experience_years': 4,
          'aadhaar_verified': false,
          'police_verified': false,
        },
      },
    ],
  };

  test('decodes the live detail response', () {
    final r = StaffRequestDtoCodec.decodeRequest(detail);
    expect(r.requestNo, 'SR-2026-0011');
    expect(r.canChoose, isTrue);
    expect(r.isOpen, isTrue);
    expect(r.rm?.name, 'Ritu Sharma');
    expect(r.requirements['patient_age'], 78);
    expect(r.candidates, hasLength(1));
    final c = r.candidates.single;
    expect(c.status, StaffRequestCandidateStatus.proposed);
    // The id to send as staff_id is the staff id, not the candidate id.
    expect(c.staff.id, 'f818b116-6b6f-4f6a-8b6c-35d0a4e44230');
    expect(c.staff.experienceYears, 4);
  });

  test('list item: counts, no candidates, nullable staff facts', () {
    final r = StaffRequestDtoCodec.decodeRequest({
      ...detail,
      'candidates': null,
      'rm': null,
      'shortlisted': 2,
      'selected': 0,
    });
    expect(r.shortlistedCount, 2);
    expect(r.candidates, isEmpty);
    expect(r.rm, isNull);

    final c = StaffRequestDtoCodec.decodeCandidate({
      'candidate_id': 'x',
      'status': 'PROPOSED',
      'staff': {'id': 's', 'first_name': 'Asha', 'series': 'CK', 'gender': null, 'experience_years': null},
    });
    expect(c.staff.gender, isNull);
    expect(c.staff.experienceYears, isNull);
  });

  test('status text matches the brief', () {
    expect(StaffRequestStatus.message('ASSIGNED'), 'Your RM is finding staff for you');
    expect(StaffRequestStatus.message('CLIENT_SELECTED'), 'You chose — your RM is setting up the trial');
    final done = StaffRequestDtoCodec.decodeRequest({...detail, 'status': 'FULFILLED'});
    expect(done.isOpen, isFalse);
    expect(done.canChoose, isFalse);
  });

  test('decodes a one-time cook booking', () {
    final r = StaffRequestDtoCodec.decodeRequest({
      ...detail,
      'series': 'CK',
      'visit_type': 'ONE_TIME',
      'duration_min': 120,
      'placement_type': 'TEMPORARY',
      'shift_hours': 2,
      'start_date': '2026-10-16',
      'start_time': '19:30',
      'lat': 28.5592,
      'lng': 77.2066,
      'menu': {
        'meal': 'DINNER',
        'meal_time': '19:30',
        'dishes': [
          {'name': 'Dal Makhani'},
          {'name': 'Butter Roti'},
        ],
        'dish_ids': ['a', 'b'],
        'special_instruction': 'Less oil',
      },
      'care_needs': null,
    });
    expect(r.isOneTime, isTrue);
    expect(r.durationMin, 120);
    expect(r.startTime, '19:30');
    expect(r.lat, 28.5592);
    expect(r.menu!.dishes, ['Dal Makhani', 'Butter Roti']);
    expect(r.menu!.weekly, isEmpty);
    expect(r.careNeeds, isNull);
  });

  test('decodes a regular cook weekly menu and UC care needs', () {
    final cook = StaffRequestDtoCodec.decodeRequest({
      ...detail,
      'menu': {
        'items': [
          {'dow': 'THU', 'meal': 'DINNER', 'dishes': ['Grandma Khichdi']},
        ],
      },
    });
    expect(cook.isOneTime, isFalse);
    expect(cook.menu!.weekly.single.dishes, ['Grandma Khichdi']);

    final care = StaffRequestDtoCodec.decodeRequest({
      ...detail,
      'care_needs': {
        'patient': {'name': 'Papa', 'age': 80},
        'activities': [
          {'type': 'WALK', 'times': ['17:00'], 'duration_min': 20},
        ],
        'dos': 'Help him walk',
      },
    });
    expect(care.careNeeds!.patient.name, 'Papa');
    expect(care.careNeeds!.activities.single.durationMin, 20);
    expect(care.careNeeds!.dos, 'Help him walk');
  });

  test('booking rules match the brief', () {
    expect([for (final d in BookingRules.durations) BookingRules.maxDishes(d)], [3, 4, 5, 7]);
    expect(BookingRules.mealForTime('10:59'), 'BREAKFAST');
    expect(BookingRules.mealForTime('11:00'), 'LUNCH');
    expect(BookingRules.mealForTime('16:00'), 'SNACKS');
    expect(BookingRules.mealForTime('19:00'), 'DINNER');
    expect(BookingRules.durationLabel(60), '1 hour');
    expect(BookingRules.durationLabel(90), '1.5 hours');
    expect(StaffRequestStatus.label('FULFILLED'), 'Booking confirmed');
  });

  test('weekly menu entry body', () {
    final e = WeeklyMenuEntry(dow: 'MON', meal: 'LUNCH', dishIds: ['x'], mealTime: '13:00');
    expect(e.toJson(typed: ['Kadhi']), {
      'dow': 'MON',
      'meal': 'LUNCH',
      'dish_ids': ['x'],
      'dishes': ['Kadhi'],
      'meal_time': '13:00',
    });
  });
}
