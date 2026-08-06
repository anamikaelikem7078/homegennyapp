import '../../domain/models/staff_models.dart';

/// Dummy API with simulated network delay for Staff module.
class StaffDummyApi {
  StaffDummyApi();

  static const _delay = Duration(milliseconds: 600);

  Future<T> _simulate<T>(T data) async {
    await Future<void>.delayed(_delay);
    return data;
  }

  StaffProfile get _profile => const StaffProfile(
        id: 'STF-001',
        name: 'Rajesh Kumar',
        email: 'rajesh.kumar@homegenny.com',
        phone: '+91 98765 43210',
        role: 'Field Staff',
        department: 'Home Services',
        employeeId: 'HG-2024-0847',
        joiningDate: '15 Jan 2024',
        completionPercent: 72,
        avatarUrl: null,
      );

  Future<StaffDashboardData> getDashboard() => _simulate(
        StaffDashboardData(
          profile: _profile,
          tasks: _tasks,
          currentStage: _pipeline.firstWhere(
            (s) => s.status == PipelineStageStatus.current,
          ),
          attendanceToday: _attendanceRecords.first,
          unreadNotifications: 3,
          profileCompletion: 72,
        ),
      );

  List<StaffTask> get _tasks => const [
        StaffTask(
          id: 't1',
          title: 'Complete safety training',
          description: 'Watch safety video and pass quiz',
          dueTime: 'Today, 5:00 PM',
          priority: TaskPriority.high,
          isCompleted: false,
        ),
        StaffTask(
          id: 't2',
          title: 'Upload ID proof',
          description: 'Aadhaar card verification pending',
          dueTime: 'Today, 6:00 PM',
          priority: TaskPriority.high,
          isCompleted: false,
        ),
        StaffTask(
          id: 't3',
          title: 'Sign employment agreement',
          description: 'Digital signature required',
          dueTime: 'Tomorrow',
          priority: TaskPriority.medium,
          isCompleted: false,
        ),
        StaffTask(
          id: 't4',
          title: 'Record introduction video',
          description: 'Client-facing certification video',
          dueTime: 'This week',
          priority: TaskPriority.medium,
          isCompleted: true,
        ),
      ];

  Future<List<StaffTask>> getTodaysTasks() => _simulate(_tasks);

  List<PipelineStage> get _pipeline => const [
        PipelineStage(
          id: 's1',
          title: 'Registration',
          description: 'Account created and verified',
          status: PipelineStageStatus.completed,
          completedAt: '10 Jan 2024',
        ),
        PipelineStage(
          id: 's2',
          title: 'Document Upload',
          description: 'ID and address proof submitted',
          status: PipelineStageStatus.completed,
          completedAt: '12 Jan 2024',
        ),
        PipelineStage(
          id: 's3',
          title: 'Training',
          description: 'Complete mandatory training modules',
          status: PipelineStageStatus.current,
          completedAt: null,
        ),
        PipelineStage(
          id: 's4',
          title: 'Video Certification',
          description: 'Record and submit certification video',
          status: PipelineStageStatus.pending,
          completedAt: null,
        ),
        PipelineStage(
          id: 's5',
          title: 'Agreement',
          description: 'Sign employment agreement',
          status: PipelineStageStatus.pending,
          completedAt: null,
        ),
        PipelineStage(
          id: 's6',
          title: 'Deployment',
          description: 'Assigned to client location',
          status: PipelineStageStatus.pending,
          completedAt: null,
        ),
      ];

  Future<List<PipelineStage>> getPipeline() => _simulate(_pipeline);

  Future<StaffProfile> getProfile() => _simulate(_profile);

  List<StaffDocument> get _documents => const [
        StaffDocument(
          id: 'd1',
          name: 'Aadhaar Card',
          type: 'PDF',
          uploadedAt: '12 Jan 2024',
          status: DocumentApprovalStatus.approved,
        ),
        StaffDocument(
          id: 'd2',
          name: 'PAN Card',
          type: 'PDF',
          uploadedAt: '12 Jan 2024',
          status: DocumentApprovalStatus.approved,
        ),
        StaffDocument(
          id: 'd3',
          name: 'Address Proof',
          type: 'PDF',
          uploadedAt: '14 Jan 2024',
          status: DocumentApprovalStatus.pending,
        ),
        StaffDocument(
          id: 'd4',
          name: 'Police Verification',
          type: 'PDF',
          uploadedAt: '15 Jan 2024',
          status: DocumentApprovalStatus.rejected,
          rejectionReason: 'Document is blurry. Please re-upload a clear copy.',
        ),
      ];

  Future<List<StaffDocument>> getDocuments() => _simulate(_documents);

  Future<StaffDocument> getDocument(String id) async {
    await Future<void>.delayed(_delay);
    return _documents.firstWhere((d) => d.id == id);
  }

  Future<void> uploadDocument(String name, String type) => _simulate(null);

  Future<void> reuploadDocument(String id, String name) => _simulate(null);

