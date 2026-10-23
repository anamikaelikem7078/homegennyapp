/// `GET /client/snapshot` — everything for the home's "Today at home":
/// each placed staff member's day, plus the client's open requests and
/// replacements. All fields match the API exactly.
class ClientSnapshot {
  const ClientSnapshot({
    required this.date,
    required this.staff,
    required this.requests,
    required this.replacements,
    required this.json,
    this.generatedAt,
  });

  factory ClientSnapshot.fromJson(Map<String, dynamic> json) => ClientSnapshot(
        date: json['date'] as String? ?? '',
        generatedAt: DateTime.tryParse(json['generated_at']?.toString() ?? ''),
        staff: _maps(json['staff']).map(SnapshotStaff.fromJson).toList(),
        requests: _maps(json['requests']).map(SnapshotRequest.fromJson).toList(),
        replacements: _maps(json['replacements']).map(SnapshotReplacement.fromJson).toList(),
        json: json,
      );

  /// IST day, `YYYY-MM-DD`.
  final String date;
  final DateTime? generatedAt;

  /// Currently placed staff (trial or confirmed), oldest first.
  final List<SnapshotStaff> staff;

  /// Open staff requests: NEW, ASSIGNED, SHORTLISTED, CLIENT_SELECTED.
  final List<SnapshotRequest> requests;

  /// Replacement requests the RM is still looking at.
  final List<SnapshotReplacement> replacements;

  /// The response as received — what the offline cache stores.
  final Map<String, dynamic> json;

  List<SnapshotReplacement> replacementsFor(String placementId) =>
      replacements.where((r) => r.placementId == placementId).toList();
}

class SnapshotStaff {
  const SnapshotStaff({
    required this.placementId,
    required this.staffId,
    required this.firstName,
    required this.series,
    required this.seriesLabel,
    required this.deployment,
    required this.today,
    required this.statusToday,
    required this.message,
    required this.last7Days,
    this.photoUrl,
  });

  factory SnapshotStaff.fromJson(Map<String, dynamic> json) {
    final staff = _map(json['staff']);
    return SnapshotStaff(
      placementId: json['placement_id']?.toString() ?? '',
      staffId: staff['id']?.toString() ?? '',
      firstName: staff['first_name'] as String? ?? '',
      series: staff['series'] as String? ?? '',
      seriesLabel: staff['series_label'] as String? ?? '',
      photoUrl: staff['photo_url'] as String?,
      deployment: SnapshotDeployment.fromJson(_map(json['deployment'])),
      today: SnapshotToday.fromJson(_map(json['today'])),
      statusToday: SnapshotStatus.fromString(json['status_today'] as String?),
      message: json['message'] as String? ?? '',
      last7Days: _maps(json['last_7_days']).map(SnapshotDay.fromJson).toList(),
    );
  }

  final String placementId;
  final String staffId;
  final String firstName;

  /// Short code: UC / SC / CK…
  final String series;
  final String seriesLabel;

  /// Relative to the API base; 404 when no photo is on file.
  final String? photoUrl;
  final SnapshotDeployment deployment;
  final SnapshotToday today;
  final SnapshotStatus statusToday;

  /// Ready-to-show line — use as is.
  final String message;

  /// Oldest first, ending with the snapshot's date.
  final List<SnapshotDay> last7Days;

  bool get isCook => today.meals != null || series.toUpperCase() == 'CK';
}

class SnapshotDeployment {
  const SnapshotDeployment({
    required this.type,
    required this.visit,
    required this.status,
    this.since,
    this.trialEnds,
    this.shiftStart,
    this.shiftHours,
  });

  factory SnapshotDeployment.fromJson(Map<String, dynamic> json) => SnapshotDeployment(
        type: json['type'] as String? ?? '',
        visit: json['visit'] as String? ?? '',
        status: json['status'] as String? ?? '',
        since: _date(json['since']),
        trialEnds: _date(json['trial_ends']),
        shiftStart: json['shift_start'] as String?,
        shiftHours: (json['shift_hours'] as num?)?.toDouble(),
      );

  final String type;
  final String visit;

  /// TRIAL or CONFIRMED.
  final String status;
  final DateTime? since;
  final DateTime? trialEnds;

  /// `HH:mm`, or null when the RM hasn't set one.
  final String? shiftStart;
  final double? shiftHours;

  bool get isTrial => status.toUpperCase() == 'TRIAL';
}

class SnapshotToday {
  const SnapshotToday({
    required this.attendance,
    required this.reportFilled,
    required this.unreadInstructions,
    this.checkIn,
    this.checkOut,
    this.lateByMin,
    this.work,
    this.meals,
  });

