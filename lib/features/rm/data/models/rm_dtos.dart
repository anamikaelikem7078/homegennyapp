import '../../domain/models/rm_models.dart';

/// JSON codec for every RM resource. Backend casing is inconsistent
/// per-module (verified against live source + Swagger — see the plan's
/// "Architecture decisions #3"): `/rm/*`, `/placements`, `/finance/customers`
/// are snake_case; `/assessments`, `/sow`, `/video-cert`, and parts of
/// `/agreements` are raw-Prisma camelCase; a few responses (e.g. invoice
/// preview) mix both in the same object. Every decoder below tries each
/// endpoint's actual casing first, with the other casing as a defensive
/// fallback, so a small verified-vs-actual mismatch degrades gracefully
/// instead of silently dropping a field.
abstract final class RmDtoCodec {
  // ── generic helpers ──

  static dynamic _v(Map<String, dynamic> j, List<String> keys) {
    for (final k in keys) {
      final val = j[k];
      if (val != null) return val;
    }
    return null;
  }

  static String _s(Map<String, dynamic> j, List<String> keys, [String fallback = '']) {
    final v = _v(j, keys);
    return v?.toString() ?? fallback;
  }

  static String? _sn(Map<String, dynamic> j, List<String> keys) {
    final v = _v(j, keys);
    return v?.toString();
  }

  /// Numeric fields — Prisma `Decimal` columns (staff_salary, management_fee,
  /// overtime_hours, eligibility_score, ...) serialize as strings, so this
  /// always tries `num.tryParse` as well as a native num.
  static num _n(Map<String, dynamic> j, List<String> keys, [num fallback = 0]) {
    final v = _v(j, keys);
    if (v == null) return fallback;
    if (v is num) return v;
    return num.tryParse(v.toString()) ?? fallback;
  }

  static num? _nn(Map<String, dynamic> j, List<String> keys) {
    final v = _v(j, keys);
    if (v == null) return null;
    if (v is num) return v;
    return num.tryParse(v.toString());
  }

  static int _i(Map<String, dynamic> j, List<String> keys, [int fallback = 0]) =>
      _n(j, keys, fallback).toInt();

