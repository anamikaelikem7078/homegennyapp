import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/router/route_helpers.dart';
import '../screens/rm_dashboard_screen.dart';
import '../screens/rm_pipeline_screen.dart';
import '../screens/rm_staff_intake_screen.dart';
import '../screens/rm_staff_detail_screen.dart';
import '../screens/rm_verification_dashboard_screen.dart';
import '../screens/rm_track1_aadhaar_screen.dart';
import '../screens/rm_track2_dl_screen.dart';
import '../screens/rm_track3_echallan_screen.dart';
import '../screens/rm_track4_pv_screen.dart';
import '../screens/rm_track5_medical_screen.dart';
import '../screens/rm_stage3_training_screen.dart';
import '../screens/rm_stage3_video_upload_screen.dart';
import '../screens/rm_stage3_video_review_screen.dart';
import '../screens/rm_stage4_hub_screen.dart';
import '../screens/rm_stage4_a1_screen.dart';
import '../screens/rm_stage4_otp_screen.dart';
import '../screens/rm_stage4_a2_screen.dart';

import '../screens/rm_stage4_a2_client_screen.dart';
import '../screens/rm_stage4_sow_amendment_screen.dart';
import '../screens/rm_stage4_a3_screen.dart';
import '../screens/rm_stage4_complete_screen.dart';
import '../screens/rm_stage5_trial_checkin_screen.dart';
import '../../../client/presentation/screens/payments/client_invoice_screen.dart';
import '../screens/rm_compliance_alerts_screen.dart';
import '../../../staff/presentation/screens/home/staff_active_placement_screen.dart';
import '../../../staff/presentation/screens/attendance/staff_daily_shift_screen.dart';
import '../../../staff/presentation/screens/salary/staff_payslip_screen.dart';

final List<RouteBase> rmRoutes = [
  fadeRoute(
    path: '/rm/dashboard',
    name: 'rmDashboard',
    builder: (context, state) => const RmDashboardScreen(),
  ),
  slideRoute(
    path: '/rm/pipeline',
    name: 'rmPipeline',
    builder: (context, state) => const RmPipelineScreen(),
  ),
  slideRoute(
    path: '/rm/staff-intake',
    name: 'rmStaffIntake',
    builder: (context, state) => const RmStaffIntakeScreen(),
  ),
  slideRoute(
    path: '/rm/staff/:id',
    name: 'rmStaffDetail',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStaffDetailScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/verification',
    name: 'rmVerificationDashboard',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmVerificationDashboardScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/verification/track1',
    name: 'rmTrack1',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmTrack1AadhaarScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/verification/track2',
    name: 'rmTrack2',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmTrack2DlScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/verification/track3',
    name: 'rmTrack3',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmTrack3EChallanScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/verification/track4',
    name: 'rmTrack4',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmTrack4PvScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/verification/track5',
    name: 'rmTrack5',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmTrack5MedicalScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage3/training',
    name: 'rmStage3Training',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage3TrainingScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage3/video-upload',
    name: 'rmStage3VideoUpload',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage3VideoUploadScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage3/video-review',
    name: 'rmStage3VideoReview',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage3VideoReviewScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/hub',
    name: 'rmStage4Hub',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4HubScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/a1',
    name: 'rmStage4A1',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4A1Screen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/a1-otp',
    name: 'rmStage4A1OTP',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4OtpScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/a2',
    name: 'rmStage4A2',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4A2Screen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/a2-client',
    name: 'rmStage4A2Client',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4A2ClientScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/sow-amendment',
    name: 'rmStage4SowAmendment',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4SowAmendmentScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/a3',
    name: 'rmStage4A3',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4A3Screen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage4/complete',
    name: 'rmStage4Complete',
    builder: (context, state) {
      final id = state.pathParameters['id']!;
      return RmStage4CompleteScreen(staffId: id);
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/stage5/trial-checkin',
    name: 'rmStage5TrialCheckin',
    builder: (context, state) {
      return const RmStage5TrialCheckinScreen();
    },
  ),
  slideRoute(
    path: '/rm/staff/:id/demo/active-placement',
    name: 'staffActivePlacement',
    builder: (context, state) => const StaffActivePlacementScreen(),
  ),
  slideRoute(
    path: '/rm/staff/:id/demo/daily-shift',
    name: 'staffDailyShift',
    builder: (context, state) => const StaffDailyShiftScreen(),
  ),
  slideRoute(
    path: '/rm/staff/:id/demo/payslip',
    name: 'staffPayslip',
    builder: (context, state) => const StaffPayslipScreen(),
  ),
  slideRoute(
    path: '/rm/staff/:id/demo/client-invoice',
    name: 'clientInvoice',
    builder: (context, state) => const ClientInvoiceScreen(),
  ),
  slideRoute(
    path: '/rm/staff/:id/demo/compliance-alerts',
    name: 'rmComplianceAlerts',
    builder: (context, state) => const RmComplianceAlertsScreen(),
  ),
];
