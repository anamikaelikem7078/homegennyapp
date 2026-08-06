/// Payment status for client invoices.
enum ClientPaymentStatus { pending, paid, overdue, processing }

/// Complaint status.
enum ClientComplaintStatus { open, inProgress, resolved, closed }

/// Replacement request status.
enum ClientReplacementStatus { pending, inReview, approved, rejected, completed }

/// Client dashboard summary.
class ClientDashboardData {
  const ClientDashboardData({
    required this.clientName,
    required this.assignedStaff,
    required this.attendanceSummary,
    required this.pendingPaymentAmount,
    required this.pendingPaymentDue,
    required this.unreadNotifications,
    required this.activeComplaints,
    required this.replacementStatus,
  });

  final String clientName;
  final ClientAssignedStaff assignedStaff;
  final ClientAttendanceSummary attendanceSummary;
  final String pendingPaymentAmount;
  final String pendingPaymentDue;
  final int unreadNotifications;
  final int activeComplaints;
  final ClientReplacementStatus? replacementStatus;
}

/// Assigned staff overview for dashboard.
class ClientAssignedStaff {
  const ClientAssignedStaff({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.shift,
    required this.isOnDuty,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String role;
  final double rating;
  final String shift;
  final bool isOnDuty;
  final String? avatarUrl;
}

/// Attendance summary for dashboard.
class ClientAttendanceSummary {
  const ClientAttendanceSummary({
    required this.presentDays,
    required this.totalDays,
    required this.attendancePercent,
    required this.lastCheckIn,
  });

  final int presentDays;
  final int totalDays;
  final double attendancePercent;
  final String lastCheckIn;
}

/// Full staff profile for client view.
class ClientStaffProfile {
  const ClientStaffProfile({
    required this.id,
    required this.name,
    required this.role,
    required this.rating,
    required this.shift,
    required this.phone,
    required this.joinedDate,
    required this.experience,
    required this.skills,
    required this.performanceScore,
    required this.attendancePercent,
    required this.reviews,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String role;
  final double rating;
  final String shift;
  final String phone;
  final String joinedDate;
  final List<ClientExperience> experience;
  final List<String> skills;
  final double performanceScore;
  final double attendancePercent;
  final List<ClientReview> reviews;
  final String? avatarUrl;
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

/// Attendance record.
class ClientAttendanceRecord {
  const ClientAttendanceRecord({
    required this.id,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.hoursWorked,
  });

  final String id;
  final String date;
  final String checkIn;
  final String? checkOut;
  final String status;
  final String hoursWorked;
}

/// Today's attendance for assigned staff.
class ClientTodayAttendance {
  const ClientTodayAttendance({
    required this.staffName,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.location,
  });

  final String staffName;
  final String? checkIn;
  final String? checkOut;
  final String status;
  final String location;
}

/// Payment invoice.
class ClientInvoice {
  const ClientInvoice({
    required this.id,
    required this.invoiceNumber,
    required this.period,
    required this.amount,
    required this.dueDate,
    required this.status,
    required this.items,
  });

  final String id;
  final String invoiceNumber;
  final String period;
  final String amount;
  final String dueDate;
  final ClientPaymentStatus status;
  final List<ClientInvoiceItem> items;
}

class ClientInvoiceItem {
  const ClientInvoiceItem({
    required this.description,
    required this.amount,
  });

  final String description;
  final String amount;
}

/// Payment history entry.
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

/// Complaint entry.
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

/// Replacement request.
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

/// Client notification.
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

/// Client profile data.
class ClientProfile {
  const ClientProfile({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.city,
    required this.pincode,
    required this.paymentMethod,
    required this.accountLast4,
    required this.upiId,
  });

  final String name;
  final String email;
  final String phone;
  final String address;
  final String city;
  final String pincode;
  final String paymentMethod;
  final String accountLast4;
  final String upiId;
}
