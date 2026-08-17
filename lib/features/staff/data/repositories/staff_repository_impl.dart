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

  // Note: there is no separate /staff/tasks/today endpoint on the backend —
  // todayTasks is embedded in GET /staff/dashboard, so today's tasks are
  // derived from the dashboard fetch rather than a dedicated remote call.
  @override
  Future<Result<List<StaffTask>>> getTodaysTasks() async {
    final result = await getDashboard();
    return result.fold(
      onSuccess: (d) => Success(d.todayTasks),
      onError: (f) => Error(f),
    );
  }

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
  Future<Result<void>> updateProfile({String? address, String? email}) =>
      _executor.mutateVoid(
        remote: () => _remote.updateProfile(address: address, email: email),
        dummy: () => _dummy.updateProfile(address: address, email: email),
      );

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
      _executor.mutateVoid(
        remote: () async {
          await _remote.uploadDocument(filePath: filePath, name: name, type: type);
        },
        dummy: () async {
          await _local.uploadDocument(name, type, filePath);
          await _dummy.uploadDocument(name, type, filePath);
        },
      );

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
  Future<Result<DeploymentInfo>> getDeployment() => _executor.fetch(
        remote: _remote.getDeployment,
        cache: _local.cacheDeployment,
        local: () async => _local.getDeployment(),
        dummy: _dummy.getDeployment,
      );

  // Note: there is no separate GET /staff/attendance/today endpoint — "today"
  // is derived from the attendance-history list (the most recent entry
  // matching today's date), matching the backend's actual data model.
  @override
  Future<Result<AttendanceRecord?>> getTodayAttendance() async {
    final result = await getAttendanceHistory();
    return result.fold(
      onSuccess: (history) {
        final today = DateTime.now().toIso8601String().substring(0, 10);
        for (final r in history) {
          if (r.date == today) return Success(r);
        }
        return Success(history.isNotEmpty ? history.first : null);
      },
      onError: (f) => Error(f),
    );
  }

  @override
  Future<Result<CheckInResult>> checkIn({double? latitude, double? longitude}) =>
      _executor.mutate(
        remote: () => _remote.checkIn(latitude: latitude, longitude: longitude),
        dummy: () => _dummy.checkIn(latitude: latitude, longitude: longitude),
      );

  @override
  Future<Result<CheckInResult>> checkOut({double? latitude, double? longitude}) =>
      _executor.mutate(
        remote: () => _remote.checkOut(latitude: latitude, longitude: longitude),
        dummy: () => _dummy.checkOut(latitude: latitude, longitude: longitude),
      );

  @override
  Future<Result<List<AttendanceRecord>>> getAttendanceHistory() => _executor.fetch(
        remote: _remote.getAttendanceHistory,
        cache: _local.cacheAttendanceHistory,
        local: () async {
          final l = await _local.getAttendanceHistory();
          return l.isEmpty ? null : l;
        },
        dummy: _dummy.getAttendanceHistory,
      );

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
