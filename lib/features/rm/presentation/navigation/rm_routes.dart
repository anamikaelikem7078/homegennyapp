/// RM feature route path constants.
abstract final class RmRoutes {
  static const String dashboard = '/rm/dashboard';
  static const String pipeline = '/rm/pipeline';
  static const String tasks = '/rm/tasks';
  static const String alerts = '/rm/alerts';
  static const String profile = '/rm/profile';
  static const String staffIntake = '/rm/staff-intake';
  static const String trials = '/rm/trials';
  static const String deferred = '/rm/deferred';
  static const String terminal = '/rm/terminal';
  static const String attendance = '/rm/attendance';
  static const String locations = '/rm/locations';
  static const String upgrades = '/rm/upgrades';

  static String staffDetail(String id) => '/rm/staff/$id';
  static String verificationDashboard(String id) => '/rm/staff/$id/verification';
  static String track1(String id) => '/rm/staff/$id/verification/track1';
  static String track2(String id) => '/rm/staff/$id/verification/track2';
  static String track3(String id) => '/rm/staff/$id/verification/track3';
  static String track4(String id) => '/rm/staff/$id/verification/track4';
  static String track5(String id) => '/rm/staff/$id/verification/track5';
  
  static String stage25Assessment(String id) => '/rm/staff/$id/stage2-5/assessment';

  static String stage3Training(String id) => '/rm/staff/$id/stage3/training';
  static String stage3VideoUpload(String id) => '/rm/staff/$id/stage3/video-upload';
  static String stage3VideoReview(String id) => '/rm/staff/$id/stage3/video-review';

  static String stage4Hub(String id) => '/rm/staff/$id/stage4/hub';
  static String stage4A1(String id) => '/rm/staff/$id/stage4/a1';
  static String stage4A2(String id) => '/rm/staff/$id/stage4/a2';
  static String stage4A2Client(String id) => '/rm/staff/$id/stage4/a2-client';
  static String stage4A3(String id) => '/rm/staff/$id/stage4/a3';

  static String placementCreate(String staffId) => '/rm/staff/$staffId/placement/create';
  static String placementDetail(String placementId) => '/rm/placements/$placementId';
  static String staffAttendance(String staffId) => '/rm/staff/$staffId/attendance';
  static String staffInvoicePreview(String staffId) => '/rm/staff/$staffId/invoice-preview';
  static String staffIncidents(String staffId) => '/rm/staff/$staffId/incidents';
  static String incidentCreate(String staffId) => '/rm/staff/$staffId/incidents/new';

  // Demo Sequential Flow Routes
  static String staffActivePlacement(String id) => '/rm/staff/$id/demo/active-placement';
  static String staffDailyShift(String id) => '/rm/staff/$id/demo/daily-shift';
  static String staffPayslip(String id) => '/rm/staff/$id/demo/payslip';
  static String clientInvoice(String id) => '/rm/staff/$id/demo/client-invoice';
}
