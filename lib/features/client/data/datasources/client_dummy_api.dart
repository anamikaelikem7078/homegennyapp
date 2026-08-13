import '../../domain/models/client_models.dart';

/// Dummy API for Client module with simulated delays.
class ClientDummyApi {
  static const _delay = Duration(milliseconds: 500);

  Future<T> _simulate<T>(T data) async {
    await Future<void>.delayed(_delay);
    return data;
  }

  static const _staffId = 'STF-001';

  ClientAssignedStaff get _assignedStaff => const ClientAssignedStaff(
        id: _staffId,
        name: 'Rajesh Kumar',
        role: 'Home Care Specialist',
        rating: 4.8,
        shift: '9:00 AM – 6:00 PM',
        isOnDuty: true,
      );

  Future<ClientDashboardData> getDashboard() => _simulate(
        ClientDashboardData(
          clientName: 'Priya Sharma',
          assignedStaff: _assignedStaff,
          attendanceSummary: const ClientAttendanceSummary(
            presentDays: 22,
            totalDays: 24,
            attendancePercent: 91.7,
            lastCheckIn: 'Today, 9:02 AM',
          ),
          pendingPaymentAmount: '₹18,500',
          pendingPaymentDue: 'Due in 5 days',
          unreadNotifications: 3,
          activeComplaints: 0,
          replacementStatus: null,
        ),
      );

  Future<ClientStaffProfile> getStaffProfile(String id) => _simulate(
        ClientStaffProfile(
          id: id,
          name: 'Rajesh Kumar',
          role: 'Home Care Specialist',
          rating: 4.8,
          shift: '9:00 AM – 6:00 PM',
          phone: '+91 98765 43210',
          joinedDate: '1 Mar 2024',
          experience: const [
            ClientExperience(
              title: 'Senior Home Care',
              organization: 'CareFirst Services',
              duration: '3 years',
              description: 'Elderly care and household management',
            ),
            ClientExperience(
              title: 'Home Care Assistant',
              organization: 'HomeHelp India',
              duration: '2 years',
              description: 'Cooking, cleaning, and daily assistance',
            ),
          ],
          skills: const [
            'Cooking',
            'Elderly Care',
            'Housekeeping',
            'First Aid',
            'Child Care',
          ],
          performanceScore: 4.7,
          attendancePercent: 94,
          reviews: const [
            ClientReview(
              comment: 'Exceptional attention to detail. The team handled our requirements with absolute discretion and precision. A standard of service rarely seen.',
              rating: 5,
              date: '2 DAYS AGO',
              reviewerName: 'ALEXANDER V.',
            ),
            ClientReview(
              comment: 'Extremely responsive and highly professional. We have switched all our property management needs to HomeGenny based on this level of performance.',
              rating: 5,
              date: '1 WEEK AGO',
              reviewerName: 'ELEANOR R.',
            ),
          ],
        ),
      );

  Future<ClientTodayAttendance> getTodayAttendance() => _simulate(
        const ClientTodayAttendance(
          staffName: 'Rajesh Kumar',
          checkIn: '9:02 AM',
          checkOut: null,
          status: 'On Duty',
          location: 'Green Park, New Delhi',
        ),
      );

  List<ClientAttendanceRecord> get _attendanceHistory => const [
        ClientAttendanceRecord(
          id: 'A1',
          date: 'Today',
          checkIn: '9:02 AM',
          checkOut: null,
          status: 'Present',
          hoursWorked: '—',
        ),
        ClientAttendanceRecord(
          id: 'A2',
          date: 'Yesterday',
          checkIn: '9:15 AM',
          checkOut: '6:30 PM',
          status: 'Present',
          hoursWorked: '9h 15m',
        ),
        ClientAttendanceRecord(
          id: 'A3',
          date: '12 Jul 2024',
          checkIn: '9:00 AM',
          checkOut: '6:15 PM',
          status: 'Present',
          hoursWorked: '9h 15m',
        ),
        ClientAttendanceRecord(
          id: 'A4',
          date: '11 Jul 2024',
          checkIn: '9:45 AM',
          checkOut: '6:00 PM',
          status: 'Late',
          hoursWorked: '8h 15m',
        ),
      ];

