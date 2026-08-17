import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../common/domain/models/placement_entity.dart';
import '../../../../common/domain/models/attendance_entity.dart';
import '../../../../common/domain/models/invoice_entity.dart';
import '../../../../common/domain/models/payment_entity.dart';
import '../../../../common/domain/models/complaint_entity.dart';
import '../../../../common/domain/models/replacement_request_entity.dart';
import '../../../../common/domain/models/notification_entity.dart';
import '../../../../common/domain/models/client_entity.dart';

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

  Future<List<ClientAssignedStaff>> getAssignedStaff() async {
    final json = await getJson(ApiConstants.clientAssignedStaff);
    return ClientDtoCodec.decodeList(
      json['assignedStaff'] as List<dynamic>? ?? [],
      ClientDtoCodec.decodeAssignedStaff,
    );
  }

  Future<ClientStaffProfile> getStaffProfile(String staffId) async {
    final json = await getJson(ApiConstants.clientStaffProfile(staffId));
    return ClientDtoCodec.decodeStaffProfile(json);
  }

  Future<ClientTodayAttendance> getTodayAttendance() async {
    final json = await getJson(ApiConstants.clientAttendanceToday);
    return ClientDtoCodec.decodeTodayAttendance(json);
  }

  Future<List<ClientAttendanceRecord>> getAttendanceHistory() async {
    final json = await getJson(ApiConstants.clientAttendanceHistory);
    return ClientDtoCodec.decodeList(
      json['history'] as List<dynamic>? ?? [],
      ClientDtoCodec.decodeAttendanceRecord,
    );
  }

  Future<void> raiseAttendanceIssue({
    required String message,
    String? staffId,
    String? title,
  }) async {
    await postJson(
      ApiConstants.clientAttendanceRaiseIssue,
      data: {
        'message': message,
        if (staffId != null) 'staff_id': staffId,
        if (title != null) 'title': title,
      },
    );
  }

  Future<List<ClientInvoice>> getInvoices() async {
    final json = await getJson(ApiConstants.clientInvoices);
    return ClientDtoCodec.decodeList(
      json['invoices'] as List<dynamic>? ?? [],
      ClientDtoCodec.decodeInvoice,
    );
  }

  // Note: GET /client/complaints does not exist on the backend — only
  // POST /client/complaints does. getComplaints() stays dummy/local-only,
  // see ClientDummyDataSource.getComplaints.

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

  Future<List<ClientPaymentHistory>> getPaymentHistory() async => [];
  Future<ClientReplacementRequest?> getReplacementStatus() async => null;
  Future<void> requestReplacement(String reason) async {}
  Future<List<ClientNotification>> getNotifications() async => [];
  Future<void> markNotificationRead(String id) async {}

  Future<void> cacheAssignedStaff(List<ClientAssignedStaff> staff) =>
      saveJsonList(
        StorageKeys.clientAssignedStaff,
        ClientDtoCodec.encodeList(staff, ClientDtoCodec.encodeAssignedStaff),
      );

  List<ClientAssignedStaff>? getAssignedStaff() {
    final json = getJsonList(StorageKeys.clientAssignedStaff);
    return json != null
        ? ClientDtoCodec.decodeList(json, ClientDtoCodec.decodeAssignedStaff)
        : null;
  }

  Future<void> cacheStaffProfile(String staffId, ClientStaffProfile profile) =>
      saveJson(
        '${StorageKeys.clientStaffProfile}_$staffId',
        ClientDtoCodec.encodeStaffProfile(profile),
      );

  ClientStaffProfile? getStaffProfile(String staffId) {
    final json = getJson('${StorageKeys.clientStaffProfile}_$staffId');
    return json != null ? ClientDtoCodec.decodeStaffProfile(json) : null;
  }

  Future<void> cacheTodayAttendance(ClientTodayAttendance attendance) =>
      saveJson(
        StorageKeys.clientTodayAttendance,
        ClientDtoCodec.encodeTodayAttendance(attendance),
      );

  ClientTodayAttendance? getTodayAttendance() {
    final json = getJson(StorageKeys.clientTodayAttendance);
    return json != null ? ClientDtoCodec.decodeTodayAttendance(json) : null;
  }

  Future<void> cacheAttendanceHistory(List<ClientAttendanceRecord> history) =>
      saveJsonList(
        StorageKeys.clientAttendanceHistory,
        ClientDtoCodec.encodeList(history, ClientDtoCodec.encodeAttendanceRecord),
      );

  Future<List<ClientAttendanceRecord>> getAttendanceHistory() async {
    final json = getJsonList(StorageKeys.clientAttendanceHistory);
    return json != null
        ? ClientDtoCodec.decodeList(json, ClientDtoCodec.decodeAttendanceRecord)
        : [];
  }

  Future<void> raiseAttendanceIssue({
    required String message,
    String? staffId,
    String? title,
  }) async {}

  Future<void> cacheInvoices(List<ClientInvoice> invoices) => saveJsonList(
    StorageKeys.clientInvoices,
    ClientDtoCodec.encodeList(invoices, ClientDtoCodec.encodeInvoice),
  );

  List<ClientInvoice>? getInvoices() {
    final json = getJsonList(StorageKeys.clientInvoices);
    return json != null
        ? ClientDtoCodec.decodeList(json, ClientDtoCodec.decodeInvoice)
        : null;
  }

  Future<void> cacheComplaints(List<ClientComplaint> complaints) => saveJsonList(
    StorageKeys.clientComplaints,
    ClientDtoCodec.encodeList(complaints, ClientDtoCodec.encodeComplaint),
  );

  Future<List<ClientComplaint>> getComplaints() async {
    final json = getJsonList(StorageKeys.clientComplaints);
    return json != null
        ? ClientDtoCodec.decodeList(json, ClientDtoCodec.decodeComplaint)
        : [];
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

  Future<List<ClientAssignedStaff>> getAssignedStaff() => _api.getAssignedStaff();
  Future<ClientStaffProfile> getStaffProfile(String staffId) => _api.getStaffProfile(staffId);
  Future<ClientTodayAttendance> getTodayAttendance() => _api.getTodayAttendance();
  Future<List<ClientAttendanceRecord>> getAttendanceHistory() => _api.getAttendanceHistory();
  Future<void> raiseAttendanceIssue({
    required String message,
    String? staffId,
    String? title,
  }) => _api.raiseAttendanceIssue(message: message, staffId: staffId, title: title);
  Future<List<ClientInvoice>> getInvoices() => _api.getInvoices();
  Future<List<ClientPaymentHistory>> getPaymentHistory() => _api.getPaymentHistory();
  Future<String> downloadInvoice(String invoiceId) => _api.downloadInvoice(invoiceId);
  Future<List<ClientComplaint>> getComplaints() => _api.getComplaints();
  Future<void> raiseComplaint({required String subject, required String description, int imageCount = 0}) =>
      _api.raiseComplaint(subject: subject, description: description, imageCount: imageCount);
  Future<ClientReplacementRequest?> getReplacementStatus() => _api.getReplacementStatus();
  Future<void> requestReplacement(String reason) => _api.requestReplacement(reason);
  Future<List<ClientNotification>> getNotifications() => _api.getNotifications();
  Future<void> markNotificationRead(String id) => _api.markNotificationRead(id);
  Future<void> makeDemoPayment(String invoiceId, double amount, String method) => _api.makeDemoPayment(invoiceId, amount, method);
  Future<ClientProfile> getProfile() => _api.getProfile();
  Future<void> updateProfile(Map<String, String> data) => _api.updateProfile(data);
}
