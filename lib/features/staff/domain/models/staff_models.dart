/// Pipeline stage status.
enum PipelineStageStatus { completed, current, pending }

/// Document approval status.
enum DocumentApprovalStatus { pending, approved, rejected }

/// Agreement status.
enum AgreementStatus { pending, signed, expired }

/// Video certification status.
enum VideoCertStatus { pending, uploaded, approved, rejected }

/// Attendance day status.
enum AttendanceDayStatus { present, absent, late, leave }

/// Staff task priority.
enum TaskPriority { high, medium, low }

/// Staff task model.
class StaffTask {
  const StaffTask({
    required this.id,
    required this.title,
    required this.description,
    required this.dueTime,
    required this.priority,
    required this.isCompleted,
  });

  final String id;
  final String title;
  final String description;
  final String dueTime;
  final TaskPriority priority;
  final bool isCompleted;
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

/// Deployment info model.
class DeploymentInfo {
  const DeploymentInfo({
    required this.clientName,
    required this.clientPhone,
    required this.workLocation,
    required this.latitude,
    required this.longitude,
    required this.joiningDate,
    required this.rmName,
    required this.rmPhone,
    required this.rmEmail,
  });

  final String clientName;
  final String clientPhone;
  final String workLocation;
  final double latitude;
  final double longitude;
  final String joiningDate;
  final String rmName;
  final String rmPhone;
  final String rmEmail;
}

/// Attendance record model.
class AttendanceRecord {
  const AttendanceRecord({
    required this.id,
    required this.date,
    required this.checkIn,
    required this.checkOut,
    required this.status,
    required this.location,
  });

  final String id;
  final String date;
  final String? checkIn;
  final String? checkOut;
  final AttendanceDayStatus status;
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

/// Staff profile model.
class StaffProfile {
  const StaffProfile({
    required this.id,
    required this.name,
    required this.email,
    required this.phone,
    required this.role,
    required this.department,
    required this.employeeId,
    required this.joiningDate,
    required this.completionPercent,
    required this.avatarUrl,
  });

  final String id;
  final String name;
  final String email;
  final String phone;
  final String role;
  final String department;
  final String employeeId;
  final String joiningDate;
  final int completionPercent;
  final String? avatarUrl;
}

/// Dashboard summary model.
class StaffDashboardData {
  const StaffDashboardData({
    required this.profile,
    required this.tasks,
    required this.currentStage,
    required this.attendanceToday,
    required this.unreadNotifications,
    required this.profileCompletion,
  });

  final StaffProfile profile;
  final List<StaffTask> tasks;
  final PipelineStage currentStage;
  final AttendanceRecord? attendanceToday;
  final int unreadNotifications;
  final int profileCompletion;
}

/// Check-in result.
class CheckInResult {
  const CheckInResult({
    required this.success,
    required this.message,
    required this.timestamp,
    required this.gpsVerified,
  });

  final bool success;
  final String message;
  final String timestamp;
  final bool gpsVerified;
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
