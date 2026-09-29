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

/// Training material type — matches the backend's uppercase enum exactly.
enum TrainingMaterialType { note, pdf, video }

/// One study-material item on a training batch — matches an entry of
/// `GET /training/mine`'s `batches[].materials[]` exactly.
class TrainingMaterial {
  const TrainingMaterial({
    required this.id,
    required this.type,
    required this.title,
    required this.createdAt,
    this.body,
    this.sizeBytes,
    this.viewUrl,
  });

  final String id;
  final TrainingMaterialType type;
  final String title;
  final String createdAt;
  /// Set only for [TrainingMaterialType.note] — the note text itself.
  final String? body;
  final int? sizeBytes;
  /// Relative (needs the Bearer header) or, once cloud storage is live, an
  /// absolute signed URL (needs none) — null for notes. Never cache this;
  /// re-fetch `/training/mine` for a fresh one each time it's opened.
  final String? viewUrl;
}

/// A quiz's state, driving its card entirely — never re-derive this from
/// dates on the client, the backend already accounts for `opensAt` etc.
enum TrainingQuizState { locked, scheduled, available, inProgress, underReview, passed, failed }

/// Score summary of a quiz's most recent graded attempt — matches
/// a quiz object's `lastResult` exactly (null until at least one attempt has
/// been graded).
class QuizLastResult {
  const QuizLastResult({
    required this.attemptId,
    required this.score,
    required this.maxScore,
    required this.passed,
    required this.gradedAt,
  });

  final String attemptId;
  final int score;
  final int maxScore;
  final bool passed;
  final String gradedAt;
}

/// One row of a quiz's `attempts[]` history — every past (and the current)
/// attempt, each with its own [attemptId] usable against the result endpoint.
class QuizAttemptSummary {
  const QuizAttemptSummary({
    required this.attemptId,
    required this.attemptNumber,
    required this.status,
    required this.score,
    required this.maxScore,
    required this.passed,
    required this.submittedAt,
    required this.gradedAt,
  });

  final String attemptId;
  final int attemptNumber;
  final String status;
  final int? score;
  final int? maxScore;
  final bool? passed;
  final String? submittedAt;
  final String? gradedAt;
}

/// A quiz on a training batch — matches `GET /training/mine`'s
/// `batches[].quizzes[]` item (also returned as-is by
/// `GET /training/quizzes/mine`) exactly. Drive the quiz card entirely off
/// [state]; never compute pass/fail or availability from dates on the phone.
class TrainingQuiz {
  const TrainingQuiz({
    required this.id,
    required this.batchId,
    required this.batchCode,
    required this.title,
    required this.questionCount,
    required this.totalPoints,
    required this.passMarks,
    required this.state,
    this.quizDate,
    this.opensAt,
    this.attemptId,
    this.rescheduleNote,
    this.lastResult,
    this.attempts = const [],
  });

  final String id;
  final String batchId;
  final String batchCode;
  final String title;
  final int questionCount;
  final int totalPoints;
  final int passMarks;
  final TrainingQuizState state;
  final String? quizDate;
  /// `LOCKED` → a plain `YYYY-MM-DD` date. `SCHEDULED` → a full ISO
  /// date-time. Null otherwise.
  final String? opensAt;
  final String? attemptId;
  final String? rescheduleNote;
  final QuizLastResult? lastResult;
  final List<QuizAttemptSummary> attempts;
}

/// One training batch a staff member is/was enrolled in — matches an entry
/// of `GET /training/mine`'s `batches[]` exactly. `startDate`/`endDate`/
/// `quizDate` are plain `YYYY-MM-DD` — show as-is, never parse into a UTC
/// `DateTime` (that can shift the displayed day).
class TrainingBatch {
  const TrainingBatch({
    required this.id,
    required this.batchCode,
    required this.series,
    required this.trainerName,
    required this.status,
    required this.startDate,
    required this.endDate,
    required this.enrolledAt,
    required this.materials,
    required this.quizzes,
    this.classroom,
    this.quizDate,
  });

  final String id;
  final String batchCode;
  final String series;
  final String trainerName;
  final String? classroom;
  final String status;
  final String startDate;
  final String endDate;
  final String? quizDate;
  final String enrolledAt;
  final List<TrainingMaterial> materials;
  final List<TrainingQuiz> quizzes;
}

