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
        staffId: _staffId,
        staffCode: 'staff001',
        fullName: 'Rajesh Kumar',
        series: 'MAID',
        deploymentDate: '2024-03-01T00:00:00.000Z',
        status: 'ACTIVE_DEPLOYED',
      );

  Future<ClientDashboardData> getDashboard() => _simulate(
        const ClientDashboardData(
          clientName: 'Priya Sharma',
          activePlacementsCount: 1,
          todayAttendanceStatus: 'CHECKED_IN',
          pendingInvoicesCount: 1,
          totalUnpaidAmount: 18500,
        ),
      );

  Future<List<ClientAssignedStaff>> getAssignedStaff() =>
      _simulate([_assignedStaff]);

  Future<ClientStaffProfile> getStaffProfile(String id) => _simulate(
        ClientStaffProfile(
          staffId: id,
          staffCode: 'staff001',
          fullName: 'Rajesh Kumar',
          series: 'MAID',
          isVerified: true,
          pvStatus: 'CLEAR',
          videoCertAvailable: true,
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

  static final _now = DateTime.now().toUtc();
  static String _ago(int minutes) => _now.subtract(Duration(minutes: minutes)).toIso8601String();

  Future<ClientTodayAttendance> getTodayAttendance() => _simulate(
        ClientTodayAttendance(
          staffName: 'Rajesh Kumar',
          checkInTime: _ago(150),
          checkOutTime: null,
          todayStatus: 'PRESENT',
          gpsVerified: true,
          staff: [
            ClientStaffToday(
              staffId: 'staff001',
              placementId: 'PLC-001',
              name: 'Rajesh Kumar',
              series: 'COOK',
              seriesLabel: 'Cook',
              status: 'PRESENT',
              checkIn: _ago(150),
              gpsVerified: true,
              checkInDistanceM: 22,
              lastLocation: ClientStaffLastLocation(
                at: _ago(2),
                lat: 28.5594,
                lng: 77.2068,
                distanceM: 25,
                atHome: true,
                label: 'At home',
              ),
            ),
            const ClientStaffToday(
              staffId: 'staff002',
              placementId: 'PLC-002',
              name: 'Asha Kumari',
              series: 'UNSKILLED_CARE',
              seriesLabel: 'Caretaker (UC)',
              status: 'NOT_CHECKED_IN',
            ),
          ],
        ),
      );

  Future<ClientStaffLocation> getStaffLocation(String staffId) {
    const home = ClientMapPoint(at: null, lat: 28.5592, lng: 77.2066);
    if (staffId != 'staff001') {
      return _simulate(ClientStaffLocation(staffId: staffId, status: 'NOT_CHECKED_IN', home: home));
    }
    return _simulate(
      ClientStaffLocation(
        staffId: staffId,
        placementId: 'PLC-001',
        status: 'PRESENT',
        checkIn: ClientMapPoint(at: _ago(150), lat: 28.5594, lng: 77.2066),
        checkInLabel: 'at home',
        last: ClientStaffLastLocation(
          at: _ago(2),
          lat: 28.5594,
          lng: 77.2068,
          distanceM: 25,
          atHome: true,
          label: 'At home',
        ),
        home: home,
        trail: [
          ClientMapPoint(at: _ago(150), lat: 28.5594, lng: 77.2066),
          ClientMapPoint(at: _ago(60), lat: 28.5630, lng: 77.2090),
          ClientMapPoint(at: _ago(2), lat: 28.5594, lng: 77.2068),
        ],
        nextRefreshSec: 60,
      ),
    );
  }

  Future<void> setHomeLocation() => _simulate(null);

  List<ClientAttendanceRecord> get _attendanceHistory => const [
        ClientAttendanceRecord(
          date: '2026-08-15',
          checkIn: '9:02 AM',
          checkOut: null,
          status: 'PRESENT',
        ),
        ClientAttendanceRecord(
          date: '2026-08-14',
          checkIn: '9:15 AM',
          checkOut: '6:30 PM',
          status: 'PRESENT',
        ),
        ClientAttendanceRecord(
          date: '2026-08-13',
          checkIn: '9:00 AM',
          checkOut: '6:15 PM',
          status: 'PRESENT',
        ),
        ClientAttendanceRecord(
          date: '2026-08-12',
          checkIn: null,
          checkOut: null,
          status: 'ABSENT',
        ),
      ];

  Future<List<ClientAttendanceRecord>> getAttendanceHistory({String? staffId}) => _simulate([
        for (final r in _attendanceHistory)
          if (staffId == null || staffId == 'staff001') r,
      ]);

  Future<void> raiseAttendanceIssue({
    required String message,
    String? staffId,
    String? title,
  }) => _simulate(null);

  ClientInvoice get _currentInvoice => const ClientInvoice(
        id: 'HG-INV-2407-001',
        invoiceId: 'HG-INV-2407-001',
        invoiceNumber: 'HG-INV-2407-001',
        billingMonth: '7/2024',
        salaryComponent: 15000,
        managementFee: 3000,
        gstAmount: 540,
        totalAmount: 18540,
        status: 'PENDING',
        dueDate: '2024-07-22T00:00:00.000Z',
        periodFrom: '2024-07-16',
        periodTo: '2024-07-31',
      );

  /// A fortnightly client gets two invoices for July.
  ClientInvoice get _earlierInvoice => const ClientInvoice(
        id: 'HG-INV-2407-000',
        invoiceId: 'HG-INV-2407-000',
        invoiceNumber: 'HG-INV-2407-000',
        billingMonth: '7/2024',
        salaryComponent: 15000,
        managementFee: 3000,
        gstAmount: 540,
        totalAmount: 18540,
        status: 'PAID',
        dueDate: '2024-07-08T00:00:00.000Z',
        periodFrom: '2024-07-01',
        periodTo: '2024-07-15',
      );

  Future<List<ClientInvoice>> getInvoices() => _simulate([_currentInvoice, _earlierInvoice]);

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

  Future<String> downloadInvoice(String invoiceId) => _simulate(
        '<html><body><h1>Invoice $invoiceId</h1><p>Offline demo copy — '
        'connect to the network for the real document.</p></body></html>',
      );

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
