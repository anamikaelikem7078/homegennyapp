// Fake API answers for test/user_flow_walkthrough_test.dart — the endpoints
// the dummy data sources don't cover. One consistent household story:
//
//  • Client: the Demo Client household (New Delhi).
//  • Rajesh Kumar — cook, placement PLC-001 (confirmed).
//  • Asha Kumari — caretaker for the client's mother, placement PLC-002.
//  • A cook request (REQ-1) with three shortlisted candidates waiting for
//    the client's choice, a caretaker request the RM is working on, and a
//    fulfilled one.
//  • RM pipeline: staff at every stage; stf-101 Sunita Devi is at S5 Deploy
//    and is the one the RM places.
import 'package:dio/dio.dart';

String _d(int daysFromToday) {
  final d = DateTime.now().add(Duration(days: daysFromToday));
  return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
}

String _ago({int days = 0, int hours = 0, int minutes = 0}) => DateTime.now()
    .subtract(Duration(days: days, hours: hours, minutes: minutes))
    .toUtc()
    .toIso8601String();

Map<String, Object?> _staffRow(
  String id,
  String code,
  String name,
  String series,
  String stage, {
  String mobile = '98xxxxxx10',
}) => {
  'id': id,
  'staff_code': code,
  'full_name': name,
  'series': series,
  'series_db': switch (series) {
    'UC' => 'UNSKILLED_CARE',
    'SC' => 'SKILLED_CARE',
    _ => 'COOK',
  },
  'pipeline_stage': stage,
  'mobile': mobile,
  'language_tier': 'HINDI',
  'address': 'Lajpat Nagar, New Delhi',
  'pv_status': switch (stage) {
    'S1_INTAKE' => 'NOT_INITIATED',
    'S2_VERIFY' => 'IN_PROGRESS',
    _ => 'CLEAR',
  },
  'created_at': _ago(days: 20),
  'updated_at': _ago(days: 1),
};

final _pipeline = {
  'S1_INTAKE': [
    _staffRow('stf-201', 'CK-0231', 'Kavita Yadav', 'CK', 'S1_INTAKE'),
    _staffRow('stf-202', 'UC-0412', 'Ramesh Pal', 'UC', 'S1_INTAKE'),
  ],
  'S2_VERIFY': [
    _staffRow('stf-203', 'SC-0118', 'Meena Kumari', 'SC', 'S2_VERIFY'),
    _staffRow('stf-204', 'CK-0229', 'Anil Verma', 'CK', 'S2_VERIFY'),
  ],
  'S3_TRAIN': [_staffRow('stf-205', 'UC-0407', 'Ravi Kumar', 'UC', 'S3_TRAIN')],
  'S4_AGREEMENTS': [
    _staffRow('stf-206', 'CK-0226', 'Pooja Singh', 'CK', 'S4_AGREEMENTS'),
  ],
  'S5_DEPLOY': [
    _staffRow('stf-101', 'CK-0219', 'Sunita Devi', 'CK', 'S5_DEPLOY'),
    _staffRow('staff002', 'UC-0398', 'Asha Kumari', 'UC', 'S5_DEPLOY'),
  ],
};

Map<String, Object?> _candidate(
  String id,
  String staffId,
  String first,
  num years,
  String note, {
  String status = 'PROPOSED',
}) => {
  'candidate_id': id,
  'status': status,
  'rm_note': note,
  'staff': {
    'id': staffId,
    'first_name': first,
    'series': 'CK',
    'language_tier': 'HINDI',
    'gender': 'FEMALE',
    'experience_years': years,
    'aadhaar_verified': true,
    'police_verified': true,
  },
};

final _cookRequest = {
  'id': 'req-1',
  'request_no': 'REQ-2026-0142',
  'status': 'SHORTLISTED',
  'series': 'CK',
  'series_db': 'COOK',
  'placement_type': 'PERMANENT',
  'visit_type': 'REGULAR',
  'shift_hours': 4,
  'headcount': 1,
  'gender_pref': 'FEMALE',
  'start_date': _d(5),
  'start_time': '08:00',
  'address': '42, Green Park Extension, New Delhi - 110016',
  'language': 'Hindi',
  'notes': 'Vegetarian North Indian food, family of four.',
  'created_at': _ago(days: 3),
  'shortlisted': 3,
  'rm': {'name': 'Demo RM', 'phone': '9800000001'},
  'candidates': [
    _candidate(
      'cand-1',
      'stf-101',
      'Sunita',
      6,
      'Very good with North Indian vegetarian food.',
    ),
    _candidate(
      'cand-2',
      'stf-206',
      'Pooja',
      3,
      'Can also cook South Indian breakfast.',
    ),
    _candidate(
      'cand-3',
      'stf-207',
      'Lakshmi',
      9,
      'Has cooked for a family of six before.',
    ),
  ],
};

