import '../../../../core/data/repository_executor.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/client_models.dart';
import '../../domain/repositories/client_repository.dart';
import '../datasources/client_datasource.dart';

class ClientRepositoryImpl implements ClientRepository {
  ClientRepositoryImpl({
    required RepositoryExecutor executor,
    required ClientRemoteDataSource remote,
    required ClientLocalDataSource local,
    required ClientDummyDataSource dummy,
  }) : _executor = executor,
       _remote = remote,
       _local = local,
       _dummy = dummy;

  final RepositoryExecutor _executor;
  final ClientRemoteDataSource _remote;
  final ClientLocalDataSource _local;
  final ClientDummyDataSource _dummy;

  @override
  Future<Result<ClientDashboardData>> getDashboard() => _executor.fetch(
    remote: _remote.getDashboard,
    cache: _local.cacheDashboard,
    local: () async => _local.getDashboard(),
    dummy: _dummy.getDashboard,
  );

  @override
  Future<Result<ClientStaffProfile>> getStaffProfile(String staffId) =>
      _executor.fetch(dummy: () => _dummy.getStaffProfile(staffId));

  @override
  Future<Result<ClientTodayAttendance>> getTodayAttendance() =>
      _executor.fetch(dummy: _dummy.getTodayAttendance);

  @override
  Future<Result<List<ClientAttendanceRecord>>> getAttendanceHistory() =>
      _executor.fetch(
        local: () async {
          final l = await _local.getAttendanceHistory();
          return l.isEmpty ? null : l;
        },
        dummy: _dummy.getAttendanceHistory,
      );

  @override
  Future<Result<void>> raiseAttendanceIssue(String message) =>
      _executor.mutateVoid(dummy: () => _dummy.raiseAttendanceIssue(message));

  @override
  Future<Result<ClientInvoice>> getCurrentInvoice() =>
      _executor.fetch(dummy: _dummy.getCurrentInvoice);

  @override
  Future<Result<List<ClientPaymentHistory>>> getPaymentHistory() =>
      _executor.fetch(
        local: () async {
          final l = await _local.getPaymentHistory();
          return l.isEmpty ? null : l;
        },
        dummy: _dummy.getPaymentHistory,
      );

  @override
  Future<Result<String>> downloadInvoice(String invoiceId) =>
      _executor.mutate(dummy: () => _dummy.downloadInvoice(invoiceId));

  @override
  Future<Result<List<ClientComplaint>>> getComplaints() => _executor.fetch(
    local: () async {
      final l = await _local.getComplaints();
      return l.isEmpty ? null : l;
    },
    dummy: _dummy.getComplaints,
  );

  @override
  Future<Result<void>> raiseComplaint({
    required String subject,
    required String description,
    int imageCount = 0,
  }) => _executor.mutateVoid(
    remote: () async {
      await _remote.raiseComplaint(subject: subject, description: description);
    },
    dummy: () => _dummy.raiseComplaint(
      subject: subject,
      description: description,
      imageCount: imageCount,
    ),
  );

  @override
  Future<Result<ClientReplacementRequest?>> getReplacementStatus() =>
      _executor.fetch(dummy: _dummy.getReplacementStatus);

  @override
  Future<Result<void>> requestReplacement(String reason) =>
      _executor.mutateVoid(dummy: () => _dummy.requestReplacement(reason));

  @override
  Future<Result<List<ClientNotification>>> getNotifications() =>
      _executor.fetch(
        local: () async {
          final l = await _local.getNotifications();
          return l.isEmpty ? null : l;
        },
        dummy: _dummy.getNotifications,
      );

  @override
  Future<Result<void>> markNotificationRead(String id) =>
      _executor.mutateVoid(dummy: () => _dummy.markNotificationRead(id));

  @override
  Future<Result<ClientProfile>> getProfile() => _executor.fetch(
    remote: _remote.getProfile,
    cache: _local.cacheProfile,
    local: () async => _local.getProfile(),
    dummy: _dummy.getProfile,
  );

  @override
  Future<Result<void>> updateProfile(Map<String, String> data) =>
      _executor.mutateVoid(dummy: () => _dummy.updateProfile(data));

  @override
  Future<Result<void>> makeDemoPayment(
    String invoiceId,
    double amount,
    String method,
  ) => _executor.mutateVoid(
    dummy: () async {
      await _dummy.makeDemoPayment(invoiceId, amount, method);
    },
  );
}
