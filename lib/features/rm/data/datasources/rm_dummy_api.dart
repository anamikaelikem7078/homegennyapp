import '../../domain/models/rm_models.dart';

/// Dummy API for RM module with simulated delays.
class RmDummyApi {
  static const _delay = Duration(milliseconds: 500);

  Future<T> _simulate<T>(T data) async {
    await Future<void>.delayed(_delay);
    return data;
  }

  List<RmStaffMember> get _staff => const [
        RmStaffMember(
          id: 'STF-001',
          name: 'Rajesh Kumar',
          phone: '+91 98765 43210',
          email: 'rajesh@homegenny.com',
          role: 'Field Staff',
          department: 'Home Services',
          status: 'Active',
          pipelineStage: 'Training',
          trainingProgress: 0.6,
          joiningDate: '15 Jan 2024',
        ),
        RmStaffMember(
          id: 'STF-002',
          name: 'Priya Nair',
          phone: '+91 98123 45678',
          email: 'priya@homegenny.com',
          role: 'Field Staff',
          department: 'Home Services',
          status: 'Pending Verification',
          pipelineStage: 'Document Upload',
          trainingProgress: 0.2,
          joiningDate: '20 Feb 2024',
        ),
        RmStaffMember(
          id: 'STF-003',
          name: 'Amit Singh',
          phone: '+91 99887 76655',
          email: 'amit@homegenny.com',
          role: 'Senior Staff',
          department: 'Home Services',
          status: 'Deployed',
          pipelineStage: 'Deployment',
          trainingProgress: 1.0,
          joiningDate: '10 Nov 2023',
        ),
      ];

  List<RmClient> get _clients => const [
        RmClient(
          id: 'CLT-001',
          name: 'Priya Sharma',
          phone: '+91 99887 76655',
          email: 'priya.sharma@email.com',
          address: '42, Green Park Extension, New Delhi',
          requirements: 'Full-time house help, cooking & cleaning',
          assignedStaffId: 'STF-001',
          assignedStaffName: 'Rajesh Kumar',
          status: 'Active',
        ),
        RmClient(
          id: 'CLT-002',
          name: 'Anil Mehta',
          phone: '+91 98712 34567',
          email: 'anil.mehta@email.com',
          address: '15, Bandra West, Mumbai',
          requirements: 'Elderly care, 8 hours daily',
          assignedStaffId: 'STF-003',
          assignedStaffName: 'Amit Singh',
          status: 'Trial',
        ),
        RmClient(
          id: 'CLT-003',
          name: 'Sneha Reddy',
          phone: '+91 91234 56789',
          email: 'sneha@email.com',
          address: '8, Koramangala, Bangalore',
          requirements: 'Part-time cleaning, weekends',
          assignedStaffId: null,
          assignedStaffName: null,
          status: 'Unassigned',
        ),
      ];

  Future<RmDashboardData> getDashboard() => _simulate(
        RmDashboardData(
          rmName: 'Amit Verma',
          followUpsToday: _followUps,
          pendingVerification: 3,
          pendingTraining: 2,
          pendingAgreement: 1,
          pendingDeployment: 2,
          clientRequests: 2,
          totalStaff: 24,
          totalClients: 18,
          unreadNotifications: 5,
        ),
      );

  List<RmFollowUp> get _followUps => const [
        RmFollowUp(
          id: 'f1',
          title: 'Verify Priya Nair documents',
          subtitle: 'Police verification pending',
          time: '10:00 AM',
          type: RmPendingType.verification,
          staffId: 'STF-002',
        ),
        RmFollowUp(
          id: 'f2',
          title: 'Review Rajesh training progress',
          subtitle: 'Safety quiz incomplete',
          time: '11:30 AM',
          type: RmPendingType.training,
          staffId: 'STF-001',
        ),
        RmFollowUp(
          id: 'f3',
          title: 'Assign staff to Sneha Reddy',
          subtitle: 'Client request - part-time',
          time: '2:00 PM',
          type: RmPendingType.deployment,
          clientId: 'CLT-003',
        ),
        RmFollowUp(
          id: 'f4',
          title: 'Agreement signing - Priya Nair',
          subtitle: 'Employment agreement pending',
          time: '4:00 PM',
          type: RmPendingType.agreement,
          staffId: 'STF-002',
        ),
      ];

