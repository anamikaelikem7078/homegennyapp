import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/data/datasources/base_local_datasource.dart';
import '../../../../core/data/datasources/json_asset_loader.dart';
import '../../../../core/data/models/api_response.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/models/rm_models.dart';
import '../datasources/rm_dummy_api.dart';
import '../models/rm_dtos.dart';

class RmRemoteDataSource extends BaseRemoteDataSource {
  RmRemoteDataSource(super.dio);

  Future<RmDashboardData> getDashboard() async {
    final json = await getJson(ApiConstants.rmDashboard);
    return RmDtoCodec.decodeDashboard(json);
  }

  Future<PaginatedResponse<RmStaffMember>> getStaff(PaginationParams params) async {
    final json = await getJson(ApiConstants.rmStaff, queryParameters: params.toQueryParams());
    return PaginatedResponse.fromJson(json, RmDtoCodec.decodeStaff);
  }

  Future<PaginatedResponse<RmClient>> getClients(PaginationParams params) async {
    final json = await getJson(ApiConstants.rmClients, queryParameters: params.toQueryParams());
    return PaginatedResponse.fromJson(json, RmDtoCodec.decodeClient);
  }

  Future<void> approveDocument(String id, {String? remarks}) async {
    await postJson('${ApiConstants.rmVerification}/$id/approve', data: {'remarks': remarks});
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String staffId,
    required String documentType,
  }) async {
    return uploadMultipart(
      ApiConstants.uploadDocument,
      formData: FormData.fromMap({
        'staff_id': staffId,
        'document_type': documentType,
        'file': await MultipartFile.fromFile(filePath),
      }),
    );
  }
}

class RmLocalDataSource extends BaseLocalDataSource {
  RmLocalDataSource(super.hive);

  Future<void> cacheDashboard(RmDashboardData data) =>
      saveJson(StorageKeys.rmDashboard, RmDtoCodec.encodeDashboard(data));

  RmDashboardData? getDashboard() {
    final json = getJson(StorageKeys.rmDashboard);
    return json != null ? RmDtoCodec.decodeDashboard(json) : null;
  }

  Future<void> cacheStaffList(List<RmStaffMember> staff) => saveJsonList(
        StorageKeys.rmStaffList,
        staff.map(RmDtoCodec.encodeStaff).toList(),
      );

  List<RmStaffMember>? getStaffList() {
    final list = getJsonList(StorageKeys.rmStaffList);
    return list?.map(RmDtoCodec.decodeStaff).toList();
  }
}

class RmDummyDataSource {
  RmDummyDataSource({RmDummyApi? api, JsonAssetLoader? jsonLoader})
      : _api = api ?? RmDummyApi(),
        _json = jsonLoader ?? JsonAssetLoader();

  final RmDummyApi _api;
  final JsonAssetLoader _json;

  Future<RmDashboardData> getDashboard() async {
    try {
      final json = await _json.loadMap('assets/json/rm/dashboard.json');
      final base = RmDtoCodec.decodeDashboard(json);
      final followUps = await _api.getTodaysFollowUps();
      return RmDashboardData(
        rmName: base.rmName,
        followUpsToday: followUps,
        pendingVerification: base.pendingVerification,
        pendingTraining: base.pendingTraining,
        pendingAgreement: base.pendingAgreement,
        pendingDeployment: base.pendingDeployment,
        clientRequests: base.clientRequests,
        totalStaff: base.totalStaff,
        totalClients: base.totalClients,
        unreadNotifications: base.unreadNotifications,
      );
    } catch (_) {
      return _api.getDashboard();
    }
  }

  Future<List<RmFollowUp>> getTodaysFollowUps() => _api.getTodaysFollowUps();
  Future<List<RmStaffMember>> getStaff({String? query}) => _api.getStaff(query: query);
  Future<RmStaffDetail> getStaffDetail(String id) => _api.getStaffDetail(id);
  Future<void> createStaff(Map<String, String> data) => _api.createStaff(data);
  Future<void> updateStaff(String id, Map<String, String> data) => _api.updateStaff(id, data);
  Future<List<RmClient>> getClients({String? query}) => _api.getClients(query: query);
  Future<RmClient> getClientDetail(String id) => _api.getClientDetail(id);
  Future<List<RmPendingDocument>> getPendingDocuments() => _api.getPendingDocuments();
  Future<void> approveDocument(String id, {String? remarks}) => _api.approveDocument(id, remarks: remarks);
  Future<void> rejectDocument(String id, String remarks) => _api.rejectDocument(id, remarks);
  Future<List<RmPendingVideo>> getPendingVideos() => _api.getPendingVideos();
  Future<void> approveVideo(String id, {String? remarks}) => _api.approveVideo(id, remarks: remarks);
  Future<void> rejectVideo(String id, String remarks) => _api.rejectVideo(id, remarks);
  Future<void> assignTraining(String staffId, String courseId) => _api.assignTraining(staffId, courseId);
  Future<List<RmDeployment>> getDeployments() => _api.getDeployments();
  Future<void> assignDeployment({required String staffId, required String clientId, required String type}) =>
      _api.assignDeployment(staffId: staffId, clientId: clientId, type: type);
  Future<RmReportSummary> getReport(RmReportPeriod period) => _api.getReport(period);
  Future<RmReportSummary> getAttendanceReport() => _api.getAttendanceReport();
  Future<RmReportSummary> getPipelineReport() => _api.getPipelineReport();
  Future<RmReportSummary> getDeploymentReport() => _api.getDeploymentReport();
  Future<List<RmClientRequest>> getClientRequests() => _api.getClientRequests();
  Future<List<RmNotification>> getNotifications() => _api.getNotifications();
  Future<void> markNotificationRead(String id) => _api.markNotificationRead(id);
}