  static bool _b(Map<String, dynamic> j, List<String> keys, [bool fallback = false]) {
    final v = _v(j, keys);
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  static List<String> _sl(Map<String, dynamic> j, List<String> keys) {
    final v = _v(j, keys);
    if (v is List) return v.map((e) => e.toString()).toList();
    return const [];
  }

  static List<T> _list<T>(dynamic json, T Function(Map<String, dynamic>) decode) {
    if (json is! List) return const [];
    return json.whereType<Map<String, dynamic>>().map(decode).toList();
  }

  // ── Staff row (toStaffDto — snake_case) ──

  static StaffRow decodeStaffRow(Map<String, dynamic> j) => StaffRow(
        id: _s(j, ['id']),
        staffCode: _s(j, ['staff_code', 'staffCode']),
        branchId: _sn(j, ['branch_id', 'branchId']),
        assignedRmId: _sn(j, ['assigned_rm_id', 'assignedRmId']),
        series: _s(j, ['series']),
        seriesDb: _sn(j, ['series_db', 'seriesDb']),
        roleTypes: _sl(j, ['role_types', 'roleTypes']),
        languageTier: _sn(j, ['language_tier', 'languageTier']),
        pipelineStage: _s(j, ['pipeline_stage', 'pipelineStage']),
        currentScenarioCode: _sn(j, ['current_scenario_code', 'currentScenarioCode']),
        terminalOutcome: _sn(j, ['terminal_outcome', 'terminalOutcome']),
        fullName: _s(j, ['full_name', 'fullName']),
        dateOfBirth: _sn(j, ['date_of_birth', 'dateOfBirth']),
        mobile: _s(j, ['mobile']),
        email: _sn(j, ['email']),
        address: _sn(j, ['address']),
        emergencyContactName: _sn(j, ['emergency_contact_name', 'emergencyContactName']),
        emergencyContactMobile: _sn(j, ['emergency_contact_mobile', 'emergencyContactMobile']),
        pvStatus: _sn(j, ['pv_status', 'pvStatus']),
        restrictedListFlag: _b(j, ['restricted_list_flag', 'restrictedListFlag']),
        videoCertId: _sn(j, ['video_cert_id', 'videoCertId']),
        createdAt: _sn(j, ['created_at', 'createdAt']),
        updatedAt: _sn(j, ['updated_at', 'updatedAt']),
      );

  // ── Dashboard ──

  static RmDashboard decodeDashboard(Map<String, dynamic> j) {
    final kpisJson = (j['kpis'] as Map<String, dynamic>?) ?? const {};
    final kpis = RmDashboardKpis(
      totalStaff: _i(kpisJson, ['total_staff']),
      activePipeline: _i(kpisJson, ['active_pipeline']),
      pendingVerification: _i(kpisJson, ['pending_verification']),
      pendingVideo: _i(kpisJson, ['pending_video']),
      trialPlacements: _i(kpisJson, ['trial_placements']),
      activePlacements: _i(kpisJson, ['active_placements']),
      trainingQueue: _i(kpisJson, ['training_queue']),
      deploymentQueue: _i(kpisJson, ['deployment_queue']),
      deferredCases: _i(kpisJson, ['deferred_cases']),
      monthlyPlacements: _i(kpisJson, ['monthly_placements']),
      openIncidents: _i(kpisJson, ['open_incidents']),
      pendingShifts: _i(kpisJson, ['pending_shifts']),
    );
    final funnel = _list(j['funnel'], (e) => PipelineFunnelEntry(
          stage: _s(e, ['stage']),
          count: _i(e, ['count']),
        ));
    final seriesDist = _list(j['seriesDistribution'] ?? j['series_distribution'],
        (e) => SeriesDistributionEntry(series: _s(e, ['series']), count: _i(e, ['count'])));
    return RmDashboard(kpis: kpis, funnel: funnel, seriesDistribution: seriesDist);
  }

  // ── Kanban ──

  static KanbanResult decodeKanban(Map<String, dynamic> j) {
    final columnsJson = (j['columns'] as Map<String, dynamic>?) ?? const {};
    final columns = <String, List<StaffRow>>{
      for (final entry in columnsJson.entries) entry.key: _list(entry.value, decodeStaffRow),
    };
    return KanbanResult(columns: columns, total: _i(j, ['total']));
  }

  // ── Intake ──

  static IntakeResult decodeIntakeResult(Map<String, dynamic> j) => IntakeResult(
        outcome: _s(j, ['outcome']),
        staff: decodeStaffRow((j['staff'] as Map<String, dynamic>?) ?? const {}),
      );

  // ── Placements ──

  static PlacementRow decodePlacementRow(Map<String, dynamic> j) => PlacementRow(
        id: _s(j, ['id']),
        staffId: _s(j, ['staff_id', 'staffId']),
        clientId: _s(j, ['client_id', 'clientId']),
        status: _s(j, ['status']),
        staffSalary: _nn(j, ['staff_salary', 'staffSalary']),
        managementFee: _nn(j, ['management_fee', 'managementFee']),
        trialStartDate: _sn(j, ['trial_start_date', 'trialStartDate']),
        trialEndDate: _sn(j, ['trial_end_date', 'trialEndDate']),
        createdAt: _sn(j, ['created_at', 'createdAt']),
        updatedAt: _sn(j, ['updated_at', 'updatedAt']),
        staffCode: _sn(j, ['staff_code', 'staffCode']),
        series: _sn(j, ['series']),
      );

  static List<PlacementRow> decodePlacementList(Map<String, dynamic> j) =>
      _list(j['items'], decodePlacementRow);

  static TrialRow decodeTrialRow(Map<String, dynamic> j) => TrialRow(
        id: _s(j, ['id']),
        staffId: _s(j, ['staff_id', 'staffId']),
        clientId: _s(j, ['client_id', 'clientId']),
        branchId: _s(j, ['branch_id', 'branchId']),
        rmId: _sn(j, ['rm_id', 'rmId']),
        status: _s(j, ['status']),
        trialStartDate: _sn(j, ['trial_start_date', 'trialStartDate']),
        trialEndDate: _sn(j, ['trial_end_date', 'trialEndDate']),
        staffSalary: _nn(j, ['staff_salary', 'staffSalary']),
        managementFee: _nn(j, ['management_fee', 'managementFee']),
        createdAt: _sn(j, ['created_at', 'createdAt']),
        updatedAt: _sn(j, ['updated_at', 'updatedAt']),
      );

  static FinanceCustomer decodeFinanceCustomer(Map<String, dynamic> j) => FinanceCustomer(
        id: _s(j, ['id']),
        customerName: _s(j, ['customer_name', 'customerName']),
        address: _sn(j, ['address']),
        city: _sn(j, ['city']),
        state: _sn(j, ['state']),
        pincode: _sn(j, ['pincode']),
        unitCode: _sn(j, ['unit_code', 'unitCode']),
        unitName: _sn(j, ['unit_name', 'unitName']),
        status: _sn(j, ['status']),
      );

  // ── Deferred ──

  static DeferredRow decodeDeferredRow(Map<String, dynamic> j) {
    final staffJson = j['staff'] as Map<String, dynamic>?;
    return DeferredRow(
      id: _s(j, ['id']),
      staffId: _s(j, ['staff_id', 'staffId']),
      reason: _s(j, ['reason']),
      deferredAt: _sn(j, ['deferred_at', 'deferredAt']),
      resumeAt: _sn(j, ['resume_at', 'resumeAt']),
      timeoutAt: _sn(j, ['timeout_at', 'timeoutAt']),
      notes: _sn(j, ['notes']),
      resumeStage: _sn(j, ['resume_stage', 'resumeStage']),
      staff: staffJson == null
          ? null
          : DeferredStaffSummary(
              id: _s(staffJson, ['id']),
              staffCode: _s(staffJson, ['staff_code', 'staffCode']),
              fullName: _s(staffJson, ['full_name', 'fullName']),
              series: _sn(staffJson, ['series']),
              currentScenarioCode: _sn(staffJson, ['current_scenario_code', 'currentScenarioCode']),
            ),
    );
  }

  // ── Incidents ──

  static IncidentRow decodeIncidentRow(Map<String, dynamic> j) {
    final staffJson = j['staff'] as Map<String, dynamic>?;
    return IncidentRow(
      id: _s(j, ['id']),
      staffId: _sn(j, ['staff_id', 'staffId']),
      clientId: _sn(j, ['client_id', 'clientId']),
      placementId: _sn(j, ['placement_id', 'placementId']),
      type: _s(j, ['type']),
      status: _s(j, ['status']),
      title: _s(j, ['title']),
      description: _sn(j, ['description']),
      evidenceUrls: _sl(j, ['evidence_urls', 'evidenceUrls']),
      resolution: _sn(j, ['resolution']),
      createdAt: _sn(j, ['created_at', 'createdAt']),
      staff: staffJson == null
          ? null
          : IncidentStaffSummary(
              staffCode: _s(staffJson, ['staff_code', 'staffCode']),
              fullName: _s(staffJson, ['full_name', 'fullName']),
            ),
    );
  }

  // ── Shifts ──

  static ShiftLogRow decodeShiftLogRow(Map<String, dynamic> j) {
    final staffJson = j['staff'] as Map<String, dynamic>?;
    return ShiftLogRow(
      id: _s(j, ['id']),
      staffId: _s(j, ['staff_id', 'staffId']),
      placementId: _sn(j, ['placement_id', 'placementId']),
      shiftDate: _s(j, ['shift_date', 'shiftDate']),
      checkInAt: _sn(j, ['check_in_at', 'checkInAt']),
      checkOutAt: _sn(j, ['check_out_at', 'checkOutAt']),
      status: _s(j, ['status']),
      notes: _sn(j, ['notes']),
      staff: staffJson == null
          ? null
          : ShiftStaffSummary(
              staffCode: _s(staffJson, ['staff_code', 'staffCode']),
              fullName: _s(staffJson, ['full_name', 'fullName']),
              series: _sn(staffJson, ['series']),
            ),
    );
  }

  // ── Upgrades ──

  static UpgradeRequestRow decodeUpgradeRow(Map<String, dynamic> j) {
    final staffJson = j['staff'] as Map<String, dynamic>?;
    return UpgradeRequestRow(
      id: _s(j, ['id']),
      staffId: _s(j, ['staff_id', 'staffId']),
      fromSeries: _s(j, ['from_series', 'fromSeries']),
      toSeries: _s(j, ['to_series', 'toSeries']),
      status: _s(j, ['status']),
      eligibilityScore: _nn(j, ['eligibility_score', 'eligibilityScore']),
      rmRecommendation: _sn(j, ['rm_recommendation', 'rmRecommendation']),
      createdAt: _sn(j, ['created_at', 'createdAt']),
      staff: staffJson == null
          ? null
          : ShiftStaffSummary(
              staffCode: _s(staffJson, ['staff_code', 'staffCode']),
              fullName: _s(staffJson, ['full_name', 'fullName']),
              series: _sn(staffJson, ['series']),
            ),
    );
  }

  // ── Locations ──

  static LocationsData decodeLocations(Map<String, dynamic> j) => LocationsData(
        cities: _sl(j, ['cities']),
        branches: _list(j['branches'], (e) => BranchInfo(
              id: _s(e, ['id']),
              name: _s(e, ['name']),
              city: _s(e, ['city']),
            )),
        areas: _list(j['areas'], (e) => AreaInfo(
              city: _s(e, ['city']),
              area: _s(e, ['area']),
              branchCode: _s(e, ['branch_code', 'branchCode']),
              branchId: _s(e, ['branch_id', 'branchId']),
              label: _s(e, ['label']),
            )),
      );

  // ── Attendance ──

  static DailyAttendanceRecord decodeDailyRecord(Map<String, dynamic> j) => DailyAttendanceRecord(
        date: _s(j, ['date']),
        status: _s(j, ['status']),
        overtimeHours: _nn(j, ['overtime_hours', 'overtimeHours']),
      );

  static StaffAttendanceRow decodeStaffAttendanceRow(Map<String, dynamic> j) => StaffAttendanceRow(
        staffId: _s(j, ['staff_id', 'staffId']),
        staffCode: _s(j, ['staff_code', 'staffCode']),
        fullName: _s(j, ['full_name', 'fullName']),
        placementId: _s(j, ['placement_id', 'placementId']),
        monthlySalary: _n(j, ['monthly_salary', 'monthlySalary']),
        monthlyManagementFee: _n(j, ['monthly_management_fee', 'monthlyManagementFee']),
        presentDays: _i(j, ['present_days', 'presentDays']),
        absentDays: _i(j, ['absent_days', 'absentDays']),
        leaveDays: _i(j, ['leave_days', 'leaveDays']),
        overtimeDays: _i(j, ['overtime_days', 'overtimeDays']),
        billableDays: _i(j, ['billable_days', 'billableDays']),
        daysInMonth: _i(j, ['days_in_month', 'daysInMonth']),
        proratedGross: _n(j, ['prorated_gross', 'proratedGross']),
        invoiceId: _sn(j, ['invoice_id', 'invoiceId']),
        dailyRecords: _list(j['daily_records'] ?? j['dailyRecords'], decodeDailyRecord),
      );

  static AttendanceMonthResult decodeAttendanceMonth(Map<String, dynamic> j) => AttendanceMonthResult(
        month: _i(j, ['month']),
        year: _i(j, ['year']),
        branchId: _s(j, ['branch_id', 'branchId']),
        staff: _list(j['staff'], decodeStaffAttendanceRow),
      );

  static PayrollCalculation decodeCalculation(Map<String, dynamic> j) => PayrollCalculation(
        grossSalary: _n(j, ['grossSalary', 'gross_salary']),
        esicEmployee: _n(j, ['esicEmployee', 'esic_employee']),
        esicEmployer: _n(j, ['esicEmployer', 'esic_employer']),
        pfEmployee: _n(j, ['pfEmployee', 'pf_employee']),
        pfEmployer: _n(j, ['pfEmployer', 'pf_employer']),
        netSalary: _n(j, ['netSalary', 'net_salary']),
        managementFee: _n(j, ['managementFee', 'management_fee']),
        gstOnFee: _n(j, ['gstOnFee', 'gst_on_fee']),
        clientTotalCharge: _n(j, ['clientTotalCharge', 'client_total_charge']),
      );

  static InvoicePreview decodeInvoicePreview(Map<String, dynamic> j) => InvoicePreview(
        placementId: _s(j, ['placement_id', 'placementId']),
        staffId: _s(j, ['staff_id', 'staffId']),
        periodMonth: _i(j, ['period_month', 'periodMonth']),
        periodYear: _i(j, ['period_year', 'periodYear']),
        monthlySalary: _n(j, ['monthly_salary', 'monthlySalary']),
        monthlyManagementFee: _n(j, ['monthly_management_fee', 'monthlyManagementFee']),
        presentDays: _i(j, ['present_days', 'presentDays']),
        absentDays: _i(j, ['absent_days', 'absentDays']),
        leaveDays: _i(j, ['leave_days', 'leaveDays']),
        overtimeDays: _i(j, ['overtime_days', 'overtimeDays']),
        billableDays: _i(j, ['billable_days', 'billableDays']),
        daysInMonth: _i(j, ['days_in_month', 'daysInMonth']),
        proratedGross: _n(j, ['prorated_gross', 'proratedGross']),
        proratedManagementFee: _n(j, ['prorated_management_fee', 'proratedManagementFee']),
        calculation: decodeCalculation((j['calculation'] as Map<String, dynamic>?) ?? const {}),
        staffCode: _sn(j, ['staff_code', 'staffCode']),
        staffName: _sn(j, ['staff_name', 'staffName']),
        invoiceId: _sn(j, ['invoice_id', 'invoiceId']),
      );

  static GenerateInvoiceResult decodeGenerateInvoiceResult(Map<String, dynamic> j) =>
      GenerateInvoiceResult(
        invoiceId: _s(j, ['invoice_id', 'invoiceId']),
        invoiceNumber: _s(j, ['invoice_number', 'invoiceNumber']),
        payrollId: _s(j, ['payroll_id', 'payrollId']),
        preview: decodeInvoicePreview((j['preview'] as Map<String, dynamic>?) ?? const {}),
        calculation: decodeCalculation((j['calculation'] as Map<String, dynamic>?) ?? const {}),
      );

  // ── Assessments (camelCase, raw Prisma; score/type nested in skillScores) ──

  static Assessment decodeAssessment(Map<String, dynamic> j) {
    final skillScores = (j['skillScores'] ?? j['skill_scores']) as Map<String, dynamic>?;
    return Assessment(
      id: _s(j, ['id']),
      staffId: _s(j, ['staffId', 'staff_id']),
      assessorId: _sn(j, ['assessorId', 'assessor_id']),
      attemptNumber: _i(j, ['attemptNumber', 'attempt_number'], 1),
      status: _s(j, ['status'], 'PENDING'),
      assessmentType: skillScores == null ? null : _sn(skillScores, ['assessmentType', 'assessment_type']),
      score: skillScores == null ? null : _nn(skillScores, ['score']),
      result: _sn(j, ['result']),
      remarks: _sn(j, ['remarks']),
      approvedAt: _sn(j, ['approvedAt', 'approved_at']),
      createdAt: _sn(j, ['createdAt', 'created_at']),
    );
  }

  static AssessmentSubmitResult decodeAssessmentSubmitResult(Map<String, dynamic> j) =>
      AssessmentSubmitResult(
        assessment: decodeAssessment(j),
        autoTerminated: _b(j, ['autoTerminated']),
        terminalOutcome: _sn(j, ['terminalOutcome']),
        message: _sn(j, ['message']),
      );

  // ── Agreements ──

  static Agreement decodeAgreement(Map<String, dynamic> j) => Agreement(
        id: _s(j, ['id']),
        staffId: _sn(j, ['staff_id', 'staffId']),
        clientId: _s(j, ['client_id', 'clientId']),
        placementId: _sn(j, ['placement_id', 'placementId']),
        type: _s(j, ['type']),
        status: _s(j, ['status'], 'PENDING'),
        otpVerified: _b(j, ['otp_verified', 'otpVerified']),
        pdfUrl: _sn(j, ['pdf_url', 'pdfUrl']),
        createdAt: _sn(j, ['created_at', 'createdAt']),
      );

  static SendOtpResult decodeSendOtpResult(Map<String, dynamic> j) => SendOtpResult(
        agreementType: _s(j, ['agreement_type', 'agreementType']),
        staffName: _s(j, ['staff_name', 'staffName']),
        expiresInMinutes: _i(j, ['expires_in_minutes', 'expiresInMinutes'], 10),
        devOtp: _sn(j, ['dev_otp', 'devOtp']),
      );

  static SignAgreementResult decodeSignResult(Map<String, dynamic> j) => SignAgreementResult(
        id: _s(j, ['id']),
        status: _s(j, ['status']),
        type: _s(j, ['type']),
        clientId: _s(j, ['clientId', 'client_id']),
      );

  static GeneratePdfResult decodeGeneratePdfResult(Map<String, dynamic> j) => GeneratePdfResult(
        agreementId: _s(j, ['agreement_id', 'agreementId']),
        pdfUrl: _s(j, ['pdf_url', 'pdfUrl']),
        sha256: _s(j, ['sha256']),
      );

  static ScopeOfWork decodeSow(Map<String, dynamic> j) => ScopeOfWork(
        id: _s(j, ['id']),
        placementId: _s(j, ['placementId', 'placement_id']),
        clientId: _s(j, ['clientId', 'client_id']),
        staffId: _s(j, ['staffId', 'staff_id']),
        content: _s(j, ['content']),
        version: _i(j, ['version'], 1),
        status: _s(j, ['status'], 'DRAFT'),
        isNonStandard: _b(j, ['isNonStandard', 'is_non_standard']),
        sentAt: _sn(j, ['sentAt', 'sent_at']),
        acknowledgedAt: _sn(j, ['acknowledgedAt', 'acknowledged_at']),
        supersedesId: _sn(j, ['supersedesId', 'supersedes_id']),
        createdAt: _sn(j, ['createdAt', 'created_at']),
      );

  // ── Verification (S2) ──

  static AadhaarResult decodeAadhaar(Map<String, dynamic> j) => AadhaarResult(
        nameLast4: _s(j, ['aadhaar_number_last4', 'aadhaarNumberLast4']),
        name: _s(j, ['name']),
        verified: _b(j, ['verified']),
      );

  static DlResult decodeDl(Map<String, dynamic> j) => DlResult(
        dlNumber: _s(j, ['dl_number', 'dlNumber']),
        name: _s(j, ['name']),
        status: _s(j, ['status']),
        vehicleClasses: _sl(j, ['vehicle_classes', 'vehicleClasses']),
      );

  static EchallanResult decodeEchallan(Map<String, dynamic> j) => EchallanResult(
        count: _i(j, ['count']),
      );

  static PvResult decodePv(Map<String, dynamic> j) => PvResult(
        referenceNumber: _s(j, ['reference_number', 'referenceNumber']),
        status: _s(j, ['status'], 'PENDING'),
        submittedAt: _s(j, ['submitted_at', 'submittedAt']),
      );

  static MedicalResult decodeMedical(Map<String, dynamic> j) => MedicalResult(
        status: _s(j, ['status']),
        notes: _s(j, ['notes']),
        date: _s(j, ['date']),
      );

  /// `GET /verification/:staffId` — aggregated read-back of all 5 tracks.
  /// No documented response schema (Swagger only shows `200: {}`), so this
  /// decoder is intentionally forgiving: it treats the response as a map of
  /// track-type keys to result maps, plus an optional `required`/`series`
  /// hint list, and returns raw status strings per track rather than
  /// asserting a specific shape.
  static Map<String, String> decodeVerificationStatus(Map<String, dynamic> j) {
    final tracks = (j['tracks'] as Map<String, dynamic>?) ?? j;
    final result = <String, String>{};
    for (final entry in tracks.entries) {
      if (entry.value is Map<String, dynamic>) {
        final status = _sn(entry.value as Map<String, dynamic>, ['status']);
        if (status != null) result[entry.key] = status;
      } else if (entry.value is String) {
        result[entry.key] = entry.value as String;
      }
    }
    return result;
  }

  // ── Video certification ──

  static VideoCertPrompts decodeVideoCertPrompts(Map<String, dynamic> j) => VideoCertPrompts(
        count: _i(j, ['count']),
        minDuration: _i(j, ['minDuration', 'min_duration']),
        prompts: _sl(j, ['prompts']),
      );

  static VideoCertItem decodeVideoCertItem(Map<String, dynamic> j) => VideoCertItem(
        id: _s(j, ['id']),
        staffId: _s(j, ['staffId', 'staff_id']),
        promptKey: _s(j, ['promptKey', 'prompt_key']),
        videoUrl: _s(j, ['videoUrl', 'video_url']),
        attemptNumber: _i(j, ['attemptNumber', 'attempt_number'], 1),
        reviewStatus: _s(j, ['reviewStatus', 'review_status'], 'PENDING'),
        reviewNotes: _sn(j, ['reviewNotes', 'review_notes']),
        createdAt: _sn(j, ['createdAt', 'created_at']),
      );
}
