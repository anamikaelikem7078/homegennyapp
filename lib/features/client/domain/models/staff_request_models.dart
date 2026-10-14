import '../../../care/domain/care_models.dart';

/// A client's request for staff (`/client/staff-requests`).
///
/// Flow: ASSIGNED → (RM shortlists) SHORTLISTED → (client chooses)
/// CLIENT_SELECTED → (RM makes the trial placement) FULFILLED. "None of
/// these" sends SHORTLISTED back to ASSIGNED; any open status can be
/// CANCELLED with a reason.
abstract final class StaffRequestStatus {
  static const newRequest = 'NEW';
  static const assigned = 'ASSIGNED';
  static const shortlisted = 'SHORTLISTED';
  static const clientSelected = 'CLIENT_SELECTED';
  static const fulfilled = 'FULFILLED';
  static const cancelled = 'CANCELLED';

  static const open = [newRequest, assigned, shortlisted, clientSelected];

  /// Short chip text.
  static String label(String status) => switch (status) {
        newRequest => 'Received',
        assigned => 'Finding staff',
        shortlisted => 'Ready to choose',
        clientSelected => 'You chose',
        fulfilled => 'Booking confirmed',
        cancelled => 'Cancelled',
        _ => status,
      };

  /// The sentence the brief asks the client to see for each status.
  static String message(String status) => switch (status) {
        newRequest => 'Request received — assigning your relationship manager',
        assigned => 'Your RM is finding staff for you',
        shortlisted => 'Staff ready for you to choose',
        clientSelected => 'You chose — your RM is setting up the trial',
        fulfilled => 'Booking confirmed',
        cancelled => 'Cancelled',
        _ => status,
      };
}

/// `visit_type` on a request: a single visit, or staff who come every day.
abstract final class VisitType {
  static const oneTime = 'ONE_TIME';
  static const regular = 'REGULAR';
}

/// Booking rules the backend enforces, mirrored for the form.
abstract final class BookingRules {
  /// `duration_min` choices for a one-time visit.
  static const durations = [60, 90, 120, 180];

  /// How many dishes a one-time cook visit of [durationMin] covers.
  static int maxDishes(int durationMin) => switch (durationMin) {
        60 => 3,
        90 => 4,
        120 => 5,
        _ => 7,
      };

  /// The meal the server picks from a visit's start time (`HH:MM`).
  static String mealForTime(String hhmm) {
    final parts = hhmm.split(':');
    final minutes = (int.tryParse(parts.first) ?? 0) * 60 + (parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0);
    if (minutes < 11 * 60) return 'BREAKFAST';
    if (minutes < 16 * 60) return 'LUNCH';
    if (minutes < 19 * 60) return 'SNACKS';
    return 'DINNER';
  }

  /// 60 → "1 hour", 90 → "1.5 hours".
  static String durationLabel(int durationMin) {
    final h = hours(durationMin / 60);
    return h == '1' ? '1 hour' : '$h hours';
  }

  /// 2 → "2", 1.5 → "1.5".
  static String hours(num h) => h == h.roundToDouble() ? '${h.round()}' : '$h';
}

/// A request's `menu`: the dishes for a one-time cook visit, or a regular
/// cook's weekly menu ([weekly] non-empty).
class StaffRequestMenu {
  const StaffRequestMenu({
    this.meal,
    this.mealTime,
    this.dishes = const [],
    this.specialInstruction,
    this.weekly = const [],
  });

  final String? meal;
  final String? mealTime;
  final List<String> dishes;
  final String? specialInstruction;
  final List<WeeklyMenuEntry> weekly;
}

/// One `menu.items[]` entry of a regular cook's weekly menu.
class WeeklyMenuEntry {
  WeeklyMenuEntry({
    required this.dow,
    required this.meal,
    List<String>? dishIds,
    List<String>? dishes,
    this.mealTime,
  })  : dishIds = dishIds ?? [],
        dishes = dishes ?? [];

