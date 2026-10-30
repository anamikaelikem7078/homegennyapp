/// Client confirmation of attendance days and the monthly muster roll
/// (Form XVI). A day the staff member marks in the app needs the client's
/// OK; days HR or the RM enter don't (`NOT_REQUIRED`).
library;

num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');
int _int(Object? v) => _num(v)?.toInt() ?? 0;
String? _str(Object? v) => v == null || '$v'.isEmpty ? null : '$v';
List<Map<String, dynamic>> _maps(Object? v) => [
      for (final e in (v as List?) ?? const [])
        if (e is Map) Map<String, dynamic>.from(e),
    ];

/// `client_status` of an attendance day.
abstract final class ClientDayStatus {
  static const notRequired = 'NOT_REQUIRED';
  static const pending = 'PENDING';
  static const approved = 'APPROVED';
  static const deemed = 'DEEMED';
  static const disputed = 'DISPUTED';
  static const approvedPaper = 'APPROVED_PAPER';

  /// Filter value for `GET /client/attendance/approvals`.
  static const all = 'ALL';

  static bool isConfirmed(String? s) => s == approved || s == deemed || s == approvedPaper;
}

/// One day in `GET /client/attendance/approvals` `items[]`.
class ApprovalDay {
  const ApprovalDay({
    required this.id,
    required this.date,
    required this.staffId,
    required this.staffName,
    required this.clientStatus,
    this.staffCode,
    this.placementId,
    this.status,
    this.hoursWorked,
    this.checkIn,
    this.checkOut,
    this.checkInIst,
    this.checkOutIst,
    this.source,
    this.clientNote,
    this.clientActionAt,
    this.deemedAt,
    this.resolutionNote,
  });

  factory ApprovalDay.fromJson(Map<String, dynamic> j) => ApprovalDay(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        staffId: '${j['staff_id'] ?? ''}',
        staffName: _str(j['staff_name']) ?? 'Staff',
        staffCode: _str(j['staff_code']),
        placementId: _str(j['placement_id']),
        status: _str(j['status']),
        hoursWorked: _num(j['hours_worked']),
        checkIn: _str(j['check_in']),
        checkOut: _str(j['check_out']),
        checkInIst: _str(j['check_in_ist']),
        checkOutIst: _str(j['check_out_ist']),
        source: _str(j['source']),
        clientStatus: _str(j['client_status']) ?? ClientDayStatus.pending,
        clientNote: _str(j['client_note']),
        clientActionAt: _str(j['client_action_at']),
        deemedAt: _str(j['deemed_at']),
        resolutionNote: _str(j['resolution_note']),
      );

  final String id;
  final String date; // YYYY-MM-DD
  final String staffId;
  final String staffName;
  final String? staffCode;
  final String? placementId;
  final String? status;
  final num? hoursWorked;
  final String? checkIn;
  final String? checkOut;
  final String? checkInIst;
  final String? checkOutIst;
  final String? source;
  final String clientStatus;
  final String? clientNote;
  final String? clientActionAt;

  /// PENDING only: when the day auto-confirms (48 hours after marking).
  final String? deemedAt;
  final String? resolutionNote;

  bool get isPending => clientStatus == ClientDayStatus.pending;
}

/// `GET /client/attendance/approvals` response.
class ApprovalList {
  const ApprovalList({
    required this.items,
    this.from,
    this.to,
    this.pendingCount = 0,
    this.disputedCount = 0,
  });

  factory ApprovalList.fromJson(Map<String, dynamic> j) => ApprovalList(
        from: _str(j['from']),
        to: _str(j['to']),
        pendingCount: _int(j['pending_count']),
        disputedCount: _int(j['disputed_count']),
        items: _maps(j['items']).map(ApprovalDay.fromJson).toList(),
      );

  final String? from;
  final String? to;
  final int pendingCount;
  final int disputedCount;
  final List<ApprovalDay> items;
}

/// What the client says really happened on a disputed day (optional).
abstract final class DisputeActual {
  static const options = [
    ('ABSENT', 'Absent'),
    ('HALF_DAY', 'Half day'),
    ('LATE', 'Late'),
    ('LEFT_EARLY', 'Left early'),
    ('OTHER', 'Other'),
  ];
}

/// One staff row of the muster roll.
class MusterRow {
  const MusterRow({
    required this.name,
    required this.days,
    this.code,
    this.rank,
    this.fatherOrHusbandName,
    this.sex,
    this.daysPresent,
    this.additionalHours,
    this.weeklyOff,
    this.total,
    this.remarks,
  });

  factory MusterRow.fromJson(Map<String, dynamic> j) => MusterRow(
        code: _str(j['code']),
        rank: _str(j['rank']),
        name: _str(j['name']) ?? 'Staff',
        fatherOrHusbandName: _str(j['father_or_husband_name']),
        sex: _str(j['sex']),
        days: [for (final d in (j['days'] as List?) ?? const []) d == null ? '' : '$d'],
        daysPresent: _num(j['days_present']),
        additionalHours: _num(j['additional_hours']),
        weeklyOff: _num(j['weekly_off']),
        total: _num(j['total']),
        remarks: _str(j['remarks']),
      );

