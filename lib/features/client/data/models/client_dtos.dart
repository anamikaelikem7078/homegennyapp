import '../../domain/models/client_models.dart';

abstract final class ClientDtoCodec {
  static Map<String, dynamic> encodeDashboard(ClientDashboardData d) => {
        'client_name': d.clientName,
        'pending_payment_amount': d.pendingPaymentAmount,
        'pending_payment_due': d.pendingPaymentDue,
        'unread_notifications': d.unreadNotifications,
        'active_complaints': d.activeComplaints,
      };

  static ClientDashboardData decodeDashboard(Map<String, dynamic> json) =>
      ClientDashboardData(
        clientName: json['client_name'] as String,
        assignedStaff: ClientAssignedStaff(
          id: json['staff_id'] as String? ?? 'STF-001',
          name: json['staff_name'] as String? ?? 'Rajesh Kumar',
          role: json['staff_role'] as String? ?? 'Home Care Specialist',
          rating: (json['staff_rating'] as num?)?.toDouble() ?? 4.8,
          shift: json['staff_shift'] as String? ?? '9:00 AM – 6:00 PM',
          isOnDuty: json['staff_on_duty'] as bool? ?? true,
        ),
        attendanceSummary: ClientAttendanceSummary(
          presentDays: json['present_days'] as int? ?? 22,
          totalDays: json['total_days'] as int? ?? 24,
          attendancePercent: (json['attendance_percent'] as num?)?.toDouble() ?? 91.7,
          lastCheckIn: json['last_check_in'] as String? ?? 'Today, 9:02 AM',
        ),
        pendingPaymentAmount: json['pending_payment_amount'] as String,
        pendingPaymentDue: json['pending_payment_due'] as String,
        unreadNotifications: json['unread_notifications'] as int,
        activeComplaints: json['active_complaints'] as int? ?? 0,
        replacementStatus: null,
      );

  static Map<String, dynamic> encodeProfile(ClientProfile p) => {
        'name': p.name, 'email': p.email, 'phone': p.phone,
        'address': p.address, 'city': p.city, 'pincode': p.pincode,
        'payment_method': p.paymentMethod, 'account_last4': p.accountLast4,
        'upi_id': p.upiId,
      };

  static ClientProfile decodeProfile(Map<String, dynamic> json) => ClientProfile(
        name: json['name'] as String,
        email: json['email'] as String,
        phone: json['phone'] as String,
        address: json['address'] as String,
        city: json['city'] as String,
        pincode: json['pincode'] as String,
        paymentMethod: json['payment_method'] as String,
        accountLast4: json['account_last4'] as String,
        upiId: json['upi_id'] as String,
      );
}
