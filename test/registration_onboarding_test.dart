import 'package:flutter_test/flutter_test.dart';
import 'package:homegennyapp/common/data/models/auth_dto.dart';
import 'package:homegennyapp/common/domain/models/otp_send_result.dart';
import 'package:homegennyapp/common/domain/models/user_role.dart';
import 'package:homegennyapp/core/exceptions/exception_handler.dart';
import 'package:homegennyapp/core/onboarding/onboarding_models.dart';
import 'package:homegennyapp/core/onboarding/onboarding_providers.dart';
import 'package:homegennyapp/core/series/series_catalog.dart';
import 'package:homegennyapp/features/client/data/models/client_dtos.dart';
import 'package:homegennyapp/features/staff/data/models/staff_dtos.dart';
import 'package:homegennyapp/features/staff/domain/models/staff_models.dart';

// Samples are the registration brief's (21 Oct 2026) responses.
void main() {
  group('login', () {
    test('POST /auth/otp/send — new number', () {
      final r = OtpSendResult.fromJson({
        'sent': true,
        'expires_at': '2026-10-21T07:28:28.291Z',
        'is_registered': false,
        'role': null,
        'use_password_login': false,
      });
      expect(r.isRegistered, isFalse);
      expect(r.role, isNull);
      expect(r.usePasswordLogin, isFalse);
      expect(r.expiresAt, DateTime.utc(2026, 10, 21, 7, 28, 28, 291));
    });

    test('POST /auth/otp/send — office number', () {
      final r = OtpSendResult.fromJson({'sent': false, 'is_registered': true, 'use_password_login': true});
      expect(r.usePasswordLogin, isTrue);
    });

    test('POST /auth/otp/verify — new staff with an empty name', () {
      final dto = AuthTokensDto.fromJson({
        'access_token': 'a',
        'refresh_token': 'r',
        'must_change_password': false,
        'is_new_user': true,
        'user': {
          'id': 'u1',
          'full_name': '',
          'role': 'STAFF',
          'phone': '9876543210',
          'staffCode': 'new004',
          'series': null,
          'assignedRm': null,
          'profile_complete': false,
        },
      });
      expect(dto.isNewUser, isTrue);
      expect(dto.user!.role, UserRole.staff);
      expect(dto.user!.name, '');
      expect(displayNameOr(dto.user!.name, dto.user!.phone), '9876543210');
      expect(displayNameOr('', null), 'Welcome');
    });

    test('client login user — customerName is the display name', () {
      final user = UserDto.fromJson({'id': 'c1', 'role': 'CLIENT', 'phone': '9', 'customerName': 'Anil Arora'});
      expect(user.name, 'Anil Arora');
    });
  });

  group('GET /me/onboarding', () {
    test('new staff', () {
      final s = OnboardingStatus.fromJson({
        'role': 'STAFF',
        'profile_complete': false,
        'missing': ['full_name', 'date_of_birth', 'gender', 'series', 'address', 'city', 'pincode', 'emergency_contact'],
        'next_step': 'COMPLETE_PROFILE',
        'pipeline_stage': 'S1_INTAKE',
        'rm': null,
      });
      expect(s.isLocked, isTrue);
      expect(s.nextStep, OnboardingNextStep.completeProfile);
      expect(s.rm, isNull);
    });

    test('submitted, RM assigned', () {
      final s = OnboardingStatus.fromJson({
        'role': 'STAFF',
        'profile_complete': true,
        'missing': [],
        'next_step': 'VERIFICATION',
        'pipeline_stage': 'S2_VERIFY',
        'rm': {'name': 'Pooja Mishra', 'phone': '9800000002'},
      });
      expect(s.isLocked, isFalse);
      expect(s.nextStep, OnboardingNextStep.verification);
      expect(s.rm!.name, 'Pooja Mishra');
    });

    test('wizard opens at the step of the first missing field', () {
      expect(profileWizardRoute(UserRole.staff, ['emergency_contact']), '/staff/complete-profile?step=2');
      expect(profileWizardRoute(UserRole.staff, ['city', 'emergency_contact']), '/staff/complete-profile?step=1');
      expect(profileWizardRoute(UserRole.staff, ['date_of_birth', 'city']), '/staff/complete-profile?step=0');
      expect(profileWizardRoute(UserRole.client, ['address', 'city']), '/client/complete-profile?step=1');
      expect(profileWizardRoute(UserRole.client, ['name', 'pincode']), '/client/complete-profile?step=0');
      expect(profileWizardRoute(UserRole.rm, ['name']), isNull);
    });
  });

  group('403 PROFILE_INCOMPLETE', () {
    final body = {
      'statusCode': 403,
      'message': {
        'statusCode': 403,
        'error': 'PROFILE_INCOMPLETE',
        'message': 'Complete your profile first — date_of_birth, city missing.',
        'missing': ['date_of_birth', 'city'],
      },
    };

    test('error code and missing fields are read from message', () {
      expect(ExceptionHandler.extractErrorCode(body), 'PROFILE_INCOMPLETE');
      expect(ExceptionHandler.extractMissing(body), ['date_of_birth', 'city']);
    });

    test("Nest's generic labels are not error codes", () {
      expect(ExceptionHandler.extractErrorCode({'statusCode': 400, 'message': 'x', 'error': 'Bad Request'}), isNull);
    });
  });

  group('GET /meta/cities', () {
    test('Other has no areas', () {
      final other = CityOption.fromJson({'city': 'Other', 'areas': []});
      final delhi = CityOption.fromJson({'city': 'Delhi NCR', 'areas': ['Gurgaon', 'Noida', 'South Delhi']});
      expect(other.isOther, isTrue);
      expect(delhi.areas, hasLength(3));
    });
  });

  group('staff profile', () {
    test('GET /staff/profile for a new sign-up — blanks stay blank', () {
      final p = StaffDtoCodec.decodeProfile({
        'id': 'u1',
        'staffApplicantId': 's1',
        'staffCode': 'new004',
        'fullName': null,
        'mobile': '9876543210',
        'email': null,
        'series': null,
        'pipelineStage': 'S1_INTAKE',
        'address': null,
        'dateOfBirth': null,
        'gender': null,
        'city': null,
        'area': null,
        'pincode': null,
        'emergencyContactName': null,
        'emergencyContactMobile': null,
        'languages': [],
        'alternatePhone': null,
        'experienceYears': null,
        'profile_complete': false,
        'missing': ['full_name'],
        'locked_fields': [],
      });
      expect(p.fullName, '');
      expect(p.series, '');
      expect(p.profileComplete, isFalse);
      expect(p.lockedFields, isEmpty);
      expect(SeriesDisplay.label(p.series), '—');
    });

    test('after Submit, identity fields are locked', () {
      final p = StaffDtoCodec.decodeProfile({
        'id': 'u1',
        'fullName': 'Geeta Kumari',
        'mobile': '9876543210',
        'gender': 'FEMALE',
        'city': 'Delhi NCR',
        'pincode': '110017',
        'experienceYears': 4,
        'languages': ['Hindi', 'English'],
        'profile_complete': true,
        'locked_fields': ['full_name', 'date_of_birth', 'gender', 'series'],
      });
      expect(p.isLocked('full_name'), isTrue);
      expect(p.isLocked('address'), isFalse);
      expect(p.experienceYears, 4);
      expect(p.languages, ['Hindi', 'English']);
    });

    test('POST /staff/profile/submit', () {
      final r = StaffProfileSubmitResult.fromJson({
        'outcome': 'ADVANCE_S2',
        'assigned': {'id': 'x', 'name': 'Pooja Mishra'},
        'role': 'STAFF',
        'profile_complete': true,
        'missing': [],
        'next_step': 'VERIFICATION',
        'pipeline_stage': 'S2_VERIFY',
        'rm': {'name': 'Pooja Mishra', 'phone': '9800000002'},
      });
      expect(r.isRestricted, isFalse);
      expect(r.assignedRmName, 'Pooja Mishra');
      expect(r.onboarding.nextStep, OnboardingNextStep.verification);

      final pune = StaffProfileSubmitResult.fromJson({
        'outcome': 'ADVANCE_S2',
        'assigned': null,
        'profile_complete': true,
        'next_step': 'WAIT_FOR_RM',
        'rm': null,
      });
      expect(pune.onboarding.nextStep, OnboardingNextStep.waitForRm);
      expect(pune.assignedRmName, isNull);
    });

    test('GET /staff/dashboard with no RM yet', () {
      final d = StaffDtoCodec.decodeDashboard({
        'staffCode': 'new004',
        'fullName': null,
        'series': null,
        'pipelineStage': 'S1_INTAKE',
        'completionPct': 0,
        'profileComplete': false,
        'assignedRm': null,
        'todayTasks': [
          {'id': 'profile', 'title': 'Complete your profile'},
        ],
      });
      expect(d.assignedRmName, '');
      expect(d.profileComplete, isFalse);
      expect(d.todayTasks.single.id, 'profile');
      expect(d.todayTasks.single.done, isFalse);
    });
  });

  group('client profile', () {
    test('GET /client/profile for a new sign-up', () {
      final p = ClientDtoCodec.decodeProfile({
        'name': null,
        'email': null,
        'phone': '9876543210',
        'address': null,
        'city': null,
        'state': null,
        'pincode': null,
        'lat': null,
        'lng': null,
        'self_registered': true,
        'profile_complete': false,
        'profile_missing': ['name', 'address', 'city', 'pincode'],
      });
      expect(p.name, '');
      expect(p.profileComplete, isFalse);
      expect(p.profileMissing, ['name', 'address', 'city', 'pincode']);
      expect(p.lat, isNull);
    });
  });
}