/// Video-certification progress line ("Video certification 3/9 approved") —
/// matches `GET /training/mine`'s `videoCert` object exactly.
class TrainingVideoCertProgress {
  const TrainingVideoCertProgress({required this.approved, required this.required_});

  final int approved;
  final int required_;
}

/// The entire Training home screen in one call — matches
/// `GET /training/mine` exactly. `batches` is newest first; usually one, but
/// a re-trained staff member can have more.
class TrainingHome {
  const TrainingHome({
    required this.staffFullName,
    required this.staffCode,
    required this.series,
    required this.pipelineStage,
    required this.videoCert,
    required this.batches,
  });

  final String staffFullName;
  final String staffCode;
  final String series;
  final String pipelineStage;
  final TrainingVideoCertProgress videoCert;
  final List<TrainingBatch> batches;
}

/// A quiz question type — MCQ (pick one of [TrainingQuizQuestion.options]) or
/// free-text (answer-type, marked by the trainer on the web).
enum TrainingQuestionType { mcq, text }

/// One question of a started quiz attempt — matches
/// `POST /training/quizzes/:quizId/start`'s `questions[]` item exactly.
/// There is intentionally **no correct-answer field** here: the server never
/// sends it to the app, only the result endpoint reveals correctness.
class TrainingQuizQuestion {
  const TrainingQuizQuestion({
    required this.id,
    required this.questionText,
    required this.type,
    required this.orderIndex,
    required this.points,
    this.options,
  });

  final String id;
  final String questionText;
  final TrainingQuestionType type;
  final List<String>? options;
  final int orderIndex;
  final int points;
}

/// A started (or resumed) quiz attempt, with its questions — matches
/// `POST /training/quizzes/:quizId/start`'s response exactly.
class QuizAttemptStart {
  const QuizAttemptStart({
    required this.attemptId,
    required this.quizId,
    required this.status,
    required this.title,
    required this.totalPoints,
    required this.passMarks,
    required this.questions,
  });

  final String attemptId;
  final String quizId;
  final String status;
  final String title;
  final int totalPoints;
  final int passMarks;
  final List<TrainingQuizQuestion> questions;
}

/// One answer to submit — exactly one of [selectedOption] (MCQ, 0-based
/// index) / [answerText] (TEXT) should be set; leaving both unset marks the
/// question wrong (✘) server-side.
class TrainingQuizAnswer {
  const TrainingQuizAnswer({required this.questionId, this.selectedOption, this.answerText});

  final String questionId;
  final int? selectedOption;
  final String? answerText;

  Map<String, dynamic> toJson() => {
        'question_id': questionId,
        if (selectedOption != null) 'selected_option': selectedOption,
        if (answerText != null) 'answer_text': answerText,
      };
}

/// Immediate response to submitting a quiz attempt — matches
/// `POST /training/quizzes/attempts/:attemptId/submit`'s response exactly.
/// [score]/[passed] are null while [pendingReview] is true (an answer-type
/// question is awaiting the trainer's ✔/✘ on the web).
class QuizSubmitResult {
  const QuizSubmitResult({
    required this.attemptId,
    required this.state,
    required this.pendingReview,
    required this.maxScore,
    required this.passMarks,
    this.score,
    this.passed,
  });

  final String attemptId;
  final TrainingQuizState state;
  final bool pendingReview;
  final int? score;
  final int maxScore;
  final int passMarks;
  final bool? passed;
}

/// Per-question breakdown of a graded (or under-review) attempt — matches
/// `GET /training/quizzes/attempts/:attemptId/result`'s `questions[]` item
/// exactly. There is intentionally no field for which option was *correct* —
/// only which one the staff picked, and whether that was right.
class QuizResultQuestion {
  const QuizResultQuestion({
    required this.questionId,
    required this.questionText,
    required this.type,
    required this.points,
    required this.correct,
    required this.pointsAwarded,
    this.options,
    this.yourSelectedOption,
    this.yourAnswerText,
  });

  final String questionId;
  final String questionText;
  final TrainingQuestionType type;
  final List<String>? options;
  final int points;
  final int? yourSelectedOption;
  final String? yourAnswerText;
  final bool correct;
  final int pointsAwarded;
}

