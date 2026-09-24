/// Payment status for dummy-only payment history entries.
enum ClientPaymentStatus { pending, paid, overdue, processing }

/// Complaint status.
enum ClientComplaintStatus { open, inProgress, resolved, closed }

/// Replacement request status.
enum ClientReplacementStatus { pending, inReview, approved, rejected, completed }

/// Client dashboard summary — matches `GET /client/dashboard` exactly (a flat
/// object; the backend does not nest staff/attendance data under it).
class ClientDashboardData {
  const ClientDashboardData({
    required this.clientName,
    required this.activePlacementsCount,
    required this.todayAttendanceStatus,
    required this.pendingInvoicesCount,
    required this.totalUnpaidAmount,
  });

  final String clientName;
  final int activePlacementsCount;
  final String todayAttendanceStatus;
  final int pendingInvoicesCount;
  final double totalUnpaidAmount;
}

/// Assigned staff entry — matches `GET /client/assigned-staff` item shape
/// exactly. The backend does not provide rating, shift, on-duty status, or
/// an avatar for this list.
class ClientAssignedStaff {
  const ClientAssignedStaff({
    required this.staffId,
    required this.deploymentDate,
    required this.status,
    this.staffCode,
    this.fullName,
    this.series,
  });

  final String staffId;
  final String? staffCode;
  final String? fullName;
  final String? series;
  final String deploymentDate;
  final String status;
}

/// Attendance aggregate for the attendance-summary screen, computed
/// client-side from `GET /client/attendance/history` (which returns
/// `totalPresent`/`totalAbsent` counts) — not a direct API response shape.
class ClientAttendanceSummary {
  const ClientAttendanceSummary({
    required this.presentDays,
    required this.totalDays,
    required this.attendancePercent,
  });

  final int presentDays;
  final int totalDays;
  final double attendancePercent;
}

/// Full staff profile for client view — matches `GET /client/staff/:id/profile`
/// exactly for the fields the backend supports. Experience, skills, reviews,
/// and performance score are not backed by any endpoint yet and default to
/// empty/absent rather than fabricated content.
class ClientStaffProfile {
  const ClientStaffProfile({
    required this.staffId,
    required this.staffCode,
    required this.fullName,
    required this.series,
    required this.isVerified,
    required this.pvStatus,
    required this.videoCertAvailable,
    this.experience = const [],
    this.skills = const [],
    this.reviews = const [],
    this.performanceScore,
    this.attendancePercent,
  });

  final String staffId;
  final String staffCode;
  final String fullName;
  final String series;
  final bool isVerified;
  final String pvStatus;
  final bool videoCertAvailable;
  final List<ClientExperience> experience;
  final List<String> skills;
  final List<ClientReview> reviews;
  final double? performanceScore;
  final double? attendancePercent;
}

class ClientExperience {
  const ClientExperience({
    required this.title,
    required this.organization,
    required this.duration,
    required this.description,
  });

  final String title;
  final String organization;
  final String duration;
  final String description;
}

class ClientReview {
  const ClientReview({
    required this.comment,
    required this.rating,
    required this.date,
    required this.reviewerName,
  });

  final String comment;
  final double rating;
  final String date;
  final String reviewerName;
}

/// Attendance history record — matches `GET /client/attendance/history`
/// `history[]` item shape exactly. No id or hours-worked field is provided.
class ClientAttendanceRecord {
  const ClientAttendanceRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
  });

  final String date;
  final String status;
  final String? checkIn;
  final String? checkOut;
}

/// Today's attendance for assigned staff — matches `GET /client/attendance/today`
/// exactly. No location field is provided.
class ClientTodayAttendance {
  const ClientTodayAttendance({
    required this.todayStatus,
    this.staffCode,
    this.staffName,
    this.checkInTime,
    this.checkOutTime,
    this.gpsVerified = false,
  });

  final String? staffCode;
  final String? staffName;
  final String todayStatus;
  final String? checkInTime;
  final String? checkOutTime;
  final bool gpsVerified;
}

/// Invoice — matches `GET /client/invoices` `invoices[]` item shape exactly.
/// `id`/`invoiceNumber` is the human-readable invoice number (contains
/// slashes, e.g. "HPL-01/202609/0002") — display only, never pass it as a
/// URL path segment (404s). `invoiceId` is the UUID — always use it for
/// GET /client/invoices/:invoiceId and GET /client/invoices/download?id=.
/// There is no nested line-items array from the list endpoint; [items] is
/// derived client-side from the three numeric components for the summary
/// card — the detail endpoint returns real line items instead (see
/// [ClientInvoiceDetail]).
class ClientInvoice {
  const ClientInvoice({
    required this.id,
    required this.invoiceId,
    required this.invoiceNumber,
    required this.billingMonth,
    required this.salaryComponent,
    required this.managementFee,
    required this.gstAmount,
    required this.totalAmount,
    required this.status,
    required this.dueDate,
  });

