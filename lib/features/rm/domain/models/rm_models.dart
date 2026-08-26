/// RM domain models. Field names are plain Dart camelCase regardless of the
/// wire casing of the endpoint they came from — the DTO layer
/// (`data/models/rm_dtos.dart`) is where snake_case vs camelCase per-module
/// inconsistency is normalized away. See the plan's "Architecture decisions
/// #3" for which modules use which casing on the wire.
library;

// ── Dashboard ──

class RmDashboardKpis {
  const RmDashboardKpis({
    this.totalStaff = 0,
    this.activePipeline = 0,
    this.pendingVerification = 0,
    this.pendingVideo = 0,
    this.trialPlacements = 0,
    this.activePlacements = 0,
    this.trainingQueue = 0,
    this.deploymentQueue = 0,
    this.deferredCases = 0,
    this.monthlyPlacements = 0,
    this.openIncidents = 0,
    this.pendingShifts = 0,
  });

  final int totalStaff;
  final int activePipeline;
  final int pendingVerification;
  final int pendingVideo;
  final int trialPlacements;
  final int activePlacements;
  final int trainingQueue;
  final int deploymentQueue;
  final int deferredCases;
  final int monthlyPlacements;
  final int openIncidents;
  final int pendingShifts;
}

class PipelineFunnelEntry {
  const PipelineFunnelEntry({required this.stage, required this.count});
  final String stage;
  final int count;
}

class SeriesDistributionEntry {
  const SeriesDistributionEntry({required this.series, required this.count});
  final String series;
  final int count;
}

class RmDashboard {
  const RmDashboard({
    required this.kpis,
    required this.funnel,
    required this.seriesDistribution,
  });

  final RmDashboardKpis kpis;
  final List<PipelineFunnelEntry> funnel;
  final List<SeriesDistributionEntry> seriesDistribution;
}

// ── Staff row (matches backend `toStaffDto` exactly — used by kanban,
//    terminal list, and the intake/advance responses) ──

