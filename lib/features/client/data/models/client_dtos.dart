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
      };

  static ClientProfile decodeProfile(Map<String, dynamic> json) => ClientProfile(
        name: json['name'] as String? ?? '',
        email: json['email'] as String? ?? '',
        phone: json['phone'] as String? ?? '',
        address: json['address'] as String? ?? '',
        city: json['city'] as String? ?? '',
        pincode: json['pincode'] as String? ?? '',
        paymentMethod: json['payment_method'] as String?,
        accountLast4: json['account_last4'] as String?,
        upiId: json['upi_id'] as String?,
      );

  // ── Assigned staff ── (matches GET /client/assigned-staff item shape)
  static Map<String, dynamic> encodeAssignedStaff(ClientAssignedStaff s) => {
        'staffId': s.staffId,
        'staffCode': s.staffCode,
        'fullName': s.fullName,
        'series': s.series,
        'deploymentDate': s.deploymentDate,
        'status': s.status,
      };

  static ClientAssignedStaff decodeAssignedStaff(Map<String, dynamic> json) =>
      ClientAssignedStaff(
        staffId: json['staffId'] as String,
        staffCode: json['staffCode'] as String?,
        fullName: json['fullName'] as String?,
        series: json['series'] as String?,
        deploymentDate: json['deploymentDate'] as String? ?? '',
        status: json['status'] as String? ?? 'ON_TRIAL',
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
      };

  static ClientStaffProfile decodeStaffProfile(Map<String, dynamic> json) =>
      ClientStaffProfile(
        staffId: json['staffId'] as String,
        staffCode: json['staffCode'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        series: json['series'] as String? ?? '',
        isVerified: json['isVerified'] as bool? ?? false,
        pvStatus: json['pvStatus'] as String? ?? 'NOT_INITIATED',
        videoCertAvailable: json['videoCertAvailable'] as bool? ?? false,
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

  // ── Today's attendance ── (matches GET /client/attendance/today exactly)
  static Map<String, dynamic> encodeTodayAttendance(ClientTodayAttendance t) => {
        'staffCode': t.staffCode,
        'staffName': t.staffName,
        'todayStatus': t.todayStatus,
        'checkInTime': t.checkInTime,
        'checkOutTime': t.checkOutTime,
        'gpsVerified': t.gpsVerified,
      };

  static ClientTodayAttendance decodeTodayAttendance(Map<String, dynamic> json) =>
      ClientTodayAttendance(
        staffCode: json['staffCode'] as String?,
        staffName: json['staffName'] as String?,
        todayStatus: json['todayStatus'] as String? ?? 'NOT_CHECKED_IN',
        checkInTime: json['checkInTime'] as String?,
        checkOutTime: json['checkOutTime'] as String?,
        gpsVerified: json['gpsVerified'] as bool? ?? false,
      );

  // ── Attendance history ── (matches GET /client/attendance/history
  // `history[]` item shape; no id/hours-worked field exists)
  static Map<String, dynamic> encodeAttendanceRecord(ClientAttendanceRecord r) => {
        'date': r.date,
        'status': r.status,
        'checkIn': r.checkIn,
        'checkOut': r.checkOut,
      };

  static ClientAttendanceRecord decodeAttendanceRecord(Map<String, dynamic> json) =>
      ClientAttendanceRecord(
        date: json['date'] as String? ?? '',
        status: json['status'] as String? ?? 'ABSENT',
        checkIn: json['checkIn'] as String?,
        checkOut: json['checkOut'] as String?,
      );

  // ── Invoice ── (matches GET /client/invoices `invoices[]` item shape;
  // no nested line-items array is returned by the backend)
  static Map<String, dynamic> encodeInvoice(ClientInvoice i) => {
        'id': i.id,
        'invoiceId': i.invoiceId,
        'invoiceNumber': i.invoiceNumber,
        'billingMonth': i.billingMonth,
        'salaryComponent': i.salaryComponent,
        'managementFee': i.managementFee,
        'gstAmount': i.gstAmount,
        'totalAmount': i.totalAmount,
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
      };

  static ClientNotification decodeNotification(Map<String, dynamic> json) =>
      ClientNotification(
        id: json['id'] as String? ?? '',
        title: json['title'] as String? ?? '',
        message: json['message'] as String? ?? '',
        time: json['time'] as String? ?? '',
        isRead: json['is_read'] as bool? ?? json['isRead'] as bool? ?? false,
        type: json['type'] as String? ?? '',
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
