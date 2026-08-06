/// RM pending item types.
enum RmPendingType {
  verification,
  training,
  agreement,
  deployment,
  video,
  document,
}

/// Staff verification status.
enum RmVerificationStatus { pending, approved, rejected }

/// Video review status.
enum RmVideoStatus { pending, approved, rejected }

/// Deployment status.
enum RmDeploymentStatus { trial, permanent, pending }

/// Report period type.
enum RmReportPeriod { daily, weekly, monthly }

/// RM dashboard summary.
class RmDashboardData {
  const RmDashboardData({
    required this.rmName,
    required this.followUpsToday,
    required this.pendingVerification,
    required this.pendingTraining,
    required this.pendingAgreement,
    required this.pendingDeployment,
    required this.clientRequests,
    required this.totalStaff,
    required this.totalClients,
    required this.unreadNotifications,
  });

  final String rmName;
  final List<RmFollowUp> followUpsToday;
  final int pendingVerification;
  final int pendingTraining;
  final int pendingAgreement;
  final int pendingDeployment;
  final int clientRequests;
  final int totalStaff;
  final int totalClients;
  final int unreadNotifications;
}

/// Follow-up item for RM.
class RmFollowUp {
  const RmFollowUp({
    required this.id,
    required this.title,
    required this.subtitle,
    required this.time,
    required this.type,
    this.staffId,
    this.clientId,
  });

  final String id;
  final String title;
  final String subtitle;
  final String time;
  final RmPendingType type;
  final String? staffId;
  final String? clientId;
}

/// Managed staff member.
class RmStaffMember {
  const RmStaffMember({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.role,
    required this.department,
    required this.status,
    required this.pipelineStage,
    required this.trainingProgress,
    required this.joiningDate,
    this.avatarUrl,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String role;
  final String department;
  final String status;
  final String pipelineStage;
  final double trainingProgress;
  final String joiningDate;
  final String? avatarUrl;
}

/// Client managed by RM.
class RmClient {
  const RmClient({
    required this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.requirements,
    required this.assignedStaffId,
    required this.assignedStaffName,
    required this.status,
  });

  final String id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String requirements;
  final String? assignedStaffId;
  final String? assignedStaffName;
  final String status;
}

/// Pending document for verification.
class RmPendingDocument {
  const RmPendingDocument({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.documentName,
    required this.documentType,
    required this.uploadedAt,
    required this.status,
    this.remarks,
  });

  final String id;
  final String staffId;
  final String staffName;
  final String documentName;
  final String documentType;
  final String uploadedAt;
  final RmVerificationStatus status;
  final String? remarks;
}

/// Pending video for review.
class RmPendingVideo {
  const RmPendingVideo({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.promptTitle,
    required this.uploadedAt,
    required this.status,
    this.remarks,
  });

  final String id;
  final String staffId;
  final String staffName;
  final String promptTitle;
  final String uploadedAt;
  final RmVideoStatus status;
  final String? remarks;
}

/// Client request from RM dashboard.
class RmClientRequest {
  const RmClientRequest({
    required this.id,
    required this.clientName,
    required this.requestType,
    required this.message,
    required this.time,
    required this.isUrgent,
  });

  final String id;
  final String clientName;
  final String requestType;
  final String message;
  final String time;
  final bool isUrgent;
}

/// Deployment assignment.
class RmDeployment {
  const RmDeployment({
    required this.id,
    required this.staffId,
    required this.staffName,
    required this.clientId,
    required this.clientName,
    required this.location,
    required this.startDate,
    required this.status,
  });

  final String id;
  final String staffId;
  final String staffName;
  final String clientId;
  final String clientName;
  final String location;
  final String startDate;
  final RmDeploymentStatus status;
}

/// Report summary data.
class RmReportSummary {
  const RmReportSummary({
    required this.title,
    required this.period,
    required this.metrics,
  });

  final String title;
  final String period;
  final List<RmReportMetric> metrics;
}

class RmReportMetric {
  const RmReportMetric({
    required this.label,
    required this.value,
    required this.change,
    this.isPositive = true,
  });

  final String label;
  final String value;
  final String change;
  final bool isPositive;
}

/// RM notification.
class RmNotification {
  const RmNotification({
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

/// Staff detail extended info.
class RmStaffDetail extends RmStaffMember {
  const RmStaffDetail({
    required super.id,
    required super.name,
    required super.phone,
    required super.email,
    required super.role,
    required super.department,
    required super.status,
    required super.pipelineStage,
    required super.trainingProgress,
    required super.joiningDate,
    super.avatarUrl,
    required this.documentsCount,
    required this.attendancePercent,
    required this.lastSalary,
    required this.address,
  });

  final int documentsCount;
  final double attendancePercent;
  final String lastSalary;
  final String address;
}
