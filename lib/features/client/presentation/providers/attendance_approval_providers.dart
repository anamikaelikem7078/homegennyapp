import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/utils/result.dart';
import '../../data/attendance_approval_api.dart';
import '../../domain/models/attendance_approval_models.dart';

export '../../data/attendance_approval_api.dart' show attendanceApprovalApiProvider;

T _unwrap<T>(Result<T> r) => r.fold(onSuccess: (d) => d, onError: (f) => throw Exception(f.message));

/// Days for the confirm screen, by `client_status` filter (last 30 days).
final clientApprovalsProvider = FutureProvider.autoDispose.family<ApprovalList, String>(
  (ref, status) async => _unwrap(await ref.watch(attendanceApprovalApiProvider).list(status: status)),
);

/// Waiting days, for the Home "N days to confirm" card. Not autoDispose:
/// the Home keeps it, and the confirm screen invalidates it after an action.
final clientPendingApprovalsProvider = FutureProvider<ApprovalList>(
  (ref) async => _unwrap(await ref.watch(attendanceApprovalApiProvider).list(status: ClientDayStatus.pending)),
);

final clientMusterRollProvider = FutureProvider.autoDispose.family<MusterRoll, ({int month, int year})>(
  (ref, k) async => _unwrap(await ref.watch(attendanceApprovalApiProvider).musterRoll(k.month, k.year)),
);
