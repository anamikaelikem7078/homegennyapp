import '../../../../core/utils/currency_formatter.dart';
import '../../domain/models/staff_models.dart';

/// Staff module DTOs with JSON serialization and domain mapping.
abstract final class StaffDtoCodec {
  // ── Dashboard ── (matches GET /staff/dashboard exactly — flat, camelCase)
  static Map<String, dynamic> encodeDashboard(StaffDashboardData d) => {
        'staffCode': d.staffCode,
        'fullName': d.fullName,
        'series': d.series,
        'pipelineStage': d.pipelineStage,
        'completionPct': d.completionPct,
        'assignedRm': {'name': d.assignedRmName, 'phone': d.assignedRmPhone},
        'todayTasks': d.todayTasks.map(encodeTask).toList(),
      };

  static StaffDashboardData decodeDashboard(Map<String, dynamic> json) {
    final rm = json['assignedRm'] as Map<String, dynamic>?;
    return StaffDashboardData(
      staffCode: json['staffCode'] as String? ?? '',
      fullName: json['fullName'] as String? ?? '',
      series: json['series'] as String? ?? '',
      pipelineStage: json['pipelineStage'] as String? ?? '',
      completionPct: json['completionPct'] as int? ?? 0,
      assignedRmName: rm?['name'] as String? ?? '',
      assignedRmPhone: rm?['phone'] as String? ?? '',
      todayTasks: ((json['todayTasks'] as List<dynamic>?) ?? [])
          .map((e) => decodeTask(e as Map<String, dynamic>))
          .toList(),
    );
  }

  // ── Profile ── (matches GET /staff/profile exactly)
  static Map<String, dynamic> encodeProfile(StaffProfile p) => {
        'id': p.id,
        'staffApplicantId': p.staffApplicantId,
        'staffCode': p.staffCode,
        'fullName': p.fullName,
        'mobile': p.mobile,
        'email': p.email,
        'series': p.series,
        'pipelineStage': p.pipelineStage,
        'address': p.address,
        'dateOfBirth': p.dateOfBirth,
      };

  static StaffProfile decodeProfile(Map<String, dynamic> json) => StaffProfile(
        id: json['id'] as String? ?? '',
        staffApplicantId: json['staffApplicantId'] as String?,
        staffCode: json['staffCode'] as String? ?? '',
        fullName: json['fullName'] as String? ?? '',
        mobile: json['mobile'] as String? ?? '',
        email: json['email'] as String? ?? '',
        series: json['series'] as String? ?? '',
        pipelineStage: json['pipelineStage'] as String? ?? '',
        address: json['address'] as String?,
        dateOfBirth: json['dateOfBirth']?.toString(),
      );

  // ── Task ── (matches GET /staff/dashboard `todayTasks[]` item exactly —
  // hardcoded server-side per the backend, but decoded like any real field)
  static Map<String, dynamic> encodeTask(StaffTask t) => {
        'id': t.id, 'title': t.title, 'done': t.done,
      };

  static StaffTask decodeTask(Map<String, dynamic> json) => StaffTask(
        id: json['id'].toString(),
        title: json['title'] as String? ?? '',
        done: json['done'] as bool? ?? false,
      );

  // ── Pipeline ──
  static Map<String, dynamic> encodePipelineStage(PipelineStage s) => {
        'id': s.id, 'title': s.title, 'description': s.description,
        'status': s.status.name, 'completed_at': s.completedAt,
      };

  static PipelineStage decodePipelineStage(Map<String, dynamic> json) => PipelineStage(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        status: PipelineStageStatus.values.byName(json['status'] as String),
        completedAt: json['completed_at'] as String?,
      );

  // ── Document ──
  static Map<String, dynamic> encodeDocument(StaffDocument d) => {
        'id': d.id, 'name': d.name, 'type': d.type, 'uploaded_at': d.uploadedAt,
        'status': d.status.name, 'rejection_reason': d.rejectionReason,
      };

