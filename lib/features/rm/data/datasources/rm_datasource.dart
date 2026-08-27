import '../../../../core/constants/api_constants.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/models/rm_models.dart';
import '../models/rm_dtos.dart';

/// Remote RM API datasource — one method per endpoint, verified against
/// live Swagger JSON (`/api/docs-json`) and backend source. See the plan's
/// "Architecture decisions #2" — this datasource is always called directly
/// by the repository with no dummy fallback, so it always hits the real API.
class RmRemoteDataSource extends BaseRemoteDataSource {
  RmRemoteDataSource(super.dio);

  // ── Dashboard / Kanban ──

  Future<RmDashboard> getDashboard() async {
    final json = await getJson(ApiConstants.rmDashboard);
    return RmDtoCodec.decodeDashboard(json);
  }

  Future<KanbanResult> getKanban({String? search, String? series, int? limit}) async {
    final json = await getJson(ApiConstants.rmKanban, queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
      if (series != null) 'series': series,
      if (limit != null) 'limit': limit,
    });
    return RmDtoCodec.decodeKanban(json);
  }

  // ── Intake / Advance ──

  Future<IntakeResult> postIntake(Map<String, dynamic> body) async {
    final json = await postJson(ApiConstants.rmIntake, data: body);
    return RmDtoCodec.decodeIntakeResult(json);
  }

  Future<StaffRow> advanceStage(
    String staffId,
    String toStage, {
    String? reasonCode,
    Map<String, dynamic>? payload,
    String? terminalOutcome,
  }) async {
    final json = await postJson(
      ApiConstants.rmPipelineAdvance(staffId),
      data: {
        'to_stage': toStage,
        if (reasonCode != null) 'reason_code': reasonCode,
        if (payload != null) 'payload': payload,
        if (terminalOutcome != null) 'terminal_outcome': terminalOutcome,
      },
    );
    return RmDtoCodec.decodeStaffRow(json);
  }

  // ── Trials / Deferred / Terminal ──

  Future<List<TrialRow>> getTrials() async {
    final json = await getJson(ApiConstants.rmTrials);
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeTrialRow).toList();
  }

  Future<List<DeferredRow>> getDeferred() async {
    final json = await getJson(ApiConstants.rmDeferred);
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeDeferredRow).toList();
  }

  Future<void> resumeDeferred(String staffId, String toStage) async {
    await postJson(ApiConstants.rmDeferredResume(staffId), data: {'to_stage': toStage});
  }

  Future<List<StaffRow>> getTerminal() async {
    final json = await getJson(ApiConstants.rmTerminal);
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeStaffRow).toList();
  }

  // ── Incidents ──

  Future<List<IncidentRow>> getIncidents({String? status}) async {
    final json = await getJson(ApiConstants.rmIncidents, queryParameters: {
      if (status != null) 'status': status,
    });
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeIncidentRow).toList();
  }

  Future<IncidentRow> createIncident(Map<String, dynamic> body) async {
    final json = await postJson(ApiConstants.rmIncidents, data: body);
    return RmDtoCodec.decodeIncidentRow(json);
  }

  // ── Shifts ──

  Future<List<ShiftLogRow>> getShifts({String? status}) async {
    final json = await getJson(ApiConstants.rmShifts, queryParameters: {
      if (status != null) 'status': status,
    });
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeShiftLogRow).toList();
  }

  Future<ShiftLogRow> reviewShift(String id, String action, {String? notes}) async {
    final json = await patchJson(ApiConstants.rmShiftReview(id), data: {
      'action': action,
      if (notes != null) 'notes': notes,
    });
    return RmDtoCodec.decodeShiftLogRow(json);
  }

  // ── Upgrades ──

  Future<List<UpgradeRequestRow>> getUpgrades() async {
    final json = await getJson(ApiConstants.rmUpgrades);
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeUpgradeRow).toList();
  }

  // ── Locations ──

  Future<LocationsData> getLocations() async {
    final json = await getJson(ApiConstants.rmLocations);
    return RmDtoCodec.decodeLocations(json);
  }

  // ── Attendance ──

  Future<AttendanceMonthResult> getAttendance({
    required String branchId,
    required int month,
    required int year,
    String? branchCode,
  }) async {
    final json = await getJson(ApiConstants.rmAttendance, queryParameters: {
      'branchId': branchId,
      'month': month,
      'year': year,
      if (branchCode != null) 'branchCode': branchCode,
    });
    return RmDtoCodec.decodeAttendanceMonth(json);
  }

  Future<Map<String, dynamic>> markAttendance({
    required String staffId,
    required String date,
    String? status,
    num? overtimeHours,
    String? branchId,
  }) async {
    return putJson(ApiConstants.rmAttendance, data: {
      'staff_id': staffId,
      'date': date,
      'status': status,
      if (overtimeHours != null) 'overtime_hours': overtimeHours,
      if (branchId != null) 'branch_id': branchId,
    });
  }

  Future<InvoicePreview> getInvoicePreview(String staffId, {required int month, required int year}) async {
    final json = await getJson(
      ApiConstants.rmInvoicePreview(staffId),
      queryParameters: {'month': month, 'year': year},
    );
    return RmDtoCodec.decodeInvoicePreview(json);
  }

  Future<GenerateInvoiceResult> generateInvoice(String staffId, {required int month, required int year}) async {
    final json = await postJson(
      ApiConstants.rmGenerateInvoice(staffId),
      queryParameters: {'month': month, 'year': year},
    );
    return RmDtoCodec.decodeGenerateInvoiceResult(json);
  }

  // ── Placements ──

  Future<PlacementRow> createPlacement(Map<String, dynamic> body) async {
    final json = await postJson(ApiConstants.placements, data: body);
    return RmDtoCodec.decodePlacementRow(json);
  }

  Future<List<PlacementRow>> listPlacements({String? staffId, String? clientId, int limit = 100, int offset = 0}) async {
    final json = await getJson(ApiConstants.placements, queryParameters: {
      if (staffId != null) 'staff_id': staffId,
      if (clientId != null) 'client_id': clientId,
      'limit': limit,
      'offset': offset,
    });
    final items = RmDtoCodec.decodePlacementList(json);
    // Defensive client-side filter too: some deployments may ignore the
    // staff_id/client_id query params (pre-redeploy backend) and return the
    // full unfiltered page, so this filter is a safety net either way.
    return items.where((p) {
      if (staffId != null && p.staffId != staffId) return false;
      if (clientId != null && p.clientId != clientId) return false;
      return true;
    }).toList();
  }

  Future<PlacementRow> confirmPlacement(String id) async {
    final json = await postJson(ApiConstants.placementConfirm(id));
    return RmDtoCodec.decodePlacementRow(json);
  }

  Future<void> exitPlacement(String id, {required String exitDate, required String exitScenarioCode}) async {
    await postJson(ApiConstants.placementExit(id), data: {
      'exit_date': exitDate,
      'exit_scenario_code': exitScenarioCode,
    });
  }

  Future<WageBreakup> calculateWage(Map<String, dynamic> wageConfig) async {
    final json = await postJson(ApiConstants.placementsCalculateWage, data: wageConfig);
    return RmDtoCodec.decodeWageBreakup(json);
  }

  // ── Verification (S2) ──

  /// Step 1/2 — sends a real UIDAI OTP to the Aadhaar-linked mobile via
  /// Sandbox KYC, returns a reference_id to pass to verifyAadhaarOtp below.
  Future<String> generateAadhaarOtp({required String aadhaarNumber}) async {
    final json = await postJson(ApiConstants.verificationAadhaarGenerateOtp, data: {
      'aadhaar_number': aadhaarNumber,
    });
    return (json['reference_id'] ?? json['referenceId'])?.toString() ?? '';
  }

  /// Step 2/2 — verify the OTP the staff received against the reference_id.
  Future<AadhaarResult> verifyAadhaarOtp({
    required String referenceId,
    required String otp,
    required String aadhaarNumber,
    String? staffId,
  }) async {
    final json = await postJson(ApiConstants.verificationAadhaarVerifyOtp, data: {
      'reference_id': referenceId,
      'otp': otp,
      'aadhaar_number': aadhaarNumber,
      if (staffId != null) 'staff_id': staffId,
    });
    return RmDtoCodec.decodeAadhaar(json);
  }

  Future<DlResult> verifyDl({required String dlNumber, required String dob, String? staffId}) async {
    final json = await postJson(ApiConstants.verificationDl, data: {
      'dl_number': dlNumber,
      'dob': dob,
      if (staffId != null) 'staff_id': staffId,
    });
    return RmDtoCodec.decodeDl(json);
  }

  Future<EchallanResult> verifyEchallan(String dlNumber, {String? staffId}) async {
    final json = await postJson(
      ApiConstants.verificationEchallan(dlNumber),
      queryParameters: {if (staffId != null) 'staff_id': staffId},
    );
    return RmDtoCodec.decodeEchallan(json);
  }

  Future<PvResult> submitPv(String staffId, {String? notes}) async {
    final json = await postJson(ApiConstants.verificationPvSubmit(staffId), data: {
      if (notes != null) 'notes': notes,
    });
    return RmDtoCodec.decodePv(json);
  }

  Future<PvCloseResult> closePv(String staffId, {required String result, String? notes}) async {
    final json = await postJson(ApiConstants.verificationPvClose(staffId), data: {
      'result': result,
      if (notes != null) 'notes': notes,
    });
    return RmDtoCodec.decodePvClose(json);
  }

  Future<MedicalResult> submitMedical(String staffId, {required bool passed, String? notes, String? verifiedBy}) async {
    final json = await postJson(ApiConstants.verificationMedicalSubmit(staffId), data: {
      'passed': passed,
      if (notes != null) 'notes': notes,
      if (verifiedBy != null) 'verifiedBy': verifiedBy,
    });
    return RmDtoCodec.decodeMedical(json);
  }

  /// `GET /verification/:staffId` — new endpoint (deployed as of this
  /// integration), aggregates all 5 track statuses server-side. No
  /// documented response schema in Swagger, so the decoder is forgiving —
  /// see `RmDtoCodec.decodeVerificationStatus`.
  Future<Map<String, String>> getVerificationStatus(String staffId) async {
    final json = await getJson(ApiConstants.verificationStatus(staffId));
    return RmDtoCodec.decodeVerificationStatus(json);
  }

  /// Pulls the Aadhaar track's persisted verify-call result (name/last-4/
  /// verified) back out of the same aggregate status response, if that
  /// track has already been cleared — lets the Aadhaar eKYC screen show
  /// what was verified instead of re-prompting for a number/OTP that was
  /// already submitted.
  Future<AadhaarResult?> getAadhaarVerificationResult(String staffId) async {
    final json = await getJson(ApiConstants.verificationStatus(staffId));
    final tracks = json['tracks'];
    if (tracks is! List) return null;
    for (final entry in tracks) {
      if (entry is! Map<String, dynamic>) continue;
      final track = entry['track'] ?? entry['track_type'];
      if (track != 'aadhaar' && track != 'AADHAAR_EKYC') continue;
      final result = entry['result'];
      if (result is Map<String, dynamic>) return RmDtoCodec.decodeAadhaar(result);
      return null;
    }
    return null;
  }

  // ── Assessments (S2.5) ──

  Future<List<Assessment>> listAssessments() async {
    final json = await getJson(ApiConstants.assessments);
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeAssessment).toList();
  }

  Future<Assessment> createAssessment({
    required String staffId,
    String assessmentType = 'GENERAL',
    String? assessorId,
    Map<String, dynamic>? skillScores,
    String? remarks,
  }) async {
    final json = await postJson(ApiConstants.assessmentsCreate, data: {
      'staff_id': staffId,
      'assessment_type': assessmentType,
      if (assessorId != null) 'assessor_id': assessorId,
      if (skillScores != null) 'skill_scores': skillScores,
      if (remarks != null) 'remarks': remarks,
    });
    return RmDtoCodec.decodeAssessment(json);
  }

  Future<Assessment> getAssessment(String id) async {
    final json = await getJson(ApiConstants.assessmentDetail(id));
    return RmDtoCodec.decodeAssessment(json);
  }

  Future<Assessment> updateAssessment(String id, {String? status, String? remarks, String? assessorId}) async {
    final json = await putJson(ApiConstants.assessmentsUpdate(id), data: {
      if (status != null) 'status': status,
      if (remarks != null) 'remarks': remarks,
      if (assessorId != null) 'assessor_id': assessorId,
    });
    return RmDtoCodec.decodeAssessment(json);
  }

  Future<AssessmentSubmitResult> submitAssessment({
    required String id,
    num? score,
    required String result,
    String? remarks,
  }) async {
    final json = await postJson(ApiConstants.assessmentsSubmit, data: {
      'id': id,
      if (score != null) 'score': score,
      'result': result,
      if (remarks != null) 'remarks': remarks,
    });
    return RmDtoCodec.decodeAssessmentSubmitResult(json);
  }

  // ── Agreements + SOW (S4) ──

  Future<List<Agreement>> listAgreements({String? staffId, String? clientId, String? status}) async {
    final json = await getJson(ApiConstants.agreements, queryParameters: {
      if (staffId != null) 'staffId': staffId,
      if (clientId != null) 'clientId': clientId,
      if (status != null) 'status': status,
    });
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeAgreement).toList();
  }

  Future<Agreement> createAgreement({String? staffId, String? clientId, required String type, String? placementId}) async {
    final json = await postJson(ApiConstants.agreements, data: {
      if (staffId != null) 'staff_id': staffId,
      if (clientId != null && clientId.isNotEmpty) 'client_id': clientId,
      'type': type,
      if (placementId != null) 'placement_id': placementId,
    });
    return RmDtoCodec.decodeAgreement(json);
  }

  Future<SendOtpResult> sendEsignOtp({required String staffId, required String agreementType, required String staffName}) async {
    final json = await postJson(ApiConstants.agreementsSendOtp, data: {
      'staff_id': staffId,
      'agreement_type': agreementType,
      'staff_name': staffName,
    });
    return RmDtoCodec.decodeSendOtpResult(json);
  }

  Future<void> verifyEsignOtp({required String staffId, required String agreementType, required String otp}) async {
    await postJson(ApiConstants.agreementsVerifyOtp, data: {
      'staff_id': staffId,
      'agreement_type': agreementType,
      'otp': otp,
    });
  }

  Future<SignAgreementResult> signAgreement(String id, {String? otp}) async {
    final json = await postJson(ApiConstants.agreementSign(id), data: {
      if (otp != null) 'otp': otp,
    });
    return RmDtoCodec.decodeSignResult(json);
  }

  Future<GeneratePdfResult> generateAgreementPdf(String id) async {
    final json = await postJson(ApiConstants.agreementGeneratePdf(id));
    return RmDtoCodec.decodeGeneratePdfResult(json);
  }

  Future<ScopeOfWork> createSow({required String placementId, required String content, bool isNonStandard = false}) async {
    final json = await postJson(ApiConstants.sow, data: {
      'placement_id': placementId,
      'content': content,
      'is_non_standard': isNonStandard,
    });
    return RmDtoCodec.decodeSow(json);
  }

  Future<List<ScopeOfWork>> listSow(String placementId) async {
    final json = await getJson(ApiConstants.sow, queryParameters: {'placement_id': placementId});
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeSow).toList();
  }

  Future<ScopeOfWork> getSow(String id) async {
    final json = await getJson(ApiConstants.sowDetail(id));
    return RmDtoCodec.decodeSow(json);
  }

  Future<ScopeOfWork> updateSow(String id, String content) async {
    final json = await patchJson(ApiConstants.sowDetail(id), data: {'content': content});
    return RmDtoCodec.decodeSow(json);
  }

  Future<ScopeOfWork> sendSow(String id) async {
    final json = await postJson(ApiConstants.sowSend(id));
    return RmDtoCodec.decodeSow(json);
  }

  Future<ScopeOfWork> amendSow(String id, String content) async {
    final json = await postJson(ApiConstants.sowAmend(id), data: {'content': content});
    return RmDtoCodec.decodeSow(json);
  }

  Future<ClientIndemnity> createIndemnity({required String placementId, required String clauseVersion, required String clauseText}) async {
    final json = await postJson(ApiConstants.indemnity, data: {
      'placement_id': placementId,
      'clause_version': clauseVersion,
      'clause_text': clauseText,
    });
    return RmDtoCodec.decodeIndemnity(json);
  }

  Future<List<ClientIndemnity>> listIndemnity(String placementId) async {
    final json = await getJson(ApiConstants.indemnity, queryParameters: {'placement_id': placementId});
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeIndemnity).toList();
  }

  // ── Video certification (S3, RM-usable read-only subset) ──

  Future<VideoCertPrompts> getVideoCertPrompts(String series) async {
    final json = await getJson(ApiConstants.videoCertPrompts(series));
    return RmDtoCodec.decodeVideoCertPrompts(json);
  }

  Future<String> getVideoCertViewUrl(String key) async {
    final json = await postJson(ApiConstants.videoCertViewUrl, data: {'key': key});
    return (json['url'] as String?) ?? '';
  }

  Future<List<VideoCertItem>> listVideoCerts(String staffId) async {
    final json = await getJson(ApiConstants.videoCertList(staffId));
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeVideoCertItem).toList();
  }

  // ── Finance customers (client picker) ──

  Future<List<FinanceCustomer>> getFinanceCustomers({String? search}) async {
    final json = await getJson(ApiConstants.financeCustomers, queryParameters: {
      if (search != null && search.isNotEmpty) 'search': search,
    });
    final items = (json['items'] as List<dynamic>?) ?? (json as List<dynamic>? ?? []);
    return items.whereType<Map<String, dynamic>>().map(RmDtoCodec.decodeFinanceCustomer).toList();
  }
}
