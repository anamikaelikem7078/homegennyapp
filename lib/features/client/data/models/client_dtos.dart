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
        billingMonth: json['billingMonth'] as String? ?? '',
        salaryComponent: (json['salaryComponent'] as num?)?.toDouble() ?? 0,
        managementFee: (json['managementFee'] as num?)?.toDouble() ?? 0,
        gstAmount: (json['gstAmount'] as num?)?.toDouble() ?? 0,
        totalAmount: (json['totalAmount'] as num?)?.toDouble() ?? 0,
        status: json['status'] as String? ?? 'PENDING',
        dueDate: json['dueDate'] as String? ?? '',
      );

  // ── Complaint ── (dummy/local-cache only — GET /client/complaints does
  // not exist on the backend, only POST does)
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
        id: json['id'] as String,
        subject: json['subject'] as String? ?? '',
        description: json['description'] as String? ?? '',
        status: ClientComplaintStatus.values.byNameOrDefault(
          json['status'] as String?,
          ClientComplaintStatus.open,
        ),
        createdAt: json['created_at'] as String? ?? '',
        updatedAt: json['updated_at'] as String? ?? '',
        imageCount: json['image_count'] as int? ?? 0,
        resolution: json['resolution'] as String?,
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