  factory SnapshotToday.fromJson(Map<String, dynamic> json) => SnapshotToday(
        attendance: json['attendance'] as String? ?? 'NOT_STARTED',
        checkIn: json['check_in'] as String?,
        checkOut: json['check_out'] as String?,
        lateByMin: (json['late_by_min'] as num?)?.toInt(),
        work: json['work'] is Map ? SnapshotWork.fromJson(_map(json['work'])) : null,
        meals: json['meals'] is Map ? SnapshotMeals.fromJson(_map(json['meals'])) : null,
        reportFilled: json['report_filled'] as bool? ?? false,
        unreadInstructions: (json['unread_instructions'] as num?)?.toInt() ?? 0,
      );

  /// ON_TIME, LATE, CHECKED_IN, NOT_STARTED, NOT_IN_YET, NO_SHOW, ABSENT, ON_LEAVE.
  final String attendance;
  final String? checkIn;
  final String? checkOut;
  final int? lateByMin;

  /// Caretakers (UC/SC) only.
  final SnapshotWork? work;

  /// Cooks (CK) only.
  final SnapshotMeals? meals;
  final bool reportFilled;
  final int unreadInstructions;
}

class SnapshotWork {
  const SnapshotWork({required this.done, required this.total, required this.missed, this.next});

  factory SnapshotWork.fromJson(Map<String, dynamic> json) => SnapshotWork(
        done: (json['done'] as num?)?.toInt() ?? 0,
        total: (json['total'] as num?)?.toInt() ?? 0,
        missed: (json['missed'] as num?)?.toInt() ?? 0,
        next: json['next'] as String?,
      );

  final int done;
  final int total;
  final int missed;

  /// Next task still to do; null when nothing is left.
  final String? next;
}

class SnapshotMeals {
  const SnapshotMeals({required this.planned, required this.logged, required this.due, required this.notLogged});

  factory SnapshotMeals.fromJson(Map<String, dynamic> json) => SnapshotMeals(
        planned: (json['planned'] as num?)?.toInt() ?? 0,
        logged: (json['logged'] as num?)?.toInt() ?? 0,
        due: (json['due'] as num?)?.toInt() ?? 0,
        notLogged: ((json['not_logged'] as List?) ?? const []).map((e) => e.toString()).toList(),
      );

  final int planned;
  final int logged;

  /// Meals whose time has passed.
  final int due;
  final List<String> notLogged;
}

class SnapshotDay {
  const SnapshotDay({required this.date, required this.attendance});

  factory SnapshotDay.fromJson(Map<String, dynamic> json) => SnapshotDay(
        date: _date(json['date']),
        attendance: json['attendance'] as String? ?? 'NONE',
      );

  final DateTime? date;

  /// PRESENT, ABSENT, LEAVE or NONE.
  final String attendance;
}

/// `status_today` — the worst of attendance, missed tasks, meals and report.
enum SnapshotStatus {
  green,
  amber,
  red,
  notStarted;

  static SnapshotStatus fromString(String? raw) => switch (raw?.toUpperCase()) {
        'GREEN' => green,
        'AMBER' => amber,
        'RED' => red,
        _ => notStarted,
      };
}

class SnapshotRequest {
  const SnapshotRequest({
    required this.id,
    required this.requestNo,
    required this.series,
    required this.status,
    this.visitType,
    this.startDate,
    this.startTime,
  });

  factory SnapshotRequest.fromJson(Map<String, dynamic> json) => SnapshotRequest(
        id: json['id']?.toString() ?? '',
        requestNo: json['request_no'] as String? ?? '',
        series: json['series'] as String? ?? '',
        status: json['status'] as String? ?? '',
        visitType: json['visit_type'] as String?,
        startDate: json['start_date'] as String?,
        startTime: json['start_time'] as String?,
      );

  final String id;
  final String requestNo;
  final String series;

  /// NEW, ASSIGNED, SHORTLISTED (the client must choose), CLIENT_SELECTED.
  final String status;
  final String? visitType;
  final String? startDate;
  final String? startTime;

  bool get needsChoice => status.toUpperCase() == 'SHORTLISTED';
}

class SnapshotReplacement {
  const SnapshotReplacement({required this.id, required this.placementId, required this.status});

  factory SnapshotReplacement.fromJson(Map<String, dynamic> json) => SnapshotReplacement(
        id: json['id']?.toString() ?? '',
        placementId: json['placement_id']?.toString() ?? '',
        status: json['status'] as String? ?? '',
      );

  final String id;
  final String placementId;
  final String status;
}

Map<String, dynamic> _map(Object? v) => v is Map ? Map<String, dynamic>.from(v) : const {};

List<Map<String, dynamic>> _maps(Object? v) =>
    v is List ? v.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList() : const [];

/// `YYYY-MM-DD` as a local calendar date (no time-zone shift).
DateTime? _date(Object? v) {
  final m = RegExp(r'^(\d{4})-(\d{2})-(\d{2})').firstMatch(v?.toString() ?? '');
  if (m == null) return null;
  return DateTime(int.parse(m[1]!), int.parse(m[2]!), int.parse(m[3]!));
}