  static StaffDocument decodeDocument(Map<String, dynamic> json) => StaffDocument(
        id: json['id'] as String,
        name: json['name'] as String,
        type: json['type'] as String,
        uploadedAt: json['uploaded_at'] as String,
        status: DocumentApprovalStatus.values.byName(json['status'] as String),
        rejectionReason: json['rejection_reason'] as String?,
      );

  // ── Attendance ── (matches GET /staff/attendance/history `history[]` item
  // exactly — snake_case check_in/check_out, lowercase status)
  static Map<String, dynamic> encodeAttendance(AttendanceRecord r) => {
        'date': r.date, 'check_in': r.checkIn, 'check_out': r.checkOut,
        'status': r.status, 'location': r.location,
      };

  static AttendanceRecord decodeAttendance(Map<String, dynamic> json) => AttendanceRecord(
        date: json['date'] as String? ?? '',
        checkIn: json['check_in'] as String?,
        checkOut: json['check_out'] as String?,
        status: json['status'] as String? ?? 'absent',
        location: json['location'] as String?,
      );

  // ── Deployment ── (matches GET /staff/deployment exactly)
  static Map<String, dynamic> encodeDeployment(DeploymentInfo d) => {
        'hasActivePlacement': d.hasActivePlacement,
        'placementId': d.placementId,
        'clientName': d.clientName,
        'deploymentAddress': d.deploymentAddress,
        'deploymentDate': d.deploymentDate,
        'trialStatus': d.trialStatus,
      };

  static DeploymentInfo decodeDeployment(Map<String, dynamic> json) => DeploymentInfo(
        hasActivePlacement: json['hasActivePlacement'] as bool? ?? false,
        placementId: json['placementId'] as String?,
        clientName: json['clientName'] as String?,
        deploymentAddress: json['deploymentAddress'] as String?,
        deploymentDate: json['deploymentDate'] as String?,
        trialStatus: json['trialStatus'] as String?,
      );

  // ── Check-in / check-out result ── (matches both
  // POST /staff/attendance/check-in and .../check-out response exactly)
  static CheckInResult decodeCheckInResult(Map<String, dynamic> json) => CheckInResult(
        success: json['success'] as bool? ?? true,
        attendanceId: json['attendanceId'] as String? ?? '',
        status: json['status'] as String? ?? 'CHECKED_IN',
        timestamp: json['timestamp'] as String? ?? '',
        latitude: (json['latitude'] as num?)?.toDouble(),
        longitude: (json['longitude'] as num?)?.toDouble(),
      );

  // ── Notification ──
  static Map<String, dynamic> encodeNotification(StaffNotification n) => {
        'id': n.id, 'title': n.title, 'message': n.message,
        'time': n.time, 'is_read': n.isRead, 'type': n.type,
      };

