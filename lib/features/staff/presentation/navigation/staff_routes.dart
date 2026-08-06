/// Staff module route paths.
abstract final class StaffRoutes {
  static const String root = '/staff';
  static const String home = '/staff/home';
  static const String dashboard = '/staff/dashboard';
  static const String pipeline = '/staff/pipeline';
  static const String attendance = '/staff/attendance';
  static const String notifications = '/staff/notifications';
  static const String profile = '/staff/profile';

  // Home
  static const String tasksToday = '/staff/tasks/today';
  static const String profileCompletion = '/staff/profile/completion';

  // Pipeline
  static String pipelineStage(String id) => '/staff/pipeline/stage/$id';

  // Documents
  static const String documents = '/staff/documents';
  static const String documentsUpload = '/staff/documents/upload';
  static String documentDetail(String id) => '/staff/documents/$id';
  static String documentReupload(String id) => '/staff/documents/$id/reupload';

  // Training
  static const String training = '/staff/training';
  static const String trainingCategories = '/staff/training/categories';
  static String trainingVideo(String id) => '/staff/training/video/$id';
  static String trainingPdf(String id) => '/staff/training/pdf/$id';
  static String trainingQuiz(String id) => '/staff/training/quiz/$id';
  static String trainingResult(String id) => '/staff/training/result/$id';
  static String trainingCertificate(String id) => '/staff/training/certificate/$id';

  // Video certification
  static const String videoCertification = '/staff/video-certification';
  static const String videoCertRecord = '/staff/video-certification/record';
  static const String videoCertPreview = '/staff/video-certification/preview';
  static const String videoCertUpload = '/staff/video-certification/upload';
  static String videoCertStatus(String id) =>
      '/staff/video-certification/status/$id';

  // Agreement
  static const String agreement = '/staff/agreement';
  static const String agreementSignature = '/staff/agreement/signature';
  static const String agreementStatus = '/staff/agreement/status';

  // Deployment
  static const String deployment = '/staff/deployment';

  // Attendance detail
  static const String checkIn = '/staff/attendance/check-in';
  static const String checkOut = '/staff/attendance/check-out';
  static const String attendanceHistory = '/staff/attendance/history';
  static const String monthlyAttendance = '/staff/attendance/monthly';

  // Salary
  static const String salary = '/staff/salary';
  static String payslip(String id) => '/staff/salary/payslip/$id';
  static const String salaryHistory = '/staff/salary/history';
  static const String bankDetails = '/staff/salary/bank';
  static const String taxDeclaration = '/staff/salary/tax';

  // Settings & help
  static const String settings = '/staff/settings';
  static const String settingsLanguage = '/staff/settings/language';
  static const String settingsTheme = '/staff/settings/theme';
  static const String settingsBiometric = '/staff/settings/biometric';
  static const String settingsPassword = '/staff/settings/password';
  static const String help = '/staff/help';

  static const List<String> tabRoutes = [
    home,
    pipeline,
    attendance,

    profile,
  ];
}
