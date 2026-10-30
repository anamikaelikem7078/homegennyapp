import 'package:file_picker/file_picker.dart';

import '../../../../core/utils/result.dart';
import '../models/staff_models.dart';

/// Staff module repository contract.
abstract interface class StaffRepository {
  Future<Result<StaffDashboardData>> getDashboard();
  Future<Result<List<StaffTask>>> getTodaysTasks();
  Future<Result<List<PipelineStage>>> getPipeline();
  Future<Result<StaffProfile>> getProfile();
  /// `PUT /staff/profile` — any subset of the snake_case profile fields.
  Future<Result<StaffProfile>> updateProfile(Map<String, dynamic> fields);

  /// `POST /staff/profile/submit` — the whole wizard form.
  Future<Result<StaffProfileSubmitResult>> submitProfile(Map<String, dynamic> fields);
  Future<Result<List<StaffDocument>>> getDocuments();
  Future<Result<StaffDocument>> getDocument(String id);
  Future<Result<void>> uploadDocument(String name, String type, PlatformFile file);
  Future<Result<void>> reuploadDocument(String id, String name);
  Future<Result<TrainingHome>> getTrainingHome();
  Future<Result<QuizAttemptStart>> startQuiz(String quizId);
  Future<Result<QuizSubmitResult>> submitQuizAttempt(String attemptId, List<TrainingQuizAnswer> answers);
  Future<Result<QuizResultDetail>> getQuizResult(String attemptId);
  Future<Result<List<int>>> downloadTrainingMaterial(String viewUrl);
  Future<Result<List<VideoCertPrompt>>> getVideoCertPrompts();
  Future<Result<void>> uploadVideoCert(
    String promptId,
    PlatformFile file, {
    void Function(int sent, int total)? onProgress,
  });
  Future<Result<StaffAgreement>> getAgreement();
  Future<Result<void>> signAgreement(String signature);
  Future<Result<DeploymentInfo>> getDeployment();
  Future<Result<AttendanceRecord?>> getTodayAttendance();
  Future<Result<StaffPlacementsToday>> getPlacementsToday();
  Future<Result<CheckInResult>> checkIn({double? latitude, double? longitude, String? placementId});
  Future<Result<LocationUploadResult>> sendLocationPoints(List<LocationPoint> points);
  Future<Result<CheckInResult>> checkOut({double? latitude, double? longitude});
  Future<Result<List<AttendanceRecord>>> getAttendanceHistory();
  Future<Result<MonthlyAttendance>> getMonthlyAttendance(String month);
  /// The latest month, or [period] when given.
  Future<Result<SalarySummary>> getSalarySummary({SalaryPeriod? period});
  Future<Result<PayslipHistory>> getPayslipHistory();
  Future<Result<Payslip>> getPayslip(String ref);
  Future<Result<List<int>>> downloadPayslipPdf(String ref);
  Future<Result<BankDetails>> getBankDetails();
  Future<Result<BankDetails>> updateBankDetails({
    required String accountHolderName,
    required String accountNumber,
    required String ifsc,
    String? bankName,
  });
  Future<Result<List<StaffNotification>>> getNotifications();
  Future<Result<void>> markNotificationRead(String id);
  Future<Result<void>> updatePassword(String current, String newPassword);
}
