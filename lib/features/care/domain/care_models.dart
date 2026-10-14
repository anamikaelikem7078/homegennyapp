/// Daily care (care plan + checklist), shared by the client and staff apps.
/// Everything is per placement. Dates are IST `YYYY-MM-DD`, times `HH:MM`.
library;

Map<String, dynamic> _map(Object? v) => v is Map<String, dynamic> ? v : const {};
List<Map<String, dynamic>> _maps(Object? v) =>
    [for (final e in (v is List ? v : const [])) if (e is Map<String, dynamic>) e];
List<String> _strings(Object? v) => [for (final e in (v is List ? v : const [])) '$e'];
String? _str(Object? v) => v == null || '$v'.trim().isEmpty ? null : '$v';
num? _num(Object? v) => v is num ? v : num.tryParse('${v ?? ''}');

/// A line the backend wrote about what changed — shown as-is, never diffed.
class CareChange {
  const CareChange({required this.type, required this.text});
  factory CareChange.fromJson(Map<String, dynamic> j) =>
      CareChange(type: '${j['type'] ?? ''}', text: '${j['text'] ?? ''}');
  final String type;
  final String text;

  static List<CareChange> list(Object? v) => [for (final m in _maps(v)) CareChange.fromJson(m)];
}

// ── Plan ──────────────────────────────────────────────────────────────────

abstract final class CareEnums {
  static const routes = ['ORAL', 'INJECTION', 'DROPS', 'INHALER', 'TOPICAL', 'OTHER'];
  static const foodRelations = ['BEFORE', 'AFTER', 'WITH', 'ANY'];
  static const activityTypes = ['EXERCISE', 'PHYSIO', 'WALK', 'BATH', 'POSITION_CHANGE', 'OTHER'];
  static const mobility = ['WALKING', 'ASSISTED', 'BEDRIDDEN'];
  static const meals = ['BREAKFAST', 'LUNCH', 'SNACKS', 'DINNER'];
}

class CarePatient {
  CarePatient({
    this.name,
    this.age,
    this.gender,
    this.conditions = const [],
    this.allergies = const [],
    this.mobility,
    this.doctorName,
    this.doctorPhone,
    this.emergencyContactName,
    this.emergencyContactPhone,
  });

  factory CarePatient.fromJson(Map<String, dynamic> j) => CarePatient(
        name: _str(j['name']),
        age: _num(j['age']),
        gender: _str(j['gender']),
        conditions: _strings(j['conditions']),
        allergies: _strings(j['allergies']),
        mobility: _str(j['mobility']),
        doctorName: _str(j['doctor_name']),
        doctorPhone: _str(j['doctor_phone']),
        emergencyContactName: _str(j['emergency_contact_name']),
        emergencyContactPhone: _str(j['emergency_contact_phone']),
      );

  String? name;
  num? age;
  String? gender;
  List<String> conditions;
  List<String> allergies;
  String? mobility;
  String? doctorName;
  String? doctorPhone;
  String? emergencyContactName;
  String? emergencyContactPhone;

  Map<String, dynamic> toJson() => {
        'name': ?name,
        'age': ?age,
        'gender': ?gender,
        'conditions': conditions,
        'allergies': allergies,
        'mobility': ?mobility,
        'doctor_name': ?doctorName,
        'doctor_phone': ?doctorPhone,
        'emergency_contact_name': ?emergencyContactName,
        'emergency_contact_phone': ?emergencyContactPhone,
      };
}

class CareMedication {
  CareMedication({
    this.id,
    this.name = '',
    this.dose = '',
    this.unit,
    this.route = 'ORAL',
    List<String>? times,
    this.foodRelation = 'ANY',
    this.startDate,
    this.endDate,
    this.instructions,
    this.prescriptionFileId,
  }) : times = times ?? [];

  factory CareMedication.fromJson(Map<String, dynamic> j) => CareMedication(
        id: _str(j['id']),
        name: '${j['name'] ?? ''}',
        dose: '${j['dose'] ?? ''}',
        unit: _str(j['unit']),
        route: _str(j['route']) ?? 'ORAL',
        times: _strings(j['times']),
        foodRelation: _str(j['food_relation']) ?? 'ANY',
        startDate: _str(j['start_date']),
        endDate: _str(j['end_date']),
        instructions: _str(j['instructions']),
        prescriptionFileId: _str(j['prescription_file_id']),
      );