final _careRequest = {
  'id': 'req-2',
  'request_no': 'REQ-2026-0150',
  'status': 'ASSIGNED',
  'series': 'SC',
  'series_db': 'SKILLED_CARE',
  'placement_type': 'PERMANENT',
  'visit_type': 'REGULAR',
  'shift_hours': 24, // 24×7 live-in
  'headcount': 1,
  'gender_pref': 'ANY',
  'start_date': _d(10),
  'start_time': '09:00',
  'address': '42, Green Park Extension, New Delhi - 110016',
  'notes': 'Round-the-clock care for my father after surgery.',
  'created_at': _ago(days: 1),
  'rm': {'name': 'Demo RM', 'phone': '9800000001'},
};

final _fulfilledRequest = {
  'id': 'req-3',
  'request_no': 'REQ-2026-0098',
  'status': 'FULFILLED',
  'series': 'UC',
  'series_db': 'UNSKILLED_CARE',
  'placement_type': 'PERMANENT',
  'visit_type': 'REGULAR',
  'shift_hours': 8,
  'headcount': 1,
  'gender_pref': 'FEMALE',
  'start_date': _d(-40),
  'start_time': '09:00',
  'created_at': _ago(days: 50),
  'selected': 1,
};

final _carePlan = {
  'id': 'plan-1',
  'version': 2,
  'patient': {
    'name': 'Kamla Devi',
    'age': 78,
    'gender': 'FEMALE',
    'conditions': ['Diabetes', 'Knee pain'],
    'allergies': ['Penicillin'],
    'mobility': 'ASSISTED',
    'doctor_name': 'Dr. Mehra',
    'doctor_phone': '9811000000',
    'emergency_contact_name': 'Demo Client',
    'emergency_contact_phone': '9800000004',
  },
  'medications': [
    {
      'id': 'm1',
      'name': 'Metformin',
      'dose': '500',
      'unit': 'mg',
      'route': 'ORAL',
      'times': ['08:00', '20:00'],
      'food_relation': 'AFTER',
    },
  ],
  'vitals': <Object>[],
  'activities': [
    {
      'id': 'a1',
      'type': 'WALK',
      'title': 'Evening walk in the park',
      'times': ['17:30'],
      'duration_min': 20,
    },
    {
      'id': 'a2',
      'type': 'BATH',
      'title': 'Help with bath',
      'times': ['09:30'],
    },
  ],
  'diet_notes': 'Low sugar. Soft food at night.',
  'dos': 'Keep water within reach. Talk to her during meals.',
  'donts': 'Do not leave her alone on the stairs.',
};

List<Map<String, Object?>> _careTasks() => [
  {
    'id': 't1',
    'date': _d(0),
    'type': 'MEDICATION',
    'item_id': 'm1',
    'title': 'Metformin 500 mg',
    'time': '08:00',
    'status': 'DONE',
    'done_at': _ago(hours: 3),
  },
  {
    'id': 't2',
    'date': _d(0),
    'type': 'ACTIVITY',
    'item_id': 'a2',
    'title': 'Help with bath',
    'time': '09:30',
    'status': 'DONE',
    'done_at': _ago(hours: 2),
  },
  {
    'id': 't3',
    'date': _d(0),
    'type': 'ACTIVITY',
    'item_id': 'a1',
    'title': 'Evening walk in the park',
    'time': '17:30',
    'status': 'PENDING',
  },
  {
    'id': 't4',
    'date': _d(0),
    'type': 'MEDICATION',
    'item_id': 'm1',
    'title': 'Metformin 500 mg',
    'time': '20:00',
    'status': 'PENDING',
  },
];

const _careSummary = {
  'total': 4,
  'done': 2,
  'pending': 2,
  'missed': 0,
  'skipped': 0,
  'adherence_pct': 100,
};

final _foodProfile = {
  'id': 'fp-1',
  'version': 1,
  'diet_type': 'VEG',
  'allergies': ['Peanuts'],
  'spice_level': 2,
  'salt': 'NORMAL',
  'oil': 'LOW',
  'health_conditions': ['DIABETIC'],
  'cuisines': ['North Indian'],
  'dislikes': 'Bitter gourd',
  'family_size': 4,
};

