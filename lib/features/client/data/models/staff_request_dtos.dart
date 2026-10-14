import '../../../care/domain/care_models.dart';
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
        visitType: j['visit_type'] as String? ?? VisitType.regular,
        durationMin: (j['duration_min'] as num?)?.toInt(),
        startDate: j['start_date'] as String?,
        startTime: j['start_time'] as String?,
        address: j['address'] as String?,
        lat: (j['lat'] as num?)?.toDouble(),
        lng: (j['lng'] as num?)?.toDouble(),
        language: j['language'] as String?,
        menu: j['menu'] is Map<String, dynamic> ? decodeMenu(j['menu'] as Map<String, dynamic>) : null,
        careNeeds: j['care_needs'] is Map<String, dynamic>
            ? CarePlan.fromJson(j['care_needs'] as Map<String, dynamic>)
            : null,
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

  /// One-time `{ meal, meal_time, dishes, special_instruction }` or regular
  /// `{ items: [{ dow, meal, dishes, meal_time }] }`. Dishes come back as
  /// `{ name }` objects (strings are accepted too).
  static StaffRequestMenu decodeMenu(Map<String, dynamic> j) {
    List<String> names(Object? v) => [
          for (final d in (v is List ? v : const []))
            if (d is Map && d['name'] != null) '${d['name']}' else if (d is String) d,
        ];
    return StaffRequestMenu(
      meal: j['meal'] as String?,
      mealTime: j['meal_time'] as String?,
      dishes: names(j['dishes']),
      specialInstruction: j['special_instruction'] as String?,
      weekly: [
        for (final e in (j['items'] as List?) ?? const [])
          if (e is Map<String, dynamic>)
            WeeklyMenuEntry(
              dow: e['dow'] as String? ?? '',
              meal: e['meal'] as String? ?? '',
              dishIds: [for (final id in (e['dish_ids'] as List?) ?? const []) '$id'],
              dishes: names(e['dishes']),
              mealTime: e['meal_time'] as String?,
            ),
      ],
    );
  }

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
