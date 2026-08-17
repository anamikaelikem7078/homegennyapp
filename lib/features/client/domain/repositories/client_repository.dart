import '../../../../core/utils/result.dart';
import '../models/client_models.dart';

/// Client module repository contract.
abstract interface class ClientRepository {
  Future<Result<ClientDashboardData>> getDashboard();
  Future<Result<List<ClientAssignedStaff>>> getAssignedStaff();
  Future<Result<ClientStaffProfile>> getStaffProfile(String staffId);
  Future<Result<ClientTodayAttendance>> getTodayAttendance();
  Future<Result<List<ClientAttendanceRecord>>> getAttendanceHistory();
  Future<Result<void>> raiseAttendanceIssue({
    required String message,
    String? staffId,
    String? title,
  });
  Future<Result<List<ClientInvoice>>> getInvoices();
  Future<Result<List<ClientPaymentHistory>>> getPaymentHistory();
  Future<Result<String>> downloadInvoice(String invoiceId);
  Future<Result<List<ClientComplaint>>> getComplaints();
  Future<Result<void>> raiseComplaint({
    required String subject,
    required String description,
    int imageCount,
    List<String>? imagePaths,
  });
  Future<Result<ClientReplacementRequest?>> getReplacementStatus();
  Future<Result<void>> requestReplacement(String reason);
  Future<Result<List<ClientNotification>>> getNotifications();
  Future<Result<void>> markNotificationRead(String id);
  Future<Result<void>> makeDemoPayment(String invoiceId, double amount, String method);
  Future<Result<ClientProfile>> getProfile();
  Future<Result<void>> updateProfile(Map<String, String> data);
}
