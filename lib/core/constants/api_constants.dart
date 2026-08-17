/// API endpoint and header constants.
abstract final class ApiConstants {
  static const String baseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: 'https://homegennyserver-po5u.onrender.com/api/v1',
  );

  // Auth
  static const String authLogin = '/auth/login';
  static const String authVerifyOtp = '/auth/verify-otp';
  static const String authRefreshToken = '/auth/refresh';
  static const String authForgotPassword = '/auth/forgot-password';
  static const String authResetPassword = '/auth/reset-password';
  static const String authChangePassword = '/auth/change-password';
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

  // RM — verified against live Swagger JSON (/api/docs-json), not just
  // backend source, since the two occasionally disagree (e.g. placement
  // confirm exists live but was absent from the local backend checkout).
  static const String rmDashboard = '/rm/dashboard';
  static const String rmKanban = '/rm/kanban';
  static const String rmIntake = '/rm/intake';
  static String rmPipelineAdvance(String staffId) => '/rm/pipeline/$staffId/advance';
  static const String rmTrials = '/rm/trials';
  static const String rmDeferred = '/rm/deferred';
  static String rmDeferredResume(String staffId) => '/rm/deferred/$staffId/resume';
  static const String rmTerminal = '/rm/terminal';
  static const String rmIncidents = '/rm/incidents';
  static const String rmShifts = '/rm/shifts';
  static String rmShiftReview(String id) => '/rm/shifts/$id/review';
  static const String rmUpgrades = '/rm/upgrades';
  static const String rmLocations = '/rm/locations';
  static const String rmAttendance = '/rm/attendance';
  static String rmInvoicePreview(String staffId) => '/rm/attendance/$staffId/invoice-preview';
  static String rmGenerateInvoice(String staffId) => '/rm/attendance/$staffId/generate-invoice';

  // Placements
  static const String placements = '/placements';
  static String placementConfirm(String id) => '/placements/$id/confirm';
  static String placementExit(String id) => '/placements/$id/exit';

  // Verification (S2)
  static const String verificationAadhaar = '/verification/aadhaar';
  static const String verificationDl = '/verification/dl';
  static String verificationEchallan(String dlNumber) => '/verification/echallan/$dlNumber';
  static String verificationPvSubmit(String staffId) => '/verification/pv/submit/$staffId';
  static String verificationMedicalSubmit(String staffId) => '/verification/medical/submit/$staffId';
  static String verificationStatus(String staffId) => '/verification/$staffId';

  // Assessments (S2.5)
  static const String assessments = '/assessments';
  static const String assessmentsCreate = '/assessments/create';
  static const String assessmentsSubmit = '/assessments/submit';
  static String assessmentsUpdate(String id) => '/assessments/update/$id';
  static String assessmentDetail(String id) => '/assessments/$id';

  // Agreements + SOW (S4)
  static const String agreements = '/agreements';
  static const String agreementsSendOtp = '/agreements/esign/send-otp';
  static const String agreementsVerifyOtp = '/agreements/esign/verify-otp';
  static String agreementSign(String id) => '/agreements/$id/sign';
  static String agreementGeneratePdf(String id) => '/agreements/$id/generate-pdf';
  static const String sow = '/sow';
  static String sowDetail(String id) => '/sow/$id';
  static String sowSend(String id) => '/sow/$id/send';
  static String sowAmend(String id) => '/sow/$id/amend';

  // Video certification (S3)
  static String videoCertPrompts(String series) => '/video-cert/prompts/$series';
  static const String videoCertViewUrl = '/video-cert/view-url';
  static String videoCertList(String staffId) => '/video-cert/list/$staffId';

  // Finance (client picker for placements)
  static const String financeCustomers = '/finance/customers';

  // Client
  static const String clientDashboard = '/client/dashboard';
  static String clientStaffProfile(String id) => '/client/staff/$id/profile';
  static const String clientAssignedStaff = '/client/assigned-staff';
  static const String clientAttendanceToday = '/client/attendance/today';
  static const String clientAttendanceHistory = '/client/attendance/history';
  static const String clientAttendanceRaiseIssue = '/client/attendance/raise-issue';
  static const String clientInvoice = '/client/payments/invoice';
  static const String clientInvoices = '/client/invoices';
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
