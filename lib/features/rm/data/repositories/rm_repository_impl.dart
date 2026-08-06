import '../../../../core/data/repository_executor.dart';
import '../../../../core/data/models/api_response.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/rm_models.dart';
import '../../domain/repositories/rm_repository.dart';
import '../datasources/rm_datasource.dart';

class RmRepositoryImpl implements RmRepository {
  RmRepositoryImpl({
    required RepositoryExecutor executor,
    required RmRemoteDataSource remote,
    required RmLocalDataSource local,
    required RmDummyDataSource dummy,
  })  : _executor = executor,
        _remote = remote,
        _local = local,
        _dummy = dummy;

  final RepositoryExecutor _executor;
  final RmRemoteDataSource _remote;
  final RmLocalDataSource _local;
  final RmDummyDataSource _dummy;

  @override
  Future<Result<RmDashboardData>> getDashboard() => _executor.fetch(
        remote: _remote.getDashboard,
        cache: _local.cacheDashboard,
        local: () async => _local.getDashboard(),
        dummy: _dummy.getDashboard,
      );

  @override
  Future<Result<List<RmFollowUp>>> getTodaysFollowUps() =>
      _executor.fetch(dummy: _dummy.getTodaysFollowUps);

  @override
  Future<Result<List<RmStaffMember>>> getStaff({String? query}) => _executor.fetch(
        remote: () async {
          final page = await _remote.getStaff(PaginationParams(query: query));
          return page.items;
        },
        cache: _local.cacheStaffList,
        local: () async => _local.getStaffList(),
        dummy: () => _dummy.getStaff(query: query),
      );

  @override
  Future<Result<RmStaffDetail>> getStaffDetail(String id) =>
      _executor.fetch(dummy: () => _dummy.getStaffDetail(id));

  @override
  Future<Result<void>> createStaff(Map<String, String> data) =>
      _executor.mutateVoid(dummy: () => _dummy.createStaff(data));

  @override
  Future<Result<void>> updateStaff(String id, Map<String, String> data) =>
      _executor.mutateVoid(dummy: () => _dummy.updateStaff(id, data));

  @override
  Future<Result<List<RmClient>>> getClients({String? query}) => _executor.fetch(
        remote: () async {
          final page = await _remote.getClients(PaginationParams(query: query));
          return page.items;
        },
        dummy: () => _dummy.getClients(query: query),
      );

  @override
  Future<Result<RmClient>> getClientDetail(String id) =>
      _executor.fetch(dummy: () => _dummy.getClientDetail(id));

  @override
  Future<Result<List<RmPendingDocument>>> getPendingDocuments() =>
      _executor.fetch(dummy: _dummy.getPendingDocuments);

  @override
  Future<Result<void>> approveDocument(String id, {String? remarks}) => _executor.mutateVoid(
        remote: () => _remote.approveDocument(id, remarks: remarks),
        dummy: () => _dummy.approveDocument(id, remarks: remarks),
      );

  @override
  Future<Result<void>> rejectDocument(String id, String remarks) =>
      _executor.mutateVoid(dummy: () => _dummy.rejectDocument(id, remarks));

  @override
  Future<Result<List<RmPendingVideo>>> getPendingVideos() =>
      _executor.fetch(dummy: _dummy.getPendingVideos);

  @override
  Future<Result<void>> approveVideo(String id, {String? remarks}) =>
      _executor.mutateVoid(dummy: () => _dummy.approveVideo(id, remarks: remarks));

  @override
  Future<Result<void>> rejectVideo(String id, String remarks) =>
      _executor.mutateVoid(dummy: () => _dummy.rejectVideo(id, remarks));

  @override
  Future<Result<void>> assignTraining(String staffId, String courseId) =>
      _executor.mutateVoid(dummy: () => _dummy.assignTraining(staffId, courseId));

  @override
  Future<Result<List<RmDeployment>>> getDeployments() =>
      _executor.fetch(dummy: _dummy.getDeployments);

  @override
  Future<Result<void>> assignDeployment({
    required String staffId,
    required String clientId,
    required String type,
  }) =>
      _executor.mutateVoid(
        dummy: () => _dummy.assignDeployment(staffId: staffId, clientId: clientId, type: type),
      );

  @override
  Future<Result<RmReportSummary>> getReport(RmReportPeriod period) =>
      _executor.fetch(dummy: () => _dummy.getReport(period));

  @override
  Future<Result<RmReportSummary>> getAttendanceReport() =>
      _executor.fetch(dummy: _dummy.getAttendanceReport);

  @override
  Future<Result<RmReportSummary>> getPipelineReport() =>
      _executor.fetch(dummy: _dummy.getPipelineReport);

  @override
  Future<Result<RmReportSummary>> getDeploymentReport() =>
      _executor.fetch(dummy: _dummy.getDeploymentReport);

  @override
  Future<Result<List<RmClientRequest>>> getClientRequests() =>
      _executor.fetch(dummy: _dummy.getClientRequests);

  @override
  Future<Result<List<RmNotification>>> getNotifications() =>
      _executor.fetch(dummy: _dummy.getNotifications);

  @override
  Future<Result<void>> markNotificationRead(String id) =>
      _executor.mutateVoid(dummy: () => _dummy.markNotificationRead(id));
}
