import 'package:file_picker/file_picker.dart';

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
        staffApplicantId: 'STF-001',
        staffCode: 'staff001',
        fullName: 'Rajesh Kumar',
        mobile: '+91 98765 43210',
        email: 'rajesh.kumar@homegenny.com',
        series: 'MAID',
        pipelineStage: 'S3_TRAIN',
        address: '42, Green Park Extension, New Delhi',
        dateOfBirth: '1996-05-15',
      );

  Future<StaffDashboardData> getDashboard() => _simulate(
        StaffDashboardData(
          staffCode: _profile.staffCode,
          fullName: _profile.fullName,
          series: _profile.series,
          pipelineStage: _profile.pipelineStage,
          completionPct: 72,
          assignedRmName: 'Amit Verma',
          assignedRmPhone: '+91 98123 45678',
          todayTasks: _tasks,
        ),
      );

  List<StaffTask> get _tasks => const [
        StaffTask(id: '1', title: 'Complete safety training', done: false),
        StaffTask(id: '2', title: 'Upload ID proof', done: false),
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

  Future<void> updateProfile({String? address, String? email}) => _simulate(null);

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

  Future<void> uploadDocument(String name, String type, PlatformFile file) => _simulate(null);

  Future<void> reuploadDocument(String id, String name) => _simulate(null);

  // Dummy answer key kept only on the phone side, to score the offline demo
  // quiz — the real API never sends this to the app (see decodeQuizQuestion).
  static const _dummyQuizAnswerKey = {'q1': 1, 'q2': 0};

  List<TrainingQuizQuestion> get _dummyQuizQuestions => const [
        TrainingQuizQuestion(
          id: 'q1',
          questionText: 'What should you do first in case of fire?',
          type: TrainingQuestionType.mcq,
          options: ['Run immediately', 'Activate fire alarm', 'Take photos', 'Ignore it'],
          orderIndex: 0,
          points: 1,
        ),
        TrainingQuizQuestion(
          id: 'q2',
          questionText: 'PPE stands for?',
          type: TrainingQuestionType.mcq,
          options: [
            'Personal Protective Equipment',
            'Public Property Entry',
            'Private Process Engine',
            'None of the above',
          ],
          orderIndex: 1,
          points: 1,
        ),
        TrainingQuizQuestion(
          id: 'q3',
          questionText: 'How would you handle a medical emergency at a client home?',
          type: TrainingQuestionType.text,
          orderIndex: 2,
          points: 1,
        ),
      ];

  TrainingHome get _trainingHome => TrainingHome(
        staffFullName: _profile.fullName,
        staffCode: _profile.staffCode,
        series: _profile.series,
        pipelineStage: _profile.pipelineStage,
        videoCert: const TrainingVideoCertProgress(approved: 3, required_: 9),
        batches: [
          TrainingBatch(
            id: 'batch-1',
            batchCode: 'TRN-M3X-DEMO-0001',
            series: _profile.series,
            trainerName: 'Sunita Trainer',
            classroom: 'Room A',
            status: 'ONGOING',
            startDate: '2026-09-29',
            endDate: '2026-10-04',
            quizDate: '2026-10-02',
            enrolledAt: DateTime.now().toIso8601String(),
            materials: const [
              TrainingMaterial(
                id: 'mat-note-1',
                type: TrainingMaterialType.note,
                title: 'Read this first',
                createdAt: '2026-09-29T00:00:00.000Z',
                body: 'Welcome to your training batch. Complete the material below, then attempt the quiz.',
              ),
              TrainingMaterial(
                id: 'mat-pdf-1',
                type: TrainingMaterialType.pdf,
                title: 'Safety rules',
                createdAt: '2026-09-29T00:00:00.000Z',
                sizeBytes: 182044,
              ),
              TrainingMaterial(
                id: 'mat-video-1',
                type: TrainingMaterialType.video,
                title: 'Day 1 intro',
                createdAt: '2026-09-29T00:00:00.000Z',
              ),
            ],
            quizzes: [
              TrainingQuiz(
                id: 'quiz-1',
                batchId: 'batch-1',
                batchCode: 'TRN-M3X-DEMO-0001',
                title: 'Day 1 Recap',
                questionCount: _dummyQuizQuestions.length,
                totalPoints: _dummyQuizQuestions.length,
                passMarks: 2,
                state: TrainingQuizState.available,
                quizDate: '2026-10-02',
              ),
            ],
          ),
        ],
      );

  Future<TrainingHome> getTrainingHome() => _simulate(_trainingHome);

  Future<QuizAttemptStart> startQuiz(String quizId) => _simulate(
        QuizAttemptStart(
          attemptId: 'attempt-$quizId',
          quizId: quizId,
          status: 'IN_PROGRESS',
          title: 'Day 1 Recap',
          totalPoints: _dummyQuizQuestions.length,
          passMarks: 2,
          questions: _dummyQuizQuestions,
        ),
      );

  Future<QuizSubmitResult> submitQuizAttempt(
    String attemptId,
    List<TrainingQuizAnswer> answers,
  ) async {
    await Future<void>.delayed(_delay);
    final hasTextAnswer = answers.any((a) => a.answerText != null && a.answerText!.isNotEmpty);
    if (hasTextAnswer) {
      return QuizSubmitResult(
        attemptId: attemptId,
        state: TrainingQuizState.underReview,
        pendingReview: true,
        maxScore: _dummyQuizQuestions.length,
        passMarks: 2,
      );
    }
    var score = 0;
    for (final a in answers) {
      if (_dummyQuizAnswerKey[a.questionId] == a.selectedOption) score++;
    }
    final passed = score >= 2;
    return QuizSubmitResult(
      attemptId: attemptId,
      state: passed ? TrainingQuizState.passed : TrainingQuizState.failed,
      pendingReview: false,
      score: score,
      maxScore: _dummyQuizQuestions.length,
      passMarks: 2,
      passed: passed,
    );
  }

  Future<QuizResultDetail> getQuizResult(String attemptId) => _simulate(
        QuizResultDetail(
          attemptId: attemptId,
          title: 'Day 1 Recap',
          state: TrainingQuizState.passed,
          score: 2,
          maxScore: _dummyQuizQuestions.length,
          passMarks: 2,
          passed: true,
          gradedAt: DateTime.now().toIso8601String(),
          questions: [
            for (final q in _dummyQuizQuestions)
              QuizResultQuestion(
                questionId: q.id,
                questionText: q.questionText,
                type: q.type,
                options: q.options,
                points: q.points,
                yourSelectedOption: q.type == TrainingQuestionType.mcq ? _dummyQuizAnswerKey[q.id] : null,
                yourAnswerText: q.type == TrainingQuestionType.text ? 'Sample answer' : null,
                correct: true,
                pointsAwarded: q.points,
              ),
          ],
        ),
      );

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
        hasActivePlacement: true,
        placementId: 'PLC-001',
        clientName: 'Priya Sharma',
        deploymentAddress: '42, Green Park Extension, New Delhi - 110016',
        deploymentDate: '2024-03-01T00:00:00.000Z',
        trialStatus: 'CONFIRMED',
      );

  Future<DeploymentInfo> getDeployment() => _simulate(_deployment);

  final List<AttendanceRecord> _attendanceRecords = [
    const AttendanceRecord(
      date: '2026-08-15',
      checkIn: '09:02 AM',
      checkOut: null,
      status: 'present',
      location: 'Green Park, Delhi',
    ),
    const AttendanceRecord(
      date: '2026-08-14',
      checkIn: '09:15 AM',
      checkOut: '06:30 PM',
      status: 'present',
      location: 'Green Park, Delhi',
    ),
    const AttendanceRecord(
      date: '2026-08-13',
      checkIn: '08:55 AM',
      checkOut: '06:15 PM',
      status: 'present',
      location: 'Green Park, Delhi',
    ),
  ];

  String get _todayKey => DateTime.now().toIso8601String().substring(0, 10);

  Future<AttendanceRecord?> getTodayAttendance() async {
    await Future<void>.delayed(_delay);
    // A record only counts as "today's" if its date actually matches — once
    // the date rolls over, a completed previous shift must not keep blocking
    // the check-in toggle for the new day.
    if (_attendanceRecords.isNotEmpty &&
        _attendanceRecords.first.date == _todayKey) {
      return _attendanceRecords.first;
    }
    return null;
  }

  Future<CheckInResult> checkIn({double? latitude, double? longitude}) async {
    await Future<void>.delayed(_delay);
    final now = DateTime.now();
    final timestamp = now.toIso8601String();
    final record = AttendanceRecord(
      date: _todayKey,
      checkIn: timestamp,
      checkOut: null,
      status: 'present',
      location: _attendanceRecords.isNotEmpty
          ? _attendanceRecords.first.location
          : null,
    );
    if (_attendanceRecords.isNotEmpty && _attendanceRecords.first.date == _todayKey) {
      _attendanceRecords[0] = record;
    } else {
      _attendanceRecords.insert(0, record);
    }
    return CheckInResult(
      success: true,
      attendanceId: 'a1',
      status: 'CHECKED_IN',
      timestamp: timestamp,
    );
  }

  Future<CheckInResult> checkOut({double? latitude, double? longitude}) async {
    await Future<void>.delayed(_delay);
    final timestamp = DateTime.now().toIso8601String();
    if (_attendanceRecords.isNotEmpty && _attendanceRecords.first.date == _todayKey) {
      _attendanceRecords[0] = AttendanceRecord(
        date: _attendanceRecords[0].date,
        checkIn: _attendanceRecords[0].checkIn,
        checkOut: timestamp,
        status: _attendanceRecords[0].status,
        location: _attendanceRecords[0].location,
      );
    }
    return CheckInResult(
      success: true,
      attendanceId: 'a1',
      status: 'CHECKED_OUT',
      timestamp: timestamp,
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
        hasPayslips: true,
        month: 'June 2024',
        gross: '₹28,000',
        deductions: '₹2,240',
        net: '₹25,760',
        status: 'Paid',
        ref: 'FIELD_PAYROLL:demo-june',
      );

  Future<SalarySummary> getSalarySummary() => _simulate(_salarySummary);

  List<Payslip> get _payslips => const [
        Payslip(
          ref: 'FIELD_PAYROLL:demo-june',
          month: 'June 2024',
          amount: '₹25,760',
          grossAmount: '₹28,000',
          deductionsAmount: '₹2,240',
          deductionBreakdown: {'pf': 1800, 'esic': 440},
          status: 'Paid',
          presentDays: 26,
        ),
        Payslip(
          ref: 'FIELD_PAYROLL:demo-may',
          month: 'May 2024',
          amount: '₹25,760',
          grossAmount: '₹28,000',
          deductionsAmount: '₹2,240',
          deductionBreakdown: {'pf': 1800, 'esic': 440},
          status: 'Paid',
          presentDays: 25,
        ),
        Payslip(
          ref: 'FIELD_PAYROLL:demo-april',
          month: 'April 2024',
          amount: '₹24,500',
          grossAmount: '₹26,500',
          deductionsAmount: '₹2,000',
          deductionBreakdown: {'pf': 1600, 'esic': 400},
          status: 'Paid',
          presentDays: 24,
        ),
      ];

  Future<List<Payslip>> getPayslipHistory() => _simulate(_payslips);

  Future<Payslip> getPayslip(String ref) async {
    await Future<void>.delayed(_delay);
    return _payslips.firstWhere((p) => p.ref == ref);
  }

  Future<List<int>> downloadPayslipPdf(String ref) => _simulate(
        'Offline demo copy — connect to the network for the real PDF.'.codeUnits,
      );

  BankDetails get _bankDetails => const BankDetails(
        accountHolderName: 'Rajesh Kumar',
        accountNumberMasked: '****4567',
        last4: '4567',
        bankName: 'HDFC Bank',
        ifsc: 'HDFC0001234',
        verified: true,
        verifiedAt: null,
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

  Future<List<int>> downloadMaterialBytes(String viewUrl) => _simulate(
        'Offline demo copy — connect to the network for the real file.'.codeUnits,
      );
}