  /// Kept when editing so today's ticks stay attached; null = new item.
  String? id;
  String name;
  String dose;
  String? unit;
  String route;
  List<String> times;
  String foodRelation;
  String? startDate;
  String? endDate;
  String? instructions;
  String? prescriptionFileId;

  String get summary => '$name $dose${unit != null ? ' $unit' : ''}';

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'name': name,
        'dose': dose,
        'unit': ?unit,
        'route': route,
        'times': times,
        'food_relation': foodRelation,
        'start_date': ?startDate,
        'end_date': ?endDate,
        'instructions': ?instructions,
        'prescription_file_id': ?prescriptionFileId,
      };
}

class CareVital {
  CareVital({
    this.id,
    required this.type,
    List<String>? times,
    this.min,
    this.max,
    this.systolicMin,
    this.systolicMax,
    this.diastolicMin,
    this.diastolicMax,
    this.label,
    this.unit,
  }) : times = times ?? [];

  factory CareVital.fromJson(Map<String, dynamic> j) => CareVital(
        id: _str(j['id']),
        type: '${j['type'] ?? ''}',
        times: _strings(j['times']),
        min: _num(j['min']),
        max: _num(j['max']),
        systolicMin: _num(j['systolic_min']),
        systolicMax: _num(j['systolic_max']),
        diastolicMin: _num(j['diastolic_min']),
        diastolicMax: _num(j['diastolic_max']),
        label: _str(j['label']),
        unit: _str(j['unit']),
      );

  String? id;
  String type;
  List<String> times;
  num? min;
  num? max;
  num? systolicMin;
  num? systolicMax;
  num? diastolicMin;
  num? diastolicMax;
  String? label;
  String? unit;

  bool get isBp => type == 'BP';

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'type': type,
        'times': times,
        if (isBp) ...{
          'systolic_min': ?systolicMin,
          'systolic_max': ?systolicMax,
          'diastolic_min': ?diastolicMin,
          'diastolic_max': ?diastolicMax,
        } else ...{
          'min': ?min,
          'max': ?max,
        },
      };
}

class CareActivity {
  CareActivity({
    this.id,
    this.type = 'OTHER',
    this.title = '',
    List<String>? times,
    this.durationMin,
    this.notes,
  }) : times = times ?? [];

  factory CareActivity.fromJson(Map<String, dynamic> j) => CareActivity(
        id: _str(j['id']),
        type: _str(j['type']) ?? 'OTHER',
        title: '${j['title'] ?? ''}',
        times: _strings(j['times']),
        durationMin: _num(j['duration_min']),
        notes: _str(j['notes']),
      );

  String? id;
  String type;
  String title;
  List<String> times;
  num? durationMin;
  String? notes;

  Map<String, dynamic> toJson() => {
        'id': ?id,
        'type': type,
        'title': title,
        'times': times,
        'duration_min': ?durationMin,
        'notes': ?notes,
      };
}

class CarePlan {
  CarePlan({
    this.id,
    this.version = 0,
    CarePatient? patient,
    List<CareMedication>? medications,
    List<CareVital>? vitals,
    List<CareActivity>? activities,
    this.dietNotes,
    this.dos,
    this.donts,
    this.changes = const [],
  })  : patient = patient ?? CarePatient(),
        medications = medications ?? [],
        vitals = vitals ?? [],
        activities = activities ?? [];

  factory CarePlan.fromJson(Map<String, dynamic> j) => CarePlan(
        id: _str(j['id']),
        version: _num(j['version'])?.toInt() ?? 0,
        patient: CarePatient.fromJson(_map(j['patient'])),
        medications: [for (final m in _maps(j['medications'])) CareMedication.fromJson(m)],
        vitals: [for (final m in _maps(j['vitals'])) CareVital.fromJson(m)],
        activities: [for (final m in _maps(j['activities'])) CareActivity.fromJson(m)],
        dietNotes: _str(j['diet_notes']),
        dos: _str(j['dos']),
        donts: _str(j['donts']),
        changes: CareChange.list(j['changes']),
      );

