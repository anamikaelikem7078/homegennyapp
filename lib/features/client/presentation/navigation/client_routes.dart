/// Client module route paths.
abstract final class ClientRoutes {
  static const String root = '/client';
  static const String dashboard = '/client/dashboard';
  static const String staff = '/client/staff';
  static const String payments = '/client/payments';
  static const String notifications = '/client/notifications';
  static const String profile = '/client/profile';

  // Dashboard
  static const String assignedStaff = '/client/assigned-staff';
  static const String attendanceSummary = '/client/attendance-summary';
  static const String pendingPayment = '/client/pending-payment';

  // Staff
  static String staffProfile(String id) => '/client/staff/$id';
  static String staffExperience(String id) => '/client/staff/$id/experience';
  static String staffSkills(String id) => '/client/staff/$id/skills';
  static String staffAttendance(String id) => '/client/staff/$id/attendance';
  static String staffPerformance(String id) => '/client/staff/$id/performance';

  // Attendance
  static const String attendanceToday = '/client/attendance/today';
  static const String attendanceHistory = '/client/attendance/history';
  static const String attendanceRaiseIssue = '/client/attendance/raise-issue';

  // Payments
  static const String invoice = '/client/payments/invoice';
  static const String paymentHistory = '/client/payments/history';
  static const String paymentGateway = '/client/payments/gateway';
  static String downloadInvoice(String id) => '/client/payments/invoice/$id/download';
  static const String paymentStatus = '/client/payments/status';

  // Complaint
  static const String complaintRaise = '/client/complaint/raise';
  static const String complaintUpload = '/client/complaint/upload';
  static const String complaintHistory = '/client/complaint/history';

  // Replacement
  static const String replacementRequest = '/client/replacement/request';
  static const String replacementStatus = '/client/replacement/status';

  // Profile
  static const String personalDetails = '/client/profile/personal';
  static const String address = '/client/profile/address';
  static const String paymentDetails = '/client/profile/payment-details';
  static const String settings = '/client/settings';

  static const List<String> tabRoutes = [
    dashboard,
    staff,
    payments,
    notifications,
    profile,
  ];
}
