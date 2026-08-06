/// API endpoint and header constants.
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://api.homegenny.com/v1',
  );

  // Auth
  static const String authLogin = '/auth/login';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authRefreshToken = '/auth/refresh';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authLogout = '/auth/logout';
  static const String userProfile = '/user/profile';
  static const String appVersion = '/app/version';

  // Uploads
  static const String uploadImage = '/upload/image';
  static const String uploadVideo = '/upload/video';
  static const String uploadDocument = '/upload/document';

  // Staff
  static const String staffDashboard = '/staff/dashboard';
  static const String staffTasks = '/staff/tasks/today';
  static const String staffPipeline = '/staff/pipeline';
  static const String staffProfile = '/staff/profile';
  static const String staffDocuments = '/staff/documents';
  static String staffDocument(String id) => '/staff/documents/$id';
  static const String staffTraining = '/staff/training';
  static const String staffVideoCert = '/staff/video-certification';
  static const String staffAgreement = '/staff/agreement';
  static const String staffDeployment = '/staff/deployment';
  static const String staffAttendance = '/staff/attendance';
  static const String staffAttendanceCheckIn = '/staff/attendance/check-in';
  static const String staffAttendanceCheckOut = '/staff/attendance/check-out';
  static const String staffAttendanceHistory = '/staff/attendance/history';
  static const String staffSalary = '/staff/salary';
  static const String staffNotifications = '/staff/notifications';

  // RM
  static const String rmDashboard = '/rm/dashboard';
  static const String rmFollowUps = '/rm/follow-ups/today';
  static const String rmStaff = '/rm/staff';
  static String rmStaffDetail(String id) => '/rm/staff/$id';
  static const String rmClients = '/rm/clients';
  static String rmClientDetail(String id) => '/rm/clients/$id';
  static const String rmVerification = '/rm/verification/pending';
  static const String rmVideos = '/rm/videos/pending';
  static const String rmDeployments = '/rm/deployments';
  static const String rmReports = '/rm/reports';
  static const String rmClientRequests = '/rm/client-requests';
  static const String rmNotifications = '/rm/notifications';

  // Client
  static const String clientDashboard = '/client/dashboard';
  static String clientStaff(String id) => '/client/staff/$id';
  static const String clientAttendance = '/client/attendance';
  static const String clientAttendanceHistory = '/client/attendance/history';
  static const String clientInvoice = '/client/payments/invoice';
  static const String clientPaymentHistory = '/client/payments/history';
  static const String clientComplaints = '/client/complaints';
  static const String clientReplacement = '/client/replacement';
  static const String clientNotifications = '/client/notifications';
  static const String clientProfile = '/client/profile';

  // Maps
  static const String mapsGeocode = '/maps/geocode';
  static const String mapsReverseGeocode = '/maps/reverse-geocode';

  static const String headerAuthorization = 'Authorization';
  static const String headerContentType = 'Content-Type';
  static const String headerAccept = 'Accept';
  static const String contentTypeJson = 'application/json';
  static const String bearerPrefix = 'Bearer ';
}