List<Map<String, Object?>> _menuItems() => [
  for (var i = 0; i < 3; i++) ...[
    {
      'id': 'menu-${i}b',
      'date': _d(i),
      'meal': 'BREAKFAST',
      'status': i == 1 ? 'SUGGESTED' : 'APPROVED',
      'suggested_by_cook': i == 1,
      'dishes': [
        {'name': i == 1 ? 'Poha' : 'Aloo paratha'},
        {'name': 'Curd'},
      ],
    },
    {
      'id': 'menu-${i}l',
      'date': _d(i),
      'meal': 'LUNCH',
      'status': 'APPROVED',
      'dishes': [
        {'name': 'Dal tadka'},
        {'name': 'Jeera rice'},
        {'name': 'Bhindi sabzi'},
        {'name': 'Roti'},
      ],
    },
    {
      'id': 'menu-${i}d',
      'date': _d(i),
      'meal': 'DINNER',
      'status': i == 1 ? 'SUGGESTED' : 'PLANNED',
      'suggested_by_cook': i == 1,
      'dishes': [
        {'name': 'Paneer butter masala'},
        {'name': 'Roti'},
      ],
    },
  ],
];

Map<String, Object?> _meal(
  String id,
  int daysAgo,
  String meal,
  List<String> dishes,
  int? rating,
) => {
  'id': id,
  'date': _d(-daysAgo),
  'meal': meal,
  'dishes': [
    for (final d in dishes) {'name': d, 'spice_level': 2},
  ],
  'servings': 4,
  'cooked_at': _ago(days: daysAgo, hours: 1),
  if (rating != null)
    'feedback': {
      'rating': rating,
      'tags': rating >= 4 ? ['TASTY'] : ['TOO_SALTY'],
      'comment': rating >= 4 ? 'Lovely, just like home.' : null,
    },
};

List<Map<String, Object?>> _meals() => [
  _meal('meal-1', 0, 'BREAKFAST', ['Aloo paratha', 'Curd'], null),
  _meal('meal-2', 1, 'DINNER', ['Paneer butter masala', 'Roti'], 5),
  _meal('meal-3', 1, 'LUNCH', ['Rajma', 'Rice'], 4),
  _meal('meal-4', 2, 'LUNCH', ['Chole', 'Rice'], 3),
];

const _rating = {'avg_7d': 4.3, 'count_7d': 9, 'avg_30d': 4.4, 'count_30d': 38};

List<Map<String, Object?>> _instructions() => [
  {
    'id': 'ins-1',
    'placement_id': 'PLC-002',
    'kind': 'ONE_TIME',
    'status': 'SENT',
    'text': 'Please give Maa her eye drops after lunch today.',
    'created_at': _ago(minutes: 40),
    'client_name': 'Demo Client',
  },
  {
    'id': 'ins-2',
    'placement_id': 'PLC-002',
    'kind': 'RECURRING',
    'status': 'ACKNOWLEDGED',
    'text': 'Make her walk for 10 minutes after dinner.',
    'recurrence': {
      'times': ['21:00'],
      'days': ['MON', 'TUE', 'WED', 'THU', 'FRI', 'SAT', 'SUN'],
    },
    'acknowledged_at': _ago(days: 2),
    'created_at': _ago(days: 3),
    'client_name': 'Demo Client',
  },
  {
    'id': 'ins-3',
    'placement_id': 'PLC-002',
    'kind': 'ONE_TIME',
    'status': 'DONE',
    'text': 'Change the bed sheets.',
    'done_at': _ago(days: 1),
    'created_at': _ago(days: 1, hours: 4),
    'client_name': 'Demo Client',
  },
];

Map<String, Object?> _snapshotStaff({
  required String placementId,
  required String staffId,
  required String firstName,
  required String series,
  required String seriesLabel,
  required String status,
  required String message,
  required Map<String, Object?> today,
}) => {
  'placement_id': placementId,
  'staff': {
    'id': staffId,
    'first_name': firstName,
    'series': series,
    'series_label': seriesLabel,
  },
  'deployment': {
    'type': 'PERMANENT',
    'visit': 'REGULAR',
    'status': 'CONFIRMED',
    'since': _d(-60),
    'shift_start': '08:00',
    'shift_hours': 8,
  },
  'today': today,
  'status_today': status,
  'message': message,
  'last_7_days': [
    for (var i = 6; i >= 0; i--)
      {'date': _d(-i), 'attendance': i == 3 ? 'ABSENT' : 'PRESENT'},
  ],
};

final _invoicePreview = {
  'placement_id': 'PLC-001',
  'staff_id': 'stf-101',
  'staff_code': 'CK-0219',
  'staff_name': 'Sunita Devi',
  'period_month': DateTime.now().month,
  'period_year': DateTime.now().year,
  'monthly_salary': 18000,
  'monthly_management_fee': 3000,
  'present_days': 24,
  'absent_days': 1,
  'leave_days': 1,
  'overtime_days': 0,
  'billable_days': 25,
  'days_in_month': 31,
  'prorated_gross': 14516,
  'prorated_management_fee': 2419,
  'calculation': {
    'grossSalary': 14516,
    'esicEmployee': 109,
    'esicEmployer': 472,
    'pfEmployee': 1742,
    'pfEmployer': 1742,
    'netSalary': 12665,
    'managementFee': 2419,
    'gstOnFee': 435,
    'clientTotalCharge': 19584,
  },
};