  static const days = ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'];

  String dow;
  String meal;
  List<String> dishIds;

  /// Display names (decoded) or typed names (sent).
  List<String> dishes;
  String? mealTime;

  Map<String, dynamic> toJson({List<String> typed = const []}) => {
        'dow': dow,
        'meal': meal,
        if (dishIds.isNotEmpty) 'dish_ids': dishIds,
        if (typed.isNotEmpty) 'dishes': typed,
        'meal_time': ?mealTime,
      };
}

/// Candidate status on a request. WITHDRAWN is never sent to the client.
abstract final class StaffRequestCandidateStatus {
  static const proposed = 'PROPOSED';
  static const clientSelected = 'CLIENT_SELECTED';
  static const placed = 'PLACED';
  static const clientRejected = 'CLIENT_REJECTED';
}

class StaffRequest {
  const StaffRequest({
    required this.id,
    required this.requestNo,
    required this.status,
    required this.series,
    required this.seriesDb,
    required this.placementType,
    required this.shiftHours,
    required this.headcount,
    required this.genderPref,
    required this.requirements,
    this.visitType = VisitType.regular,
    this.durationMin,
    this.startDate,
    this.startTime,
    this.address,
    this.lat,
    this.lng,
    this.language,
    this.menu,
    this.careNeeds,
    this.notes,
    this.cancelReason,
    this.createdAt,
    this.shortlistedCount = 0,
    this.selectedCount = 0,
    this.rm,
    this.candidates = const [],
  });

  final String id;
  final String requestNo;
  final String status;

  /// Short form (UC / SC / CK).
  final String series;

  /// Long form (UNSKILLED_CARE / SKILLED_CARE / COOK).
  final String seriesDb;
  final String placementType;
  final num shiftHours;
  final int headcount;
  final String genderPref;
  final Map<String, dynamic> requirements;

  /// ONE_TIME or REGULAR.
  final String visitType;

  /// One-time visits only: 60 / 90 / 120 / 180.
  final int? durationMin;
  final String? startDate;

  /// `HH:MM`, 24 h.
  final String? startTime;
  final String? address;
  final double? lat;
  final double? lng;
  final String? language;

  /// Cook only.
  final StaffRequestMenu? menu;

  /// UC/SC only — the care-plan shape.
  final CarePlan? careNeeds;
  final String? notes;
  final String? cancelReason;
  final DateTime? createdAt;

  /// List view only: how many staff are waiting for the client's choice.
  final int shortlistedCount;
  final int selectedCount;

  /// Detail view only.
  final StaffRequestRm? rm;
  final List<StaffRequestCandidate> candidates;

  bool get isOneTime => visitType == VisitType.oneTime;

  bool get isOpen => StaffRequestStatus.open.contains(status);
  bool get canChoose => status == StaffRequestStatus.shortlisted;
}

class StaffRequestRm {
  const StaffRequestRm({this.name, this.phone});
  final String? name;
  final String? phone;
}

class StaffRequestCandidate {
  const StaffRequestCandidate({
    required this.candidateId,
    required this.status,
    required this.staff,
    this.rmNote,
    this.clientNote,
  });

  final String candidateId;
  final String status;
  final String? rmNote;
  final String? clientNote;
  final CandidateStaff staff;
}

/// The privacy-safe card: no phone, surname, Aadhaar or address.
class CandidateStaff {
  const CandidateStaff({
    required this.id,
    required this.firstName,
    required this.series,
    this.languageTier,
    this.gender,
    this.experienceYears,
    this.aadhaarVerified = false,
    this.policeVerified = false,
  });

  /// Send this (not the candidate id) as `staff_id` when choosing.
  final String id;
  final String firstName;
  final String series;
  final String? languageTier;
  final String? gender;
  final num? experienceYears;
  final bool aadhaarVerified;
  final bool policeVerified;
}