  Future<List<RmFollowUp>> getTodaysFollowUps() => _simulate(_followUps);

  Future<List<RmStaffMember>> getStaff({String? query}) async {
    await Future<void>.delayed(_delay);
    if (query == null || query.isEmpty) return _staff;
    final q = query.toLowerCase();
    return _staff
        .where(
          (s) =>
              s.name.toLowerCase().contains(q) ||
              s.id.toLowerCase().contains(q),
        )
        .toList();
  }

  Future<RmStaffDetail> getStaffDetail(String id) async {
    await Future<void>.delayed(_delay);
    final s = _staff.firstWhere((e) => e.id == id);
    return RmStaffDetail(
      id: s.id,
      name: s.name,
      phone: s.phone,
      email: s.email,
      role: s.role,
      department: s.department,
      status: s.status,
      pipelineStage: s.pipelineStage,
      trainingProgress: s.trainingProgress,
      joiningDate: s.joiningDate,
      documentsCount: 4,
      attendancePercent: 92,
      lastSalary: '₹25,760',
      address: 'Delhi, India',
    );
  }

  Future<void> createStaff(Map<String, String> data) => _simulate(null);
  Future<void> updateStaff(String id, Map<String, String> data) =>
      _simulate(null);

  Future<List<RmClient>> getClients({String? query}) async {
    await Future<void>.delayed(_delay);
    if (query == null || query.isEmpty) return _clients;
    final q = query.toLowerCase();
    return _clients
        .where((c) => c.name.toLowerCase().contains(q))
        .toList();
  }

  Future<RmClient> getClientDetail(String id) async {
    await Future<void>.delayed(_delay);
    return _clients.firstWhere((c) => c.id == id);
  }

  List<RmPendingDocument> get _pendingDocs => const [
        RmPendingDocument(
          id: 'DOC-001',
          staffId: 'STF-002',
          staffName: 'Priya Nair',
          documentName: 'Police Verification',
          documentType: 'PDF',
          uploadedAt: 'Today',
          status: RmVerificationStatus.pending,
        ),
        RmPendingDocument(
          id: 'DOC-002',
          staffId: 'STF-001',
          staffName: 'Rajesh Kumar',
          documentName: 'Address Proof',
          documentType: 'PDF',
          uploadedAt: 'Yesterday',
          status: RmVerificationStatus.pending,
        ),
      ];

  Future<List<RmPendingDocument>> getPendingDocuments() =>
      _simulate(_pendingDocs);

  Future<void> approveDocument(String id, {String? remarks}) =>
      _simulate(null);
  Future<void> rejectDocument(String id, String remarks) => _simulate(null);

  List<RmPendingVideo> get _pendingVideos => const [
        RmPendingVideo(
          id: 'VID-001',
          staffId: 'STF-002',
          staffName: 'Priya Nair',
          promptTitle: 'Service Demonstration',
          uploadedAt: '2h ago',
          status: RmVideoStatus.pending,
        ),
        RmPendingVideo(
          id: 'VID-002',
          staffId: 'STF-001',
          staffName: 'Rajesh Kumar',
          promptTitle: 'Client Greeting',
          uploadedAt: '5h ago',
          status: RmVideoStatus.pending,
        ),
      ];

  Future<List<RmPendingVideo>> getPendingVideos() =>
      _simulate(_pendingVideos);

  Future<void> approveVideo(String id, {String? remarks}) => _simulate(null);
  Future<void> rejectVideo(String id, String remarks) => _simulate(null);
  Future<void> assignTraining(String staffId, String courseId) =>
      _simulate(null);

