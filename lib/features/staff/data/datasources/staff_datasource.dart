import 'package:dio/dio.dart';

import '../../../../core/constants/api_constants.dart';
import '../../../../core/constants/storage_keys.dart';
import '../../../../core/data/datasources/base_local_datasource.dart';
import '../../../../core/data/datasources/json_asset_loader.dart';
import '../../../../core/network/api_service.dart';
import '../../domain/models/staff_models.dart';
import '../datasources/staff_dummy_api.dart';
import '../models/staff_dtos.dart';

/// Remote staff API datasource.
class StaffRemoteDataSource extends BaseRemoteDataSource {
  StaffRemoteDataSource(super.dio);

  Future<StaffDashboardData> getDashboard() async {
    final json = await getJson(ApiConstants.staffDashboard);
    return StaffDtoCodec.decodeDashboard(json);
  }

  Future<List<StaffTask>> getTodaysTasks() async {
    final json = await getJson(ApiConstants.staffTasks);
    return StaffDtoCodec.decodeList(
      json['items'] as List<dynamic>? ?? [],
      StaffDtoCodec.decodeTask,
    );
  }

  Future<List<PipelineStage>> getPipeline() async {
    final json = await getJson(ApiConstants.staffPipeline);
    return StaffDtoCodec.decodeList(
      json['items'] as List<dynamic>? ?? [],
      StaffDtoCodec.decodePipelineStage,
    );
  }

  Future<StaffProfile> getProfile() async {
    final json = await getJson(ApiConstants.staffProfile);
    return StaffDtoCodec.decodeProfile(json);
  }

  Future<List<StaffDocument>> getDocuments({int page = 1}) async {
    final json = await getJson(
      ApiConstants.staffDocuments,
      queryParameters: {'page': page, 'per_page': 20},
    );
    return StaffDocumentsPageDto.fromJson(json).items;
  }

  Future<List<StaffNotification>> getNotifications() async {
    final json = await getJson(ApiConstants.staffNotifications);
    return StaffDtoCodec.decodeList(
      json['items'] as List<dynamic>? ?? [],
      StaffDtoCodec.decodeNotification,
    );
  }

  Future<Map<String, dynamic>> uploadDocument({
    required String filePath,
    required String name,
    required String type,
  }) async {
    return uploadMultipart(
      ApiConstants.staffDocuments,
      formData: FormData.fromMap({
        'name': name,
        'type': type,
        'file': await MultipartFile.fromFile(filePath),
      }),
    );
  }
}

/// Local staff cache datasource (Hive offline storage).
class StaffLocalDataSource extends BaseLocalDataSource {
  StaffLocalDataSource(super.hive);

  Future<void> cacheDashboard(StaffDashboardData data) =>
      saveJson(StorageKeys.staffDashboard, StaffDtoCodec.encodeDashboard(data));

  StaffDashboardData? getDashboard() {
    final json = getJson(StorageKeys.staffDashboard);
    return json != null ? StaffDtoCodec.decodeDashboard(json) : null;
  }

  Future<void> cacheProfile(StaffProfile profile) =>
      saveJson(StorageKeys.staffProfile, StaffDtoCodec.encodeProfile(profile));

  StaffProfile? getProfile() {
    final json = getJson(StorageKeys.staffProfile);
    return json != null ? StaffDtoCodec.decodeProfile(json) : null;
  }

  Future<void> cacheDocuments(List<StaffDocument> docs) => saveJsonList(
        StorageKeys.staffDocuments,
        StaffDtoCodec.encodeList(docs, StaffDtoCodec.encodeDocument),
      );

  List<StaffDocument>? getDocuments() {
    final list = getJsonList(StorageKeys.staffDocuments);
    return list?.map(StaffDtoCodec.decodeDocument).toList();
  }

  Future<void> cachePipeline(List<PipelineStage> stages) => saveJsonList(
        StorageKeys.staffPipeline,
        StaffDtoCodec.encodeList(stages, StaffDtoCodec.encodePipelineStage),
      );

