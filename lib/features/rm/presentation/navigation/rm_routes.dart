/// RM module route paths.
abstract final class RmRoutes {
  static const String root = '/rm';
  static const String dashboard = '/rm/dashboard';
  static const String staff = '/rm/staff';
  static const String clients = '/rm/clients';
  static const String reports = '/rm/reports';
  static const String profile = '/rm/profile';

  // Dashboard
  static const String followUpsToday = '/rm/follow-ups/today';
  static const String pendingVerification = '/rm/pending/verification';
  static const String pendingTraining = '/rm/pending/training';
  static const String pendingAgreement = '/rm/pending/agreement';
  static const String pendingDeployment = '/rm/pending/deployment';
  static const String clientRequests = '/rm/client-requests';

  // Staff
  static const String staffSearch = '/rm/staff/search';
  static const String staffCreate = '/rm/staff/create';
  static String staffDetail(String id) => '/rm/staff/$id';
  static String staffEdit(String id) => '/rm/staff/$id/edit';
  static String staffDocuments(String id) => '/rm/staff/$id/documents';
  static String staffTraining(String id) => '/rm/staff/$id/training';
  static String staffAttendance(String id) => '/rm/staff/$id/attendance';
  static String staffSalary(String id) => '/rm/staff/$id/salary';

  // Verification
  static const String verificationPending = '/rm/verification/pending';
  static String verificationDetail(String id) => '/rm/verification/$id';
  static String verificationApprove(String id) => '/rm/verification/$id/approve';
  static String verificationReject(String id) => '/rm/verification/$id/reject';

  // Training
  static const String trainingAssign = '/rm/training/assign';
  static const String trainingProgress = '/rm/training/progress';
  static const String trainingCertificates = '/rm/training/certificates';

  // Video
  static const String videosPending = '/rm/videos/pending';
  static String videoWatch(String id) => '/rm/videos/$id/watch';
  static String videoReview(String id) => '/rm/videos/$id/review';

  // Client
  static String clientDetail(String id) => '/rm/clients/$id';
  static String clientRequirements(String id) => '/rm/clients/$id/requirements';
  static String clientAssignStaff(String id) => '/rm/clients/$id/assign-staff';
  static String clientReplacement(String id) => '/rm/clients/$id/replacement';

  // Deployment
  static const String deployment = '/rm/deployment';
  static const String deploymentAssignStaff = '/rm/deployment/assign-staff';
  static const String deploymentAssignClient = '/rm/deployment/assign-client';
  static const String deploymentTrial = '/rm/deployment/trial';
  static const String deploymentPermanent = '/rm/deployment/permanent';

  // Reports
  static const String reportDaily = '/rm/reports/daily';
  static const String reportWeekly = '/rm/reports/weekly';
  static const String reportMonthly = '/rm/reports/monthly';
  static const String reportAttendance = '/rm/reports/attendance';
  static const String reportPipeline = '/rm/reports/pipeline';
  static const String reportDeployment = '/rm/reports/deployment';

  // Other
  static const String notifications = '/rm/notifications';
  static const String settings = '/rm/settings';

  static const List<String> tabRoutes = [
    dashboard,
    staff,
    clients,
    reports,
    profile,
  ];
}
