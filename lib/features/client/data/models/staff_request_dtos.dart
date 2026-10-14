import '../../domain/models/staff_request_models.dart';

/// Decodes `/client/staff-requests` responses (list items and detail share
/// one shape; the list adds `shortlisted`/`selected`, the detail adds `rm`
/// and `candidates`).
abstract final class StaffRequestDtoCodec {
  static StaffRequest decodeRequest(Map<String, dynamic> j) => StaffRequest(
        id: j['id'] as String? ?? '',
        requestNo: j['request_no'] as String? ?? '',
        status: j['status'] as String? ?? '',
        series: j['series'] as String? ?? '',
        seriesDb: j['series_db'] as String? ?? '',
        placementType: j['placement_type'] as String? ?? 'PERMANENT',
        shiftHours: j['shift_hours'] as num? ?? 8,
        headcount: (j['headcount'] as num?)?.toInt() ?? 1,
        genderPref: j['gender_pref'] as String? ?? 'ANY',
        requirements: j['requirements'] is Map<String, dynamic>
            ? j['requirements'] as Map<String, dynamic>
            : const {},
        startDate: j['start_date'] as String?,
        address: j['address'] as String?,
        language: j['language'] as String?,
        budgetMin: j['budget_min'] as num?,
        budgetMax: j['budget_max'] as num?,
        notes: j['notes'] as String?,
        cancelReason: j['cancel_reason'] as String?,
        createdAt: DateTime.tryParse(j['created_at'] as String? ?? '')?.toLocal(),
        shortlistedCount: (j['shortlisted'] as num?)?.toInt() ?? 0,
        selectedCount: (j['selected'] as num?)?.toInt() ?? 0,
        rm: j['rm'] is Map<String, dynamic>
            ? StaffRequestRm(
                name: (j['rm'] as Map<String, dynamic>)['name'] as String?,
                phone: (j['rm'] as Map<String, dynamic>)['phone'] as String?,
              )
            : null,
        candidates: [
          for (final c in (j['candidates'] as List?) ?? const [])
            if (c is Map<String, dynamic>) decodeCandidate(c),
        ],
      );

  static StaffRequestCandidate decodeCandidate(Map<String, dynamic> j) {
    final s = j['staff'] is Map<String, dynamic>
        ? j['staff'] as Map<String, dynamic>
        : const <String, dynamic>{};
    return StaffRequestCandidate(
      candidateId: j['candidate_id'] as String? ?? '',
      status: j['status'] as String? ?? '',
      rmNote: j['rm_note'] as String?,
      clientNote: j['client_note'] as String?,
      staff: CandidateStaff(
        id: s['id'] as String? ?? '',
        firstName: s['first_name'] as String? ?? 'Staff',
        series: s['series'] as String? ?? '',
        languageTier: s['language_tier'] as String?,
        gender: s['gender'] as String?,
        experienceYears: s['experience_years'] as num?,
        aadhaarVerified: s['aadhaar_verified'] as bool? ?? false,
        policeVerified: s['police_verified'] as bool? ?? false,
      ),
    );
  }
}