  List<TrainingCategory> get _categories => const [
        TrainingCategory(
          id: 'c1',
          name: 'Safety & Compliance',
          courseCount: 3,
          icon: 'shield',
        ),
        TrainingCategory(
          id: 'c2',
          name: 'Customer Service',
          courseCount: 2,
          icon: 'people',
        ),
        TrainingCategory(
          id: 'c3',
          name: 'Technical Skills',
          courseCount: 4,
          icon: 'build',
        ),
      ];

  Future<List<TrainingCategory>> getTrainingCategories() =>
      _simulate(_categories);

  List<TrainingCourse> get _courses => const [
        TrainingCourse(
          id: 'tr1',
          title: 'Workplace Safety Basics',
          categoryId: 'c1',
          duration: '25 min',
          progress: 1.0,
          type: 'video',
        ),
        TrainingCourse(
          id: 'tr2',
          title: 'Fire Safety Guidelines',
          categoryId: 'c1',
          duration: '15 min',
          progress: 0.6,
          type: 'pdf',
        ),
        TrainingCourse(
          id: 'tr3',
          title: 'Safety Assessment Quiz',
          categoryId: 'c1',
          duration: '10 min',
          progress: 0.0,
          type: 'quiz',
        ),
        TrainingCourse(
          id: 'tr4',
          title: 'Client Communication',
          categoryId: 'c2',
          duration: '20 min',
          progress: 0.0,
          type: 'video',
        ),
      ];

  Future<List<TrainingCourse>> getTrainingCourses({String? categoryId}) async {
    await Future<void>.delayed(_delay);
    if (categoryId == null) return _courses;
    return _courses.where((c) => c.categoryId == categoryId).toList();
  }

  Future<TrainingCourse> getTrainingCourse(String id) async {
    await Future<void>.delayed(_delay);
    return _courses.firstWhere((c) => c.id == id);
  }

  List<QuizQuestion> get _quizQuestions => const [
        QuizQuestion(
          id: 'q1',
          question: 'What should you do first in case of fire?',
          options: [
            'Run immediately',
            'Activate fire alarm',
            'Take photos',
            'Ignore it',
          ],
          correctIndex: 1,
        ),
        QuizQuestion(
          id: 'q2',
          question: 'PPE stands for?',
          options: [
            'Personal Protective Equipment',
            'Public Property Entry',
            'Private Process Engine',
            'None of the above',
          ],
          correctIndex: 0,
        ),
        QuizQuestion(
          id: 'q3',
          question: 'Who is responsible for workplace safety?',
          options: ['Only managers', 'Only staff', 'Everyone', 'Nobody'],
          correctIndex: 2,
        ),
      ];

  Future<List<QuizQuestion>> getQuiz(String courseId) =>
      _simulate(_quizQuestions);

  Future<QuizResult> submitQuiz(
    String courseId,
    Map<String, int> answers,
  ) async {
    await Future<void>.delayed(_delay);
    var score = 0;
    for (final q in _quizQuestions) {
      if (answers[q.id] == q.correctIndex) score++;
    }
    return QuizResult(
      score: score,
      total: _quizQuestions.length,
      passed: score >= 2,
    );
  }

  List<VideoCertPrompt> get _videoPrompts => const [
        VideoCertPrompt(
          id: 'v1',
          title: 'Self Introduction',
          instructions:
              'Introduce yourself, mention your experience and skills (max 2 min)',
          status: VideoCertStatus.approved,
        ),
        VideoCertPrompt(
          id: 'v2',
          title: 'Service Demonstration',
          instructions:
              'Demonstrate basic home service procedure (max 3 min)',
          status: VideoCertStatus.pending,
        ),
        VideoCertPrompt(
          id: 'v3',
          title: 'Client Greeting',
          instructions:
              'Show how you greet and communicate with clients (max 1 min)',
          status: VideoCertStatus.pending,
        ),
      ];

  Future<List<VideoCertPrompt>> getVideoCertPrompts() =>
      _simulate(_videoPrompts);

  Future<void> uploadVideoCert(String promptId) => _simulate(null);

  StaffAgreement get _agreement => const StaffAgreement(
        id: 'agr1',
        title: 'Employment Agreement',
        content:
            'This Employment Agreement is entered into between HomeGenny Pvt. Ltd. and the Employee. '
            'The Employee agrees to perform duties as assigned, maintain confidentiality, '
            'follow safety protocols, and adhere to company policies. '
            'Compensation and benefits will be as per the offer letter. '
            'Either party may terminate with 30 days written notice.',
        status: AgreementStatus.pending,
        signedAt: null,
      );

  Future<StaffAgreement> getAgreement() => _simulate(_agreement);

  Future<void> signAgreement(String signature) => _simulate(null);

  DeploymentInfo get _deployment => const DeploymentInfo(
        clientName: 'Priya Sharma',
        clientPhone: '+91 99887 76655',
        workLocation: '42, Green Park Extension, New Delhi - 110016',
        latitude: 28.5672,
        longitude: 77.2100,
        joiningDate: '1 Mar 2024',
        rmName: 'Amit Verma',
        rmPhone: '+91 98123 45678',
        rmEmail: 'amit.verma@homegenny.com',
      );

