import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/client_models.dart';

export '../../../../core/di/injection.dart' show clientRepositoryProvider;

final clientDashboardProvider = FutureProvider<ClientDashboardData>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getDashboard();
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

final clientInvoiceProvider = FutureProvider<ClientInvoice>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getCurrentInvoice();
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

final clientReplacementProvider =
    FutureProvider<ClientReplacementRequest?>((ref) async {
  final result = await ref.watch(clientRepositoryProvider).getReplacementStatus();
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
