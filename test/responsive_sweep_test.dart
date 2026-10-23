// Layout sweep across every screen. Run with dummy data so screens render
// real content instead of empty / error states:
//
//   flutter test test/responsive_sweep_test.dart \
//     --dart-define=USE_DUMMY_API=true --dart-define=ENABLE_OFFLINE_CACHE=false
//
// Every screen is pumped at the smallest supported phone, a common phone at
// the largest text scale `ResponsiveFrame` allows, and a landscape phone.
// Each overflow is printed as a `SWEEP|` line and fails that test. Plugin
// errors (camera, maps, secure storage…) are not layout bugs and are ignored.
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:homegennyapp/common/presentation/screens/developer_tools_screen.dart';
import 'package:homegennyapp/common/presentation/screens/no_internet_screen.dart';
import 'package:homegennyapp/common/presentation/screens/session_expired_screen.dart';
import 'package:homegennyapp/common/presentation/screens/update_app_screen.dart';
import 'package:homegennyapp/core/di/injection.dart';
import 'package:homegennyapp/core/localization/generated/app_localizations.dart';
import 'package:homegennyapp/core/presentation/screens/app_settings_screens.dart';
import 'package:homegennyapp/core/presentation/screens/error_not_found_screen.dart';
import 'package:homegennyapp/core/storage/hive_service.dart';
import 'package:homegennyapp/core/theme/app_theme.dart';
import 'package:homegennyapp/features/care/domain/cook_models.dart';
import 'package:homegennyapp/features/client/presentation/screens/attendance/client_attendance_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/care/client_care_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/care/client_cook_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/care/client_instruction_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/complaint/client_complaint_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/home/client_home_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/notifications/client_notifications_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/payments/client_invoice_screen.dart'
    as invoice;
import 'package:homegennyapp/features/client/presentation/screens/payments/client_payment_screens.dart'
    as pay;
import 'package:homegennyapp/features/client/presentation/screens/profile/client_profile_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/profile/client_profile_wizard_screen.dart';
import 'package:homegennyapp/features/client/presentation/screens/replacement/client_replacement_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/staff/client_staff_screens.dart';
import 'package:homegennyapp/features/client/presentation/screens/staff_request/client_staff_request_screens.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_account_screens.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_alerts_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_assessment_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_attendance_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_dashboard_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_deferred_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_invoice_preview_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_locations_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_pipeline_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_placement_create_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_placement_detail_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_profile_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_signup_requests_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_staff_detail_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_staff_incidents_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_staff_intake_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage3_training_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage3_video_review_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage4_a1_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage4_a2_client_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage4_a2_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage4_a3_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage4_hub_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_stage5_deploy_hub_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_tasks_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_terminal_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_track1_aadhaar_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_track2_dl_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_track3_echallan_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_track4_pv_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_track5_medical_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_trials_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_upgrades_screen.dart';
import 'package:homegennyapp/features/rm/presentation/screens/rm_verification_dashboard_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/agreement/agreement_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/agreement/agreement_status_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/attendance/attendance_history_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/attendance/attendance_hub_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/attendance/check_in_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/attendance/check_out_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/attendance/monthly_attendance_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/attendance/staff_daily_shift_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/care/staff_care_screens.dart';
import 'package:homegennyapp/features/staff/presentation/screens/care/staff_client_updates_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/care/staff_cook_screens.dart';
import 'package:homegennyapp/features/staff/presentation/screens/care/staff_instruction_screens.dart';
import 'package:homegennyapp/features/staff/presentation/screens/deployment/deployment_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/documents/document_detail_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/documents/documents_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/documents/upload_document_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/help/help_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/home/staff_active_placement_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/home/staff_home_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/notifications/notifications_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/pipeline/staff_pipeline_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/profile/profile_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/profile/staff_profile_wizard_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/salary/salary_screens.dart'
    as salary;
import 'package:homegennyapp/features/staff/presentation/screens/salary/staff_payslip_screen.dart'
    as payslip;
import 'package:homegennyapp/features/staff/presentation/screens/salary/tax_declaration_screen.dart';
import 'package:homegennyapp/features/staff/presentation/screens/settings/settings_screens.dart';
import 'package:homegennyapp/features/staff/presentation/screens/training/training_screens.dart';
import 'package:homegennyapp/features/staff/presentation/screens/video_certification/video_certification_screens.dart';

import 'helpers/real_fonts.dart';

const _viewports = <(String, Size, double)>[
  ('320x568@1.0', Size(320, 568), 1.0),
  ('360x740@1.3', Size(360, 740), 1.3),
  ('landscape', Size(740, 360), 1.0),
];