  Future<DeploymentInfo> getDeployment() => _simulate(_deployment);

  final List<AttendanceRecord> _attendanceRecords = [
    const AttendanceRecord(
      id: 'a1',
      date: 'Today',
      checkIn: '09:02 AM',
      checkOut: null,
      status: AttendanceDayStatus.present,
      location: 'Green Park, Delhi',
    ),
    const AttendanceRecord(
      id: 'a2',
      date: 'Yesterday',
      checkIn: '09:15 AM',
      checkOut: '06:30 PM',
      status: AttendanceDayStatus.late,
      location: 'Green Park, Delhi',
    ),
    const AttendanceRecord(
      id: 'a3',
      date: '18 Jul 2024',
      checkIn: '08:55 AM',
      checkOut: '06:15 PM',
      status: AttendanceDayStatus.present,
      location: 'Green Park, Delhi',
    ),
  ];

  Future<AttendanceRecord?> getTodayAttendance() async {
    await Future<void>.delayed(_delay);
    return _attendanceRecords.first;
  }

  Future<CheckInResult> checkIn({String? selfiePath}) async {
    await Future<void>.delayed(_delay);
    if (_attendanceRecords.isNotEmpty) {
      _attendanceRecords[0] = AttendanceRecord(
        id: _attendanceRecords[0].id,
        date: _attendanceRecords[0].date,
        checkIn: '09:02 AM',
        checkOut: null,
        status: AttendanceDayStatus.present,
        location: _attendanceRecords[0].location,
      );
    }
    return const CheckInResult(
      success: true,
      message: 'Checked in successfully',
      timestamp: '09:02 AM',
      gpsVerified: true,
    );
  }

  Future<CheckInResult> checkOut() async {
    await Future<void>.delayed(_delay);
    if (_attendanceRecords.isNotEmpty) {
      _attendanceRecords[0] = AttendanceRecord(
        id: _attendanceRecords[0].id,
        date: _attendanceRecords[0].date,
        checkIn: _attendanceRecords[0].checkIn,
        checkOut: '06:30 PM',
        status: _attendanceRecords[0].status,
        location: _attendanceRecords[0].location,
      );
    }
    return const CheckInResult(
      success: true,
      message: 'Checked out successfully',
      timestamp: '06:30 PM',
      gpsVerified: true,
    );
  }

  Future<List<AttendanceRecord>> getAttendanceHistory() =>
      _simulate(_attendanceRecords);

  Future<MonthlyAttendance> getMonthlyAttendance(String month) => _simulate(
        const MonthlyAttendance(
          month: 'July 2024',
          present: 18,
          absent: 1,
          late: 2,
          leave: 1,
        ),
      );

  SalarySummary get _salarySummary => const SalarySummary(
        month: 'June 2024',
        gross: '₹28,000',
        deductions: '₹2,240',
        net: '₹25,760',
        status: 'Paid',
      );

  Future<SalarySummary> getSalarySummary() => _simulate(_salarySummary);

  List<Payslip> get _payslips => const [
        Payslip(
          id: 'p1',
          month: 'June 2024',
          amount: '₹25,760',
          paidOn: '1 Jul 2024',
        ),
        Payslip(
          id: 'p2',
          month: 'May 2024',
          amount: '₹25,760',
          paidOn: '1 Jun 2024',
        ),
        Payslip(
          id: 'p3',
          month: 'April 2024',
          amount: '₹24,500',
          paidOn: '1 May 2024',
        ),
      ];

  Future<List<Payslip>> getPayslipHistory() => _simulate(_payslips);

  Future<Payslip> getPayslip(String id) async {
    await Future<void>.delayed(_delay);
    return _payslips.firstWhere((p) => p.id == id);
  }

  BankDetails get _bankDetails => const BankDetails(
        accountHolder: 'Rajesh Kumar',
        accountNumber: '****4567',
        bankName: 'HDFC Bank',
        ifsc: 'HDFC0001234',
      );

  Future<BankDetails> getBankDetails() => _simulate(_bankDetails);

  List<StaffNotification> get _notifications => const [
        StaffNotification(
          id: 'n1',
          title: 'Document Rejected',
          message: 'Police verification document needs re-upload',
          time: '2h ago',
          isRead: false,
          type: 'document',
        ),
        StaffNotification(
          id: 'n2',
          title: 'Training Reminder',
          message: 'Complete Safety Assessment Quiz by today',
          time: '5h ago',
          isRead: false,
          type: 'training',
        ),
        StaffNotification(
          id: 'n3',
          title: 'Salary Credited',
          message: 'June salary of ₹25,760 has been credited',
          time: '1d ago',
          isRead: false,
          type: 'salary',
        ),
        StaffNotification(
          id: 'n4',
          title: 'Agreement Pending',
          message: 'Please sign your employment agreement',
          time: '2d ago',
          isRead: true,
          type: 'agreement',
        ),
      ];

  Future<List<StaffNotification>> getNotifications() =>
      _simulate(_notifications);

  Future<void> markNotificationRead(String id) => _simulate(null);

  Future<void> updatePassword(String current, String newPassword) =>
      _simulate(null);
}
