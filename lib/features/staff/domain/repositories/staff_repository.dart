import '../../../../core/utils/result.dart';
import '../models/staff_models.dart';

/// Staff module repository contract.
abstract interface class StaffRepository {
  Future<Result<StaffDashboardData>> getDashboard();
  Future<Result<List<StaffTask>>> getTodaysTasks();
  Future<Result<List<PipelineStage>>> getPipeline();
  Future<Result<StaffProfile>> getProfile();
  Future<Result<void>> updateProfile({String? address, String? email});
  Future<Result<List<StaffDocument>>> getDocuments();
  Future<Result<StaffDocument>> getDocument(String id);
  Future<Result<void>> uploadDocument(String name, String type, String filePath);
  Future<Result<void>> reuploadDocument(String id, String name);
  Future<Result<List<TrainingCategory>>> getTrainingCategories();
  Future<Result<List<TrainingCourse>>> getTrainingCourses({String? categoryId});
  Future<Result<TrainingCourse>> getTrainingCourse(String id);
  Future<Result<List<QuizQuestion>>> getQuiz(String courseId);
  Future<Result<QuizResult>> submitQuiz(String courseId, Map<String, int> answers);
  Future<Result<List<VideoCertPrompt>>> getVideoCertPrompts();
  Future<Result<void>> uploadVideoCert(String promptId);
  Future<Result<StaffAgreement>> getAgreement();
  Future<Result<void>> signAgreement(String signature);
  Future<Result<DeploymentInfo>> getDeployment();
  Future<Result<AttendanceRecord?>> getTodayAttendance();
  Future<Result<CheckInResult>> checkIn({double? latitude, double? longitude});
  Future<Result<CheckInResult>> checkOut({double? latitude, double? longitude});
  Future<Result<List<AttendanceRecord>>> getAttendanceHistory();
  Future<Result<MonthlyAttendance>> getMonthlyAttendance(String month);
  Future<Result<SalarySummary>> getSalarySummary();
  Future<Result<List<Payslip>>> getPayslipHistory();
  Future<Result<Payslip>> getPayslip(String id);
  Future<Result<BankDetails>> getBankDetails();
  Future<Result<List<StaffNotification>>> getNotifications();
  Future<Result<void>> markNotificationRead(String id);
  Future<Result<void>> updatePassword(String current, String newPassword);
}
