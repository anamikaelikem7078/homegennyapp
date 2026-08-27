import '../../../../core/utils/result.dart';
import '../models/rm_models.dart';

/// RM module repository contract. Every method hits the real API — see
/// `RmRepositoryImpl` for why no dummy/mock fallback is wired in.
abstract interface class RmRepository {
  // Dashboard / Kanban
  Future<Result<RmDashboard>> getDashboard();
  Future<Result<KanbanResult>> getKanban({String? search, String? series, int? limit});

  // Intake / Advance
  Future<Result<IntakeResult>> submitIntake(Map<String, dynamic> body);
  Future<Result<StaffRow>> advanceStage(
    String staffId,
    String toStage, {
    String? reasonCode,
    Map<String, dynamic>? payload,
    String? terminalOutcome,
  });

  // Trials / Deferred / Terminal
  Future<Result<List<TrialRow>>> getTrials();
  Future<Result<List<DeferredRow>>> getDeferred();
  Future<Result<void>> resumeDeferred(String staffId, String toStage);
  Future<Result<List<StaffRow>>> getTerminal();

  // Incidents
  Future<Result<List<IncidentRow>>> getIncidents({String? status});
  Future<Result<IncidentRow>> createIncident(Map<String, dynamic> body);

  // Shifts
  Future<Result<List<ShiftLogRow>>> getShifts({String? status});
  Future<Result<ShiftLogRow>> reviewShift(String id, String action, {String? notes});

  // Upgrades
  Future<Result<List<UpgradeRequestRow>>> getUpgrades();

  // Locations
  Future<Result<LocationsData>> getLocations();

  // Attendance / Invoicing
  Future<Result<AttendanceMonthResult>> getAttendance({
    required String branchId,
    required int month,
    required int year,
    String? branchCode,
  });
  Future<Result<Map<String, dynamic>>> markAttendance({
    required String staffId,
    required String date,
    String? status,
    num? overtimeHours,
    String? branchId,
  });
  Future<Result<InvoicePreview>> getInvoicePreview(String staffId, {required int month, required int year});
  Future<Result<GenerateInvoiceResult>> generateInvoice(String staffId, {required int month, required int year});

  // Placements
  Future<Result<PlacementRow>> createPlacement(Map<String, dynamic> body);
  Future<Result<List<PlacementRow>>> listPlacements({String? staffId, String? clientId, int limit, int offset});
  Future<Result<PlacementRow>> confirmPlacement(String id);
  Future<Result<void>> exitPlacement(String id, {required String exitDate, required String exitScenarioCode});
  Future<Result<WageBreakup>> calculateWage(Map<String, dynamic> wageConfig);

  // Verification (S2)
  Future<Result<String>> generateAadhaarOtp({required String aadhaarNumber});
  Future<Result<AadhaarResult>> verifyAadhaarOtp({
    required String referenceId,
    required String otp,
    required String aadhaarNumber,
    String? staffId,
  });
  Future<Result<DlResult>> verifyDl({required String dlNumber, required String dob, String? staffId});
  Future<Result<EchallanResult>> verifyEchallan(String dlNumber, {String? staffId});
  Future<Result<PvResult>> submitPv(String staffId, {String? notes});
  Future<Result<PvCloseResult>> closePv(String staffId, {required String result, String? notes});
  Future<Result<MedicalResult>> submitMedical(String staffId, {required bool passed, String? notes, String? verifiedBy});
  Future<Result<Map<String, String>>> getVerificationStatus(String staffId);

  // Assessments (S2.5)
  Future<Result<List<Assessment>>> listAssessments();
  Future<Result<Assessment>> createAssessment({
    required String staffId,
    String assessmentType,
    String? assessorId,
    Map<String, dynamic>? skillScores,
    String? remarks,
  });
  Future<Result<Assessment>> getAssessment(String id);
  Future<Result<Assessment>> updateAssessment(String id, {String? status, String? remarks, String? assessorId});
  Future<Result<AssessmentSubmitResult>> submitAssessment({required String id, num? score, required String result, String? remarks});

  // Agreements + SOW (S4)
  Future<Result<List<Agreement>>> listAgreements({String? staffId, String? clientId, String? status});
  Future<Result<Agreement>> createAgreement({String? staffId, String? clientId, required String type, String? placementId});
  Future<Result<SendOtpResult>> sendEsignOtp({required String staffId, required String agreementType, required String staffName});
  Future<Result<void>> verifyEsignOtp({required String staffId, required String agreementType, required String otp});
  Future<Result<SignAgreementResult>> signAgreement(String id, {String? otp});
  Future<Result<GeneratePdfResult>> generateAgreementPdf(String id);
  Future<Result<ScopeOfWork>> createSow({required String placementId, required String content, bool isNonStandard});
  Future<Result<List<ScopeOfWork>>> listSow(String placementId);
  Future<Result<ScopeOfWork>> getSow(String id);
  Future<Result<ScopeOfWork>> updateSow(String id, String content);
  Future<Result<ScopeOfWork>> sendSow(String id);
  Future<Result<ScopeOfWork>> amendSow(String id, String content);
  Future<Result<ClientIndemnity>> createIndemnity({required String placementId, required String clauseVersion, required String clauseText});
  Future<Result<List<ClientIndemnity>>> listIndemnity(String placementId);

  // Video certification (S3, RM-usable read-only subset)
  Future<Result<VideoCertPrompts>> getVideoCertPrompts(String series);
  Future<Result<String>> getVideoCertViewUrl(String key);
  Future<Result<List<VideoCertItem>>> listVideoCerts(String staffId);

  // Finance customers (client picker)
  Future<Result<List<FinanceCustomer>>> getFinanceCustomers({String? search});
}