  String? id;
  int version;
  CarePatient patient;
  List<CareMedication> medications;
  List<CareVital> vitals;
  List<CareActivity> activities;
  String? dietNotes;
  String? dos;
  String? donts;
  final List<CareChange> changes;

  /// The `PUT …/plan` body — always the whole plan.
  Map<String, dynamic> toJson() => {
        'patient': patient.toJson(),
        'medications': [for (final m in medications) m.toJson()],
        'vitals': [for (final v in vitals) v.toJson()],
        'activities': [for (final a in activities) a.toJson()],
        'diet_notes': dietNotes ?? '',
        'dos': dos ?? '',
        'donts': donts ?? '',
      };
}

/// One entry of `vital_types` — the checks the backend knows, with ranges.
class VitalType {
  const VitalType({
    required this.type,
    required this.label,
    required this.unit,
    this.defaultMin,
    this.defaultMax,
    this.systolicMin,
    this.systolicMax,
    this.diastolicMin,
    this.diastolicMax,
  });

  factory VitalType.fromJson(Map<String, dynamic> j) => VitalType(
        type: '${j['type'] ?? ''}',
        label: '${j['label'] ?? j['type'] ?? ''}',
        unit: '${j['unit'] ?? ''}',
        defaultMin: _num(j['default_min']),
        defaultMax: _num(j['default_max']),
        systolicMin: _num(j['systolic_min']),
        systolicMax: _num(j['systolic_max']),
        diastolicMin: _num(j['diastolic_min']),
        diastolicMax: _num(j['diastolic_max']),
      );

  final String type;
  final String label;
  final String unit;
  final num? defaultMin;
  final num? defaultMax;
  final num? systolicMin;
  final num? systolicMax;
  final num? diastolicMin;
  final num? diastolicMax;

  /// Used if `GET …/plan` hasn't answered — mirrors the backend.
  static const fallback = [
    VitalType(type: 'BP', label: 'Blood pressure', unit: 'mmHg', systolicMin: 90, systolicMax: 140, diastolicMin: 60, diastolicMax: 90),
    VitalType(type: 'SUGAR_FASTING', label: 'Sugar (fasting)', unit: 'mg/dL', defaultMin: 70, defaultMax: 130),
    VitalType(type: 'SUGAR_PP', label: 'Sugar (after meal)', unit: 'mg/dL', defaultMin: 70, defaultMax: 180),
    VitalType(type: 'SUGAR_RANDOM', label: 'Sugar (random)', unit: 'mg/dL', defaultMin: 70, defaultMax: 200),
    VitalType(type: 'TEMP', label: 'Temperature', unit: '°F', defaultMin: 97, defaultMax: 99.5),
    VitalType(type: 'SPO2', label: 'Oxygen (SpO2)', unit: '%', defaultMin: 94, defaultMax: 100),
    VitalType(type: 'PULSE', label: 'Pulse', unit: 'bpm', defaultMin: 60, defaultMax: 100),
    VitalType(type: 'WEIGHT', label: 'Weight', unit: 'kg'),
  ];
}

class CarePlanVersion {
  const CarePlanVersion({required this.version, required this.status, this.createdAt, this.changes = const []});
  final int version;
  final String status;
  final DateTime? createdAt;
  final List<CareChange> changes;
}

/// `GET /care/placements/:pid/plan`.
class CarePlanView {
  const CarePlanView({
    required this.placementId,
    this.plan,
    this.staffName,
    this.staffSeries,
    this.staffAcknowledgedAt,
    this.versions = const [],
    this.vitalTypes = VitalType.fallback,
  });

