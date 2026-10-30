import '../../domain/models/client_models.dart';

abstract final class ClientDtoCodec {
  // ── Dashboard ── (flat shape, matches GET /client/dashboard exactly)
  static Map<String, dynamic> encodeDashboard(ClientDashboardData d) => {
        'customerName': d.clientName,
        'activePlacementsCount': d.activePlacementsCount,
        'todayAttendanceStatus': d.todayAttendanceStatus,
        'pendingInvoicesCount': d.pendingInvoicesCount,
        'totalUnpaidAmount': d.totalUnpaidAmount,
      };

  static ClientDashboardData decodeDashboard(Map<String, dynamic> json) =>
      ClientDashboardData(
        clientName: json['customerName'] as String? ?? '',
        activePlacementsCount: json['activePlacementsCount'] as int? ?? 0,
        todayAttendanceStatus:
            json['todayAttendanceStatus'] as String? ?? 'NOT_CHECKED_IN',
        pendingInvoicesCount: json['pendingInvoicesCount'] as int? ?? 0,
        totalUnpaidAmount: (json['totalUnpaidAmount'] as num?)?.toDouble() ?? 0,
      );

  // ── Profile ── (matches GET /client/profile exactly, incl. the 3
  // hardcoded-snake_case-in-source payment fields, always null server-side)
  static Map<String, dynamic> encodeProfile(ClientProfile p) => {
        'name': p.name, 'email': p.email, 'phone': p.phone,
        'address': p.address, 'city': p.city, 'pincode': p.pincode,
        'payment_method': p.paymentMethod, 'account_last4': p.accountLast4,
        'upi_id': p.upiId,
        'lat': p.lat, 'lng': p.lng,
        'profile_complete': p.profileComplete,
        'profile_missing': p.profileMissing,
        'assignedRm': p.assignedRmName == null
            ? null
            : {'name': p.assignedRmName, 'phone': p.assignedRmPhone},
      };

  static ClientProfile decodeProfile(Map<String, dynamic> json) {
    final rm = json['assignedRm'] as Map<String, dynamic>?;
    return ClientProfile(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        pincode: json['pincode']?.toString() ?? '',
        paymentMethod: json['payment_method'] as String?,
        accountLast4: json['account_last4'] as String?,
        upiId: json['upi_id'] as String?,
        assignedRmName: rm?['name'] as String?,
        assignedRmPhone: rm?['phone'] as String?,
        lat: (json['lat'] as num?)?.toDouble(),
        lng: (json['lng'] as num?)?.toDouble(),
        profileComplete: json['profile_complete'] as bool? ?? true,
        profileMissing: (json['profile_missing'] as List?)?.map((e) => e.toString()).toList() ?? const [],
      );
  }

  // ── Assigned staff ── (matches GET /client/assigned-staff item shape)
  static Map<String, dynamic> encodeAssignedStaff(ClientAssignedStaff s) => {
        'staffId': s.staffId,
        'staffCode': s.staffCode,
        'fullName': s.fullName,
        'series': s.series,
        'deploymentDate': s.deploymentDate,
        'status': s.status,
        'placementId': s.placementId,
        'features': {
          'care_plan': s.hasCarePlan,
          'menu': s.hasMenu,
          'instructions': s.hasInstructions,
        },
      };

  static ClientAssignedStaff decodeAssignedStaff(Map<String, dynamic> json) =>
      ClientAssignedStaff(
        staffId: json['staffId'] as String,
        staffCode: json['staffCode'] as String?,
        fullName: json['fullName'] as String?,
        series: json['series'] as String?,
        deploymentDate: json['deploymentDate'] as String? ?? '',
        status: json['status'] as String? ?? 'ON_TRIAL',
        placementId: json['placementId'] as String?,
        hasCarePlan: (json['features'] as Map?)?['care_plan'] == true,
        hasMenu: (json['features'] as Map?)?['menu'] == true,
        hasInstructions: (json['features'] as Map?)?['instructions'] != false,
      );

  // ── Staff profile detail ── (matches GET /client/staff/:id/profile exactly;
  // experience/skills/reviews/performance have no backing endpoint)
  static Map<String, dynamic> encodeExperience(ClientExperience e) => {
        'title': e.title,
        'organization': e.organization,
        'duration': e.duration,
        'description': e.description,
      };

