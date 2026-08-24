import '../../../../core/data/repository_executor.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/rm_models.dart';
import '../../domain/repositories/rm_repository.dart';
import '../datasources/rm_datasource.dart';

/// RM repository — real API only. Deliberately never supplies a `dummy:`
/// callback to `RepositoryExecutor`, so it always hits the real backend
/// regardless of the app-wide `AppConfig.useDummyApi` flag (which defaults
/// to true and would otherwise silently serve fake data — see the plan's
/// "Architecture decisions #2"). It also skips the `cache:`/`local:`
/// fallback for everything here: RM operates on live operational state
/// (pipeline stage, placements, incidents, shifts) where a stale local
/// cache masquerading as current truth would be actively harmful.
class RmRepositoryImpl implements RmRepository {
  RmRepositoryImpl({
    required RepositoryExecutor executor,
    required RmRemoteDataSource remote,
  })  : _executor = executor,
        _remote = remote;

  final RepositoryExecutor _executor;
  final RmRemoteDataSource _remote;

  @override
  Future<Result<RmDashboard>> getDashboard() => _executor.fetch(remote: _remote.getDashboard);

  @override
  Future<Result<KanbanResult>> getKanban({String? search, String? series, int? limit}) =>
      _executor.fetch(remote: () => _remote.getKanban(search: search, series: series, limit: limit));

  @override
  Future<Result<IntakeResult>> submitIntake(Map<String, dynamic> body) =>
      _executor.mutate(remote: () => _remote.postIntake(body));

  @override
  Future<Result<StaffRow>> advanceStage(
    String staffId,
    String toStage, {
    String? reasonCode,
    Map<String, dynamic>? payload,
    String? terminalOutcome,
  }) =>
      _executor.mutate(
        remote: () => _remote.advanceStage(
          staffId,
          toStage,
          reasonCode: reasonCode,
          payload: payload,
          terminalOutcome: terminalOutcome,
        ),
      );

  @override
  Future<Result<List<TrialRow>>> getTrials() => _executor.fetch(remote: _remote.getTrials);

  @override
  Future<Result<List<DeferredRow>>> getDeferred() => _executor.fetch(remote: _remote.getDeferred);

  @override
  Future<Result<void>> resumeDeferred(String staffId, String toStage) =>
      _executor.mutateVoid(remote: () => _remote.resumeDeferred(staffId, toStage));

  @override
  Future<Result<List<StaffRow>>> getTerminal() => _executor.fetch(remote: _remote.getTerminal);

  @override
  Future<Result<List<IncidentRow>>> getIncidents({String? status}) =>
      _executor.fetch(remote: () => _remote.getIncidents(status: status));

  @override
  Future<Result<IncidentRow>> createIncident(Map<String, dynamic> body) =>
      _executor.mutate(remote: () => _remote.createIncident(body));

  @override
  Future<Result<List<ShiftLogRow>>> getShifts({String? status}) =>
      _executor.fetch(remote: () => _remote.getShifts(status: status));

  @override
  Future<Result<ShiftLogRow>> reviewShift(String id, String action, {String? notes}) =>
      _executor.mutate(remote: () => _remote.reviewShift(id, action, notes: notes));

  @override
  Future<Result<List<UpgradeRequestRow>>> getUpgrades() => _executor.fetch(remote: _remote.getUpgrades);

  @override
  Future<Result<LocationsData>> getLocations() => _executor.fetch(remote: _remote.getLocations);

  @override
  Future<Result<AttendanceMonthResult>> getAttendance({
    required String branchId,
    required int month,
    required int year,
    String? branchCode,
  }) =>
      _executor.fetch(
        remote: () => _remote.getAttendance(branchId: branchId, month: month, year: year, branchCode: branchCode),
      );