  static StaffNotification decodeNotification(Map<String, dynamic> json) =>
      StaffNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        message: json['message'] as String,
        time: json['time'] as String,
        isRead: json['is_read'] as bool,
        type: json['type'] as String,
      );

  static List<Map<String, dynamic>> encodeList<T>(
    List<T> items,
    Map<String, dynamic> Function(T) encoder,
  ) => items.map(encoder).toList();

  static List<T> decodeList<T>(
    List<dynamic> json,
    T Function(Map<String, dynamic>) decoder,
  ) => json.map((e) => decoder(e as Map<String, dynamic>)).toList();

  // ── Video certification ── (GET /video-cert/prompts/:series returns
  // `{ count, minDuration, prompts: string[] }` — prompts have no server-side
  // id/title, just the raw question text, so the app derives a stable
  // `prompt_<n>` key (1-based, matching the `promptKey` example in the
  // backend's own API docs) from list position.
  static List<VideoCertPrompt> decodeVideoCertPrompts(Map<String, dynamic> json) {
    final prompts = (json['prompts'] as List<dynamic>? ?? []).cast<String>();
    return [
      for (var i = 0; i < prompts.length; i++)
        VideoCertPrompt(
          id: 'prompt_${i + 1}',
          title: 'Prompt ${i + 1}',
          instructions: prompts[i],
          status: VideoCertStatus.pending,
        ),
    ];
  }

  // ── Video certification upload record ── (matches a row returned by
  // GET /video-cert/list/:staffId exactly — Prisma's VideoCertification
  // model serialized as-is: camelCase field names).
  static VideoCertUploadRecord decodeVideoCertUpload(Map<String, dynamic> json) =>
      VideoCertUploadRecord(
        id: json['id'] as String? ?? '',
        promptKey: json['promptKey'] as String? ?? '',
        reviewStatus: json['reviewStatus'] as String? ?? 'PENDING',
        attemptNumber: json['attemptNumber'] as int? ?? 1,
      );

  static const _monthNames = [
    '', 'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December',
  ];

  static String _periodLabel(int? month, int? year) {
    if (month == null || year == null || month < 1 || month > 12) return '';
    return '${_monthNames[month]} $year';
  }

  static List<SalaryHouse> _decodeHouses(List<dynamic>? json) => (json ?? [])
      .map((e) => e as Map<String, dynamic>)
      .map((h) => SalaryHouse(
            clientName: h['client_name'] as String? ?? h['clientName'] as String? ?? '',
            placementType: h['placement_type'] as String? ?? h['placementType'] as String? ?? '',
            worked: h['worked'] as String? ?? '',
            grossSalary: (h['gross_salary'] as num?)?.toDouble() ??
                (h['grossSalary'] as num?)?.toDouble() ?? 0,
          ))
      .toList();

  /// Decodes one `salary`-shaped object — shared by GET /staff/salary's
  /// `salary` field and each item of GET /staff/payslips' `items[]`, which
  /// are identical in shape per the backend audit (snake_case wire fields:
  /// period_month, period_year, days_worked, gross_salary, esic_employee,
  /// pf_employee, total_deductions, net_salary, status, houses[]).
  static ({
    String month,
    String ref,
    String gross,
    String deductions,
    String net,
    String status,
    List<SalaryHouse> houses,
    int? presentDays,
    Map<String, double> deductionBreakdown,
  }) _decodeSalaryObject(Map<String, dynamic> json) {
    final month = json['period_month'] as int? ?? json['periodMonth'] as int?;
    final year = json['period_year'] as int? ?? json['periodYear'] as int?;
    final esic = (json['esic_employee'] as num?)?.toDouble();
    final pf = (json['pf_employee'] as num?)?.toDouble();
    return (
      month: _periodLabel(month, year),
      ref: '${month ?? ''}-${year ?? ''}',
      gross: CurrencyFormatter.inr(((json['gross_salary'] as num?) ?? 0).toDouble()),
      deductions: CurrencyFormatter.inr(((json['total_deductions'] as num?) ?? 0).toDouble()),
      net: CurrencyFormatter.inr(((json['net_salary'] as num?) ?? 0).toDouble()),
      status: json['status'] as String? ?? '',
      houses: _decodeHouses(json['houses'] as List<dynamic>?),
      presentDays: json['days_worked'] as int?,
      deductionBreakdown: {
        if (esic != null) 'esic': esic,
        if (pf != null) 'pf': pf,
      },
    );
  }

  // ── Salary summary ── (matches GET /staff/salary exactly — `{"salary":
  // {...}}` normally, or `{"salary": null, "message": "..."}` as a normal
  // 200 before any payroll has run for this staff member)
  static SalarySummary decodeSalarySummary(Map<String, dynamic> json) {
    final salary = json['salary'] as Map<String, dynamic>?;
    if (salary == null) {
      return SalarySummary(
        hasPayslips: false,
        month: '',
        gross: '',
        deductions: '',
        net: '',
        status: '',
        emptyMessage: json['message'] as String? ?? 'No payroll has been run for you yet.',
      );
    }
    final s = _decodeSalaryObject(salary);
    return SalarySummary(
      hasPayslips: true,
      month: s.month,
      gross: s.gross,
      deductions: s.deductions,
      net: s.net,
      status: s.status,
      houses: s.houses,
      ref: s.ref,
    );
  }

  // ── Payslip ── (matches one item of GET /staff/payslips `items[]` —
  // same shape as the GET /staff/salary `salary` object)
  static Payslip decodePayslip(Map<String, dynamic> json) {
    final s = _decodeSalaryObject(json);
    return Payslip(
      ref: s.ref,
      month: s.month,
      amount: s.net,
      grossAmount: s.gross,
      deductionsAmount: s.deductions,
      deductionBreakdown: s.deductionBreakdown,
      status: s.status,
      houses: s.houses,
      presentDays: s.presentDays,
    );
  }

  // ── Agreement status ── (GET /staff/agreement — read-only status; the
  // exact field set isn't documented beyond "status", so this decode is
  // tolerant and keeps the existing title/content placeholders when the
  // backend doesn't return document text on this read endpoint)
  static StaffAgreement decodeAgreement(Map<String, dynamic> json) {
    final statusStr = (json['status'] as String? ?? 'pending').toLowerCase();
    final status = AgreementStatus.values.firstWhere(
      (s) => s.name == statusStr,
      orElse: () => AgreementStatus.pending,
    );
    return StaffAgreement(
      id: json['id'] as String? ?? '',
      title: json['title'] as String? ?? 'Employment Agreement',
      content: json['content'] as String? ?? '',
      status: status,
      signedAt: json['signedAt'] as String? ?? json['signed_at'] as String?,
    );
  }

  // ── Bank account ── (matches GET /staff/bank-account's `bankAccount`
  // object exactly)
  static BankDetails decodeBankDetails(Map<String, dynamic> json) {
    final b = json['bankAccount'] as Map<String, dynamic>? ?? json;
    return BankDetails(
      accountHolderName: b['accountHolderName'] as String? ?? '',
      accountNumberMasked: b['accountNumberMasked'] as String? ?? '',
      last4: b['last4'] as String? ?? '',
      ifsc: b['ifsc'] as String? ?? '',
      bankName: b['bankName'] as String? ?? '',
      verified: b['verified'] as bool? ?? false,
      verifiedAt: b['verifiedAt'] as String?,
    );
  }
}

