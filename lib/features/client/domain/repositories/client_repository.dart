import '../../../../core/utils/result.dart';
import '../models/client_models.dart';
import '../models/staff_request_models.dart';

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
  Future<Result<ClientInvoiceDetail>> getInvoiceDetail(String invoiceId);
  Future<Result<List<ClientPaymentHistory>>> getPaymentHistory();
  Future<Result<String>> downloadInvoice(String invoiceId);
  Future<Result<List<ClientComplaint>>> getComplaints();
  Future<Result<void>> raiseComplaint({
    required String subject,
    required String description,
    int imageCount,
    List<String>? imagePaths,
  });
  Future<Result<List<ClientReplacementRequest>>> getReplacements();
  Future<Result<ReplacementRequestResult>> requestReplacement({
    required String reason,
    String? placementId,
    String? preferredDate,
  });
  Future<Result<List<ClientNotification>>> getNotifications();
  Future<Result<void>> markNotificationRead(String id);
  Future<Result<void>> makeDemoPayment(String invoiceId, double amount, String method);
  Future<Result<ClientProfile>> getProfile();
  Future<Result<void>> updateProfile(Map<String, String> data);

  // Staff requests
  Future<Result<List<StaffRequest>>> getStaffRequests();
  Future<Result<StaffRequest>> getStaffRequest(String id);
  Future<Result<StaffRequest>> createStaffRequest(Map<String, dynamic> body);
  Future<Result<void>> selectStaffForRequest(String id, {required String staffId, String? note});
  Future<Result<void>> rejectStaffRequestShortlist(String id, String reason);
  Future<Result<void>> cancelStaffRequest(String id, String reason);
}
