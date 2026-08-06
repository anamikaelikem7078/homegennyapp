import '../../domain/models/rm_models.dart';

/// RM module DTO codec for JSON ↔ domain mapping.
abstract final class RmDtoCodec {
  static Map<String, dynamic> encodeDashboard(RmDashboardData d) => {
        'rm_name': d.rmName,
        'pending_verification': d.pendingVerification,
        'pending_training': d.pendingTraining,
        'pending_agreement': d.pendingAgreement,
        'pending_deployment': d.pendingDeployment,
        'client_requests': d.clientRequests,
        'total_staff': d.totalStaff,
        'total_clients': d.totalClients,
        'unread_notifications': d.unreadNotifications,
      };

  static RmDashboardData decodeDashboard(Map<String, dynamic> json) => RmDashboardData(
        rmName: json['rm_name'] as String,
        followUpsToday: const [],
        pendingVerification: json['pending_verification'] as int,
        pendingTraining: json['pending_training'] as int,
        pendingAgreement: json['pending_agreement'] as int,
        pendingDeployment: json['pending_deployment'] as int,
        clientRequests: json['client_requests'] as int,
        totalStaff: json['total_staff'] as int,
        totalClients: json['total_clients'] as int,
        unreadNotifications: json['unread_notifications'] as int,
      );

  static Map<String, dynamic> encodeStaff(RmStaffMember s) => {
        'id': s.id, 'name': s.name, 'phone': s.phone, 'email': s.email,
        'role': s.role, 'department': s.department, 'status': s.status,
        'pipeline_stage': s.pipelineStage, 'training_progress': s.trainingProgress,
        'joining_date': s.joiningDate,
      };

  static RmStaffMember decodeStaff(Map<String, dynamic> json) => RmStaffMember(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        role: json['role'] as String,
        department: json['department'] as String,
        status: json['status'] as String,
        pipelineStage: json['pipeline_stage'] as String,
        trainingProgress: (json['training_progress'] as num).toDouble(),
        joiningDate: json['joining_date'] as String,
      );

  static Map<String, dynamic> encodeClient(RmClient c) => {
        'id': c.id, 'name': c.name, 'phone': c.phone, 'email': c.email,
        'address': c.address, 'requirements': c.requirements,
        'assigned_staff_id': c.assignedStaffId, 'assigned_staff_name': c.assignedStaffName,
        'status': c.status,
      };

  static RmClient decodeClient(Map<String, dynamic> json) => RmClient(
        id: json['id'] as String,
        name: json['name'] as String,
        phone: json['phone'] as String,
        email: json['email'] as String,
        address: json['address'] as String,
        requirements: json['requirements'] as String,
        assignedStaffId: json['assigned_staff_id'] as String?,
        assignedStaffName: json['assigned_staff_name'] as String?,
        status: json['status'] as String,
      );
}
