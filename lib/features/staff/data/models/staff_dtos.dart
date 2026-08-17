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