// IDs match the dummy datasources.
const _staff = 'staff001';
const _placement = 'PLC-001';

final _screens = <String, Widget Function()>{
  // common / core
  'NoInternet': () => const NoInternetScreen(),
  'SessionExpired': () => const SessionExpiredScreen(),
  'UpdateApp': () => const UpdateAppScreen(),
  'DeveloperTools': () => const DeveloperToolsScreen(),
  'ErrorNotFound': () => const ErrorNotFoundScreen(),
  'AppLanguageSettings': () => const AppLanguageSettingsScreen(),
  'AppThemeSettings': () => const AppThemeSettingsScreen(),
  // client
  'ClientHome': () => const ClientHomeScreen(),
  'ClientAssignedStaff': () => const ClientAssignedStaffScreen(),
  'ClientAttendanceSummary': () => const ClientAttendanceSummaryScreen(),
  'ClientPendingPayment': () => const ClientPendingPaymentScreen(),
  'ClientAttendanceHistory': () => const ClientAttendanceHistoryScreen(),
  'ClientRaiseAttendanceIssue': () => const ClientRaiseAttendanceIssueScreen(),
  'ClientTodayAttendance': () => const ClientTodayAttendanceScreen(),
  'ClientCare': () => const ClientCareScreen(placementId: _placement),
  'ClientCareHistory': () =>
      const ClientCareHistoryScreen(placementId: _placement),
  'ClientCarePlan': () => const ClientCarePlanScreen(placementId: _placement),
  'ClientFoodProfile': () => const ClientFoodProfileScreen(),
  'ClientMeals': () => const ClientMealsScreen(placementId: _placement),
  'ClientMenu': () => const ClientMenuScreen(placementId: _placement),
  'ClientInstructions': () =>
      const ClientInstructionsScreen(placementId: _placement),
  'ClientNewInstruction': () =>
      const ClientNewInstructionScreen(placementId: _placement),
  'ClientComplaintHistory': () => const ClientComplaintHistoryScreen(),
  'ClientRaiseComplaint': () => const ClientRaiseComplaintScreen(),
  'ClientNotificationsTab': () => const ClientNotificationsTabScreen(),
  'ClientInvoice': () => const invoice.ClientInvoiceScreen(),
  'ClientInvoice(payments)': () => const pay.ClientInvoiceScreen(),
  'ClientDownloadInvoice': () =>
      const pay.ClientDownloadInvoiceScreen(invoiceId: 'HG-INV-2407-001'),
  'ClientPaymentHistory': () => const pay.ClientPaymentHistoryScreen(),
  'ClientPaymentStatus': () => const pay.ClientPaymentStatusScreen(),
  'ClientPaymentsTab': () => const pay.ClientPaymentsTabScreen(),
  'ClientUpiPayment': () => const pay.ClientUpiPaymentScreen(
    invoiceId: 'HG-INV-2407-001',
    amount: 18500,
  ),
  'ClientAddress': () => const ClientAddressScreen(),
  'ClientPaymentDetails': () => const ClientPaymentDetailsScreen(),
  'ClientPersonalDetails': () => const ClientPersonalDetailsScreen(),
  'ClientProfileTab': () => const ClientProfileTabScreen(),
  'ClientSettings': () => const ClientSettingsScreen(),
  'ClientProfileWizard': () => const ClientProfileWizardScreen(),
  'ClientReplacementRequest': () => const ClientReplacementRequestScreen(),
  'ClientReplacementStatus': () => const ClientReplacementStatusScreen(),
  'ClientStaffTab': () => const ClientStaffTabScreen(),
  'ClientStaffProfile': () => const ClientStaffProfileScreen(staffId: _staff),
  'ClientStaffAttendance': () =>
      const ClientStaffAttendanceScreen(staffId: _staff),
  'ClientStaffExperience': () =>
      const ClientStaffExperienceScreen(staffId: _staff),
  'ClientStaffPerformance': () =>
      const ClientStaffPerformanceScreen(staffId: _staff),
  'ClientStaffSkills': () => const ClientStaffSkillsScreen(staffId: _staff),
  'ClientStaffRequestForm': () => const ClientStaffRequestFormScreen(),
  'ClientStaffRequests': () => const ClientStaffRequestsScreen(),
  'ClientStaffRequestDetail': () =>
      const ClientStaffRequestDetailScreen(requestId: 'REQ-001'),
  // staff
  'StaffHome': () => const StaffHomeScreen(),
  'StaffProfileCompletion': () => const StaffProfileCompletionScreen(),
  'StaffTodaysTasks': () => const StaffTodaysTasksScreen(),
  'StaffActivePlacement': () => const StaffActivePlacementScreen(),
  'StaffAgreement': () => const AgreementScreen(),
  'StaffAgreementStatus': () => const AgreementStatusScreen(),
  'StaffAttendanceHistory': () => const StaffAttendanceHistoryScreen(),
  'StaffAttendanceHub': () => const StaffAttendanceHubScreen(),
  'StaffCheckIn': () => const StaffCheckInScreen(),
  'StaffCheckOut': () => const StaffCheckOutScreen(),
  'StaffMonthlyAttendance': () => const StaffMonthlyAttendanceScreen(),
  'StaffDailyShift': () => const StaffDailyShiftScreen(),
  'StaffCareToday': () => const StaffCareTodayScreen(),
  'StaffCarePlan': () => const StaffCarePlanScreen(placementId: _placement),
  'StaffCareReport': () => const StaffCareReportScreen(placementId: _placement),
  'StaffClientUpdates': () => const StaffClientUpdatesScreen(),
  'StaffCookToday': () => const StaffCookTodayScreen(),
  'StaffCookRatings': () =>
      const StaffCookRatingsScreen(placementId: _placement),
  'StaffLogMeal': () => const StaffLogMealScreen(
    placementId: _placement,
    slot: CookMealSlot(meal: 'LUNCH'),
  ),
  'StaffInstructions': () => const StaffInstructionsScreen(),
  'StaffDeployment': () => const DeploymentScreen(),
  'StaffDocuments': () => const StaffDocumentsScreen(),
  'StaffDocumentDetail': () =>
      const StaffDocumentDetailScreen(documentId: 'd1'),
  'StaffDocumentReupload': () =>
      const StaffDocumentReuploadScreen(documentId: 'd1'),
  'StaffUploadDocument': () => const StaffUploadDocumentScreen(),
  'StaffHelp': () => const StaffHelpScreen(),
  'StaffNotifications': () => const StaffNotificationsScreen(),
  'StaffPipeline': () => const StaffPipelineScreen(),
  'StaffPipelineStage': () => const StaffPipelineStageScreen(stageId: 's1'),
  'StaffProfile': () => const StaffProfileScreen(),
  'StaffProfileWizard': () => const StaffProfileWizardScreen(),
  'StaffSalary': () => const salary.StaffSalaryScreen(),
  'StaffSalaryHistory': () => const salary.StaffSalaryHistoryScreen(),
  'StaffBankDetails': () => const salary.StaffBankDetailsScreen(),
  'StaffPayslip(id)': () => const salary.StaffPayslipScreen(payslipId: 'P1'),
  'StaffPayslip': () => const payslip.StaffPayslipScreen(),
  'StaffTaxDeclaration': () => const StaffTaxDeclarationScreen(),
  'StaffSettings': () => const StaffSettingsScreen(),
  'StaffBiometricSettings': () => const StaffBiometricSettingsScreen(),
  'StaffChangePassword': () => const StaffChangePasswordScreen(),
  'StaffLanguageSettings': () => const StaffLanguageSettingsScreen(),
  'StaffThemeSettings': () => const StaffThemeSettingsScreen(),
  'StaffTraining': () => const StaffTrainingScreen(),
  'StaffTrainingMaterial': () =>
      const StaffTrainingMaterialScreen(materialId: 'mat-note-1'),
  'StaffQuiz': () => const StaffQuizScreen(quizId: 'quiz-1'),
  'StaffTrainingResult': () => const StaffTrainingResultScreen(attemptId: 'a1'),
  'StaffVideoCertification': () => const StaffVideoCertificationScreen(),
  'StaffVideoApproval': () => const StaffVideoApprovalScreen(promptId: 'v1'),
  'StaffVideoUpload': () => const StaffVideoUploadScreen(promptId: 'v1'),
  // rm (no dummy API: these show loading / error / empty states)
  'RmDashboard': () => const RmDashboardScreen(),
  'RmAlerts': () => const RmAlertsScreen(),
  'RmAttendance': () => const RmAttendanceScreen(),
  'RmDeferred': () => const RmDeferredScreen(),
  'RmLocations': () => const RmLocationsScreen(),
  'RmPipeline': () => const RmPipelineScreen(),
  'RmProfile': () => const RmProfileScreen(),
  'RmSignupRequests': () => const RmSignupRequestsScreen(),
  'RmStaffIntake': () => const RmStaffIntakeScreen(),
  'RmTasks': () => const RmTasksScreen(),
  'RmTerminal': () => const RmTerminalScreen(),
  'RmTrials': () => const RmTrialsScreen(),
  'RmUpgrades': () => const RmUpgradesScreen(),
  'RmNotificationSettings': () => const RmNotificationSettingsScreen(),
  'RmPersonalInfo': () => const RmPersonalInfoScreen(),
  'RmSecurity': () => const RmSecurityScreen(),
  'RmSupport': () => const RmSupportScreen(),
  'RmAssessment': () => const RmAssessmentScreen(staffId: _staff),
  'RmInvoicePreview': () => const RmInvoicePreviewScreen(staffId: _staff),
  'RmPlacementCreate': () => const RmPlacementCreateScreen(staffId: _staff),
  'RmPlacementDetail': () =>
      const RmPlacementDetailScreen(placementId: _placement, staffId: _staff),
  'RmStaffDetail': () => const RmStaffDetailScreen(staffId: _staff),
  'RmStaffIncidents': () => const RmStaffIncidentsScreen(staffId: _staff),
  'RmStage3Training': () => const RmStage3TrainingScreen(staffId: _staff),
  'RmStage3VideoReview': () => const RmStage3VideoReviewScreen(staffId: _staff),
  'RmStage4A1': () => const RmStage4A1Screen(staffId: _staff),
  'RmStage4A2': () =>
      const RmStage4A2Screen(staffId: _staff, placementId: _placement),
  'RmStage4A2Client': () => const RmStage4A2ClientScreen(staffId: _staff),
  'RmStage4A3': () =>
      const RmStage4A3Screen(staffId: _staff, placementId: _placement),
  'RmStage4Hub': () => const RmStage4HubScreen(staffId: _staff),
  'RmStage5DeployHub': () => const RmStage5DeployHubScreen(staffId: _staff),
  'RmTrack1Aadhaar': () => const RmTrack1AadhaarScreen(staffId: _staff),
  'RmTrack2Dl': () => const RmTrack2DlScreen(staffId: _staff),
  'RmTrack3EChallan': () => const RmTrack3EChallanScreen(staffId: _staff),
  'RmTrack4Pv': () => const RmTrack4PvScreen(staffId: _staff),
  'RmTrack5Medical': () => const RmTrack5MedicalScreen(staffId: _staff),
  'RmVerificationDashboard': () =>
      const RmVerificationDashboardScreen(staffId: _staff),
};

