import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import 'package:camera/camera.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/staff_models.dart';

export '../../../../core/di/injection.dart' show staffRepositoryProvider;

final staffDashboardProvider = FutureProvider<StaffDashboardData>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getDashboard();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffTasksProvider = FutureProvider<List<StaffTask>>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getTodaysTasks();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffPipelineProvider = FutureProvider<List<PipelineStage>>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getPipeline();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffProfileProvider = FutureProvider<StaffProfile>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getProfile();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffDocumentsProvider =
    FutureProvider<List<StaffDocument>>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getDocuments();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffDocumentProvider =
    FutureProvider.family<StaffDocument, String>((ref, id) async {
  final result = await ref.watch(staffRepositoryProvider).getDocument(id);
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffTrainingHomeProvider = FutureProvider<TrainingHome>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getTrainingHome();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

/// Starts (or resumes) a quiz attempt — a family so each quiz id gets its
/// own cached attempt while the user is on the quiz screen.
final staffQuizStartProvider =
    FutureProvider.family<QuizAttemptStart, String>((ref, quizId) async {
  final result = await ref.watch(staffRepositoryProvider).startQuiz(quizId);
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffQuizResultProvider =
    FutureProvider.family<QuizResultDetail, String>((ref, attemptId) async {
  final result = await ref.watch(staffRepositoryProvider).getQuizResult(attemptId);
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffVideoCertProvider =
    FutureProvider<List<VideoCertPrompt>>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getVideoCertPrompts();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

/// Video certification prompts submitted so far — under review or approved.
/// Null until the prompt list loads; the training summary from
/// `GET /training/mine` only counts approved ones.
final staffVideoCertSubmittedProvider = Provider<int?>((ref) => ref
    .watch(staffVideoCertProvider)
    .valueOrNull
    ?.where((p) => p.status == VideoCertStatus.uploaded || p.status == VideoCertStatus.approved)
    .length);

/// Videos recorded on-device (keyed by prompt id) that have not yet finished
/// uploading. The server only ever reports `uploaded`/`approved`/`rejected`
/// once an upload completes, so without this the prompt list has no way to
/// show that a recording already exists locally and is just waiting on the
/// upload step — the record action would look identical to a prompt that was
/// never touched.
final staffVideoCertLocalRecordingsProvider =
    StateProvider<Map<String, XFile>>((ref) => {});

/// Device-clock timestamp of the most recent successful upload for each
/// prompt (keyed by prompt id). The server response for a completed upload
/// carries no submission timestamp, so the Approval Status screen relies on
/// this — the time actually shown to the staff member — being captured
/// locally the moment the upload finishes.
final staffVideoCertSubmittedAtProvider =
    StateProvider<Map<String, DateTime>>((ref) => {});

final staffAgreementProvider = FutureProvider<StaffAgreement>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getAgreement();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffDeploymentProvider = FutureProvider<DeploymentInfo>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getDeployment();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

/// Houses the staff member can check in at today (trial, confirmed and
/// today's one-time visits), and the open shift if any.
final staffPlacementsTodayProvider = FutureProvider<StaffPlacementsToday>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getPlacementsToday();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffTodayAttendanceProvider =
    FutureProvider<AttendanceRecord?>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getTodayAttendance();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffAttendanceHistoryProvider =
    FutureProvider<List<AttendanceRecord>>((ref) async {
  final result =
      await ref.watch(staffRepositoryProvider).getAttendanceHistory();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffMonthlyAttendanceProvider =
    FutureProvider<MonthlyAttendance>((ref) async {
  final result =
      await ref.watch(staffRepositoryProvider).getMonthlyAttendance('July 2024');
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

/// The latest salary month, or the one given (e.g. from a "Salary slip
/// ready" notification).
final staffSalarySummaryProvider =
    FutureProvider.family<SalarySummary, SalaryPeriod?>((ref, period) async {
  final result = await ref.watch(staffRepositoryProvider).getSalarySummary(period: period);
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffPayslipHistoryProvider = FutureProvider<PayslipHistory>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getPayslipHistory();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffPayslipProvider =
    FutureProvider.family<Payslip, String>((ref, id) async {
  final result = await ref.watch(staffRepositoryProvider).getPayslip(id);
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffBankDetailsProvider = FutureProvider<BankDetails>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getBankDetails();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffNotificationsProvider =
    FutureProvider<List<StaffNotification>>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getNotifications();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});
