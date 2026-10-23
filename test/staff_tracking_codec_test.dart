import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/features/client/data/models/client_dtos.dart';
import 'package:homegennyapp/features/staff/data/models/staff_dtos.dart';
import 'package:homegennyapp/features/staff/domain/models/staff_models.dart';

// Samples are the backend brief's (15 Oct 2026) real test-run responses.
void main() {
  group('staff app', () {
    test('GET /staff/placements', () {
      final today = StaffDtoCodec.decodePlacementsToday({
        'date': '2026-10-15',
        'checked_in_at': null,
        'location_interval_sec': 300,
        'placements': [
          {
            'placement_id': '777de0a6',
            'client_name': 'Sharma Household',
            'address': '1 Test Lane, New Delhi',
            'home': {'lat': 28.6, 'lng': 77.25},
            'placement_type': 'PERMANENT',
            'visit_type': 'REGULAR',
            'today': 'NOT_CHECKED_IN',
          },
          {
            'placement_id': 'edc4fd87',
            'client_name': 'Verma Household',
            'address': '1 Test Lane, New Delhi',
            'home': null,
            'placement_type': 'TEMPORARY',
            'visit_type': 'REGULAR',
            'today': 'CHECKED_IN',
          },
        ],
      });
      expect(today.isCheckedIn, isFalse);
      expect(today.locationIntervalSec, 300);
      expect(today.placements, hasLength(2));
      expect(today.placements.first.hasHome, isTrue);
      expect(today.placements.last.hasHome, isFalse);
      expect(today.placements.last.today, 'CHECKED_IN');
    });

    test('check-in and check-out results', () {
      final checkIn = StaffDtoCodec.decodeCheckInResult({
        'success': true,
        'attendanceId': '29a6f5e3',
        'status': 'CHECKED_IN',
        'already_checked_in': false,
        'placement_id': 'edc4fd87',
        'client_name': 'Verma Household',
        'latitude': 28.5594,
        'longitude': 77.2066,
        'distance_m': 22,
        'at_home': true,
        'timestamp': '2026-10-15T07:37:48.476Z',
        'location_interval_sec': 300,
      });
      expect(checkIn.clientName, 'Verma Household');
      expect(checkIn.distanceM, 22);
      expect(checkIn.atHome, isTrue);
      expect(checkIn.locationIntervalSec, 300);

      final checkOut = StaffDtoCodec.decodeCheckInResult({
        'success': true,
        'status': 'CHECKED_OUT',
        'distance_m': 0,
        'worked': '0 h 30 m',
        'timestamp': '2026-10-15T07:37:48.736Z',
      });
      expect(checkOut.worked, '0 h 30 m');
      expect(checkOut.atHome, isNull);
    });

    test('location points round-trip through the queue', () {
      final point = LocationPoint(
        latitude: 28.5592,
        longitude: 77.2066,
        accuracy: 12.4,
        recordedAt: DateTime.utc(2026, 10, 15, 7, 17, 48),
      );
      final json = point.toJson();
      expect(json['recorded_at'], '2026-10-15T07:17:48.000Z');
      expect(json['accuracy'], 12);
      final back = LocationPoint.fromJson(json)!;
      expect(back.latitude, 28.5592);
      expect(back.recordedAt, point.recordedAt);
      expect(LocationPoint.fromJson({'latitude': 1}), isNull);

      final upload = StaffDtoCodec.decodeLocationUpload({'accepted': 2, 'dropped': 0, 'next_in_sec': 300});
      expect(upload.accepted, 2);
      expect(upload.nextInSec, 300);
    });
  });

  group('client app', () {
    test('GET /client/attendance/today with staff[]', () {
      final today = ClientDtoCodec.decodeTodayAttendance({
        'staffCode': 'ZT-Kam-67361',
        'staffName': 'Kamla',
        'todayStatus': 'NOT_CHECKED_IN',
        'gpsVerified': false,
        'date': '2026-10-15',
        'staff': [
          {
            'staff_id': 'dc48ae7d',
            'name': 'Kamla Devi',
            'series_label': 'Cook',
            'status': 'NOT_CHECKED_IN',
            'last_location': null,
          },
          {
            'staff_id': '334eeac7',
            'name': 'Asha Kumari',
            'series_label': 'Caretaker (UC)',
            'status': 'PRESENT',
            'check_in': '2026-10-15T07:07:48.555Z',
            'gps_verified': true,
            'check_in_distance_m': 22,
            'last_location': {
              'at': '2026-10-15T07:39:18.591Z',
              'lat': 28.57,
              'lng': 77.2066,
              'accuracy_m': null,
              'distance_m': 1201,
              'at_home': false,
              'label': '1.2 km from home',
              'stale': false,
            },
          },
        ],
      });
      expect(today.staff, hasLength(2));
      expect(today.staff.first.lastLocation, isNull);
      final asha = today.staff.last;
      expect(asha.lastLocation!.label, '1.2 km from home');
      expect(asha.lastLocation!.atHome, isFalse);

      // The cache stores the same shape, so it reads back identically.
      final cached = ClientDtoCodec.decodeTodayAttendance(ClientDtoCodec.encodeTodayAttendance(today));
      expect(cached.staff.last.lastLocation!.distanceM, 1201);
    });

    test('GET /client/staff/:id/location, on and off shift', () {
      final on = ClientDtoCodec.decodeStaffLocation({
        'staff_id': '334eeac7',
        'status': 'PRESENT',
        'check_in': {'at': '2026-10-15T07:07:48.555Z', 'lat': 28.5594, 'lng': 77.2066, 'distance_m': 22, 'label': 'at home'},
        'check_out': null,
        'last': {'at': '2026-10-15T07:39:18.591Z', 'lat': 28.57, 'lng': 77.2066, 'at_home': false, 'label': '1.2 km from home', 'stale': false},
        'home': {'lat': 28.5592, 'lng': 77.2066},
        'trail': [
          {'at': '2026-10-15T07:17:48.546Z', 'lat': 28.5592, 'lng': 77.2066},
          {'at': '2026-10-15T07:27:48.546Z', 'lat': 28.57, 'lng': 77.2066},
        ],
        'far_meters': 300,
        'next_refresh_sec': 60,
      });
      expect(on.last!.label, '1.2 km from home');
      expect(on.trail, hasLength(2));
      expect(on.home!.lat, 28.5592);
      expect(on.nextRefreshSec, 60);

      final off = ClientDtoCodec.decodeStaffLocation({
        'staff_id': '334eeac7',
        'status': 'CHECKED_OUT',
        'check_out': {'at': '2026-10-15T12:40:00.000Z'},
        'last': null,
        'home': null,
        'trail': [],
        'far_meters': 300,
        'next_refresh_sec': null,
      });
      expect(off.last, isNull);
      expect(off.home, isNull);
      expect(off.checkOutAt, '2026-10-15T12:40:00.000Z');
      expect(off.nextRefreshSec, isNull);
    });

    test('GET /client/staff/:id/profile prefers snake_case', () {
      final p = ClientDtoCodec.decodeStaffProfile({
        'staff_id': '334eeac7',
        'staff_code': 'ZT-Ash-67358',
        'full_name': 'Asha Kumari',
        'first_name': 'Asha',
        'photo_url': null,
        'phone': '6498673570',
        'age': 36,
        'series': 'UNSKILLED_CARE',
        'series_label': 'Caretaker (UC)',
        'experience_years': 6,
        'verification': {
          'is_verified': false,
          'police_verification': 'CLEAR',
          'id_verified': false,
          'health_screening': null,
          'video_certified': false,
          'trained': true,
        },
        'placement': {'status_label': 'On trial', 'start_date': '2026-10-15', 'shift_hours': 8},
        'rm': {'name': 'Pooja Mishra', 'phone': '9800000002'},
        'staffId': 'legacy',
        'fullName': 'legacy',
      });
      expect(p.staffId, '334eeac7');
      expect(p.fullName, 'Asha Kumari');
      expect(p.pvStatus, 'CLEAR');
      expect(p.healthScreening, isNull);
      expect(p.trained, isTrue);
      expect(p.rmPhone, '9800000002');
      expect(p.placementStatusLabel, 'On trial');

      // Older servers: camelCase only.
      final legacy = ClientDtoCodec.decodeStaffProfile({'staffId': 's1', 'fullName': 'Old', 'pvStatus': 'CLEAR'});
      expect(legacy.staffId, 's1');
      expect(legacy.phone, isNull);
    });
  });
}
