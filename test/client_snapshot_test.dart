import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/client/domain/models/client_snapshot.dart';
import 'package:homegennyapp/features/client/presentation/screens/home/today_at_home_card.dart';

// Sample is the "Today at home" brief's (21 Oct 2026) response.
final _sample = <String, dynamic>{
  'date': '2026-10-21',
  'generated_at': '2026-10-21T04:12:09.512Z',
  'staff': [
    {
      'placement_id': '43c0',
      'staff': {
        'id': 'c339',
        'first_name': 'Rekha',
        'series': 'UC',
        'series_label': 'Caretaker',
        'photo_url': '/client/staff/c339/photo',
        'profile_url': '/client/staff/c339/profile',
      },
      'deployment': {
        'type': 'PERMANENT',
        'visit': 'REGULAR',
        'status': 'TRIAL',
        'since': '2026-10-15',
        'trial_ends': '2026-10-22',
        'shift_start': '08:00',
        'shift_hours': 12,
      },
      'today': {
        'attendance': 'LATE',
        'check_in': '08:30',
        'check_out': null,
        'late_by_min': 30,
        'work': {'done': 6, 'total': 9, 'missed': 0, 'next': 'Evening medicine at 18:00'},
        'meals': null,
        'report_filled': false,
        'unread_instructions': 0,
      },
      'status_today': 'AMBER',
      'message': 'Rekha checked in at 08:30 (30 min late) · 6 of 9 tasks done',
      'last_7_days': [
        {'date': '2026-10-15', 'attendance': 'PRESENT'},
        {'date': '2026-10-16', 'attendance': 'PRESENT'},
        {'date': '2026-10-17', 'attendance': 'LEAVE'},
        {'date': '2026-10-18', 'attendance': 'PRESENT'},
        {'date': '2026-10-19', 'attendance': 'NONE'},
        {'date': '2026-10-20', 'attendance': 'PRESENT'},
        {'date': '2026-10-21', 'attendance': 'PRESENT'},
      ],
    },
  ],
  'requests': [
    {
      'id': 'r1',
      'request_no': 'SR-2026-0041',
      'series': 'CK',
      'status': 'SHORTLISTED',
      'visit_type': 'REGULAR',
      'start_date': '2026-10-25',
      'start_time': '08:00',
      'created_at': '2026-10-20T10:00:00Z',
    },
  ],
  'replacements': [
    {'id': 'x1', 'placement_id': '43c0', 'status': 'UNDER_RM_REVIEW', 'created_at': '2026-10-20T10:00:00Z'},
  ],
};

void main() {
  group('GET /client/snapshot', () {
    final s = ClientSnapshot.fromJson(_sample);
    final rekha = s.staff.single;

    test('staff, deployment and today', () {
      expect(s.date, '2026-10-21');
      expect(rekha.placementId, '43c0');
      expect(rekha.firstName, 'Rekha');
      expect(rekha.isCook, isFalse);
      expect(rekha.deployment.isTrial, isTrue);
      expect(rekha.deployment.trialEnds, DateTime(2026, 10, 22));
      expect(rekha.today.work!.done, 6);
      expect(rekha.today.work!.next, 'Evening medicine at 18:00');
      expect(rekha.today.meals, isNull);
      expect(rekha.statusToday, SnapshotStatus.amber);
    });

    test('7-day strip is oldest first and ends with the date', () {
      expect(rekha.last7Days, hasLength(7));
      expect(rekha.last7Days.first.date, DateTime(2026, 10, 15));
      expect(rekha.last7Days.last.date, DateTime(2026, 10, 21));
      expect(rekha.last7Days[2].attendance, 'LEAVE');
    });

    test('requests and replacements', () {
      expect(s.requests.single.needsChoice, isTrue);
      expect(s.replacementsFor('43c0'), hasLength(1));
      expect(s.replacementsFor('other'), isEmpty);
    });

    test('a cook with meals and no staff list', () {
      final cook = SnapshotStaff.fromJson({
        'placement_id': 'p2',
        'staff': {'id': 's2', 'first_name': 'Sunita', 'series': 'CK'},
        'deployment': {'status': 'CONFIRMED'},
        'today': {
          'attendance': 'NOT_STARTED',
          'work': null,
          'meals': {'planned': 3, 'logged': 1, 'due': 2, 'not_logged': ['BREAKFAST']},
        },
        'status_today': 'NOT_STARTED',
        'message': 'x',
        'last_7_days': [],
      });
      expect(cook.isCook, isTrue);
      expect(cook.today.meals!.notLogged, ['BREAKFAST']);
      expect(cook.statusToday, SnapshotStatus.notStarted);
      expect(ClientSnapshot.fromJson({'date': '2026-10-21', 'staff': []}).staff, isEmpty);
    });
  });

  group('attendance labels', () {
    const shift = SnapshotDeployment(type: '', visit: '', status: 'CONFIRMED', shiftStart: '08:00');
    String label(Map<String, dynamic> today) => attendanceLabel(SnapshotToday.fromJson(today), shift).$1;

    test('each value as the brief shows it', () {
      expect(label({'attendance': 'ON_TIME', 'check_in': '08:05'}), 'In at 08:05');
      expect(label({'attendance': 'LATE', 'check_in': '08:30', 'late_by_min': 30}), 'In at 08:30 · 30 min late');
      expect(label({'attendance': 'NOT_STARTED'}), 'Due at 08:00');
      expect(label({'attendance': 'NOT_IN_YET'}), 'Not in yet · due 08:00');
      expect(label({'attendance': 'NO_SHOW'}), 'Not checked in today');
      expect(label({'attendance': 'ABSENT'}), 'Absent today');
      expect(label({'attendance': 'ON_LEAVE'}), 'On leave today');
    });
  });
}