  final String id;
  final String invoiceId;
  final String invoiceNumber;
  final String billingMonth;
  final double salaryComponent;
  final double managementFee;
  final double gstAmount;
  final double totalAmount;
  final String status;
  final String dueDate;

  List<ClientInvoiceItem> get items => [
    if (salaryComponent != 0) ClientInvoiceItem(description: 'Staff Salary', amount: salaryComponent),
    if (managementFee != 0) ClientInvoiceItem(description: 'Management Fee', amount: managementFee),
    if (gstAmount != 0) ClientInvoiceItem(description: 'GST', amount: gstAmount),
  ];
}

class ClientInvoiceItem {
  const ClientInvoiceItem({
    required this.description,
    required this.amount,
  });

  final String description;
  final double amount;
}

/// Invoice detail — matches GET /client/invoices/:invoiceId (UUID or
/// invoiceNumber in the path). [id] is the human-readable invoice number,
/// for display only. GST is computed on [taxableValue] as a whole rather
/// than on a management-fee component; PF/ESIC/salary/management-fee are
/// never broken out to the client. [cgst]/[sgst] and [igst] are mutually
/// exclusive — CGST+SGST for a same-state client, IGST for an out-of-state
/// one — so render only the ones that are non-zero. For
/// `documentType == 'BILL_OF_SUPPLY'` all three are always zero and the
/// whole GST block should be hidden.
class ClientInvoiceDetail {
  const ClientInvoiceDetail({
    required this.id,
    required this.documentType,
    required this.billingMonth,
    required this.periodFrom,
    required this.periodTo,
    required this.status,
    required this.dueDate,
    required this.placeOfSupply,
    required this.sacCode,
    required this.staffCount,
    required this.serviceLines,
    required this.taxableValue,
    required this.cgst,
    required this.sgst,
    required this.igst,
    required this.gstAmount,
    required this.totalAmount,
    required this.amountPaid,
    required this.amountDue,
  });

  final String id;
  final String documentType;
  final String billingMonth;
  final String periodFrom;
  final String periodTo;
  final String status;
  final String dueDate;
  final String placeOfSupply;
  final String sacCode;
  final int staffCount;
  final List<ClientInvoiceServiceLine> serviceLines;
  final double taxableValue;
  final double cgst;
  final double sgst;
  final double igst;
  final double gstAmount;
  final double totalAmount;
  final double amountPaid;
  final double amountDue;
}

/// One row of [ClientInvoiceDetail.serviceLines] — one per staff-type billed
/// on the invoice.
class ClientInvoiceServiceLine {
  const ClientInvoiceServiceLine({
    required this.strength,
    required this.description,
    required this.amount,
  });

  final int strength;
  final String description;
  final double amount;
}

/// Payment history entry (dummy-only — no backing endpoint exists yet).
class ClientPaymentHistory {
  const ClientPaymentHistory({
    required this.id,
    required this.date,
    required this.amount,
    required this.method,
    required this.status,
    required this.invoiceNumber,
  });

  final String id;
  final String date;
  final String amount;
  final String method;
  final ClientPaymentStatus status;
  final String invoiceNumber;
}

/// Complaint entry — one row from GET /client/complaints (newest first).
/// `id` is the incident's `ticketNumber` and `subject` is its `title`;
/// see `ClientDtoCodec.decodeComplaint` for the full field mapping.
class ClientComplaint {
  const ClientComplaint({
    required this.id,
    required this.subject,
    required this.description,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.imageCount,
    this.resolution,
  });

  final String id;
  final String subject;
  final String description;
  final ClientComplaintStatus status;
  final String createdAt;
  final String updatedAt;
  final int imageCount;
  final String? resolution;
}

/// Replacement request — one row from GET /client/replacements (the
/// client's past requests, newest first).
class ClientReplacementRequest {
  const ClientReplacementRequest({
    required this.id,
    required this.currentStaffName,
    required this.reason,
    required this.status,
    required this.requestedAt,
    this.newStaffName,
    this.estimatedDate,
    this.remarks,
  });

  final String id;
  final String currentStaffName;
  final String reason;
  final ClientReplacementStatus status;
  final String requestedAt;
  final String? newStaffName;
  final String? estimatedDate;
  final String? remarks;
}

/// Response of POST /client/replacements — matches the 201 body exactly:
/// `{"requestId": "uuid", "status": "UNDER_RM_REVIEW", "message": "..."}`.
class ReplacementRequestResult {
  const ReplacementRequestResult({
    required this.requestId,
    required this.status,
    required this.message,
  });

  final String requestId;
  final String status;
  final String message;
}

/// Client notification (dummy-only — not in the documented Client API list).
class ClientNotification {
  const ClientNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type;
}

/// Client profile data — matches `GET /client/profile` exactly. Payment
/// fields are always null server-side (no schema exists for them yet).
class ClientProfile {
  const ClientProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
    this.paymentMethod,
    this.accountLast4,
    this.upiId,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String pincode;
  final String? paymentMethod;
  final String? accountLast4;
  final String? upiId;
}