  List<PipelineStage>? getPipeline() {
    final list = getJsonList(StorageKeys.staffPipeline);
    return list?.map(StaffDtoCodec.decodePipelineStage).toList();
  }

  Future<void> cacheNotifications(List<StaffNotification> items) => saveJsonList(
        StorageKeys.staffNotifications,
        StaffDtoCodec.encodeList(items, StaffDtoCodec.encodeNotification),
      );

  List<StaffNotification>? getNotifications() {
    final list = getJsonList(StorageKeys.staffNotifications);
    return list?.map(StaffDtoCodec.decodeNotification).toList();
  }
}

/// Dummy staff datasource — JSON assets + in-memory fallback.
class StaffDummyDataSource {
  StaffDummyDataSource({
    StaffDummyApi? api,
    JsonAssetLoader? jsonLoader,
  })  : _api = api ?? StaffDummyApi(),
        _json = jsonLoader ?? JsonAssetLoader();

  final StaffDummyApi _api;
  final JsonAssetLoader _json;

  Future<StaffDashboardData> getDashboard() async {
    try {
      final json = await _json.loadMap('assets/json/staff/dashboard.json');
      return StaffDtoCodec.decodeDashboard(json);
    } catch (_) {
      return _api.getDashboard();
    }
  }

  Future<List<StaffTask>> getTodaysTasks() => _api.getTodaysTasks();
  Future<List<PipelineStage>> getPipeline() => _api.getPipeline();
  Future<StaffProfile> getProfile() => _api.getProfile();
  Future<List<StaffDocument>> getDocuments() => _api.getDocuments();
  Future<StaffDocument> getDocument(String id) => _api.getDocument(id);
  Future<void> uploadDocument(String name, String type) => _api.uploadDocument(name, type);
  Future<void> reuploadDocument(String id, String name) => _api.reuploadDocument(id, name);
  Future<List<TrainingCategory>> getTrainingCategories() => _api.getTrainingCategories();
  Future<List<TrainingCourse>> getTrainingCourses({String? categoryId}) =>
      _api.getTrainingCourses(categoryId: categoryId);
  Future<TrainingCourse> getTrainingCourse(String id) => _api.getTrainingCourse(id);
  Future<List<QuizQuestion>> getQuiz(String courseId) => _api.getQuiz(courseId);
  Future<QuizResult> submitQuiz(String courseId, Map<String, int> answers) =>
      _api.submitQuiz(courseId, answers);
  Future<List<VideoCertPrompt>> getVideoCertPrompts() => _api.getVideoCertPrompts();
  Future<void> uploadVideoCert(String promptId) => _api.uploadVideoCert(promptId);
  Future<StaffAgreement> getAgreement() => _api.getAgreement();
  Future<void> signAgreement(String signature) => _api.signAgreement(signature);
  Future<DeploymentInfo> getDeployment() => _api.getDeployment();
  Future<AttendanceRecord?> getTodayAttendance() => _api.getTodayAttendance();
  Future<CheckInResult> checkIn({String? selfiePath}) => _api.checkIn(selfiePath: selfiePath);
  Future<CheckInResult> checkOut() => _api.checkOut();
  Future<List<AttendanceRecord>> getAttendanceHistory() => _api.getAttendanceHistory();
  Future<MonthlyAttendance> getMonthlyAttendance(String month) =>
      _api.getMonthlyAttendance(month);
  Future<SalarySummary> getSalarySummary() => _api.getSalarySummary();
  Future<List<Payslip>> getPayslipHistory() => _api.getPayslipHistory();
  Future<Payslip> getPayslip(String id) => _api.getPayslip(id);
  Future<BankDetails> getBankDetails() => _api.getBankDetails();
  Future<List<StaffNotification>> getNotifications() => _api.getNotifications();
  Future<void> markNotificationRead(String id) => _api.markNotificationRead(id);
  Future<void> updatePassword(String current, String newPassword) =>
      _api.updatePassword(current, newPassword);
}
