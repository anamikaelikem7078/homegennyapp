import '../../../../core/di/injection.dart';
import '../../../../core/utils/result.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/models/staff_models.dart';
import '../../domain/repositories/staff_repository.dart';

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

final staffTrainingCategoriesProvider =
    FutureProvider<List<TrainingCategory>>((ref) async {
  final result =
      await ref.watch(staffRepositoryProvider).getTrainingCategories();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffTrainingCoursesProvider =
    FutureProvider<List<TrainingCourse>>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getTrainingCourses();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffTrainingCourseProvider =
    FutureProvider.family<TrainingCourse, String>((ref, id) async {
  final result = await ref.watch(staffRepositoryProvider).getTrainingCourse(id);
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffQuizProvider =
    FutureProvider.family<List<QuizQuestion>, String>((ref, courseId) async {
  final result = await ref.watch(staffRepositoryProvider).getQuiz(courseId);
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

final staffSalarySummaryProvider = FutureProvider<SalarySummary>((ref) async {
  final result = await ref.watch(staffRepositoryProvider).getSalarySummary();
  return result.fold(
    onSuccess: (data) => data,
    onError: (f) => throw Exception(f.message),
  );
});

final staffPayslipHistoryProvider = FutureProvider<List<Payslip>>((ref) async {
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