  final String? code;
  final String? rank;
  final String name;
  final String? fatherOrHusbandName;
  final String? sex;

  /// Index 0 = day 1. `P` present, `½` half day, `A` absent, `L` leave,
  /// `WO` weekly off, `''` nothing recorded or under dispute.
  final List<String> days;
  final num? daysPresent;
  final num? additionalHours;
  final num? weeklyOff;
  final num? total;
  final String? remarks;
}

/// A signature on a muster roll (current `signed` or one of `versions[]`).
class MusterSignature {
  const MusterSignature({
    required this.id,
    this.version,
    this.status,
    this.signMethod,
    this.signedAt,
    this.signedName,
    this.hasScan = false,
    this.note,
    this.locked = false,
  });

  factory MusterSignature.fromJson(Map<String, dynamic> j) => MusterSignature(
        id: '${j['id'] ?? ''}',
        version: _num(j['version'])?.toInt(),
        status: _str(j['status']),
        signMethod: _str(j['sign_method']),
        signedAt: _str(j['signed_at']),
        signedName: _str(j['signed_name']),
        hasScan: j['has_scan'] == true,
        note: _str(j['note']),
        locked: j['locked'] == true,
      );

  final String id;
  final int? version;
  final String? status;

  /// `CLIENT_APP` | `PAPER_UPLOAD`.
  final String? signMethod;
  final String? signedAt;
  final String? signedName;
  final bool hasScan;
  final String? note;

  /// True once Finance approved the month's invoice: no more signing.
  final bool locked;

  bool get onPaper => signMethod == 'PAPER_UPLOAD';
}

/// `GET /client/muster-rolls?month=&year=` response.
class MusterRoll {
  const MusterRoll({
    required this.month,
    required this.year,
    required this.rows,
    required this.daysInMonth,
    this.monthLabel,
    this.dailyMandays = const [],
    this.totalPresent,
    this.totalAdditionalHours,
    this.totalWeeklyOff,
    this.totalMandays,
    this.disputedDays = 0,
    this.signed,
    this.changedSinceSigned = const [],
    this.versions = const [],
  });

  factory MusterRoll.fromJson(Map<String, dynamic> j, {required int month, required int year}) {
    final totals = j['totals'] is Map ? Map<String, dynamic>.from(j['totals'] as Map) : const <String, dynamic>{};
    final disputed = j['disputed_days'];
    return MusterRoll(
      month: month,
      year: year,
      monthLabel: _str(j['month_label']),
      daysInMonth: _num(j['days_in_month'])?.toInt() ?? DateTime(year, month + 1, 0).day,
      rows: _maps(j['rows']).map(MusterRow.fromJson).toList(),
      dailyMandays: [for (final v in (j['daily_mandays'] as List?) ?? const []) _num(v) ?? 0],
      totalPresent: _num(totals['total_present']),
      totalAdditionalHours: _num(totals['additional_hours']),
      totalWeeklyOff: _num(totals['weekly_off']),
      totalMandays: _num(totals['total_mandays']),
      // A count, or the list of disputed days.
      disputedDays: disputed is List ? disputed.length : _int(disputed),
      signed: j['signed'] is Map ? MusterSignature.fromJson(Map<String, dynamic>.from(j['signed'] as Map)) : null,
      changedSinceSigned: (j['changed_since_signed'] as List?) ?? const [],
      versions: _maps(j['versions']).map(MusterSignature.fromJson).toList(),
    );
  }

  final int month;
  final int year;
  final String? monthLabel;
  final int daysInMonth;
  final List<MusterRow> rows;
  final List<num> dailyMandays;
  final num? totalPresent;
  final num? totalAdditionalHours;
  final num? totalWeeklyOff;
  final num? totalMandays;
  final int disputedDays;
  final MusterSignature? signed;

  /// Non-empty = attendance changed after the last signature.
  final List<dynamic> changedSinceSigned;

  /// Earlier signatures.
  final List<MusterSignature> versions;

  bool get locked => signed?.locked ?? false;
  bool get needsSignature => !locked && (signed == null || changedSinceSigned.isNotEmpty);
}

/// `POST /client/muster-rolls/sign` response.
class MusterSignResult {
  const MusterSignResult({this.version, this.status, this.daysConfirmed = 0});

  factory MusterSignResult.fromJson(Map<String, dynamic> j) => MusterSignResult(
        version: _num(j['version'])?.toInt(),
        status: _str(j['status']),
        daysConfirmed: _int(j['days_confirmed']),
      );

  final int? version;
  final String? status;
  final int daysConfirmed;
}