  factory CarePlanView.fromJson(Map<String, dynamic> j) {
    final types = [for (final m in _maps(j['vital_types'])) VitalType.fromJson(m)];
    return CarePlanView(
      placementId: '${j['placement_id'] ?? ''}',
      plan: j['plan'] is Map<String, dynamic> ? CarePlan.fromJson(j['plan'] as Map<String, dynamic>) : null,
      staffName: _str(_map(j['staff'])['name']),
      staffSeries: _str(_map(j['staff'])['series']),
      staffAcknowledgedAt: DateTime.tryParse('${j['staff_acknowledged_at'] ?? ''}')?.toLocal(),
      versions: [
        for (final v in _maps(j['versions']))
          CarePlanVersion(
            version: _num(v['version'])?.toInt() ?? 0,
            status: '${v['status'] ?? ''}',
            createdAt: DateTime.tryParse('${v['created_at'] ?? ''}')?.toLocal(),
            changes: CareChange.list(v['changes']),
          ),
      ],
      vitalTypes: types.isEmpty ? VitalType.fallback : types,
    );
  }

  final String placementId;
  final CarePlan? plan;
  final String? staffName;

  /// Long form (UNSKILLED_CARE / SKILLED_CARE).
  final String? staffSeries;
  final DateTime? staffAcknowledgedAt;
  final List<CarePlanVersion> versions;
  final List<VitalType> vitalTypes;

  /// An Unskilled Caretaker can't give medicines or take vitals.
  bool get isUnskilled => staffSeries == 'UNSKILLED_CARE' || staffSeries == 'UC';
}

// ── Checklist ─────────────────────────────────────────────────────────────

abstract final class CareTaskStatus {
  static const pending = 'PENDING';
  static const done = 'DONE';
  static const skipped = 'SKIPPED';
  static const missed = 'MISSED';
}

class CareTask {
  const CareTask({
    required this.id,
    required this.date,
    required this.type,
    required this.title,
    required this.time,
    required this.status,
    this.itemId,
    this.value = const {},
    this.outOfRange = false,
    this.skipReason,
    this.notes,
    this.photoFileIds = const [],
    this.doneAt,
    this.target = const {},
  });

  factory CareTask.fromJson(Map<String, dynamic> j) => CareTask(
        id: '${j['id'] ?? ''}',
        date: '${j['date'] ?? ''}',
        type: '${j['type'] ?? ''}',
        itemId: _str(j['item_id']),
        title: '${j['title'] ?? ''}',
        time: '${j['time'] ?? ''}',
        status: '${j['status'] ?? CareTaskStatus.pending}',
        value: _map(j['value']),
        outOfRange: j['out_of_range'] == true,
        skipReason: _str(j['skip_reason']),
        notes: _str(j['notes']),
        photoFileIds: _strings(j['photo_file_ids']),
        doneAt: DateTime.tryParse('${j['done_at'] ?? ''}')?.toLocal(),
        target: _map(j['target']),
      );

  final String id;
  final String date;

  /// MEDICATION / VITAL / ACTIVITY.
  final String type;
  final String? itemId;
  final String title;
  final String time;

  /// PENDING / DONE / SKIPPED / MISSED.
  final String status;
  final Map<String, dynamic> value;
  final bool outOfRange;
  final String? skipReason;
  final String? notes;
  final List<String> photoFileIds;
  final DateTime? doneAt;

  /// For a VITAL: type, unit, min/max or BP ranges. For a MEDICATION: route,
  /// food_relation, instructions, prescription_file_id.
  final Map<String, dynamic> target;

  bool get isVital => type == 'VITAL';
  bool get isBp => target['type'] == 'BP';
  bool get isLate => value['late'] == true;

  /// "190/125 mmHg", "112 mg/dL", or null when there's no reading.
  String? get reading {
    if (value['systolic'] != null) return '${value['systolic']}/${value['diastolic']} ${value['unit'] ?? 'mmHg'}';
    if (value['value'] != null) return '${value['value']} ${value['unit'] ?? ''}'.trim();
    return null;
  }

  /// Whether [v] (or BP [sys]/[dia]) is outside [target] — to colour a
  /// reading before it is sent.
  bool isOutside({num? v, num? sys, num? dia}) {
    bool out(num? x, Object? lo, Object? hi) =>
        x != null && ((lo is num && x < lo) || (hi is num && x > hi));
    if (isBp) {
      return out(sys, target['systolic_min'], target['systolic_max']) ||
          out(dia, target['diastolic_min'], target['diastolic_max']);
    }
    return out(v, target['min'], target['max']);
  }
}