  static ClientExperience decodeExperience(Map<String, dynamic> json) =>
      ClientExperience(
        title: json['title'] as String,
        organization: json['organization'] as String,
        duration: json['duration'] as String,
        description: json['description'] as String,
      );

  static Map<String, dynamic> encodeReview(ClientReview r) => {
        'comment': r.comment,
        'rating': r.rating,
        'date': r.date,
        'reviewer_name': r.reviewerName,
      };

  static ClientReview decodeReview(Map<String, dynamic> json) => ClientReview(
        comment: json['comment'] as String,
        rating: (json['rating'] as num?)?.toDouble() ?? 0,
        date: json['date'] as String,
        reviewerName: json['reviewer_name'] as String,
      );

  static Map<String, dynamic> encodeStaffProfile(ClientStaffProfile p) => {
        'staffId': p.staffId,
        'staffCode': p.staffCode,
        'fullName': p.fullName,
        'series': p.series,
        'isVerified': p.isVerified,
        'pvStatus': p.pvStatus,
        'videoCertAvailable': p.videoCertAvailable,
        'experience': p.experience.map(encodeExperience).toList(),
        'skills': p.skills,
        'reviews': p.reviews.map(encodeReview).toList(),
        'performanceScore': p.performanceScore,
        'attendancePercent': p.attendancePercent,
        // Newer snake_case shape (written so the cache decodes the same way).
        'first_name': p.firstName,
        'photo_url': p.photoUrl,
        'phone': p.phone,
        'age': p.age,
        'gender': p.gender,
        'series_label': p.seriesLabel,
        'city': p.city,
        'hometown': p.hometown,
        'experience_years': p.experienceYears,
        'emergency_contact_name': p.emergencyContactName,
        'verification': {
          'is_verified': p.isVerified,
          'police_verification': p.pvStatus,
          'id_verified': p.idVerified,
          'health_screening': p.healthScreening,
          'video_certified': p.videoCertAvailable,
          'trained': p.trained,
        },
        'placement': {
          'status_label': p.placementStatusLabel,
          'start_date': p.placementStartDate,
          'shift_hours': p.shiftHours,
        },
        'rm': {'name': p.rmName, 'phone': p.rmPhone},
      };

  /// `GET /client/staff/:id/profile` — prefers the snake_case fields and
  /// falls back to the camelCase ones older servers send.
  static ClientStaffProfile decodeStaffProfile(Map<String, dynamic> json) {
    final v = json['verification'] is Map ? json['verification'] as Map : const {};
    final placement = json['placement'] is Map ? json['placement'] as Map : const {};
    final rm = json['rm'] is Map ? json['rm'] as Map : const {};
    return ClientStaffProfile(
        staffId: json['staff_id'] as String? ?? json['staffId'] as String,
        staffCode: json['staff_code'] as String? ?? json['staffCode'] as String? ?? '',
        fullName: json['full_name'] as String? ?? json['fullName'] as String? ?? '',
        series: json['series'] as String? ?? '',
        isVerified: v['is_verified'] as bool? ?? json['isVerified'] as bool? ?? false,
        pvStatus: v['police_verification'] as String? ?? json['pvStatus'] as String? ?? 'NOT_INITIATED',
        videoCertAvailable: v['video_certified'] as bool? ?? json['videoCertAvailable'] as bool? ?? false,
        firstName: json['first_name'] as String?,
        photoUrl: json['photo_url'] as String?,
        phone: json['phone'] as String?,
        age: (json['age'] as num?)?.toInt(),
        gender: json['gender'] as String?,
        seriesLabel: json['series_label'] as String?,
        city: json['city'] as String?,
        hometown: json['hometown'] as String?,
        experienceYears: (json['experience_years'] as num?)?.toInt(),
        emergencyContactName: json['emergency_contact_name'] as String?,
        idVerified: v['id_verified'] as bool? ?? false,
        healthScreening: v['health_screening'] as bool?,
        trained: v['trained'] as bool? ?? false,
        placementStatusLabel: placement['status_label'] as String?,
        placementStartDate: placement['start_date'] as String?,
        shiftHours: (placement['shift_hours'] as num?)?.toInt(),
        rmName: rm['name'] as String?,
        rmPhone: rm['phone'] as String?,
        experience: ((json['experience'] as List<dynamic>?) ?? [])
            .map((e) => decodeExperience(e as Map<String, dynamic>))
            .toList(),
        skills: ((json['skills'] as List<dynamic>?) ?? [])
            .map((e) => e as String)
            .toList(),
        reviews: ((json['reviews'] as List<dynamic>?) ?? [])
            .map((e) => decodeReview(e as Map<String, dynamic>))
            .toList(),
        performanceScore: (json['performanceScore'] as num?)?.toDouble(),
        attendancePercent: (json['attendancePercent'] as num?)?.toDouble(),
      );
  }