  @override
  Future<Result<Map<String, dynamic>>> markAttendance({
    required String staffId,
    required String date,
    String? status,
    num? overtimeHours,
    String? branchId,
  }) =>
      _executor.mutate(
        remote: () => _remote.markAttendance(
          staffId: staffId,
          date: date,
          status: status,
          overtimeHours: overtimeHours,
          branchId: branchId,
        ),
      );

  @override
  Future<Result<InvoicePreview>> getInvoicePreview(String staffId, {required int month, required int year}) =>
      _executor.fetch(remote: () => _remote.getInvoicePreview(staffId, month: month, year: year));

  @override
  Future<Result<GenerateInvoiceResult>> generateInvoice(String staffId, {required int month, required int year}) =>
      _executor.mutate(remote: () => _remote.generateInvoice(staffId, month: month, year: year));

  @override
  Future<Result<PlacementRow>> createPlacement(Map<String, dynamic> body) =>
      _executor.mutate(remote: () => _remote.createPlacement(body));

  @override
  Future<Result<List<PlacementRow>>> listPlacements({String? staffId, String? clientId, int limit = 100, int offset = 0}) =>
      _executor.fetch(remote: () => _remote.listPlacements(staffId: staffId, clientId: clientId, limit: limit, offset: offset));

  @override
  Future<Result<PlacementRow>> confirmPlacement(String id) =>
      _executor.mutate(remote: () => _remote.confirmPlacement(id));

  @override
  Future<Result<void>> exitPlacement(String id, {required String exitDate, required String exitScenarioCode}) =>
      _executor.mutateVoid(remote: () => _remote.exitPlacement(id, exitDate: exitDate, exitScenarioCode: exitScenarioCode));

  @override
  Future<Result<AadhaarResult>> verifyAadhaar({required String aadhaarNumber, required String otp, String? staffId}) =>
      _executor.mutate(remote: () => _remote.verifyAadhaar(aadhaarNumber: aadhaarNumber, otp: otp, staffId: staffId));

  @override
  Future<Result<DlResult>> verifyDl({required String dlNumber, required String dob, String? staffId}) =>
      _executor.mutate(remote: () => _remote.verifyDl(dlNumber: dlNumber, dob: dob, staffId: staffId));

  @override
  Future<Result<EchallanResult>> verifyEchallan(String dlNumber, {String? staffId}) =>
      _executor.mutate(remote: () => _remote.verifyEchallan(dlNumber, staffId: staffId));

  @override
  Future<Result<PvResult>> submitPv(String staffId, {String? notes}) =>
      _executor.mutate(remote: () => _remote.submitPv(staffId, notes: notes));

  @override
  Future<Result<PvCloseResult>> closePv(String staffId, {required String result, String? notes}) =>
      _executor.mutate(remote: () => _remote.closePv(staffId, result: result, notes: notes));

  @override
  Future<Result<MedicalResult>> submitMedical(String staffId, {required bool passed, String? notes, String? verifiedBy}) =>
      _executor.mutate(remote: () => _remote.submitMedical(staffId, passed: passed, notes: notes, verifiedBy: verifiedBy));

  @override
  Future<Result<Map<String, String>>> getVerificationStatus(String staffId) =>
      _executor.fetch(remote: () => _remote.getVerificationStatus(staffId));

  @override
  Future<Result<List<Assessment>>> listAssessments() => _executor.fetch(remote: _remote.listAssessments);

  @override
  Future<Result<Assessment>> createAssessment({
    required String staffId,
    String assessmentType = 'GENERAL',
    String? assessorId,
    Map<String, dynamic>? skillScores,
    String? remarks,
  }) =>
      _executor.mutate(
        remote: () => _remote.createAssessment(
          staffId: staffId,
          assessmentType: assessmentType,
          assessorId: assessorId,
          skillScores: skillScores,
          remarks: remarks,
        ),
      );

  @override
  Future<Result<Assessment>> getAssessment(String id) => _executor.fetch(remote: () => _remote.getAssessment(id));