  List<RmDeployment> get _deployments => const [
        RmDeployment(
          id: 'DEP-001',
          staffId: 'STF-001',
          staffName: 'Rajesh Kumar',
          clientId: 'CLT-001',
          clientName: 'Priya Sharma',
          location: 'Green Park, Delhi',
          startDate: '1 Mar 2024',
          status: RmDeploymentStatus.trial,
        ),
        RmDeployment(
          id: 'DEP-002',
          staffId: 'STF-003',
          staffName: 'Amit Singh',
          clientId: 'CLT-002',
          clientName: 'Anil Mehta',
          location: 'Bandra, Mumbai',
          startDate: '15 Jan 2024',
          status: RmDeploymentStatus.permanent,
        ),
      ];

  Future<List<RmDeployment>> getDeployments() => _simulate(_deployments);

  Future<void> assignDeployment({
    required String staffId,
    required String clientId,
    required String type,
  }) =>
      _simulate(null);

  Future<RmReportSummary> getReport(RmReportPeriod period) => _simulate(
        RmReportSummary(
          title: '${period.name} Report',
          period: switch (period) {
            RmReportPeriod.daily => 'Today',
            RmReportPeriod.weekly => 'This Week',
            RmReportPeriod.monthly => 'July 2024',
          },
          metrics: const [
            RmReportMetric(label: 'Staff Onboarded', value: '3', change: '+12%'),
            RmReportMetric(label: 'Deployments', value: '2', change: '+8%'),
            RmReportMetric(label: 'Verifications', value: '5', change: '-3%'),
            RmReportMetric(label: 'Client Satisfaction', value: '4.6', change: '+5%'),
          ],
        ),
      );

  Future<RmReportSummary> getAttendanceReport() => _simulate(
        const RmReportSummary(
          title: 'Attendance Report',
          period: 'July 2024',
          metrics: [
            RmReportMetric(label: 'Avg Attendance', value: '94%', change: '+2%'),
            RmReportMetric(label: 'Late Arrivals', value: '8', change: '-15%'),
            RmReportMetric(label: 'Absences', value: '3', change: '-10%'),
          ],
        ),
      );

  Future<RmReportSummary> getPipelineReport() => _simulate(
        const RmReportSummary(
          title: 'Pipeline Report',
          period: 'Current',
          metrics: [
            RmReportMetric(label: 'In Training', value: '6', change: '+2'),
            RmReportMetric(label: 'Pending Docs', value: '3', change: '-1'),
            RmReportMetric(label: 'Ready to Deploy', value: '4', change: '+1'),
          ],
        ),
      );

  Future<RmReportSummary> getDeploymentReport() => _simulate(
        const RmReportSummary(
          title: 'Deployment Report',
          period: 'July 2024',
          metrics: [
            RmReportMetric(label: 'Active Deployments', value: '12', change: '+3'),
            RmReportMetric(label: 'Trial Period', value: '4', change: '+1'),
            RmReportMetric(label: 'Permanent', value: '8', change: '+2'),
          ],
        ),
      );

  List<RmClientRequest> get _clientRequests => const [
        RmClientRequest(
          id: 'REQ-001',
          clientName: 'Sneha Reddy',
          requestType: 'Staff Assignment',
          message: 'Need part-time cleaner for weekends',
          time: '1h ago',
          isUrgent: true,
        ),
        RmClientRequest(
          id: 'REQ-002',
          clientName: 'Anil Mehta',
          requestType: 'Replacement',
          message: 'Request backup staff for trial period',
          time: '3h ago',
          isUrgent: false,
        ),
      ];

  Future<List<RmClientRequest>> getClientRequests() =>
      _simulate(_clientRequests);

  List<RmNotification> get _notifications => const [
        RmNotification(
          id: 'N1',
          title: 'Document Pending',
          message: 'Priya Nair uploaded police verification',
          time: '30m ago',
          isRead: false,
          type: 'verification',
        ),
        RmNotification(
          id: 'N2',
          title: 'Video Review',
          message: 'Rajesh Kumar submitted certification video',
          time: '2h ago',
          isRead: false,
          type: 'video',
        ),
        RmNotification(
          id: 'N3',
          title: 'Client Request',
          message: 'Sneha Reddy needs staff assignment',
          time: '4h ago',
          isRead: true,
          type: 'client',
        ),
      ];

  Future<List<RmNotification>> getNotifications() =>
      _simulate(_notifications);

  Future<void> markNotificationRead(String id) => _simulate(null);
}