  // ── Today's attendance ── (matches GET /client/attendance/today; the
  // cache stores the same shape so one decoder reads both)
  static Map<String, dynamic> encodeTodayAttendance(ClientTodayAttendance t) => {
        'staffCode': t.staffCode,
        'staffName': t.staffName,
        'todayStatus': t.todayStatus,
        'checkInTime': t.checkInTime,
        'checkOutTime': t.checkOutTime,
        'gpsVerified': t.gpsVerified,
        'date': t.date,
        'staff': t.staff.map(_encodeStaffToday).toList(),
      };

  static ClientTodayAttendance decodeTodayAttendance(Map<String, dynamic> json) =>
      ClientTodayAttendance(
        staffCode: json['staffCode'] as String?,
        staffName: json['staffName'] as String?,
        todayStatus: json['todayStatus'] as String? ?? 'NOT_CHECKED_IN',
        checkInTime: json['checkInTime'] as String?,
        checkOutTime: json['checkOutTime'] as String?,
        gpsVerified: json['gpsVerified'] as bool? ?? false,
        date: json['date'] as String?,
        staff: [
          for (final raw in json['staff'] as List<dynamic>? ?? const [])
            if (raw is Map) _decodeStaffToday(raw),
        ],
      );

  static Map<String, dynamic> _encodeStaffToday(ClientStaffToday s) => {
        'staff_id': s.staffId,
        'placement_id': s.placementId,
        'staff_code': s.staffCode,
        'name': s.name,
        'series': s.series,
        'series_label': s.seriesLabel,
        'status': s.status,
        'check_in': s.checkIn,
        'check_out': s.checkOut,
        'gps_verified': s.gpsVerified,
        'check_in_distance_m': s.checkInDistanceM,
        'last_location': s.lastLocation == null ? null : _encodeLastLocation(s.lastLocation!),
      };

  static ClientStaffToday _decodeStaffToday(Map<dynamic, dynamic> json) => ClientStaffToday(
        staffId: json['staff_id'] as String? ?? '',
        placementId: json['placement_id'] as String?,
        staffCode: json['staff_code'] as String?,
        name: json['name'] as String? ?? 'Staff',
        series: json['series'] as String?,
        seriesLabel: json['series_label'] as String?,
        status: json['status'] as String? ?? 'NOT_CHECKED_IN',
        checkIn: json['check_in'] as String?,
        checkOut: json['check_out'] as String?,
        gpsVerified: json['gps_verified'] as bool? ?? false,
        checkInDistanceM: (json['check_in_distance_m'] as num?)?.round(),
        lastLocation: json['last_location'] is Map ? decodeLastLocation(json['last_location'] as Map) : null,
      );

  static Map<String, dynamic> _encodeLastLocation(ClientStaffLastLocation l) => {
        'at': l.at,
        'lat': l.lat,
        'lng': l.lng,
        'accuracy_m': l.accuracyM,
        'distance_m': l.distanceM,
        'at_home': l.atHome,
        'label': l.label,
        'stale': l.stale,
      };