  @override
  Future<Result<Assessment>> updateAssessment(String id, {String? status, String? remarks, String? assessorId}) =>
      _executor.mutate(remote: () => _remote.updateAssessment(id, status: status, remarks: remarks, assessorId: assessorId));

  @override
  Future<Result<AssessmentSubmitResult>> submitAssessment({required String id, num? score, required String result, String? remarks}) =>
      _executor.mutate(remote: () => _remote.submitAssessment(id: id, score: score, result: result, remarks: remarks));

  @override
  Future<Result<List<Agreement>>> listAgreements({String? staffId, String? clientId, String? status}) =>
      _executor.fetch(remote: () => _remote.listAgreements(staffId: staffId, clientId: clientId, status: status));

  @override
  Future<Result<Agreement>> createAgreement({String? staffId, required String clientId, required String type, String? placementId}) =>
      _executor.mutate(remote: () => _remote.createAgreement(staffId: staffId, clientId: clientId, type: type, placementId: placementId));

  @override
  Future<Result<SendOtpResult>> sendEsignOtp({required String staffId, required String agreementType, required String staffName}) =>
      _executor.mutate(remote: () => _remote.sendEsignOtp(staffId: staffId, agreementType: agreementType, staffName: staffName));

  @override
  Future<Result<void>> verifyEsignOtp({required String staffId, required String agreementType, required String otp}) =>
      _executor.mutateVoid(remote: () => _remote.verifyEsignOtp(staffId: staffId, agreementType: agreementType, otp: otp));

  @override
  Future<Result<SignAgreementResult>> signAgreement(String id, {String? otp}) =>
      _executor.mutate(remote: () => _remote.signAgreement(id, otp: otp));

  @override
  Future<Result<GeneratePdfResult>> generateAgreementPdf(String id) =>
      _executor.mutate(remote: () => _remote.generateAgreementPdf(id));

  @override
  Future<Result<ScopeOfWork>> createSow({required String placementId, required String content, bool isNonStandard = false}) =>
      _executor.mutate(remote: () => _remote.createSow(placementId: placementId, content: content, isNonStandard: isNonStandard));

  @override
  Future<Result<List<ScopeOfWork>>> listSow(String placementId) => _executor.fetch(remote: () => _remote.listSow(placementId));

  @override
  Future<Result<ScopeOfWork>> getSow(String id) => _executor.fetch(remote: () => _remote.getSow(id));

  @override
  Future<Result<ScopeOfWork>> updateSow(String id, String content) =>
      _executor.mutate(remote: () => _remote.updateSow(id, content));

  @override
  Future<Result<ScopeOfWork>> sendSow(String id) => _executor.mutate(remote: () => _remote.sendSow(id));

  @override
  Future<Result<ScopeOfWork>> amendSow(String id, String content) =>
      _executor.mutate(remote: () => _remote.amendSow(id, content));

  @override
  Future<Result<ClientIndemnity>> createIndemnity({required String placementId, required String clauseVersion, required String clauseText}) =>
      _executor.mutate(remote: () => _remote.createIndemnity(placementId: placementId, clauseVersion: clauseVersion, clauseText: clauseText));

  @override
  Future<Result<List<ClientIndemnity>>> listIndemnity(String placementId) =>
      _executor.fetch(remote: () => _remote.listIndemnity(placementId));

  @override
  Future<Result<VideoCertPrompts>> getVideoCertPrompts(String series) =>
      _executor.fetch(remote: () => _remote.getVideoCertPrompts(series));

  @override
  Future<Result<String>> getVideoCertViewUrl(String key) =>
      _executor.fetch(remote: () => _remote.getVideoCertViewUrl(key));

  @override
  Future<Result<List<VideoCertItem>>> listVideoCerts(String staffId) =>
      _executor.fetch(remote: () => _remote.listVideoCerts(staffId));

  @override
  Future<Result<List<FinanceCustomer>>> getFinanceCustomers({String? search}) =>
      _executor.fetch(remote: () => _remote.getFinanceCustomers(search: search));
}
