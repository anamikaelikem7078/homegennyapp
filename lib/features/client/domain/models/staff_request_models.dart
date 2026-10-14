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
        fulfilled => 'Staff placed',
        cancelled => 'Cancelled',
        _ => status,
      };

  /// The sentence the brief asks the client to see for each status.
  static String message(String status) => switch (status) {
        newRequest => 'Request received — assigning your relationship manager',
        assigned => 'Your RM is finding staff for you',
        shortlisted => 'Staff ready for you to choose',
        clientSelected => 'You chose — your RM is setting up the trial',
        fulfilled => 'Staff placed',
        cancelled => 'Cancelled',
        _ => status,
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
    this.startDate,
    this.address,
    this.language,
    this.budgetMin,
    this.budgetMax,
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
  final String? startDate;
  final String? address;
  final String? language;
  final num? budgetMin;
  final num? budgetMax;
  final String? notes;
  final String? cancelReason;
  final DateTime? createdAt;

  /// List view only: how many staff are waiting for the client's choice.
  final int shortlistedCount;
  final int selectedCount;

  /// Detail view only.
  final StaffRequestRm? rm;
  final List<StaffRequestCandidate> candidates;

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