void main() {
  // Settings / theme / language screens read Hive; init() falls back to a
  // temp dir when path_provider isn't available, as in tests.
  final hive = HiveService();
  setUpAll(() async {
    await loadRealFonts();
    await hive.init();
  });

  for (final MapEntry(key: name, value: build) in _screens.entries) {
    for (final (label, size, scale) in _viewports) {
      testWidgets('$name @ $label', (tester) async {
        tester.view.physicalSize = size;
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.reset);

        final overflows = <String>{};
        final previous = FlutterError.onError;
        FlutterError.onError = (d) {
          final msg = d.exceptionAsString().split('\n').first;
          if (msg.contains('overflowed')) {
            // "The relevant error-causing widget was: Column file:///…/x.dart:42:15"
            final at = RegExp(
              r'lib/[\w/]+\.dart:\d+',
            ).firstMatch(d.toString())?.group(0);
            overflows.add(at == null ? msg : '$msg ($at)');
          } else {
            previous?.call(d);
          }
        };

        final router = GoRouter(
          routes: [GoRoute(path: '/', builder: (_, _) => build())],
        );
        await tester.pumpWidget(
          ProviderScope(
            overrides: [hiveServiceProvider.overrideWithValue(hive)],
            child: ScreenUtilInit(
              designSize: const Size(390, 844),
              builder: (_, _) => MaterialApp.router(
                theme: AppTheme.light(),
                routerConfig: router,
                localizationsDelegates: const [
                  AppLocalizations.delegate,
                  GlobalMaterialLocalizations.delegate,
                  GlobalWidgetsLocalizations.delegate,
                  GlobalCupertinoLocalizations.delegate,
                ],
                supportedLocales: AppLocalizations.supportedLocales,
                builder: (context, child) => MediaQuery(
                  data: MediaQuery.of(
                    context,
                  ).copyWith(textScaler: TextScaler.linear(scale)),
                  child: child!,
                ),
              ),
            ),
          ),
        );
        // Frame by frame, long enough for the dummy API's 600 ms delay and
        // entrance animations.
        for (var i = 0; i < 25; i++) {
          await tester.pump(const Duration(milliseconds: 100));
        }
        FlutterError.onError = previous;
        tester.takeException();

        for (final o in overflows) {
          // ignore: avoid_print
          print('SWEEP|$name|$label|$o');
        }
        expect(overflows, isEmpty);
      });
    }
  }
}