/// `METHOD /path` regex → body (or a function of the request).
final Map<String, Object> fakeBackendFixtures = {
  // ── Sign-up of a new number (the demo numbers never reach these) ──
  // 9811100001 is an office (RM) account: it signs in with a password.
  'POST /auth/otp/send': (RequestOptions o) {
    final phone = o.data is Map ? (o.data as Map)['phone'] : null;
    return phone == '9811100001'
        ? {
            'sent': false,
            'is_registered': true,
            'use_password_login': true,
            'role': 'RM',
          }
        : {'sent': true, 'is_registered': false};
  },
  'POST /auth/login': (RequestOptions o) {
    final body = o.data is Map ? o.data as Map : const {};
    if (body['password'] != 'Office@123') {
      throw const _HttpError(401, 'Invalid phone number or password');
    }
    return {
      'access_token': 'demo-access-token',
      'refresh_token': 'demo-refresh-token',
      'user': {
        'id': 'rm-office-1',
        'name': 'Office RM',
        'phone': '9811100001',
        'role': 'RM',
      },
    };
  },
  'GET /user/profile': {
    'id': 'rm-office-1',
    'name': 'Office RM',
    'phone': '9811100001',
    'role': 'RM',
  },
  'POST /auth/otp/verify': (RequestOptions o) {
    final body = o.data is Map ? o.data as Map : const {};
    return {
      'access_token': 'demo-access-token',
      'refresh_token': 'demo-refresh-token',
      'is_new_user': true,
      'user': {
        'id': 'new-user-1',
        'name': '',
        'phone': body['phone'],
        'role': body['role'] ?? 'CLIENT',
      },
    };
  },

  // ── Client ──
  'GET /client/snapshot': () => {
    'date': _d(0),
    'generated_at': _ago(minutes: 1),
    'staff': [
      _snapshotStaff(
        placementId: 'PLC-001',
        staffId: 'staff001',
        firstName: 'Rajesh',
        series: 'CK',
        seriesLabel: 'Cook',
        status: 'GREEN',
        message: 'Breakfast served. Lunch next at 1:00 PM.',
        today: {
          'attendance': 'PRESENT',
          'check_in': _ago(hours: 2, minutes: 30),
          'meals': {
            'planned': 3,
            'logged': 1,
            'due': 1,
            'not_logged': <String>[],
          },
        },
      ),
      _snapshotStaff(
        placementId: 'PLC-002',
        staffId: 'staff002',
        firstName: 'Asha',
        series: 'UC',
        seriesLabel: 'Caretaker',
        status: 'AMBER',
        message: 'Running 20 min late today.',
        today: {
          'attendance': 'NOT_STARTED',
          'late_by_min': 20,
          'work': {
            'done': 2,
            'total': 4,
            'missed': 0,
            'next': 'Evening walk at 5:30 PM',
          },
          'unread_instructions': 1,
        },
      ),
    ],
    'requests': [
      {
        'id': 'req-1',
        'request_no': 'REQ-2026-0142',
        'series': 'CK',
        'status': 'SHORTLISTED',
        'visit_type': 'REGULAR',
        'start_date': _d(5),
      },
    ],
    'replacements': <Object>[],
  },
  'GET /client/staff-requests': () => {
    'items': [_cookRequest, _careRequest, _fulfilledRequest],
  },
  'GET /client/staff-requests/req-1': () => _cookRequest,
  'GET /client/staff-requests/req-2': () => _careRequest,
  'GET /client/staff-requests/req-3': () => _fulfilledRequest,
  'GET /client/staff-requests/req-4': () => {
    ..._careRequest,
    'id': 'req-4',
    'status': 'NEW',
    'request_no': 'REQ-2026-0161',
    'series': 'UC',
    'series_db': 'UNSKILLED_CARE',
  },
  'POST /client/staff-requests': () => {
    ..._careRequest,
    'id': 'req-4',
    'status': 'NEW',
    'request_no': 'REQ-2026-0161',
    'series': 'UC',
    'series_db': 'UNSKILLED_CARE',
  },
  'POST /client/staff-requests/[^/]+/(select|reject-shortlist|cancel)': {
    'ok': true,
  },
  'GET /client/invoices/[^/]+': () => {
    'id': 'HG-INV-2407-001',
    'documentType': 'TAX_INVOICE',
    'billingMonth':
        '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}',
    'periodFrom': _d(-30),
    'periodTo': _d(-1),
    'status': 'PENDING',
    'dueDate': _d(7),
    'placeOfSupply': 'Delhi',
    'sacCode': '998513',
    // Matches the ₹18,540 the dummy invoice list shows.
    'staffCount': 1,
    'serviceLines': [
      {
        'strength': 1,
        'description': 'Cook — Rajesh Kumar (salary)',
        'amount': 15000,
      },
      {
        'strength': 1,
        'description': 'HomeGenny management fee',
        'amount': 3000,
      },
    ],
    'taxableValue': 18000,
    'cgst': 270,
    'sgst': 270,
    'igst': 0,
    'gstAmount': 540,
    'totalAmount': 18540,
    'amountPaid': 0,
    'amountDue': 18540,
  },
  'GET /client/food-profile': () => {
    'profile': _foodProfile,
    'feedback_suggestions': [
      {
        'tag': 'TOO_SALTY',
        'times': 2,
        'suggestion': 'Ask the cook to use less salt.',
      },
    ],
  },
  'GET /care/placements/[^/]+/plan': () => {
    'placement_id': 'PLC-002',
    'plan': _carePlan,
    'staff': {'name': 'Asha Kumari', 'series': 'UNSKILLED_CARE'},
    'staff_acknowledged_at': _ago(days: 2),
    'versions': [
      {
        'version': 2,
        'status': 'ACTIVE',
        'created_at': _ago(days: 3),
        'changes': [
          {'type': 'ADDED', 'text': 'Evening walk added'},
        ],
      },
      {'version': 1, 'status': 'SUPERSEDED', 'created_at': _ago(days: 30)},
    ],
  },
  'GET /care/placements/[^/]+/day': () => {
    'date': _d(0),
    'plan_version': 2,
    'summary': _careSummary,
    'tasks': _careTasks(),
  },
  'GET /care/placements/[^/]+/history': () => {
    'from': _d(-6),
    'to': _d(0),
    'medication_adherence_pct': 96,
    'missed_doses': 1,
    'days': [
      for (var i = 6; i >= 0; i--)
        {
          'date': _d(-i),
          'total': 4,
          'done': i == 4 ? 3 : 4,
          'missed': i == 4 ? 1 : 0,
          'skipped': 0,
          'adherence_pct': i == 4 ? 75 : 100,
        },
    ],
  },
  'GET /care/placements/[^/]+/menu': () => {
    'week_start': _d(0),
    'week_end': _d(6),
    'items': _menuItems(),
  },
  'GET /care/placements/[^/]+/meals': () => {
    'items': _meals(),
    'rating': _rating,
  },
  'GET /care/placements/[^/]+/instructions': () => {'items': _instructions()},
  'GET /care/placements/[^/]+/food-profile': () => {'profile': _foodProfile},
  'GET /care/dishes': () => {
    'items': [
      for (final n in [
        'Dal tadka',
        'Aloo gobi',
        'Paneer bhurji',
        'Poha',
        'Upma',
        'Rajma',
      ])
        {
          'id': n,
          'name': n,
          'diet': 'VEG',
          'meals': ['LUNCH', 'DINNER'],
        },
    ],
    'can_add': true,
  },
  'POST /client/(menu|meals|instructions)/.*': {'ok': true},
  'POST /care/placements/[^/]+/instructions': () => _instructions().first,

  // ── Staff ──
  'GET /staff/care/today': () => {
    'date': _d(0),
    'placements': [
      {
        'placement_id': 'PLC-002',
        'client': {
          'name': 'Demo Client',
          'address': '42, Green Park Extension, New Delhi',
        },
        'plan': {'id': 'plan-1', 'version': 2, 'acknowledged': true},
        'summary': _careSummary,
        'tasks': _careTasks(),
      },
    ],
  },
  'GET /staff/care/cook/today': () => {
    'date': _d(0),
    'placements': [
      {
        'placement_id': 'PLC-001',
        'client': {
          'name': 'Demo Client',
          'address': '42, Green Park Extension, New Delhi',
        },
        'food_profile': _foodProfile,
        'meals': [
          {'meal': 'BREAKFAST', 'menu': _menuItems()[0], 'log': _meals()[0]},
          {'meal': 'LUNCH', 'menu': _menuItems()[1]},
          {'meal': 'DINNER', 'menu': _menuItems()[2]},
        ],
        'rating': _rating,
      },
    ],
  },
  'GET /staff/care/instructions': () => {'items': _instructions()},
  'GET /staff/care/client-updates/unread-count': {'unread': 2},
  'GET /staff/care/client-updates': () => {
    'unread': 2,
    'items': [
      {
        'type': 'INSTRUCTION',
        'id': 'ins-1',
        'placement_id': 'PLC-002',
        'title': 'New instruction',
        'client_name': 'Demo Client',
        'changes': ['Please give Maa her eye drops after lunch today.'],
        'at': _ago(minutes: 40),
      },
      {
        'type': 'CARE_PLAN',
        'id': 'plan-1',
        'version': 2,
        'placement_id': 'PLC-002',
        'title': 'Care plan updated',
        'client_name': 'Demo Client',
        'changes': ['Evening walk added'],
        'at': _ago(days: 3),
        'seen_at': _ago(days: 2),
      },
    ],
  },
  'POST /staff/care/.*': {'ok': true},
  'PUT /staff/care/.*': {'ok': true},

  // ── RM ──
  'GET /rm/dashboard': {
    'kpis': {
      'total_staff': 48,
      'active_pipeline': 9,
      'pending_verification': 2,
      'pending_video': 1,
      'trial_placements': 2,
      'active_placements': 31,
      'training_queue': 1,
      'deployment_queue': 2,
      'deferred_cases': 1,
      'monthly_placements': 6,
      'open_incidents': 2,
      'pending_shifts': 3,
    },
    'funnel': [
      {'stage': 'S1_INTAKE', 'count': 2},
      {'stage': 'S2_VERIFY', 'count': 2},
      {'stage': 'S3_TRAIN', 'count': 1},
      {'stage': 'S4_AGREEMENTS', 'count': 1},
      {'stage': 'S5_DEPLOY', 'count': 2},
    ],
    'series_distribution': [
      {'series': 'CK', 'count': 21},
      {'series': 'UC', 'count': 17},
      {'series': 'SC', 'count': 10},
    ],
  },
  'GET /rm/kanban': {'columns': _pipeline, 'total': 8},
  'GET /rm/requests': () => {
    'items': [
      {
        'id': 'su-1',
        'type': 'STAFF',
        'name': 'Geeta Rani',
        'phone': '9876500011',
        'series': 'CK',
        'pipeline_stage': 'S1_INTAKE',
        'city': 'New Delhi',
        'created_at': _ago(hours: 2),
      },
      {
        'id': 'su-2',
        'type': 'CLIENT',
        'name': 'Arjun Malhotra',
        'phone': '9876500022',
        'email': 'arjun@example.com',
        'city': 'Gurugram',
        'created_at': _ago(hours: 5),
      },
      {
        'id': 'su-3',
        'type': 'STAFF',
        'name': 'Mohan Lal',
        'phone': '9876500033',
        'series': 'UC',
        'pipeline_stage': 'S1_INTAKE',
        'city': 'Noida',
        'created_at': _ago(days: 1),
      },
    ],
  },
  'POST /rm/requests/.*/accept': {'ok': true},
  'GET /rm/trials': () => {
    'items': [
      {
        'id': 'plc-1',
        'staff_id': 'stf-101',
        'client_id': 'client-demo-1',
        'branch_id': 'br-1',
        'status': 'TRIAL',
        'trial_start_date': _d(-2),
        'trial_end_date': _d(5),
        'created_at': _ago(days: 2),
      },
    ],
  },
  'GET /rm/deferred': () => {
    'items': [
      {
        'id': 'def-1',
        'staff_id': 'stf-208',
        'reason': 'Family emergency',
        'deferred_at': _ago(days: 6),
        'resume_at': _ago(days: -8),
        'resume_stage': 'S3_TRAIN',
        'staff': {
          'id': 'stf-208',
          'staff_code': 'UC-0401',
          'full_name': 'Deepa Rawat',
          'series': 'UC',
        },
      },
    ],
  },
  'GET /rm/terminal': () => {
    'items': [
      {
        ..._staffRow('stf-209', 'CK-0201', 'Suresh Gupta', 'CK', 'TERMINAL'),
        'terminal_outcome': 'ABANDONED',
      },
    ],
  },
  'GET /rm/incidents': () => {
    'items': [
      {
        'id': 'inc-1',
        'staff_id': 'staff002',
        'client_id': 'client-demo-1',
        'placement_id': 'PLC-002',
        'type': 'CLIENT_COMPLAINT',
        'status': 'OPEN',
        'title': 'Arrived late three days in a row',
        'description':
            'Client says the caretaker came 30 minutes late on Mon, Tue and Wed.',
        'created_at': _ago(hours: 6),
        'staff': {'staff_code': 'UC-0398', 'full_name': 'Asha Kumari'},
      },
      {
        'id': 'inc-2',
        'staff_id': 'stf-101',
        'type': 'LATE_EXIT',
        'status': 'INVESTIGATING',
        'title': 'Left before shift end',
        'created_at': _ago(days: 2),
        'staff': {'staff_code': 'CK-0219', 'full_name': 'Sunita Devi'},
      },
      {
        'id': 'inc-3',
        'staff_id': 'staff001',
        'type': 'SAFETY',
        'status': 'RESOLVED',
        'title': 'Gas left on',
        'resolution': 'Retrained on kitchen safety.',
        'created_at': _ago(days: 12),
        'staff': {'staff_code': 'CK-0188', 'full_name': 'Rajesh Kumar'},
      },
    ],
  },
  'GET /rm/shifts': () => {
    'items': [
      {
        'id': 'sh-1',
        'staff_id': 'staff001',
        'placement_id': 'PLC-001',
        'shift_date': _d(0),
        'check_in_at': _ago(hours: 3),
        'status': 'PENDING',
        'staff': {
          'staff_code': 'CK-0188',
          'full_name': 'Rajesh Kumar',
          'series': 'CK',
        },
      },
      {
        'id': 'sh-2',
        'staff_id': 'staff002',
        'placement_id': 'PLC-002',
        'shift_date': _d(-1),
        'check_in_at': _ago(days: 1, hours: 10),
        'check_out_at': _ago(days: 1, hours: 2),
        'status': 'PENDING',
        'notes': 'Checked in 400 m from home',
        'staff': {
          'staff_code': 'UC-0398',
          'full_name': 'Asha Kumari',
          'series': 'UC',
        },
      },
      {
        'id': 'sh-3',
        'staff_id': 'stf-101',
        'shift_date': _d(-1),
        'check_in_at': _ago(days: 1, hours: 9),
        'check_out_at': _ago(days: 1, hours: 1),
        'status': 'APPROVED',
        'staff': {
          'staff_code': 'CK-0219',
          'full_name': 'Sunita Devi',
          'series': 'CK',
        },
      },
    ],
  },
  'POST /rm/shifts/.*/review': (RequestOptions o) => {
    'id': 'sh-1',
    'staff_id': 'staff001',
    'shift_date': _d(0),
    'status': 'APPROVED',
  },
  'GET /rm/upgrades': () => {
    'items': [
      {
        'id': 'up-1',
        'staff_id': 'staff002',
        'from_series': 'UC',
        'to_series': 'SC',
        'status': 'PENDING_APPROVAL',
        'eligibility_score': 82,
        'rm_recommendation': 'Excellent feedback from family for 8 months.',
        'created_at': _ago(days: 4),
        'staff': {
          'staff_code': 'UC-0398',
          'full_name': 'Asha Kumari',
          'series': 'UC',
        },
      },
    ],
  },
  'GET /rm/locations': {
    'cities': ['New Delhi', 'Gurugram', 'Noida'],
    'branches': [
      {'id': 'br-1', 'name': 'South Delhi', 'city': 'New Delhi'},
      {'id': 'br-2', 'name': 'Gurugram', 'city': 'Gurugram'},
    ],
    'areas': [
      {
        'city': 'New Delhi',
        'area': 'Green Park',
        'branch_code': 'SD',
        'branch_id': 'br-1',
        'label': 'Green Park, New Delhi',
      },
      {
        'city': 'New Delhi',
        'area': 'Lajpat Nagar',
        'branch_code': 'SD',
        'branch_id': 'br-1',
        'label': 'Lajpat Nagar, New Delhi',
      },
    ],
  },
  'GET /rm/attendance': () => {
    'month': DateTime.now().month,
    'year': DateTime.now().year,
    'branch_id': 'br-1',
    'staff': [
      for (final (id, code, name) in [
        ('stf-101', 'CK-0219', 'Sunita Devi'),
        ('staff001', 'CK-0188', 'Rajesh Kumar'),
        ('staff002', 'UC-0398', 'Asha Kumari'),
      ])
        {
          'staff_id': id,
          'staff_code': code,
          'full_name': name,
          'placement_id': 'PLC-001',
          'monthly_salary': 18000,
          'monthly_management_fee': 3000,
          'present_days': 24,
          'absent_days': 1,
          'leave_days': 1,
          'billable_days': 25,
          'days_in_month': 31,
          'prorated_gross': 14516,
          'daily_records': [
            for (var i = 1; i <= DateTime.now().day; i++)
              {
                'date':
                    '${DateTime.now().year}-${DateTime.now().month.toString().padLeft(2, '0')}-${i.toString().padLeft(2, '0')}',
                'status': i == 9
                    ? 'ABSENT'
                    : i == 17
                    ? 'LEAVE'
                    : 'PRESENT',
              },
          ],
        },
    ],
  },
  'GET /rm/attendance/[^/]+/invoice-preview': () => _invoicePreview,
  'POST /rm/attendance/[^/]+/generate-invoice': () => {
    'invoice_id': 'inv-77',
    'invoice_number': 'HG/2026/10/077',
    'payroll_id': 'pay-77',
    'preview': _invoicePreview,
    'calculation': _invoicePreview['calculation'],
  },
  // Meena (stf-203) is still at S2: some checks done, some in progress.
  'GET /verification/stf-203': {
    'tracks': [
      {'track': 'aadhaar', 'status': 'CLEAR'},
      {'track': 'dl', 'status': 'NOT_APPLICABLE'},
      {'track': 'echallan', 'status': 'NOT_APPLICABLE'},
      {'track': 'pv', 'status': 'IN_PROGRESS'},
      {'track': 'medical', 'status': 'NOT_INITIATED'},
    ],
    'all_required_clear': false,
  },
  'GET /verification/[^/]+': {
    'tracks': [
      {'track': 'aadhaar', 'status': 'CLEAR'},
      {'track': 'dl', 'status': 'NOT_APPLICABLE'},
      {'track': 'echallan', 'status': 'NOT_APPLICABLE'},
      {'track': 'pv', 'status': 'CLEAR'},
      {'track': 'medical', 'status': 'CLEAR'},
    ],
    'all_required_clear': true,
  },
  // Ravi (stf-205, at S3) has one video waiting for review.
  'GET /video-cert/list/[^/]+': (RequestOptions o) {
    final inTraining = o.uri.path.endsWith('stf-205');
    return {
      'items': [
        for (final (i, k) in ['intro', 'hygiene', 'kitchen_safety'].indexed)
          {
            'id': 'vc-$i',
            'staffId': inTraining ? 'stf-205' : 'stf-101',
            'promptKey': k,
            'videoUrl': 'videos/$k.mp4',
            'attemptNumber': 1,
            'reviewStatus': inTraining && i == 2 ? 'PENDING' : 'APPROVED',
            'createdAt': _ago(days: inTraining ? 1 : 8),
          },
      ],
    };
  },
  'GET /video-cert/prompts/.*': {
    'count': 3,
    'minDuration': 20,
    'prompts': [
      'Introduce yourself',
      'Show how you wash your hands',
      'Explain how you keep the kitchen safe',
    ],
  },
  // Pooja (stf-206, at S4) has been sent A1 but not signed yet.
  'GET /agreements': (RequestOptions o) => {
    'items': [
      if (o.queryParameters['staffId'] == 'stf-206')
        {
          'id': 'ag-2',
          'staff_id': 'stf-206',
          'type': 'A1',
          'status': 'SENT',
          'otp_verified': false,
          'created_at': _ago(days: 1),
        }
      else
        {
          'id': 'ag-1',
          'staff_id': 'stf-101',
          'type': 'A1',
          'status': 'SIGNED',
          'otp_verified': true,
          'created_at': _ago(days: 6),
        },
    ],
  },
  'GET /placements': () => {
    'items': [
      {
        'id': 'plc-1',
        'staff_id': 'stf-101',
        'client_id': 'client-demo-1',
        'status': 'TRIAL',
        'staff_salary': 18000,
        'management_fee': 3000,
        'trial_start_date': _d(-2),
        'trial_end_date': _d(5),
        'created_at': _ago(days: 2),
        'staff_code': 'CK-0219',
        'series': 'CK',
      },
    ],
  },
  'GET /sow': () => {'items': <Object>[]},
  'GET /indemnity': () => {'items': <Object>[]},
  'GET /finance/customers': () => {
    'items': [
      {
        'id': 'client-demo-1',
        'customer_name': 'Demo Client',
        'address': '42, Green Park Extension',
        'city': 'New Delhi',
        'state': 'Delhi',
        'pincode': '110016',
        'status': 'ACTIVE',
      },
    ],
  },
  'GET /meta/cities': {
    'cities': [
      {'city': 'New Delhi', 'state': 'Delhi'},
      {'city': 'Gurugram', 'state': 'Haryana'},
      {'city': 'Noida', 'state': 'Uttar Pradesh'},
    ],
  },
};

/// Thrown by a fixture to answer with an HTTP error instead of 200.
class _HttpError implements Exception {
  const _HttpError(this.status, this.message);
  final int status;
  final String message;
}

/// The status and body a fixture's [_HttpError] stands for.
(int, Map<String, Object?>)? fakeBackendError(Object error) =>
    error is _HttpError
    ? (
        error.status,
        {
          'statusCode': error.status,
          'message': {'message': error.message, 'statusCode': error.status},
        },
      )
    : null;
