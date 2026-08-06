import '../../domain/models/staff_models.dart';

/// Staff module DTOs with JSON serialization and domain mapping.
abstract final class StaffDtoCodec {
  // ── Dashboard ──
  static Map<String, dynamic> encodeDashboard(StaffDashboardData d) => {
        'profile': encodeProfile(d.profile),
        'tasks': d.tasks.map(encodeTask).toList(),
        'current_stage': encodePipelineStage(d.currentStage),
        'attendance_today': d.attendanceToday != null ? encodeAttendance(d.attendanceToday!) : null,
        'unread_notifications': d.unreadNotifications,
        'profile_completion': d.profileCompletion,
      };

  static StaffDashboardData decodeDashboard(Map<String, dynamic> json) =>
      StaffDashboardData(
        profile: decodeProfile(json['profile'] as Map<String, dynamic>),
        tasks: (json['tasks'] as List<dynamic>)
            .map((e) => decodeTask(e as Map<String, dynamic>))
            .toList(),
        currentStage: decodePipelineStage(json['current_stage'] as Map<String, dynamic>),
        attendanceToday: json['attendance_today'] != null
            ? decodeAttendance(json['attendance_today'] as Map<String, dynamic>)
            : null,
        unreadNotifications: json['unread_notifications'] as int? ?? 0,
        profileCompletion: json['profile_completion'] as int? ?? 0,
      );

  // ── Profile ──
  static Map<String, dynamic> encodeProfile(StaffProfile p) => {
        'id': p.id, 'name': p.name, 'email': p.email, 'phone': p.phone,
        'role': p.role, 'department': p.department, 'employee_id': p.employeeId,
        'joining_date': p.joiningDate, 'completion_percent': p.completionPercent,
        'avatar_url': p.avatarUrl,
      };

  static StaffProfile decodeProfile(Map<String, dynamic> json) => StaffProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        role: json['role'] as String,
        department: json['department'] as String,
        employeeId: json['employee_id'] as String,
        joiningDate: json['joining_date'] as String,
        completionPercent: json['completion_percent'] as int,
        avatarUrl: json['avatar_url'] as String?,
      );

  // ── Task ──
  static Map<String, dynamic> encodeTask(StaffTask t) => {
        'id': t.id, 'title': t.title, 'description': t.description,
        'due_time': t.dueTime, 'priority': t.priority.name, 'is_completed': t.isCompleted,
      };

  static StaffTask decodeTask(Map<String, dynamic> json) => StaffTask(
        id: json['id'] as String,
        title: json['title'] as String,
        description: json['description'] as String,
        dueTime: json['due_time'] as String,
        priority: TaskPriority.values.byName(json['priority'] as String),
        isCompleted: json['is_completed'] as bool,
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

  // ── Attendance ──
  static Map<String, dynamic> encodeAttendance(AttendanceRecord r) => {
        'id': r.id, 'date': r.date, 'check_in': r.checkIn, 'check_out': r.checkOut,
        'status': r.status.name, 'location': r.location,
      };

  static AttendanceRecord decodeAttendance(Map<String, dynamic> json) => AttendanceRecord(
        id: json['id'] as String,
        date: json['date'] as String,
        checkIn: json['check_in'] as String?,
        checkOut: json['check_out'] as String?,
        status: AttendanceDayStatus.values.byName(json['status'] as String),
        location: json['location'] as String?,
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