/// Server-issued destination for a single video upload — matches
/// POST /video-cert/upload-url's response exactly.
class VideoCertUploadUrlInfo {
  const VideoCertUploadUrlInfo({
    required this.uploadUrl,
    required this.gcsKey,
    this.fields,
  });

  final String uploadUrl;
  final String gcsKey;
  final Map<String, dynamic>? fields;

  factory VideoCertUploadUrlInfo.fromJson(Map<String, dynamic> json) =>
      VideoCertUploadUrlInfo(
        uploadUrl: json['uploadUrl'] as String,
        gcsKey: json['gcsKey'] as String,
        fields: (json['fields'] as Map<String, dynamic>?),
      );
}

/// One row from GET /video-cert/list/:staffId — the staff's own upload
/// history, used to drive per-prompt status badges instead of local state.
class VideoCertUploadRecord {
  const VideoCertUploadRecord({
    required this.id,
    required this.promptKey,
    required this.reviewStatus,
    required this.attemptNumber,
  });

  final String id;
  final String promptKey;
  final String reviewStatus;
  final int attemptNumber;

  VideoCertStatus get status {
    switch (reviewStatus) {
      case 'APPROVED':
        return VideoCertStatus.approved;
      case 'REJECTED':
        return VideoCertStatus.rejected;
      default:
        return VideoCertStatus.pending;
    }
  }
}

/// Paginated staff documents response DTO.
class StaffDocumentsPageDto {
  const StaffDocumentsPageDto({required this.items, required this.page, required this.total});

  final List<StaffDocument> items;
  final int page;
  final int total;

  factory StaffDocumentsPageDto.fromJson(Map<String, dynamic> json) {
    final items = (json['items'] as List<dynamic>? ?? [])
        .map((e) => StaffDtoCodec.decodeDocument(e as Map<String, dynamic>))
        .toList();
    return StaffDocumentsPageDto(
      items: items,
      page: json['page'] as int? ?? 1,
      total: json['total'] as int? ?? items.length,
    );
  }
}