  static ClientStaffLastLocation? decodeLastLocation(Map<dynamic, dynamic> json) {
    final lat = (json['lat'] as num?)?.toDouble();
    final lng = (json['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return ClientStaffLastLocation(
      at: json['at'] as String? ?? '',
      lat: lat,
      lng: lng,
      accuracyM: (json['accuracy_m'] as num?)?.round(),
      distanceM: (json['distance_m'] as num?)?.round(),
      atHome: json['at_home'] as bool?,
      label: json['label'] as String?,
      stale: json['stale'] as bool? ?? false,
    );
  }

  // ── Live map ── (GET /client/staff/:staffId/location)
  static ClientMapPoint? _decodePoint(Object? raw) {
    if (raw is! Map) return null;
    final lat = (raw['lat'] as num?)?.toDouble();
    final lng = (raw['lng'] as num?)?.toDouble();
    if (lat == null || lng == null) return null;
    return ClientMapPoint(at: raw['at'] as String?, lat: lat, lng: lng);
  }

  static ClientStaffLocation decodeStaffLocation(Map<String, dynamic> json) {
    final checkIn = json['check_in'] is Map ? json['check_in'] as Map : null;
    final checkOut = json['check_out'] is Map ? json['check_out'] as Map : null;
    return ClientStaffLocation(
      staffId: json['staff_id'] as String? ?? '',
      placementId: json['placement_id'] as String?,
      status: json['status'] as String? ?? 'NOT_CHECKED_IN',
      checkIn: _decodePoint(checkIn),
      checkInLabel: checkIn?['label'] as String?,
      checkOutAt: checkOut?['at'] as String?,
      last: json['last'] is Map ? decodeLastLocation(json['last'] as Map) : null,
      home: _decodePoint(json['home']),
      trail: [
        for (final raw in json['trail'] as List<dynamic>? ?? const []) ?_decodePoint(raw),
      ],
      farMeters: (json['far_meters'] as num?)?.toInt() ?? 300,
      nextRefreshSec: (json['next_refresh_sec'] as num?)?.toInt(),
    );
  }

  // ── Attendance history ── (matches GET /client/attendance/history
  // `history[]` item shape)
  static Map<String, dynamic> encodeAttendanceRecord(ClientAttendanceRecord r) => {
        'date': r.date,
        'status': r.status,
        'checkIn': r.checkIn,
        'checkOut': r.checkOut,
        'staff_id': r.staffId,
        'staff_name': r.staffName,
        'worked': r.worked,
      };

  static ClientAttendanceRecord decodeAttendanceRecord(Map<String, dynamic> json) =>
      ClientAttendanceRecord(
        date: json['date'] as String? ?? '',
        status: json['status'] as String? ?? 'ABSENT',
        checkIn: json['checkIn'] as String?,
        checkOut: json['checkOut'] as String?,
        staffId: json['staff_id'] as String?,
        staffName: json['staff_name'] as String?,
        worked: json['worked'] as String?,
      );

  // ── Invoice ── (matches GET /client/invoices `invoices[]` item shape;
  // no nested line-items array is returned by the backend)
  static Map<String, dynamic> encodeInvoice(ClientInvoice i) => {
        'id': i.id,
        'invoiceId': i.invoiceId,
        'invoiceNumber': i.invoiceNumber,
        'billingMonth': i.billingMonth,
        'periodFrom': i.periodFrom,
        'periodTo': i.periodTo,
        'salaryComponent': i.salaryComponent,
        'managementFee': i.managementFee,
        'gstAmount': i.gstAmount,
        'totalAmount': i.totalAmount,
        'creditedAmount': i.creditedAmount,
        'status': i.status,
        'dueDate': i.dueDate,
      };

  static ClientInvoice decodeInvoice(Map<String, dynamic> json) => ClientInvoice(
        id: json['id'] as String? ?? '',
        // Falls back to `id` for cached rows written before invoiceId
        // existed, and for the dummy source which uses one string for both.
        invoiceId: json['invoiceId'] as String? ?? json['id'] as String? ?? '',
        // Falls back to `id` for cached rows written before invoiceNumber
        // existed, and for the dummy source which uses one string for both.
        invoiceNumber: json['invoiceNumber'] as String? ?? json['id'] as String? ?? '',
        billingMonth: json['billingMonth'] as String? ?? '',
        salaryComponent: (json['salaryComponent'] as num?)?.toDouble() ?? 0,
        managementFee: (json['managementFee'] as num?)?.toDouble() ?? 0,
        gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'PENDING',
        dueDate: json['dueDate'] as String? ?? '',
        // The invoice's own days; null only on very old invoices.
        periodFrom: json['periodFrom'] as String?,
        periodTo: json['periodTo'] as String?,
        creditedAmount: (json['creditedAmount'] as num?)?.toDouble() ?? 0,
      );

  // ── Invoice detail ── (matches GET /client/invoices/:id exactly — a
  // `serviceLines[]` array of {strength, description, amount} plus a
  // taxableValue/cgst/sgst/igst GST breakdown; no PF/ESIC/salary/management
  // fee components are sent)
  static ClientInvoiceDetail decodeInvoiceDetail(Map<String, dynamic> json) =>
      ClientInvoiceDetail(
        id: json['id'] as String? ?? '',
        documentType: json['documentType'] as String? ?? '',
        billingMonth: json['billingMonth'] as String? ?? '',
        periodFrom: json['periodFrom'] as String? ?? '',
        periodTo: json['periodTo'] as String? ?? '',
        status: json['status'] as String? ?? '',
        dueDate: json['dueDate'] as String? ?? '',
        placeOfSupply: json['placeOfSupply'] as String? ?? '',
        sacCode: json['sacCode'] as String? ?? '',
        staffCount: json['staffCount'] as int? ?? 0,
        serviceLines: ((json['serviceLines'] as List<dynamic>?) ?? [])
            .map((e) => e as Map<String, dynamic>)
            .map((i) => ClientInvoiceServiceLine(
                  strength: i['strength'] as int? ?? 0,
                  description: i['description'] as String? ?? '',
                  amount: (i['amount'] as num?)?.toDouble() ?? 0,
                ))
            .toList(),
        taxableValue: (json['taxableValue'] as num?)?.toDouble() ?? 0,
        cgst: (json['cgst'] as num?)?.toDouble() ?? 0,
        sgst: (json['sgst'] as num?)?.toDouble() ?? 0,
        igst: (json['igst'] as num?)?.toDouble() ?? 0,
        gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        amountPaid: (json['amountPaid'] as num?)?.toDouble() ?? 0,
        amountDue: (json['amountDue'] as num?)?.toDouble() ?? 0,
        creditedAmount: (json['creditedAmount'] as num?)?.toDouble() ?? 0,
      );

  // ── Payment history ── (real endpoint now; exact field names aren't
  // spelled out in the backend audit, so this decode tolerates either
  // camelCase or snake_case and falls back to the dummy-shaped keys)
  static ClientPaymentHistory decodePaymentHistory(Map<String, dynamic> json) =>
      ClientPaymentHistory(
        id: json['id'] as String? ?? '',
        date: json['date'] as String? ?? json['paidAt'] as String? ?? '',
        amount: json['amount'] is String
            ? json['amount'] as String
            : json['amount'] != null
                ? (json['amount'] as num).toString()
                : '',
        method: json['method'] as String? ?? json['paymentMethod'] as String? ?? '',
        status: ClientPaymentStatus.values.byNameOrDefault(
          (json['status'] as String?)?.toLowerCase(),
          ClientPaymentStatus.paid,
        ),
        invoiceNumber: json['invoiceNumber'] as String? ?? json['invoiceId'] as String? ?? '',
      );

  // ── Replacement request ── (matches one item of GET /client/replacements)
  static ClientReplacementStatus _decodeReplacementStatus(String? raw) {
    switch (raw) {
      case 'UNDER_RM_REVIEW':
      case 'IN_REVIEW':
        return ClientReplacementStatus.inReview;
      case 'APPROVED':
        return ClientReplacementStatus.approved;
      case 'REJECTED':
        return ClientReplacementStatus.rejected;
      case 'COMPLETED':
        return ClientReplacementStatus.completed;
      default:
        return ClientReplacementStatus.pending;
    }
  }

  static ClientReplacementRequest decodeReplacementRequest(Map<String, dynamic> json) =>
      ClientReplacementRequest(
        id: json['id'] as String? ?? json['requestId'] as String? ?? '',
        currentStaffName: json['currentStaffName'] as String? ?? json['staffName'] as String? ?? '',
        reason: json['reason'] as String? ?? '',
        status: _decodeReplacementStatus(json['status'] as String?),
        requestedAt: json['createdAt'] as String? ?? json['requestedAt'] as String? ?? '',
        newStaffName: json['newStaffName'] as String?,
        estimatedDate: json['estimatedDate'] as String?,
        remarks: json['remarks'] as String?,
      );

  // ── Replacement result ── (matches 201 body of POST /client/replacements)
  static ReplacementRequestResult decodeReplacementResult(Map<String, dynamic> json) =>
      ReplacementRequestResult(
        requestId: json['requestId'] as String? ?? '',
        status: json['status'] as String? ?? '',
        message: json['message'] as String? ?? '',
      );

  // ── Complaint ── GET /client/complaints returns `ticketNumber`, `title`,
  // `raisedAt` and an UPPER_CASE `status` (OPEN/INVESTIGATING/ESCALATED/
  // RESOLVED/CLOSED); the cache round-trip below uses the snake_case shape
  // instead, so both are accepted on decode.
  static Map<String, dynamic> encodeComplaint(ClientComplaint c) => {
        'id': c.id,
        'subject': c.subject,
        'description': c.description,
        'status': c.status.name,
        'created_at': c.createdAt,
        'updated_at': c.updatedAt,
        'image_count': c.imageCount,
        'resolution': c.resolution,
      };

  static ClientComplaint decodeComplaint(Map<String, dynamic> json) => ClientComplaint(
        id: (json['ticketNumber'] ?? json['id']) as String? ?? '',
        subject: (json['title'] ?? json['subject']) as String? ?? '',
        description: json['description'] as String? ?? '',
        status: _decodeComplaintStatus(json['status'] as String?),
        createdAt: (json['raisedAt'] ?? json['created_at']) as String? ?? '',
        updatedAt: (json['resolvedAt'] ?? json['updated_at']) as String? ?? '',
        imageCount: json['image_count'] as int? ?? 0,
        resolution: json['resolution'] as String?,
      );

  // Server statuses are OPEN/INVESTIGATING/ESCALATED/RESOLVED/CLOSED; the
  // app's ClientComplaintStatus has no separate "escalated" state, so it
  // folds into inProgress like INVESTIGATING does.
  static ClientComplaintStatus _decodeComplaintStatus(String? status) {
    switch (status) {
      case 'OPEN':
        return ClientComplaintStatus.open;
      case 'INVESTIGATING':
      case 'ESCALATED':
        return ClientComplaintStatus.inProgress;
      case 'RESOLVED':
        return ClientComplaintStatus.resolved;
      case 'CLOSED':
        return ClientComplaintStatus.closed;
      default:
        return ClientComplaintStatus.values.byNameOrDefault(
          status,
          ClientComplaintStatus.open,
        );
    }
  }

  // ── Notification ── (matches GET /client/notifications item shape,
  // scoped to the caller — same tolerant camelCase/snake_case shape as the
  // staff notification decode)
  static Map<String, dynamic> encodeNotification(ClientNotification n) => {
        'id': n.id, 'title': n.title, 'message': n.message,
        'time': n.time, 'is_read': n.isRead, 'type': n.type,
        'template': n.template, 'payload': n.payload,
      };

  static ClientNotification decodeNotification(Map<String, dynamic> json) =>
      ClientNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        time: json['time'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
        type: json['type'] as String? ?? '',
        template: json['template'] as String?,
        payload: switch (json['payload'] ?? json['data']) {
          final Map<dynamic, dynamic> m => Map<String, dynamic>.from(m),
          _ => const {},
        },
      );

  static List<Map<String, dynamic>> encodeList<T>(
    List<T> items,
    Map<String, dynamic> Function(T) encoder,
  ) => items.map(encoder).toList();

  static List<T> decodeList<T>(
    List<dynamic> json,
    T Function(Map<String, dynamic>) decoder,
  ) => json.map((e) => decoder(e as Map<String, dynamic>)).toList();
}

extension ClientEnumByNameOrDefault<T extends Enum> on List<T> {
  T byNameOrDefault(String? name, T fallback) {
    if (name == null) return fallback;
    for (final value in this) {
      if (value.name == name) return value;
    }
    return fallback;
  }
}