  Future<List<ClientAttendanceRecord>> getAttendanceHistory() =>
      _simulate(_attendanceHistory);

  Future<void> raiseAttendanceIssue(String message) => _simulate(null);

  ClientInvoice get _currentInvoice => const ClientInvoice(
        id: 'INV-2024-07',
        invoiceNumber: 'HG-INV-2407-001',
        period: 'July 2024',
        amount: '₹18,500',
        dueDate: '22 Jul 2024',
        status: ClientPaymentStatus.pending,
        items: [
          ClientInvoiceItem(description: 'Monthly Service Fee', amount: '₹15,000'),
          ClientInvoiceItem(description: 'Platform Fee', amount: '₹2,000'),
          ClientInvoiceItem(description: 'GST (18%)', amount: '₹1,500'),
        ],
      );

  Future<ClientInvoice> getCurrentInvoice() => _simulate(_currentInvoice);

  List<ClientPaymentHistory> get _paymentHistory => const [
        ClientPaymentHistory(
          id: 'P1',
          date: '15 Jun 2024',
          amount: '₹18,500',
          method: 'UPI',
          status: ClientPaymentStatus.paid,
          invoiceNumber: 'HG-INV-2406-001',
        ),
        ClientPaymentHistory(
          id: 'P2',
          date: '15 May 2024',
          amount: '₹18,500',
          method: 'Bank Transfer',
          status: ClientPaymentStatus.paid,
          invoiceNumber: 'HG-INV-2405-001',
        ),
        ClientPaymentHistory(
          id: 'P3',
          date: '15 Apr 2024',
          amount: '₹18,500',
          method: 'UPI',
          status: ClientPaymentStatus.paid,
          invoiceNumber: 'HG-INV-2404-001',
        ),
      ];

  Future<List<ClientPaymentHistory>> getPaymentHistory() =>
      _simulate(_paymentHistory);

  Future<String> downloadInvoice(String invoiceId) =>
      _simulate('Invoice $invoiceId downloaded');

  List<ClientComplaint> get _complaints => const [
        ClientComplaint(
          id: 'CMP-001',
          subject: 'Late arrival',
          description: 'Staff arrived 30 minutes late on Monday',
          status: ClientComplaintStatus.resolved,
          createdAt: '5 Jun 2024',
          updatedAt: '8 Jun 2024',
          imageCount: 0,
          resolution: 'Discussed with staff. Punctuality improved.',
        ),
      ];

  Future<List<ClientComplaint>> getComplaints() => _simulate(_complaints);

  Future<void> raiseComplaint({
    required String subject,
    required String description,
    int imageCount = 0,
  }) =>
      _simulate(null);

  Future<ClientReplacementRequest?> getReplacementStatus() => _simulate(null);

  Future<void> requestReplacement(String reason) => _simulate(null);

  List<ClientNotification> get _notifications => const [
        ClientNotification(
          id: 'N1',
          title: 'Payment Due',
          message: 'Your July invoice of ₹18,500 is due in 5 days',
          time: '2h ago',
          isRead: false,
          type: 'payment',
        ),
        ClientNotification(
          id: 'N2',
          title: 'Staff Check-in',
          message: 'Rajesh Kumar checked in at 9:02 AM',
          time: '5h ago',
          isRead: false,
          type: 'attendance',
        ),
        ClientNotification(
          id: 'N3',
          title: 'Service Reminder',
          message: 'Monthly service review scheduled for next week',
          time: '1d ago',
          isRead: true,
          type: 'general',
        ),
      ];

  Future<List<ClientNotification>> getNotifications() =>
      _simulate(_notifications);

  Future<void> markNotificationRead(String id) => _simulate(null);

  Future<ClientProfile> getProfile() => _simulate(
        const ClientProfile(
          name: 'Priya Sharma',
          email: 'priya.sharma@email.com',
          phone: '+91 99887 76655',
          address: '42, Green Park Extension',
          city: 'New Delhi',
          pincode: '110016',
          paymentMethod: 'UPI',
          accountLast4: '4521',
          upiId: 'priya@upi',
        ),
      );

  Future<void> updateProfile(Map<String, String> data) => _simulate(null);
  Future<void> makeDemoPayment(String invoiceId, double amount, String method) => _simulate(null);
}
