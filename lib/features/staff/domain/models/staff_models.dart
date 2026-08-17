/// Pipeline stage status.
enum PipelineStageStatus { completed, current, pending }

/// Document approval status.
enum DocumentApprovalStatus { pending, approved, rejected }

/// Agreement status.
enum AgreementStatus { pending, signed, expired }

/// Video certification status.
enum VideoCertStatus { pending, uploaded, approved, rejected }

/// Staff task model — matches the `todayTasks` items embedded in
/// `GET /staff/dashboard` exactly (the backend has no separate task-list
/// schema; this is the entirety of what's tracked per task).
class StaffTask {
  const StaffTask({
    required this.id,
    required this.title,
    required this.done,
  });

  final String id;
  final String title;
  final bool done;
}

/// Pipeline stage model.
class PipelineStage {
  const PipelineStage({
    required this.id,
    required this.title,
    required this.description,
    required this.status,
    required this.completedAt,
  });

  final String id;
  final String title;
  final String description;
  final PipelineStageStatus status;
  final String? completedAt;
}

/// Staff document model.
class StaffDocument {
  const StaffDocument({
    required this.id,
    required this.name,
    required this.type,
    required this.uploadedAt,
    required this.status,
    this.rejectionReason,
  });

  final String id;
  final String name;
  final String type;
  final String uploadedAt;
  final DocumentApprovalStatus status;
  final String? rejectionReason;
}

/// Training category model.
class TrainingCategory {
  const TrainingCategory({
    required this.id,
    required this.name,
    required this.courseCount,
    required this.icon,
  });

  final String id;
  final String name;
  final int courseCount;
  final String icon;
}

/// Training course model.
class TrainingCourse {
  const TrainingCourse({
    required this.id,
    required this.title,
    required this.categoryId,
    required this.duration,
    required this.progress,
    required this.type,
  });

  final String id;
  final String title;
  final String categoryId;
  final String duration;
  final double progress;
  final String type; // video, pdf, quiz
}

/// Quiz question model.
class QuizQuestion {
  const QuizQuestion({
    required this.id,
    required this.question,
    required this.options,
    required this.correctIndex,
  });

  final String id;
  final String question;
  final List<String> options;
  final int correctIndex;
}

/// Video certification prompt.
class VideoCertPrompt {
  const VideoCertPrompt({
    required this.id,
    required this.title,
    required this.instructions,
    required this.status,
  });

  final String id;
  final String title;
  final String instructions;
  final VideoCertStatus status;
}

/// Agreement model.
class StaffAgreement {
  const StaffAgreement({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.signedAt,
  });

  final String id;
  final String title;
  final String content;
  final AgreementStatus status;
  final String? signedAt;
}

/// Deployment info model — matches `GET /staff/deployment` exactly. No
/// work-location coordinates, RM contact, or salary fields are returned by
/// the backend.
class DeploymentInfo {
  const DeploymentInfo({
    required this.hasActivePlacement,
    this.placementId,
    this.clientName,
    this.deploymentAddress,
    this.deploymentDate,
    this.trialStatus,
  });

  final bool hasActivePlacement;
  final String? placementId;
  final String? clientName;
  final String? deploymentAddress;
  final String? deploymentDate;
  final String? trialStatus;
}

/// Attendance record model — matches `GET /staff/attendance/history` item
/// shape exactly (staff-specific: snake_case in the wire format, lowercase
/// status values, no id/hours-worked field, includes a raw "lat,lng"
/// location string instead of the client module's structured fields).
class AttendanceRecord {
  const AttendanceRecord({
    required this.date,
    required this.status,
    this.checkIn,
    this.checkOut,
    this.location,
  });

  final String date;
  final String status; // "present" | "in_progress" | "absent"
  final String? checkIn;
  final String? checkOut;
  final String? location;
}

/// Monthly attendance summary.
class MonthlyAttendance {
  const MonthlyAttendance({
    required this.month,
    required this.present,
    required this.absent,
    required this.late,
    required this.leave,
  });

  final String month;
  final int present;
  final int absent;
  final int late;
  final int leave;
}

/// Salary summary model.
class SalarySummary {
  const SalarySummary({
    required this.month,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.status,
  });

  final String month;
  final String gross;
  final String deductions;
  final String net;
  final String status;
}

/// Payslip model.
class Payslip {
  const Payslip({
    required this.id,
    required this.month,
    required this.amount,
    required this.paidOn,
  });

  final String id;
  final String month;
  final String amount;
  final String paidOn;
}

/// Bank details model.
class BankDetails {
  const BankDetails({
    required this.accountHolder,
    required this.accountNumber,
    required this.bankName,
    required this.ifsc,
  });

  final String accountHolder;
  final String accountNumber;
  final String bankName;
  final String ifsc;
}

/// Staff notification model.
class StaffNotification {
  const StaffNotification({
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

/// Staff profile model — matches `GET /staff/profile` exactly. `role`,
/// `department`, `employeeId` (renamed `staffCode`), `joiningDate`,
/// `completionPercent`, and `avatarUrl` do not exist on the backend.
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.staffCode,
    required this.fullName,
    required this.mobile,
    required this.email,
    required this.series,
    required this.pipelineStage,
    this.address,
    this.dateOfBirth,
  });

  final String id;
  final String staffCode;
  final String fullName;
  final String mobile;
  final String email;
  final String series;
  final String pipelineStage;
  final String? address;
  final String? dateOfBirth;
}

/// Dashboard summary model — matches `GET /staff/dashboard` exactly (flat
/// shape; `todayTasks` is server-hardcoded per the backend, not a per-user
/// task list yet, but is still real API data).
class StaffDashboardData {
  const StaffDashboardData({
    required this.staffCode,
    required this.fullName,
    required this.series,
    required this.pipelineStage,
    required this.completionPct,
    required this.assignedRmName,
    required this.assignedRmPhone,
    required this.todayTasks,
  });

  final String staffCode;
  final String fullName;
  final String series;
  final String pipelineStage;
  final int completionPct;
  final String assignedRmName;
  final String assignedRmPhone;
  final List<StaffTask> todayTasks;
}

/// Check-in/check-out result — matches the response shape of both
/// `POST /staff/attendance/check-in` and `POST /staff/attendance/check-out`.
class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.attendanceId,
    required this.status,
    required this.timestamp,
    this.latitude,
    this.longitude,
  });

  final bool success;
  final String attendanceId;
  final String status; // "CHECKED_IN" | "CHECKED_OUT"
  final String timestamp;
  final double? latitude;
  final double? longitude;
}

/// Training quiz result.
class QuizResult {
  const QuizResult({
    required this.score,
    required this.total,
    required this.passed,
  });

  final int score;
  final int total;
  final bool passed;
}
