import '../../../../core/utils/result.dart';
import '../models/rm_models.dart';

/// RM module repository contract.
abstract interface class RmRepository {
  Future<Result<RmDashboardData>> getDashboard();
  Future<Result<List<RmFollowUp>>> getTodaysFollowUps();
  Future<Result<List<RmStaffMember>>> getStaff({String? query});
  Future<Result<RmStaffDetail>> getStaffDetail(String id);
  Future<Result<void>> createStaff(Map<String, String> data);
  Future<Result<void>> updateStaff(String id, Map<String, String> data);
  Future<Result<List<RmClient>>> getClients({String? query});
  Future<Result<RmClient>> getClientDetail(String id);
  Future<Result<List<RmPendingDocument>>> getPendingDocuments();
  Future<Result<void>> approveDocument(String id, {String? remarks});
  Future<Result<void>> rejectDocument(String id, String remarks);
  Future<Result<List<RmPendingVideo>>> getPendingVideos();
  Future<Result<void>> approveVideo(String id, {String? remarks});
  Future<Result<void>> rejectVideo(String id, String remarks);
  Future<Result<void>> assignTraining(String staffId, String courseId);
  Future<Result<List<RmDeployment>>> getDeployments();
  Future<Result<void>> assignDeployment({
    required String staffId,
    required String clientId,
    required String type,
  });
  Future<Result<RmReportSummary>> getReport(RmReportPeriod period);
  Future<Result<RmReportSummary>> getAttendanceReport();
  Future<Result<RmReportSummary>> getPipelineReport();
  Future<Result<RmReportSummary>> getDeploymentReport();
  Future<Result<List<RmClientRequest>>> getClientRequests();
  Future<Result<List<RmNotification>>> getNotifications();
  Future<Result<void>> markNotificationRead(String id);
}
