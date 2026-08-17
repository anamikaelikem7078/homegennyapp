/// Secure storage and Hive box key constants.
abstract final class StorageKeys {
  static const String accessToken = 'access_token';
  static const String refreshToken = 'refresh_token';
  static const String userId = 'user_id';
  static const String userRole = 'user_role';
  static const String userProfile = 'user_profile';
  static const String biometricEnabled = 'biometric_enabled';
  static const String themeMode = 'theme_mode';
  static const String locale = 'locale';
  static const String fcmToken = 'fcm_token';
  static const String lastLoginEmail = 'last_login_email';

  static const String settingsBox = 'settings_box';
  static const String cacheBox = 'cache_box';

  // Staff offline cache
  static const String staffDashboard = 'cache_staff_dashboard';
  static const String staffProfile = 'cache_staff_profile';
  static const String staffDocuments = 'cache_staff_documents';
  static const String staffPipeline = 'cache_staff_pipeline';
  static const String staffNotifications = 'cache_staff_notifications';
  static const String staffDeployment = 'cache_staff_deployment';
  static const String staffAttendanceHistory = 'cache_staff_attendance_history';

  // RM offline cache
  static const String rmDashboard = 'cache_rm_dashboard';
  static const String rmStaffList = 'cache_rm_staff_list';
  static const String rmClientsList = 'cache_rm_clients_list';
  static const String rmNotifications = 'cache_rm_notifications';

  // Client offline cache
  static const String clientDashboard = 'cache_client_dashboard';
  static const String clientProfile = 'cache_client_profile';
  static const String clientInvoice = 'cache_client_invoice';
  static const String clientNotifications = 'cache_client_notifications';
  static const String clientAssignedStaff = 'cache_client_assigned_staff';
  static const String clientStaffProfile = 'cache_client_staff_profile';
  static const String clientTodayAttendance = 'cache_client_today_attendance';
  static const String clientAttendanceHistory = 'cache_client_attendance_history';
  static const String clientInvoices = 'cache_client_invoices';
  static const String clientComplaints = 'cache_client_complaints';
}
