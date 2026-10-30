import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/client/domain/models/attendance_approval_models.dart';
import 'package:homegennyapp/features/staff/data/models/staff_dtos.dart';

// Shapes from the "Attendance approval & muster roll — 29 Oct" brief.
void main() {
  test('approvals list parses counts and items', () {
    final list = ApprovalList.fromJson({
      'from': '2026-10-01',
      'to': '2026-10-30',
      'pending_count': 2,
      'disputed_count': 1,
      'items': [
        {
          'id': 'd1',
          'date': '2026-10-28',
          'staff_id': 's1',
          'staff_name': 'Rekha',
          'staff_code': 'HG-S-0012',
          'status': 'PRESENT',
          'hours_worked': 11.5,
          'check_in': '2026-10-28T02:30:00.000Z',
          'check_in_ist': '08:00',
          'source': 'STAFF_APP',
          'client_status': 'PENDING',
          'deemed_at': '2026-10-30T02:30:00.000Z',
        },
      ],
    });
    expect(list.pendingCount, 2);
    expect(list.disputedCount, 1);
    final d = list.items.single;
    expect(d.isPending, isTrue);
    expect(d.hoursWorked, 11.5);
    expect(d.checkInIst, '08:00');
    expect(d.checkOut, isNull);
    expect(d.deemedAt, isNotNull);
  });

  test('muster roll parses rows, totals and signature state', () {
    final roll = MusterRoll.fromJson({
      'month_label': 'October 2026',
      'days_in_month': 31,
      'rows': [
        {
          'code': 'HG-S-0012',
          'name': 'Rekha',
          'father_or_husband_name': 'Ramesh',
          'sex': 'F',
          'days': ['P', '½', 'A', 'WO', ''],
          'days_present': 1.5,
          'weekly_off': 1,
          'total': 2.5,
        },
      ],
      'daily_mandays': [1, 0.5],
      'totals': {'total_present': 1.5, 'additional_hours': 0, 'weekly_off': 1, 'total_mandays': 2.5},
      'disputed_days': 1,
      'signed': {
        'id': 'm1',
        'version': 1,
        'sign_method': 'CLIENT_APP',
        'signed_name': 'Anita',
        'locked': false,
      },
      'changed_since_signed': [
        {'date': '2026-10-05'},
      ],
      'versions': [],
    }, month: 10, year: 2026);
    expect(roll.rows.single.days[1], '½');
    expect(roll.rows.single.fatherOrHusbandName, 'Ramesh');
    expect(roll.totalMandays, 2.5);
    expect(roll.disputedDays, 1);
    expect(roll.signed!.signedName, 'Anita');
    expect(roll.needsSignature, isTrue); // changed since signed
  });

  test('a locked roll never asks for a signature', () {
    final roll = MusterRoll.fromJson({
      'rows': [],
      'signed': {'id': 'm1', 'locked': true},
      'changed_since_signed': ['x'],
    }, month: 2, year: 2026);
    expect(roll.daysInMonth, 28);
    expect(roll.needsSignature, isFalse);
  });

  test('staff history and profile carry the new fields', () {
    final r = StaffDtoCodec.decodeAttendance({
      'date': '2026-10-28',
      'status': 'present',
      'client_status': 'DISPUTED',
      'client_note': 'Left at 2 pm',
    });
    expect(r.clientStatus, 'DISPUTED');
    expect(r.clientNote, 'Left at 2 pm');
    expect(r.resolutionNote, isNull);

    final p = StaffDtoCodec.decodeProfile({'fatherOrHusbandName': 'Ramesh'});
    expect(p.fatherOrHusbandName, 'Ramesh');
  });
}