class CareSummary {
  const CareSummary({
    this.total = 0,
    this.done = 0,
    this.pending = 0,
    this.missed = 0,
    this.skipped = 0,
    this.outOfRange = 0,
    this.adherencePct,
  });

  factory CareSummary.fromJson(Map<String, dynamic> j) => CareSummary(
        total: _num(j['total'])?.toInt() ?? 0,
        done: _num(j['done'])?.toInt() ?? 0,
        pending: _num(j['pending'])?.toInt() ?? 0,
        missed: _num(j['missed'])?.toInt() ?? 0,
        skipped: _num(j['skipped'])?.toInt() ?? 0,
        outOfRange: _num(j['out_of_range'])?.toInt() ?? 0,
        adherencePct: _num(j['adherence_pct'])?.toInt(),
      );

  final int total;
  final int done;
  final int pending;
  final int missed;
  final int skipped;
  final int outOfRange;
  final int? adherencePct;
}

class CareReportMeal {
  CareReportMeal({required this.meal, this.description = '', this.quantity});
  factory CareReportMeal.fromJson(Map<String, dynamic> j) => CareReportMeal(
        meal: '${j['meal'] ?? ''}',
        description: '${j['description'] ?? ''}',
        quantity: _str(j['quantity']),
      );
  String meal;
  String description;
  String? quantity;

  Map<String, dynamic> toJson() => {'meal': meal, 'description': description, 'quantity': ?quantity};
}

/// The caretaker's end-of-day report.
class CareReport {
  const CareReport({
    this.meals = const [],
    this.fluidIntakeMl,
    this.sleep,
    this.mood,
    this.hygiene = const {},
    this.notes,
    this.photoFileIds = const [],
    this.updatedAt,
  });

  factory CareReport.fromJson(Map<String, dynamic> j) => CareReport(
        meals: [for (final m in _maps(j['meals'])) CareReportMeal.fromJson(m)],
        fluidIntakeMl: _num(j['fluid_intake_ml'])?.toInt(),
        sleep: _str(j['sleep']),
        mood: _str(j['mood']),
        hygiene: _map(j['hygiene']),
        notes: _str(j['notes']),
        photoFileIds: _strings(j['photo_file_ids']),
        updatedAt: DateTime.tryParse('${j['updated_at'] ?? ''}')?.toLocal(),
      );

  final List<CareReportMeal> meals;
  final int? fluidIntakeMl;
  final String? sleep;
  final String? mood;
  final Map<String, dynamic> hygiene;
  final String? notes;
  final List<String> photoFileIds;
  final DateTime? updatedAt;
}

/// `GET /care/placements/:pid/day`.
class CareDay {
  const CareDay({
    required this.date,
    this.summary = const CareSummary(),
    this.tasks = const [],
    this.report,
    this.planVersion,
  });

  factory CareDay.fromJson(Map<String, dynamic> j) => CareDay(
        date: '${j['date'] ?? ''}',
        planVersion: _num(j['plan_version'])?.toInt(),
        summary: CareSummary.fromJson(_map(j['summary'])),
        tasks: [for (final t in _maps(j['tasks'])) CareTask.fromJson(t)],
        report: j['report'] is Map<String, dynamic> ? CareReport.fromJson(j['report'] as Map<String, dynamic>) : null,
      );

  final String date;
  final int? planVersion;
  final CareSummary summary;
  final List<CareTask> tasks;
  final CareReport? report;
}

class CareHistoryDay {
  const CareHistoryDay({required this.date, this.total = 0, this.done = 0, this.missed = 0, this.skipped = 0, this.adherencePct});
  final String date;
  final int total;
  final int done;
  final int missed;
  final int skipped;
  final int? adherencePct;
}

class CareReading {
  const CareReading({required this.date, required this.time, required this.title, this.value = const {}, this.outOfRange = false});
  final String date;
  final String time;
  final String title;
  final Map<String, dynamic> value;
  final bool outOfRange;

  /// The number to chart (systolic for BP).
  num? get chartValue => _num(value['systolic'] ?? value['value']);
  String get text => value['systolic'] != null
      ? '${value['systolic']}/${value['diastolic']} ${value['unit'] ?? 'mmHg'}'
      : '${value['value'] ?? ''} ${value['unit'] ?? ''}'.trim();
}

