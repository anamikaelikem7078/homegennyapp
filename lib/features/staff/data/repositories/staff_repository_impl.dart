import '../../../../core/data/repository_executor.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/staff_models.dart';
import '../../domain/repositories/staff_repository.dart';
import '../datasources/staff_datasource.dart';

/// Staff repository — remote + local cache + dummy JSON fallback.
class StaffRepositoryImpl implements StaffRepository {
  StaffRepositoryImpl({
    required RepositoryExecutor executor,
    required StaffRemoteDataSource remote,
    required StaffLocalDataSource local,
    required StaffDummyDataSource dummy,
  })  : _executor = executor,
        _remote = remote,
        _local = local,
        _dummy = dummy;

  final RepositoryExecutor _executor;
  final StaffRemoteDataSource _remote;
  final StaffLocalDataSource _local;
  final StaffDummyDataSource _dummy;

  @override
  Future<Result<StaffDashboardData>> getDashboard() async {
    final localData = _local.getDashboard();
    if (localData != null) return Success(localData);

    return _executor.fetch(
      remote: _remote.getDashboard,
      cache: _local.cacheDashboard,
      local: () async => _local.getDashboard(),
      dummy: _dummy.getDashboard,
    );
  }

  @override
  Future<Result<List<StaffTask>>> getTodaysTasks() => _executor.fetch(
        remote: _remote.getTodaysTasks,
        dummy: _dummy.getTodaysTasks,
      );

  @override
  Future<Result<List<PipelineStage>>> getPipeline() => _executor.fetch(
        remote: _remote.getPipeline,
        cache: _local.cachePipeline,
        local: () async => _local.getPipeline(),
        dummy: _dummy.getPipeline,
      );

  @override
  Future<Result<StaffProfile>> getProfile() async {
    final localData = _local.getProfile();
    if (localData != null) return Success(localData);

    return _executor.fetch(
      remote: _remote.getProfile,
      cache: _local.cacheProfile,
      local: () async => _local.getProfile(),
      dummy: _dummy.getProfile,
    );
  }

  @override
  Future<Result<List<StaffDocument>>> getDocuments() => _executor.fetch(
        remote: _remote.getDocuments,
        cache: _local.cacheDocuments,
        local: () async => _local.getDocuments(),
        dummy: _dummy.getDocuments,
      );

  @override
  Future<Result<StaffDocument>> getDocument(String id) =>
      _executor.fetch(dummy: () => _dummy.getDocument(id));

  @override
  Future<Result<void>> uploadDocument(String name, String type, String filePath) =>
      _executor.mutateVoid(dummy: () async { await _local.uploadDocument(name, type, filePath); await _dummy.uploadDocument(name, type, filePath); });

  @override
  Future<Result<void>> reuploadDocument(String id, String name) =>
      _executor.mutateVoid(dummy: () => _dummy.reuploadDocument(id, name));

  @override
  Future<Result<List<TrainingCategory>>> getTrainingCategories() =>
      _executor.fetch(dummy: _dummy.getTrainingCategories);

  @override
  Future<Result<List<TrainingCourse>>> getTrainingCourses({String? categoryId}) =>
      _executor.fetch(dummy: () => _dummy.getTrainingCourses(categoryId: categoryId));

  @override
  Future<Result<TrainingCourse>> getTrainingCourse(String id) =>
      _executor.fetch(dummy: () => _dummy.getTrainingCourse(id));

  @override
  Future<Result<List<QuizQuestion>>> getQuiz(String courseId) =>
      _executor.fetch(dummy: () => _dummy.getQuiz(courseId));

  @override
  Future<Result<QuizResult>> submitQuiz(String courseId, Map<String, int> answers) =>
      _executor.mutate(dummy: () => _dummy.submitQuiz(courseId, answers));

  @override
  Future<Result<List<VideoCertPrompt>>> getVideoCertPrompts() =>
      _executor.fetch(local: () async => await _local.getVideoCertPrompts().then((l) => l.isEmpty ? null : l), dummy: _dummy.getVideoCertPrompts);

  @override
  Future<Result<void>> uploadVideoCert(String promptId) =>
      _executor.mutateVoid(dummy: () async { await _local.uploadVideoCert(promptId); await _dummy.uploadVideoCert(promptId); });

  @override
  Future<Result<StaffAgreement>> getAgreement() =>
      _executor.fetch(local: () async => _local.getAgreement(), dummy: _dummy.getAgreement);

  @override
  Future<Result<void>> signAgreement(String signature) =>
      _executor.mutateVoid(dummy: () async { await _local.signAgreement(signature); await _dummy.signAgreement(signature); });

  @override
  Future<Result<DeploymentInfo>> getDeployment() =>
      _executor.fetch(dummy: _dummy.getDeployment);

  @override
  Future<Result<AttendanceRecord?>> getTodayAttendance() =>
      _executor.fetch(local: () async => _local.getTodayAttendance(), dummy: _dummy.getTodayAttendance);

  @override
  Future<Result<CheckInResult>> checkIn({String? selfiePath}) =>
      _executor.mutate(dummy: () async { await _local.checkIn(); return _dummy.checkIn(selfiePath: selfiePath); });

  @override
  Future<Result<CheckInResult>> checkOut() =>
      _executor.mutate(dummy: () async { await _local.checkOut(); return _dummy.checkOut(); });

  @override
  Future<Result<List<AttendanceRecord>>> getAttendanceHistory() =>
      _executor.fetch(local: () async => await _local.getAttendanceHistory().then((l) => l.isEmpty ? null : l), dummy: _dummy.getAttendanceHistory);

  @override
  Future<Result<MonthlyAttendance>> getMonthlyAttendance(String month) =>
      _executor.fetch(local: () async => await _local.getMonthlyAttendance(month), dummy: () => _dummy.getMonthlyAttendance(month));

  @override
  Future<Result<SalarySummary>> getSalarySummary() =>
      _executor.fetch(dummy: _dummy.getSalarySummary);

  @override
  Future<Result<List<Payslip>>> getPayslipHistory() =>
      _executor.fetch(dummy: _dummy.getPayslipHistory);

  @override
  Future<Result<Payslip>> getPayslip(String id) =>
      _executor.fetch(dummy: () => _dummy.getPayslip(id));

  @override
  Future<Result<BankDetails>> getBankDetails() =>
      _executor.fetch(dummy: _dummy.getBankDetails);

  @override
  Future<Result<List<StaffNotification>>> getNotifications() => _executor.fetch(
        remote: _remote.getNotifications,
        cache: _local.cacheNotifications,
        local: () async => _local.getNotifications(),
        dummy: _dummy.getNotifications,
      );

  @override
  Future<Result<void>> markNotificationRead(String id) =>
      _executor.mutateVoid(dummy: () => _dummy.markNotificationRead(id));

  @override
  Future<Result<void>> updatePassword(String current, String newPassword) =>
      _executor.mutateVoid(dummy: () => _dummy.updatePassword(current, newPassword));
}