/// Full result of one quiz attempt — matches
/// `GET /training/quizzes/attempts/:attemptId/result` exactly. While the
/// attempt is still `UNDER_REVIEW`, [questions] comes back empty and
/// [score]/[passed] stay null.
class QuizResultDetail {
  const QuizResultDetail({
    required this.attemptId,
    required this.title,
    required this.state,
    required this.maxScore,
    required this.passMarks,
    required this.questions,
    this.score,
    this.passed,
    this.gradedAt,
  });

  final String attemptId;
  final String title;
  final TrainingQuizState state;
  final int? score;
  final int maxScore;
  final int passMarks;
  final bool? passed;
  final String? gradedAt;
  final List<QuizResultQuestion> questions;
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

/// One placement a salary/payslip period was earned from — matches an entry
/// of the `houses` array embedded in GET /staff/salary and
/// GET /staff/payslips items exactly.
class SalaryHouse {
  const SalaryHouse({
    required this.clientName,
    required this.placementType,
    required this.worked,
    required this.grossSalary,
  });

  final String clientName;
  final String placementType;
  final String worked;
  final double grossSalary;
}

/// Salary summary model — matches GET /staff/salary exactly (the `salary`
/// object, or `null` with a `message` when no payroll run has produced a
/// payslip for this staff member yet). [hasPayslips] is false in that case.
class SalarySummary {
  const SalarySummary({
    required this.hasPayslips,
    required this.month,
    required this.gross,
    required this.deductions,
    required this.net,
    required this.status,
    this.houses = const [],
    this.ref,
    this.emptyMessage,
  });

  final bool hasPayslips;
  final String month;
  final String gross;
  final String deductions;
  final String net;
  final String status;
  final List<SalaryHouse> houses;
  /// "$periodMonth-$periodYear" — identifies this period for
  /// GET /staff/payslips/pdf, which takes month/year query params rather
  /// than a per-payslip id.
  final String? ref;
  /// Set (with [hasPayslips] false) when the server returns
  /// `{"salary": null, "message": "..."}` — a normal 200, not an error.
  final String? emptyMessage;
}

/// Payslip model — one row from GET /staff/payslips (one per month, newest
/// first), shaped exactly like the GET /staff/salary `salary` object. [ref]
/// is a synthetic "$month-$year" key — what GET /staff/payslips/pdf expects
/// as query params.
class Payslip {
  const Payslip({
    required this.ref,
    required this.month,
    required this.amount,
    required this.grossAmount,
    required this.deductionsAmount,
    required this.deductionBreakdown,
    required this.status,
    this.houses = const [],
    this.presentDays,
  });

  final String ref;
  final String month;
  /// Net pay, formatted.
  final String amount;
  final String grossAmount;
  final String deductionsAmount;
  /// Raw deduction line items (e.g. {"esic": 2.96, "pf": 47.38}) for the
  /// detail screen — keys are backend field names, title-cased for display.
  final Map<String, double> deductionBreakdown;
  final String status;
  final List<SalaryHouse> houses;
  final int? presentDays;
}

/// Bank details model — matches GET /staff/bank-account's `bankAccount`
/// object exactly. The account number always comes back masked; saving new
/// details (PUT) always resets [verified] to false server-side.
class BankDetails {
  const BankDetails({
    required this.accountHolderName,
    required this.accountNumberMasked,
    required this.last4,
    required this.ifsc,
    required this.bankName,
    required this.verified,
    this.verifiedAt,
  });

  final String accountHolderName;
  final String accountNumberMasked;
  final String last4;
  final String ifsc;
  final String bankName;
  final bool verified;
  final String? verifiedAt;
}

/// Staff notification model. [type] can be an empty string on older rows
/// (no `type` sent by the backend) — treat that the same as an unknown type
/// and just show the text. [data] carries type-specific deep-link payload,
/// e.g. `{quizId, attemptId}` for the training-quiz types.
class StaffNotification {
  const StaffNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.type,
    this.data,
  });

  final String id;
  final String title;
  final String message;
  final String time;
  final bool isRead;
  final String type;
  final Map<String, dynamic>? data;
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
    this.staffApplicantId,
  });

  final String id;
  final String staffCode;
  final String fullName;
  final String mobile;
  final String email;
  final String series;
  final String pipelineStage;
  final String? address;
  // The staff_applicants.id row — a different id from `id` (the user account
  // id) — required by every /video-cert/* call, which keys ownership on it.
  // Null only when the logged-in account has no linked staff record at all.
  final String? staffApplicantId;
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

