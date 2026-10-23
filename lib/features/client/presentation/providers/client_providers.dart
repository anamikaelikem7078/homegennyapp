import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/client_models.dart';
import '../../domain/models/client_snapshot.dart';
import '../../domain/models/staff_request_models.dart';

export '../../../../core/di/injection.dart' show clientRepositoryProvider;

final clientDashboardProvider = FutureProvider<ClientDashboardData>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getDashboard();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

/// `GET /client/snapshot` — "Today at home". Refreshed by the home every
/// 2 minutes while it is visible, and on pull-to-refresh.
final clientSnapshotProvider = FutureProvider<ClientSnapshot>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getSnapshot();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientAssignedStaffProvider =
    FutureProvider<List<ClientAssignedStaff>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getAssignedStaff();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientStaffProfileProvider =
    FutureProvider.family<ClientStaffProfile, String>((ref, staffId) async {
  final result = await ref.watch(clientRepositoryProvider).getStaffProfile(staffId);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientTodayAttendanceProvider = FutureProvider<ClientTodayAttendance>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getTodayAttendance();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientAttendanceHistoryProvider =
    FutureProvider<List<ClientAttendanceRecord>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getAttendanceHistory();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

/// History filtered by staff member and date range (YYYY-MM-DD, at most 3
/// months apart). All null = the server default (last 30 days, everyone).
typedef ClientHistoryFilter = ({String? staffId, String? from, String? to});

final clientAttendanceHistoryFilteredProvider = FutureProvider.autoDispose
    .family<List<ClientAttendanceRecord>, ClientHistoryFilter>((ref, filter) async {
  final result = await ref
      .watch(clientRepositoryProvider)
      .getAttendanceHistory(staffId: filter.staffId, from: filter.from, to: filter.to);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

/// Live map data for one staff member; the map screen re-fetches it every
/// `next_refresh_sec` while open.
final clientStaffLocationProvider =
    FutureProvider.autoDispose.family<ClientStaffLocation, String>((ref, staffId) async {
  final result = await ref.watch(clientRepositoryProvider).getStaffLocation(staffId);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientInvoicesProvider = FutureProvider<List<ClientInvoice>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getInvoices();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientInvoiceDetailProvider =
    FutureProvider.family<ClientInvoiceDetail, String>((ref, invoiceId) async {
  final result = await ref.watch(clientRepositoryProvider).getInvoiceDetail(invoiceId);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientPaymentHistoryProvider =
    FutureProvider<List<ClientPaymentHistory>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getPaymentHistory();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientComplaintsProvider = FutureProvider<List<ClientComplaint>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getComplaints();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientReplacementsProvider =
    FutureProvider<List<ClientReplacementRequest>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getReplacements();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientNotificationsProvider =
    FutureProvider<List<ClientNotification>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getNotifications();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientProfileProvider = FutureProvider<ClientProfile>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getProfile();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

// ── Staff requests ── (autoDispose: refetched each time a screen opens,
// since push notifications are not wired yet)

final clientStaffRequestsProvider =
    FutureProvider.autoDispose<List<StaffRequest>>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getStaffRequests();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final clientStaffRequestProvider =
    FutureProvider.autoDispose.family<StaffRequest, String>((ref, id) async {
  final result = await ref.watch(clientRepositoryProvider).getStaffRequest(id);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});