/// `GET /care/placements/:pid/history`.
class CareHistory {
  const CareHistory({
    required this.from,
    required this.to,
    this.medicationAdherencePct,
    this.missedDoses = 0,
    this.days = const [],
    this.vitals = const [],
  });

  factory CareHistory.fromJson(Map<String, dynamic> j) => CareHistory(
        from: '${j['from'] ?? ''}',
        to: '${j['to'] ?? ''}',
        medicationAdherencePct: _num(j['medication_adherence_pct'])?.toInt(),
        missedDoses: _num(j['missed_doses'])?.toInt() ?? 0,
        days: [
          for (final d in _maps(j['days']))
            CareHistoryDay(
              date: '${d['date'] ?? ''}',
              total: _num(d['total'])?.toInt() ?? 0,
              done: _num(d['done'])?.toInt() ?? 0,
              missed: _num(d['missed'])?.toInt() ?? 0,
              skipped: _num(d['skipped'])?.toInt() ?? 0,
              adherencePct: _num(d['adherence_pct'])?.toInt(),
            ),
        ],
        vitals: [
          for (final v in _maps(j['vitals']))
            CareReading(
              date: '${v['date'] ?? ''}',
              time: '${v['time'] ?? ''}',
              title: '${v['title'] ?? ''}',
              value: _map(v['value']),
              outOfRange: v['out_of_range'] == true,
            ),
        ],
      );

  final String from;
  final String to;
  final int? medicationAdherencePct;
  final int missedDoses;
  final List<CareHistoryDay> days;
  final List<CareReading> vitals;
}

// ── Staff side ────────────────────────────────────────────────────────────

/// One placement in `GET /staff/care/today`.
class StaffCarePlacement {
  const StaffCarePlacement({
    required this.placementId,
    required this.clientName,
    this.clientAddress,
    this.planId,
    this.planVersion,
    this.planAcknowledged = true,
    this.planChanges = const [],
    this.summary = const CareSummary(),
    this.tasks = const [],
    this.report,
  });

  factory StaffCarePlacement.fromJson(Map<String, dynamic> j) {
    final plan = _map(j['plan']);
    final client = _map(j['client']);
    return StaffCarePlacement(
      placementId: '${j['placement_id'] ?? ''}',
      clientName: _str(client['name']) ?? 'Family',
      clientAddress: _str(client['address']),
      planId: _str(plan['id']),
      planVersion: _num(plan['version'])?.toInt(),
      planAcknowledged: plan.isEmpty || plan['acknowledged'] == true,
      planChanges: CareChange.list(plan['changes']),
      summary: CareSummary.fromJson(_map(j['summary'])),
      tasks: [for (final t in _maps(j['tasks'])) CareTask.fromJson(t)],
      report: j['report'] is Map<String, dynamic> ? CareReport.fromJson(j['report'] as Map<String, dynamic>) : null,
    );
  }

  final String placementId;
  final String clientName;
  final String? clientAddress;

  /// Active plan id — what "Mark as read" acknowledges (type CARE_PLAN).
  final String? planId;
  final int? planVersion;
  final bool planAcknowledged;
  final List<CareChange> planChanges;
  final CareSummary summary;
  final List<CareTask> tasks;
  final CareReport? report;

  bool get hasPlan => planId != null;
}

class StaffCareToday {
  const StaffCareToday({required this.date, this.placements = const []});
  factory StaffCareToday.fromJson(Map<String, dynamic> j) => StaffCareToday(
        date: '${j['date'] ?? ''}',
        placements: [for (final p in _maps(j['placements'])) StaffCarePlacement.fromJson(p)],
      );
  final String date;
  final List<StaffCarePlacement> placements;
}

/// `POST /care-files` result.
class CareFile {
  const CareFile({required this.id, required this.kind, this.mimeType, this.name});
  factory CareFile.fromJson(Map<String, dynamic> j) => CareFile(
        id: '${j['id'] ?? ''}',
        kind: '${j['kind'] ?? ''}',
        mimeType: _str(j['mime_type']),
        name: _str(j['name']),
      );
  final String id;
  final String kind;
  final String? mimeType;
  final String? name;
}
