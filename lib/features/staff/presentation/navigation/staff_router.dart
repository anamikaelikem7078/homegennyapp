import 'package:go_router/go_router.dart';

import '../../../../core/router/page_transitions.dart';
import '../../../../core/router/route_helpers.dart';
import '../../domain/models/staff_models.dart';
import '../screens/agreement/agreement_screen.dart';
import '../screens/agreement/agreement_status_screen.dart';
import '../screens/agreement/digital_signature_screen.dart';
import '../screens/attendance/attendance_history_screen.dart';
import '../screens/attendance/attendance_hub_screen.dart';
import '../screens/attendance/check_in_screen.dart';
import '../screens/attendance/check_out_screen.dart';
import '../screens/attendance/monthly_attendance_screen.dart';
import '../screens/deployment/deployment_screen.dart';
import '../screens/documents/document_detail_screen.dart';
import '../screens/documents/documents_screen.dart';
import '../screens/documents/upload_document_screen.dart';
import '../screens/help/help_screen.dart';
import '../screens/home/staff_home_screen.dart';
import '../screens/notifications/notifications_screen.dart';
import '../screens/pipeline/staff_pipeline_screen.dart';
import '../screens/profile/profile_screen.dart';
import '../screens/salary/salary_screens.dart';
import '../screens/salary/tax_declaration_screen.dart';
import '../screens/settings/settings_screens.dart';
import '../screens/training/training_screens.dart';
import '../screens/video_certification/video_certification_screens.dart';
import 'staff_routes.dart';
import 'staff_shell_screen.dart';

/// Staff module GoRouter route definitions.
List<RouteBase> get staffRoutes => [
      GoRoute(
        path: StaffRoutes.dashboard,
        redirect: (_, __) => StaffRoutes.home,
      ),
      GoRoute(
        path: StaffRoutes.root,
        redirect: (_, __) => StaffRoutes.home,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            StaffShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StaffRoutes.home,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const StaffHomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StaffRoutes.pipeline,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const StaffPipelineScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StaffRoutes.attendance,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const StaffAttendanceHubScreen(),
                ),
              ),
            ],
          ),

          StatefulShellBranch(
            routes: [
              GoRoute(
                path: StaffRoutes.profile,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const StaffProfileScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Home sub-routes
      slideRoute(
        path: StaffRoutes.tasksToday,
        builder: (_, __) => const StaffTodaysTasksScreen(),
      ),
      slideRoute(
        path: StaffRoutes.profileCompletion,
        builder: (_, __) => const StaffProfileCompletionScreen(),
      ),

      // Pipeline
      GoRoute(
        path: '/staff/pipeline/stage/:id',
        builder: (context, state) => StaffPipelineStageScreen(
          stageId: state.pathParameters['id']!,
        ),
      ),

      // Documents
      GoRoute(
        path: StaffRoutes.documents,
        builder: (_, __) => const StaffDocumentsScreen(),
        routes: [
          GoRoute(
            path: 'upload',
            builder: (_, __) => const StaffUploadDocumentScreen(),
          ),
          GoRoute(
            path: ':id',
            builder: (context, state) => StaffDocumentDetailScreen(
              documentId: state.pathParameters['id']!,
            ),
            routes: [
              GoRoute(
                path: 'reupload',
                builder: (context, state) => StaffDocumentReuploadScreen(
                  documentId: state.pathParameters['id']!,
                ),
              ),
            ],
          ),
        ],
      ),

      // Training
      GoRoute(
        path: StaffRoutes.training,
        builder: (_, __) => const StaffTrainingScreen(),
        routes: [
          GoRoute(
            path: 'categories',
            builder: (_, __) => const StaffTrainingCategoriesScreen(),
          ),
          GoRoute(
            path: 'video/:id',
            builder: (context, state) => StaffVideoPlayerScreen(
              courseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'pdf/:id',
            builder: (context, state) => StaffPdfReaderScreen(
              courseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'quiz/:id',
            builder: (context, state) => StaffQuizScreen(
              courseId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'result/:id',
            builder: (context, state) => StaffTrainingResultScreen(
              courseId: state.pathParameters['id']!,
              result: state.extra as QuizResult?,
            ),
          ),
          GoRoute(
            path: 'certificate/:id',
            builder: (context, state) => StaffCertificateScreen(
              courseId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Video certification
      GoRoute(
        path: StaffRoutes.videoCertification,
        builder: (_, __) => const StaffVideoCertificationScreen(),
        routes: [
          GoRoute(
            path: 'record',
            builder: (context, state) => StaffRecordVideoScreen(
              promptId: state.uri.queryParameters['promptId'],
              title: state.uri.queryParameters['title'],
            ),
          ),
          GoRoute(
            path: 'preview',
            builder: (context, state) => StaffVideoPreviewScreen(
              promptId: state.uri.queryParameters['promptId'],
            ),
          ),
          GoRoute(
            path: 'upload',
            builder: (context, state) => StaffVideoUploadScreen(
              promptId: state.uri.queryParameters['promptId'],
            ),
          ),
          GoRoute(
            path: 'status/:id',
            builder: (context, state) => StaffVideoApprovalScreen(
              promptId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Agreement
      GoRoute(
        path: StaffRoutes.agreement,
        builder: (_, __) => const AgreementScreen(),
        routes: [
          GoRoute(
            path: 'signature',
            builder: (_, __) => const DigitalSignatureScreen(),
          ),
          GoRoute(
            path: 'status',
            builder: (_, __) => const AgreementStatusScreen(),
          ),
        ],
      ),

      // Deployment
      GoRoute(
        path: StaffRoutes.deployment,
        builder: (_, __) => const DeploymentScreen(),
      ),

      // Attendance detail
      GoRoute(
        path: StaffRoutes.checkIn,
        builder: (_, __) => const StaffCheckInScreen(),
      ),
      GoRoute(
        path: StaffRoutes.checkOut,
        builder: (_, __) => const StaffCheckOutScreen(),
      ),
      GoRoute(
        path: StaffRoutes.attendanceHistory,
        builder: (_, __) => const StaffAttendanceHistoryScreen(),
      ),
      GoRoute(
        path: StaffRoutes.monthlyAttendance,
        builder: (_, __) => const StaffMonthlyAttendanceScreen(),
      ),

      // Salary
      GoRoute(
        path: StaffRoutes.salary,
        builder: (_, __) => const StaffSalaryScreen(),
        routes: [
          GoRoute(
            path: 'payslip/:id',
            builder: (context, state) => StaffPayslipScreen(
              payslipId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'history',
            builder: (_, __) => const StaffSalaryHistoryScreen(),
          ),
          GoRoute(
            path: 'bank',
            builder: (_, __) => const StaffBankDetailsScreen(),
          ),
          GoRoute(
            path: 'tax',
            builder: (_, __) => const StaffTaxDeclarationScreen(),
          ),
        ],
      ),

      // Settings & help
      GoRoute(
        path: StaffRoutes.settings,
        builder: (_, __) => const StaffSettingsScreen(),
        routes: [
          GoRoute(
            path: 'language',
            builder: (_, __) => const StaffLanguageSettingsScreen(),
          ),
          GoRoute(
            path: 'theme',
            builder: (_, __) => const StaffThemeSettingsScreen(),
          ),
          GoRoute(
            path: 'biometric',
            builder: (_, __) => const StaffBiometricSettingsScreen(),
          ),
          GoRoute(
            path: 'password',
            builder: (_, __) => const StaffChangePasswordScreen(),
          ),
        ],
      ),
      GoRoute(
        path: StaffRoutes.help,
        builder: (_, __) => const StaffHelpScreen(),
      ),
    ];
