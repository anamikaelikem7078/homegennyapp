import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/di/injection.dart';
import '../../../core/exceptions/exception_handler.dart';
import '../../../core/network/api_service.dart';
import '../../../core/utils/result.dart';
import '../domain/models/attendance_approval_models.dart';

/// Client attendance confirmation (`/client/attendance/approvals`,
/// `/approve`, `/{id}/dispute`) and the monthly muster roll
/// (`/client/muster-rolls`).
class AttendanceApprovalApi extends BaseRemoteDataSource {
  AttendanceApprovalApi(super.dio);

  /// Runs [call], turning any error into a [Failure] whose message is the
  /// server's — the dispute and sign 400s are shown to the user as is.
  Future<Result<T>> _guard<T>(Future<T> Function() call) async {
    try {
      return Success(await call());
    } catch (e, st) {
      return Error(ExceptionHandler.handle(e, st));
    }
  }

  /// [status] defaults to PENDING server-side; [from]/[to] (YYYY-MM-DD) to
  /// the last 30 days.
  Future<Result<ApprovalList>> list({String? status, String? from, String? to, String? staffId}) =>
      _guard(() async => ApprovalList.fromJson(await getJson('/client/attendance/approvals', queryParameters: {
            'status': ?status,
            'from': ?from,
            'to': ?to,
            'staff_id': ?staffId,
          })));

  /// Confirms the given days. Returns how many were approved.
  Future<Result<int>> approve(List<String> ids) => _guard(() async {
        final json = await postJson('/client/attendance/approve', data: {'ids': ids});
        return (json['approved'] as num?)?.toInt() ?? ids.length;
      });

  /// "Not right". [reason] is at least 5 characters; [actual] one of
  /// [DisputeActual.options].
  Future<Result<void>> dispute(String id, {required String reason, String? actual}) => _guard(() async {
        await postJson('/client/attendance/$id/dispute', data: {'reason': reason, 'actual': ?actual});
      });

  Future<Result<MusterRoll>> musterRoll(int month, int year) => _guard(() async => MusterRoll.fromJson(
        await getJson('/client/muster-rolls', queryParameters: {'month': month, 'year': year}),
        month: month,
        year: year,
      ));

  /// Form XVI as HTML (A4 landscape).
  Future<Result<String>> musterRollHtml(int month, int year) =>
      _guard(() => getText('/client/muster-rolls/print', queryParameters: {'month': month, 'year': year}));

  /// Signs the month; also confirms every day of it still waiting.
  Future<Result<MusterSignResult>> sign(int month, int year, {required String name}) =>
      _guard(() async => MusterSignResult.fromJson(
            await postJson('/client/muster-rolls/sign', data: {'month': month, 'year': year, 'name': name}),
          ));
}

final attendanceApprovalApiProvider =
    Provider<AttendanceApprovalApi>((ref) => AttendanceApprovalApi(ref.watch(dioClientProvider)));
