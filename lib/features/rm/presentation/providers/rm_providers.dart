import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/rm_models.dart';

export '../../../../core/di/injection.dart' show rmRepositoryProvider;

final rmDashboardProvider = FutureProvider<RmDashboardData>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getDashboard();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmFollowUpsProvider = FutureProvider<List<RmFollowUp>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getTodaysFollowUps();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmStaffListProvider =
    FutureProvider.family<List<RmStaffMember>, String>((ref, query) async {
  final result =
      await ref.watch(rmRepositoryProvider).getStaff(query: query);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmStaffDetailProvider =
    FutureProvider.family<RmStaffDetail, String>((ref, id) async {
  final result = await ref.watch(rmRepositoryProvider).getStaffDetail(id);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmClientsProvider =
    FutureProvider.family<List<RmClient>, String>((ref, query) async {
  final result =
      await ref.watch(rmRepositoryProvider).getClients(query: query);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmClientDetailProvider =
    FutureProvider.family<RmClient, String>((ref, id) async {
  final result = await ref.watch(rmRepositoryProvider).getClientDetail(id);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmPendingDocumentsProvider =
    FutureProvider<List<RmPendingDocument>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getPendingDocuments();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmPendingVideosProvider = FutureProvider<List<RmPendingVideo>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getPendingVideos();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmDeploymentsProvider = FutureProvider<List<RmDeployment>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getDeployments();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmClientRequestsProvider =
    FutureProvider<List<RmClientRequest>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getClientRequests();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmNotificationsProvider =
    FutureProvider<List<RmNotification>>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getNotifications();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmReportProvider =
    FutureProvider.family<RmReportSummary, RmReportPeriod>((ref, period) async {
  final result = await ref.watch(rmRepositoryProvider).getReport(period);
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmAttendanceReportProvider = FutureProvider<RmReportSummary>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getAttendanceReport();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmPipelineReportProvider = FutureProvider<RmReportSummary>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getPipelineReport();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});

final rmDeploymentReportProvider = FutureProvider<RmReportSummary>((ref) async {
  final result = await ref.watch(rmRepositoryProvider).getDeploymentReport();
  return result.fold(
    onSuccess: (d) => d,
    onError: (f) => throw Exception(f.message),
  );
});
