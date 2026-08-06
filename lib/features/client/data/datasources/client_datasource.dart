import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/data/datasources/base_local_datasource.dart';
import '../../../../core/data/datasources/json_asset_loader.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/models/client_models.dart';
import '../datasources/client_dummy_api.dart';
import '../models/client_dtos.dart';

class ClientRemoteDataSource extends BaseRemoteDataSource {
  ClientRemoteDataSource(super.dio);

  Future<ClientDashboardData> getDashboard() async {
    final json = await getJson(ApiConstants.clientDashboard);
    return ClientDtoCodec.decodeDashboard(json);
  }

  Future<ClientProfile> getProfile() async {
    final json = await getJson(ApiConstants.clientProfile);
    return ClientDtoCodec.decodeProfile(json);
  }

  Future<Map<String, dynamic>> raiseComplaint({
    required String subject,
    required String description,
    List<String>? imagePaths,
  }) async {
    final formMap = <String, dynamic>{
      'subject': subject,
      'description': description,
    };
    if (imagePaths != null) {
      for (var i = 0; i < imagePaths.length; i++) {
        formMap['images[$i]'] = await MultipartFile.fromFile(imagePaths[i]);
      }
    }
    return uploadMultipart(ApiConstants.clientComplaints, formData: FormData.fromMap(formMap));
  }
}

class ClientLocalDataSource extends BaseLocalDataSource {
  ClientLocalDataSource(super.hive);

  Future<void> cacheDashboard(ClientDashboardData data) =>
      saveJson(StorageKeys.clientDashboard, ClientDtoCodec.encodeDashboard(data));

  ClientDashboardData? getDashboard() {
    final json = getJson(StorageKeys.clientDashboard);
    return json != null ? ClientDtoCodec.decodeDashboard(json) : null;
  }

  Future<void> cacheProfile(ClientProfile profile) =>
      saveJson(StorageKeys.clientProfile, ClientDtoCodec.encodeProfile(profile));

  ClientProfile? getProfile() {
    final json = getJson(StorageKeys.clientProfile);
    return json != null ? ClientDtoCodec.decodeProfile(json) : null;
  }
}

class ClientDummyDataSource {
  ClientDummyDataSource({ClientDummyApi? api, JsonAssetLoader? jsonLoader})
      : _api = api ?? ClientDummyApi(),
        _json = jsonLoader ?? JsonAssetLoader();

  final ClientDummyApi _api;
  final JsonAssetLoader _json;

  Future<ClientDashboardData> getDashboard() async {
    try {
      final json = await _json.loadMap('assets/json/client/dashboard.json');
      return ClientDtoCodec.decodeDashboard(json);
    } catch (_) {
      return _api.getDashboard();
    }
  }

  Future<ClientStaffProfile> getStaffProfile(String staffId) => _api.getStaffProfile(staffId);
  Future<ClientTodayAttendance> getTodayAttendance() => _api.getTodayAttendance();
  Future<List<ClientAttendanceRecord>> getAttendanceHistory() => _api.getAttendanceHistory();
  Future<void> raiseAttendanceIssue(String message) => _api.raiseAttendanceIssue(message);
  Future<ClientInvoice> getCurrentInvoice() => _api.getCurrentInvoice();
  Future<List<ClientPaymentHistory>> getPaymentHistory() => _api.getPaymentHistory();
  Future<String> downloadInvoice(String invoiceId) => _api.downloadInvoice(invoiceId);
  Future<List<ClientComplaint>> getComplaints() => _api.getComplaints();
  Future<void> raiseComplaint({required String subject, required String description, int imageCount = 0}) =>
      _api.raiseComplaint(subject: subject, description: description, imageCount: imageCount);
  Future<ClientReplacementRequest?> getReplacementStatus() => _api.getReplacementStatus();
  Future<void> requestReplacement(String reason) => _api.requestReplacement(reason);
  Future<List<ClientNotification>> getNotifications() => _api.getNotifications();
  Future<void> markNotificationRead(String id) => _api.markNotificationRead(id);
  Future<ClientProfile> getProfile() => _api.getProfile();
  Future<void> updateProfile(Map<String, String> data) => _api.updateProfile(data);
}