class StaffRow {
  const StaffRow({
    required this.id,
    required this.staffCode,
    this.branchId,
    this.assignedRmId,
    required this.series,
    this.seriesDb,
    this.roleTypes = const [],
    this.languageTier,
    required this.pipelineStage,
    this.currentScenarioCode,
    this.terminalOutcome,
    required this.fullName,
    this.dateOfBirth,
    required this.mobile,
    this.email,
    this.address,
    this.emergencyContactName,
    this.emergencyContactMobile,
    this.pvStatus,
    this.restrictedListFlag = false,
    this.videoCertId,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String staffCode;
  final String? branchId;
  final String? assignedRmId;
  final String series; // short form: DR | SC | UC | MAID
  final String? seriesDb; // long DB form, e.g. SKILLED_CARE
  final List<String> roleTypes;
  final String? languageTier;
  final String pipelineStage;
  final String? currentScenarioCode;
  final String? terminalOutcome;
  final String fullName;
  final String? dateOfBirth;
  final String mobile;
  final String? email;
  final String? address;
  final String? emergencyContactName;
  final String? emergencyContactMobile;
  final String? pvStatus; // NOT_INITIATED | IN_PROGRESS | CLEAR | ADVERSE | EXPIRED
  final bool restrictedListFlag;
  final String? videoCertId;
  final String? createdAt;
  final String? updatedAt;

  String get initials =>
      fullName.trim().isEmpty ? '?' : fullName.trim().substring(0, 1).toUpperCase();
}

class KanbanResult {
  const KanbanResult({required this.columns, required this.total});
  final Map<String, List<StaffRow>> columns;
  final int total;

  List<StaffRow> get all => columns.values.expand((e) => e).toList();

  StaffRow? findById(String id) {
    for (final list in columns.values) {
      for (final s in list) {
        if (s.id == id) return s;
      }
    }
    return null;
  }
}

/// Response of `POST /rm/intake`.
class IntakeResult {
  const IntakeResult({required this.outcome, required this.staff});
  final String outcome; // RESTRICTED | ADVANCE_S2
  final StaffRow staff;
  bool get isRestricted => outcome == 'RESTRICTED';
}

// ── Placements ──

/// Row shape from `GET/POST /placements` (hand-mapped, snake_case on the
/// wire, includes joined `staff_code`/`series`).
class PlacementRow {
  const PlacementRow({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.status,
    this.staffSalary,
    this.managementFee,
    this.trialStartDate,
    this.trialEndDate,
    this.createdAt,
    this.updatedAt,
    this.staffCode,
    this.series,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String status; // TRIAL | CONFIRMED | EXITED | TERMINATED
  final num? staffSalary;
  final num? managementFee;
  final String? trialStartDate;
  final String? trialEndDate;
  final String? createdAt;
  final String? updatedAt;
  final String? staffCode;
  final String? series;

  bool get isTrial => status == 'TRIAL';
  bool get isConfirmed => status == 'CONFIRMED';
}

/// Commercial Calculator-style wage inputs — same shape Finance uses,
/// sent as `wage_config` on `POST /placements` (and `POST
/// /placements/calculate-wage` for a live preview). The backend derives
/// `staff_salary`/`management_fee` from this and ignores any flat values
/// sent alongside it.
class WageConfig {
  const WageConfig({
    required this.basicWage,
    this.da = 0,
    this.hra = 0,
    this.skilledAllowance = 0,
    this.workingHours = 8,
    this.pfApplicable = true,
    this.employerPfPct = 13,
    this.employerPfMax = 15000,
    this.employeePfPct = 12,
    this.esicApplicable = true,
    this.employerEsicPct = 3.25,
    this.employeeEsicPct = 0.75,
    this.bonusApplicable = true,
    this.bonusPct = 8.33,
    this.bonusFrequency = 'monthly',
    this.leaveDays = 32,
    this.lwfApplicable = true,
    this.lwfAmount = 62,
    this.uniformApplicable = true,
    this.uniformAllowance = 275,
    this.relievingApplicable = true,
    this.relievingPct = 16.67,
    required this.managementPct,
    this.professionalTax = 0,
    this.gstApplicable = true,
    this.gstType = 'intra',
    this.gstPct = 18,
  });

  final num basicWage;
  final num da;
  final num hra;
  final num skilledAllowance;
  final int workingHours; // 8 | 12

  final bool pfApplicable;
  final num employerPfPct;
  final num employerPfMax;
  final num employeePfPct;

  final bool esicApplicable;
  final num employerEsicPct;
  final num employeeEsicPct;

  final bool bonusApplicable;
  final num bonusPct;
  final String bonusFrequency; // monthly | annual

  final num leaveDays;

  final bool lwfApplicable;
  final num lwfAmount;

  final bool uniformApplicable;
  final num uniformAllowance;

  final bool relievingApplicable;
  final num relievingPct;

  final num managementPct;
  final num professionalTax;

  final bool gstApplicable;
  final String gstType; // intra | inter
  final num gstPct;

  Map<String, dynamic> toJson() => {
        'basic_wage': basicWage,
        'da': da,
        'hra': hra,
        'skilled_allowance': skilledAllowance,
        'working_hours': workingHours,
        'pf_applicable': pfApplicable,
        'employer_pf_pct': employerPfPct,
        'employer_pf_max': employerPfMax,
        'employee_pf_pct': employeePfPct,
        'esic_applicable': esicApplicable,
        'employer_esic_pct': employerEsicPct,
        'employee_esic_pct': employeeEsicPct,
        'bonus_applicable': bonusApplicable,
        'bonus_pct': bonusPct,
        'bonus_frequency': bonusFrequency,
        'leave_days': leaveDays,
        'lwf_applicable': lwfApplicable,
        'lwf_amount': lwfAmount,
        'uniform_applicable': uniformApplicable,
        'uniform_allowance': uniformAllowance,
        'relieving_applicable': relievingApplicable,
        'relieving_pct': relievingPct,
        'management_pct': managementPct,
        'professional_tax': professionalTax,
        'gst_applicable': gstApplicable,
        'gst_type': gstType,
        'gst_pct': gstPct,
      };
}

/// Computed breakdown returned by `POST /placements/calculate-wage` (and
/// echoed on a placement as `wage_breakup` once created with a
/// `wage_config`).
class WageBreakup {
  const WageBreakup({
    required this.netSalary,
    required this.managementFee,
    this.grossSalary,
    this.ctc,
    this.employerPfAmount,
    this.employeePfAmount,
    this.employerEsicAmount,
    this.employeeEsicAmount,
    this.bonusAmount,
    this.gstAmount,
  });

  final num netSalary;
  final num managementFee;
  final num? grossSalary;
  final num? ctc;
  final num? employerPfAmount;
  final num? employeePfAmount;
  final num? employerEsicAmount;
  final num? employeeEsicAmount;
  final num? bonusAmount;
  final num? gstAmount;
}

/// Row shape from `GET /rm/trials` — a *raw* Prisma `Placement` row
/// (camelCase), NOT the same as [PlacementRow] from `/placements`. No
/// staff/client name is embedded — the trials screen cross-references
/// against the kanban's staff list for display.
class TrialRow {
  const TrialRow({
    required this.id,
    required this.staffId,
    required this.clientId,
    required this.branchId,
    this.rmId,
    required this.status,
    this.trialStartDate,
    this.trialEndDate,
    this.staffSalary,
    this.managementFee,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String staffId;
  final String clientId;
  final String branchId;
  final String? rmId;
  final String status;
  final String? trialStartDate;
  final String? trialEndDate;
  final num? staffSalary;
  final num? managementFee;
  final String? createdAt;
  final String? updatedAt;
}

class FinanceCustomer {
  const FinanceCustomer({
    required this.id,
    required this.customerName,
    this.address,
    this.city,
    this.state,
    this.pincode,
    this.unitCode,
    this.unitName,
    this.status,
  });

  final String id;
  final String customerName;
  final String? address;
  final String? city;
  final String? state;
  final String? pincode;
  final String? unitCode;
  final String? unitName;
  final String? status;
}

// ── Deferred / Terminal ──

class DeferredStaffSummary {
  const DeferredStaffSummary({
    required this.id,
    required this.staffCode,
    required this.fullName,
    this.series,
    this.currentScenarioCode,
  });
  final String id;
  final String staffCode;
  final String fullName;
  final String? series;
  final String? currentScenarioCode;
}

/// Raw Prisma `DeferredRecord` row (camelCase), with nested staff summary.
class DeferredRow {
  const DeferredRow({
    required this.id,
    required this.staffId,
    required this.reason,
    this.deferredAt,
    this.resumeAt,
    this.timeoutAt,
    this.notes,
    this.resumeStage,
    this.staff,
  });

  final String id;
  final String staffId;
  final String reason;
  final String? deferredAt;
  final String? resumeAt;
  final String? timeoutAt;
  final String? notes;
  final String? resumeStage;
  final DeferredStaffSummary? staff;
}

// ── Incidents ──

/// The only 6 `IncidentType` values the backend currently supports —
/// extending this list is blocked server-side on a Postgres enum-owner
/// permission issue and is not yet live.
abstract final class IncidentTypes {
  static const clientComplaint = 'CLIENT_COMPLAINT';
  static const staffMisconduct = 'STAFF_MISCONDUCT';
  static const safetyIssue = 'SAFETY_ISSUE';
  static const attendanceFraud = 'ATTENDANCE_FRAUD';
  static const drivingViolation = 'DRIVING_VIOLATION';
  static const lateExit = 'LATE_EXIT';

  static const List<String> all = [
    clientComplaint,
    staffMisconduct,
    safetyIssue,
    attendanceFraud,
    drivingViolation,
    lateExit,
  ];

  static String label(String type) => switch (type) {
        clientComplaint => 'Client Complaint',
        staffMisconduct => 'Staff Misconduct',
        safetyIssue => 'Safety Issue',
        attendanceFraud => 'Attendance Fraud',
        drivingViolation => 'Driving Violation',
        lateExit => 'Late Exit',
        _ => type,
      };
}

class IncidentStaffSummary {
  const IncidentStaffSummary({required this.staffCode, required this.fullName});
  final String staffCode;
  final String fullName;
}

class IncidentRow {
  const IncidentRow({
    required this.id,
    this.staffId,
    this.clientId,
    this.placementId,
    required this.type,
    required this.status,
    required this.title,
    this.description,
    this.evidenceUrls = const [],
    this.resolution,
    this.createdAt,
    this.staff,
  });

  final String id;
  final String? staffId;
  final String? clientId;
  final String? placementId;
  final String type;
  final String status;
  final String title;
  final String? description;
  final List<String> evidenceUrls;
  final String? resolution;
  final String? createdAt;
  final IncidentStaffSummary? staff;
}

// ── Shifts ──

class ShiftStaffSummary {
  const ShiftStaffSummary({
    required this.staffCode,
    required this.fullName,
    this.series,
  });
  final String staffCode;
  final String fullName;
  final String? series;
}

class ShiftLogRow {
  const ShiftLogRow({
    required this.id,
    required this.staffId,
    this.placementId,
    required this.shiftDate,
    this.checkInAt,
    this.checkOutAt,
    required this.status,
    this.notes,
    this.staff,
  });

  final String id;
  final String staffId;
  final String? placementId;
  final String shiftDate;
  final String? checkInAt;
  final String? checkOutAt;
  final String status; // PENDING | APPROVED | REJECTED | FLAGGED
  final String? notes;
  final ShiftStaffSummary? staff;
}

// ── Upgrades ──

class UpgradeRequestRow {
  const UpgradeRequestRow({
    required this.id,
    required this.staffId,
    required this.fromSeries,
    required this.toSeries,
    required this.status,
    this.eligibilityScore,
    this.rmRecommendation,
    this.createdAt,
    this.staff,
  });

  final String id;
  final String staffId;
  final String fromSeries;
  final String toSeries;
  final String status;
  final num? eligibilityScore;
  final String? rmRecommendation;
  final String? createdAt;
  final ShiftStaffSummary? staff;
}

// ── Locations ──

class BranchInfo {
  const BranchInfo({required this.id, required this.name, required this.city});
  final String id;
  final String name;
  final String city;
}

class AreaInfo {
  const AreaInfo({
    required this.city,
    required this.area,
    required this.branchCode,
    required this.branchId,
    required this.label,
  });
  final String city;
  final String area;
  final String branchCode;
  final String branchId;
  final String label;
}

class LocationsData {
  const LocationsData({
    this.cities = const [],
    this.branches = const [],
    this.areas = const [],
  });
  final List<String> cities;
  final List<BranchInfo> branches;
  final List<AreaInfo> areas;
}

// ── Attendance ──

abstract final class AttendanceStatuses {
  static const present = 'PRESENT';
  static const absent = 'ABSENT';
  static const leave = 'LEAVE';
  static const overtime = 'OVERTIME';
  static const all = [present, absent, leave, overtime];
}

class DailyAttendanceRecord {
  const DailyAttendanceRecord({
    required this.date,
    required this.status,
    this.overtimeHours,
  });
  final String date;
  final String status;
  final num? overtimeHours;
}

class StaffAttendanceRow {
  const StaffAttendanceRow({
    required this.staffId,
    required this.staffCode,
    required this.fullName,
    required this.placementId,
    required this.monthlySalary,
    required this.monthlyManagementFee,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.overtimeDays,
    required this.billableDays,
    required this.daysInMonth,
    required this.proratedGross,
    this.invoiceId,
    this.dailyRecords = const [],
  });

  final String staffId;
  final String staffCode;
  final String fullName;
  final String placementId;
  final num monthlySalary;
  final num monthlyManagementFee;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int overtimeDays;
  final int billableDays;
  final int daysInMonth;
  final num proratedGross;
  final String? invoiceId;
  final List<DailyAttendanceRecord> dailyRecords;
}

class AttendanceMonthResult {
  const AttendanceMonthResult({
    required this.month,
    required this.year,
    required this.branchId,
    this.staff = const [],
  });
  final int month;
  final int year;
  final String branchId;
  final List<StaffAttendanceRow> staff;
}

/// Payroll calculation breakdown — field names match
/// `PayrollService.calculatePayrollWithAbsoluteFee` exactly (camelCase,
/// nested inside the invoice-preview response).
class PayrollCalculation {
  const PayrollCalculation({
    required this.grossSalary,
    required this.esicEmployee,
    required this.esicEmployer,
    required this.pfEmployee,
    required this.pfEmployer,
    required this.netSalary,
    required this.managementFee,
    required this.gstOnFee,
    required this.clientTotalCharge,
  });

  final num grossSalary;
  final num esicEmployee;
  final num esicEmployer;
  final num pfEmployee;
  final num pfEmployer;
  final num netSalary;
  final num managementFee;
  final num gstOnFee;
  final num clientTotalCharge;
}

/// `GET /rm/attendance/:staffId/invoice-preview` response — every number
/// here comes straight from the backend; the app never recomputes them.
class InvoicePreview {
  const InvoicePreview({
    required this.placementId,
    required this.staffId,
    required this.periodMonth,
    required this.periodYear,
    required this.monthlySalary,
    required this.monthlyManagementFee,
    required this.presentDays,
    required this.absentDays,
    required this.leaveDays,
    required this.overtimeDays,
    required this.billableDays,
    required this.daysInMonth,
    required this.proratedGross,
    required this.proratedManagementFee,
    required this.calculation,
    this.staffCode,
    this.staffName,
    this.invoiceId,
  });

  final String placementId;
  final String staffId;
  final int periodMonth;
  final int periodYear;
  final num monthlySalary;
  final num monthlyManagementFee;
  final int presentDays;
  final int absentDays;
  final int leaveDays;
  final int overtimeDays;
  final int billableDays;
  final int daysInMonth;
  final num proratedGross;
  final num proratedManagementFee;
  final PayrollCalculation calculation;
  final String? staffCode;
  final String? staffName;
  final String? invoiceId;

  bool get alreadyGenerated => invoiceId != null;
}

class GenerateInvoiceResult {
  const GenerateInvoiceResult({
    required this.invoiceId,
    required this.invoiceNumber,
    required this.payrollId,
    required this.preview,
    required this.calculation,
  });
  final String invoiceId;
  final String invoiceNumber;
  final String payrollId;
  final InvoicePreview preview;
  final PayrollCalculation calculation;
}

// ── Assessments (S2.5) ──

abstract final class AssessmentResults {
  static const pass = 'PASS';
  static const partial = 'PARTIAL';
  static const fail = 'FAIL';
  static const all = [pass, partial, fail];
}

class Assessment {
  const Assessment({
    required this.id,
    required this.staffId,
    this.assessorId,
    required this.attemptNumber,
    required this.status,
    this.assessmentType,
    this.score,
    this.result,
    this.remarks,
    this.approvedAt,
    this.createdAt,
  });

  final String id;
  final String staffId;
  final String? assessorId;
  final int attemptNumber;
  final String status; // PENDING | COMPLETED
  final String? assessmentType; // lives inside skillScores.assessmentType
  final num? score; // lives inside skillScores.score
  final String? result; // PASS | PARTIAL | FAIL
  final String? remarks;
  final String? approvedAt;
  final String? createdAt;

  bool get passed => result == AssessmentResults.pass;
}

/// Extra fields returned only on the DR-series 3rd-fail auto-terminate path.
class AssessmentSubmitResult {
  const AssessmentSubmitResult({
    required this.assessment,
    this.autoTerminated = false,
    this.terminalOutcome,
    this.message,
  });
  final Assessment assessment;
  final bool autoTerminated;
  final String? terminalOutcome;
  final String? message;
}

// ── Agreements / SOW (S4) ──

abstract final class AgreementTypes {
  static const a1Employment = 'A1';
  static const a2Sow = 'A2';
  static const a3Indemnity = 'A3';
  static const all = [a1Employment, a2Sow, a3Indemnity];

  static String label(String type) => switch (type) {
        a1Employment => 'A1 · Employment Agreement',
        a2Sow => 'A2 · Scope of Work',
        a3Indemnity => 'A3 · Client Indemnity',
        _ => type,
      };
}

class Agreement {
  const Agreement({
    required this.id,
    this.staffId,
    required this.clientId,
    this.placementId,
    required this.type,
    required this.status,
    this.otpVerified = false,
    this.pdfUrl,
    this.createdAt,
  });

  final String id;
  final String? staffId;
  final String clientId;
  final String? placementId;
  final String type;
  final String status; // PENDING | SIGNED | VOID | EXPIRED | DRAFT | SENT | REJECTED
  final bool otpVerified;
  final String? pdfUrl;
  final String? createdAt;

  bool get isSigned => status == 'SIGNED';
}

class SendOtpResult {
  const SendOtpResult({
    required this.agreementType,
    required this.staffName,
    required this.expiresInMinutes,
    this.devOtp,
  });
  final String agreementType;
  final String staffName;
  final int expiresInMinutes;
  final String? devOtp; // only present outside production
}

class SignAgreementResult {
  const SignAgreementResult({
    required this.id,
    required this.status,
    required this.type,
    required this.clientId,
  });
  final String id;
  final String status;
  final String type;
  final String clientId;
}

class GeneratePdfResult {
  const GeneratePdfResult({
    required this.agreementId,
    required this.pdfUrl,
    required this.sha256,
  });
  final String agreementId;
  final String pdfUrl;
  final String sha256;
}

class ScopeOfWork {
  const ScopeOfWork({
    required this.id,
    required this.placementId,
    required this.clientId,
    required this.staffId,
    required this.content,
    required this.version,
    required this.status,
    this.isNonStandard = false,
    this.sentAt,
    this.acknowledgedAt,
    this.supersedesId,
    this.createdAt,
  });

  final String id;
  final String placementId;
  final String clientId;
  final String staffId;
  final String content;
  final int version;
  final String status; // DRAFT | SENT | ACKNOWLEDGED | SUPERSEDED
  final bool isNonStandard;
  final String? sentAt;
  final String? acknowledgedAt;
  final String? supersedesId;
  final String? createdAt;

  bool get isAcknowledged => status == 'ACKNOWLEDGED';
}

/// A3 — Client Indemnity. Placement-scoped (`/indemnity`), each clause
/// version its own immutable row — never edited after creation. Unlike SOW,
/// `POST /indemnity` both creates and sends in one call (there's no DRAFT
/// state); the client then acknowledges or contests it.
class ClientIndemnity {
  const ClientIndemnity({
    required this.id,
    required this.placementId,
    required this.clientId,
    required this.clauseVersion,
    required this.clauseText,
    this.sentAt,
    this.acknowledgedAt,
    this.contested = false,
    this.createdAt,
  });

  final String id;
  final String placementId;
  final String clientId;
  final String clauseVersion;
  final String clauseText;
  final String? sentAt;
  final String? acknowledgedAt;
  final bool contested;
  final String? createdAt;

  bool get isAcknowledged => acknowledgedAt != null;
}

// ── Verification (S2) ──

class AadhaarResult {
  const AadhaarResult({
    required this.nameLast4,
    required this.name,
    required this.verified,
  });
  final String nameLast4;
  final String name;
  final bool verified;
}

class DlResult {
  const DlResult({
    required this.dlNumber,
    required this.name,
    required this.status,
    this.vehicleClasses = const [],
  });
  final String dlNumber;
  final String name;
  final String status; // VALID | EXPIRED | SUSPENDED | REVOKED
  final List<String> vehicleClasses;
}

class EchallanResult {
  const EchallanResult({required this.count});
  final int count;
}

class PvResult {
  const PvResult({
    required this.referenceNumber,
    required this.status,
    required this.submittedAt,
  });
  final String referenceNumber;
  final String status; // always PENDING on submit
  final String submittedAt;
}

class PvCloseResult {
  const PvCloseResult({
    required this.staffId,
    required this.pvStatus,
    required this.trackStatus,
    required this.closedAt,
  });
  final String staffId;
  final String pvStatus; // CLEAR | ADVERSE
  final String trackStatus;
  final String closedAt;
}

class MedicalResult {
  const MedicalResult({required this.status, required this.notes, required this.date});
  final String status; // CLEAR | FAILED
  final String notes;
  final String date;
}

// ── Video certification (S3) ──

class VideoCertPrompts {
  const VideoCertPrompts({
    required this.count,
    required this.minDuration,
    required this.prompts,
  });
  final int count;
  final int minDuration; // seconds
  final List<String> prompts;
}

class VideoCertItem {
  const VideoCertItem({
    required this.id,
    required this.staffId,
    required this.promptKey,
    required this.videoUrl,
    required this.attemptNumber,
    required this.reviewStatus,
    this.reviewNotes,
    this.createdAt,
  });

  final String id;
  final String staffId;
  final String promptKey;
  final String videoUrl; // GCS key — pass to /video-cert/view-url for playback
  final int attemptNumber;
  final String reviewStatus; // PENDING | APPROVED | REJECTED
  final String? reviewNotes;
  final String? createdAt;
}
