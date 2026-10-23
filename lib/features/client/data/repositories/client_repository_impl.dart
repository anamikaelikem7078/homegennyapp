import '../../../../core/config/app_config.dart';
import '../../../../core/data/repository_executor.dart';
import '../../../../core/utils/result.dart';
import '../../domain/models/client_models.dart';
import '../../domain/models/client_snapshot.dart';
import '../../domain/models/staff_request_models.dart';
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
  Future<Result<ClientSnapshot>> getSnapshot() => _executor.fetch(
    remote: _remote.getSnapshot,
    cache: _local.cacheSnapshot,
    local: () async => _local.getSnapshot(_istToday()),
  );

  /// The snapshot's day is IST.
  static String _istToday() {
    final ist = DateTime.now().toUtc().add(const Duration(hours: 5, minutes: 30));
    return '${ist.year.toString().padLeft(4, '0')}-${ist.month.toString().padLeft(2, '0')}-${ist.day.toString().padLeft(2, '0')}';
  }

  @override
  Future<Result<ClientDashboardData>> getDashboard() => _executor.fetch(
    remote: _remote.getDashboard,
    cache: _local.cacheDashboard,
    local: () async => _local.getDashboard(),
    dummy: _dummy.getDashboard,
  );

  @override
  Future<Result<List<ClientAssignedStaff>>> getAssignedStaff() =>
      _executor.fetch(
        remote: _remote.getAssignedStaff,
        cache: _local.cacheAssignedStaff,
        local: () async => _local.getAssignedStaff(),
        dummy: _dummy.getAssignedStaff,
      );

  @override
  Future<Result<ClientStaffProfile>> getStaffProfile(String staffId) =>
      _executor.fetch(
        remote: () => _remote.getStaffProfile(staffId),
        cache: (data) => _local.cacheStaffProfile(staffId, data),
        local: () async => _local.getStaffProfile(staffId),
        dummy: () => _dummy.getStaffProfile(staffId),
      );

  @override
  Future<Result<ClientTodayAttendance>> getTodayAttendance() =>
      _executor.fetch(
        remote: _remote.getTodayAttendance,
        cache: _local.cacheTodayAttendance,
        local: () async => _local.getTodayAttendance(),
        dummy: _dummy.getTodayAttendance,
      );

  @override
  Future<Result<List<ClientAttendanceRecord>>> getAttendanceHistory({String? staffId, String? from, String? to}) {
    // Only the unfiltered default (last 30 days, everyone) is cached.
    final filtered = staffId != null || from != null || to != null;
    return _executor.fetch(
      remote: () => _remote.getAttendanceHistory(staffId: staffId, from: from, to: to),
      cache: filtered ? null : _local.cacheAttendanceHistory,
      local: filtered
          ? null
          : () async {
              final l = await _local.getAttendanceHistory();
              return l.isEmpty ? null : l;
            },
      dummy: () => _dummy.getAttendanceHistory(staffId: staffId, from: from, to: to),
    );
  }

  // Never cached: a stale position would mislead.
  @override
  Future<Result<ClientStaffLocation>> getStaffLocation(String staffId) => _executor.fetch(
        remote: () => _remote.getStaffLocation(staffId),
        dummy: () => _dummy.getStaffLocation(staffId),
      );

  @override
  Future<Result<void>> setHomeLocation({required double lat, required double lng}) => _executor.mutateVoid(
        remote: () => _remote.setHomeLocation(lat: lat, lng: lng),
        dummy: () => _dummy.setHomeLocation(lat: lat, lng: lng),
      );

  @override
  Future<Result<void>> raiseAttendanceIssue({
    required String message,
    String? staffId,
    String? title,
  }) => _executor.mutateVoid(
    remote: () => _remote.raiseAttendanceIssue(
      message: message,
      staffId: staffId,
      title: title,
    ),
    dummy: () => _dummy.raiseAttendanceIssue(
      message: message,
      staffId: staffId,
      title: title,
    ),
  );

  @override
  Future<Result<List<ClientInvoice>>> getInvoices() => _executor.fetch(
    remote: _remote.getInvoices,
    cache: _local.cacheInvoices,
    local: () async => _local.getInvoices(),
    dummy: _dummy.getInvoices,
  );

  @override
  Future<Result<ClientInvoiceDetail>> getInvoiceDetail(String invoiceId) =>
      _executor.fetch(remote: () => _remote.getInvoiceDetail(invoiceId));

  @override
  Future<Result<List<ClientPaymentHistory>>> getPaymentHistory() =>
      _executor.fetch(
        remote: _remote.getPaymentHistory,
        local: () async {
          final l = await _local.getPaymentHistory();
          return l.isEmpty ? null : l;
        },
        dummy: _dummy.getPaymentHistory,
      );

  @override
  Future<Result<String>> downloadInvoice(String invoiceId) => _executor.mutate(
    remote: () => _remote.downloadInvoice(invoiceId),
    dummy: () => _dummy.downloadInvoice(invoiceId),
  );

  @override
  Future<Result<List<ClientComplaint>>> getComplaints() => _executor.fetch(
    remote: _remote.getComplaints,
    cache: _local.cacheComplaints,
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
    List<String>? imagePaths,
  }) => _executor.mutateVoid(
    remote: () async {
      await _remote.raiseComplaint(
        subject: subject,
        description: description,
        imagePaths: imagePaths,
      );
    },
    dummy: () => _dummy.raiseComplaint(
      subject: subject,
      description: description,
      imageCount: imagePaths?.length ?? imageCount,
    ),
  );

  @override
  Future<Result<List<ClientReplacementRequest>>> getReplacements() =>
      _executor.fetch(
        remote: _remote.getReplacements,
        dummy: () async {
          final status = await _dummy.getReplacementStatus();
          return status == null ? <ClientReplacementRequest>[] : [status];
        },
      );

  @override
  Future<Result<ReplacementRequestResult>> requestReplacement({
    required String reason,
    String? placementId,
    String? preferredDate,
  }) =>
      _executor.mutate(
        remote: () => _remote.postReplacement(
          reason: reason,
          placementId: placementId,
          preferredDate: preferredDate,
        ),
        dummy: () async {
          await _dummy.requestReplacement(reason);
          return const ReplacementRequestResult(
            requestId: 'dummy',
            status: 'UNDER_RM_REVIEW',
            message: 'Replacement request recorded. Your RM can see it and will be in touch.',
          );
        },
      );

  @override
  Future<Result<List<ClientNotification>>> getNotifications() =>
      _executor.fetch(
        remote: _remote.getNotifications,
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
    // Never a demo name when offline with no cache.
    dummy: AppConfig.useDummyApi ? _dummy.getProfile : null,
  );

  @override
  Future<Result<ClientProfile>> updateProfile(Map<String, dynamic> fields) =>
      _executor.mutate(
        remote: () async {
          final profile = await _remote.updateProfile(fields);
          await _local.cacheProfile(profile);
          return profile;
        },
        dummy: () => _dummy.updateProfile(fields),
      );

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

  // ── Staff requests ── (live only: no cache or dummy, the status moves
  // under the client's feet as the RM works on it)

  @override
  Future<Result<List<StaffRequest>>> getStaffRequests() =>
      _executor.fetch(remote: _remote.getStaffRequests);

  @override
  Future<Result<StaffRequest>> getStaffRequest(String id) =>
      _executor.fetch(remote: () => _remote.getStaffRequest(id));

  @override
  Future<Result<StaffRequest>> createStaffRequest(Map<String, dynamic> body) =>
      _executor.mutate(remote: () => _remote.createStaffRequest(body));

  @override
  Future<Result<void>> selectStaffForRequest(String id, {required String staffId, String? note}) =>
      _executor.mutateVoid(
        remote: () => _remote.selectStaffForRequest(id, staffId: staffId, note: note),
      );

  @override
  Future<Result<void>> rejectStaffRequestShortlist(String id, String reason) =>
      _executor.mutateVoid(remote: () => _remote.rejectStaffRequestShortlist(id, reason));

  @override
  Future<Result<void>> cancelStaffRequest(String id, String reason) =>
      _executor.mutateVoid(remote: () => _remote.cancelStaffRequest(id, reason));
}
