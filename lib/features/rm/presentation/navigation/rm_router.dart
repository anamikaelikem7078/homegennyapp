import 'package:go_router/go_router.dart';

import '../../../../core/router/page_transitions.dart';
import '../../../../core/router/route_helpers.dart';
import '../../../../core/presentation/screens/app_settings_screens.dart';

import '../../domain/models/rm_models.dart';
import '../screens/client/rm_client_screens.dart';
import '../screens/dashboard/rm_dashboard_screens.dart';
import '../screens/deployment/rm_deployment_screens.dart';
import '../screens/profile/rm_profile_screens.dart';
import '../screens/reports/rm_reports_screens.dart';
import '../screens/staff/rm_staff_screens.dart';
import '../screens/training/rm_training_screens.dart';
import '../screens/verification/rm_verification_screens.dart';
import '../screens/video/rm_video_screens.dart';
import 'rm_routes.dart';
import 'rm_shell_screen.dart';

/// RM module GoRouter route definitions.
List<RouteBase> get rmRoutes => [
      GoRoute(
        path: RmRoutes.root,
        redirect: (_, __) => RmRoutes.dashboard,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            RmShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RmRoutes.dashboard,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const RmDashboardHomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RmRoutes.staff,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const RmStaffTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RmRoutes.clients,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const RmClientsTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RmRoutes.reports,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const RmReportsTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: RmRoutes.profile,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const RmProfileTabScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Dashboard sub-routes
      GoRoute(
        path: RmRoutes.followUpsToday,
        builder: (_, __) => const RmFollowUpsTodayScreen(),
      ),
      GoRoute(
        path: RmRoutes.pendingVerification,
        builder: (_, __) => const RmPendingListScreen(
          title: 'Pending Verification',
          type: RmPendingType.verification,
        ),
      ),
      GoRoute(
        path: RmRoutes.pendingTraining,
        builder: (_, __) => const RmPendingTrainingScreen(),
      ),
      GoRoute(
        path: RmRoutes.pendingAgreement,
        builder: (_, __) => const RmPendingAgreementScreen(),
      ),
      GoRoute(
        path: RmRoutes.pendingDeployment,
        builder: (_, __) => const RmPendingDeploymentScreen(),
      ),
      GoRoute(
        path: RmRoutes.clientRequests,
        builder: (_, __) => const RmClientRequestsScreen(),
      ),

      // Staff routes
      GoRoute(
        path: RmRoutes.staffCreate,
        builder: (_, __) => const RmCreateStaffScreen(),
      ),
      GoRoute(
        path: '/rm/staff/:id',
        builder: (context, state) => RmStaffDetailScreen(
          staffId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'edit',
            builder: (context, state) => RmEditStaffScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'documents',
            builder: (context, state) => RmStaffDocumentsScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'training',
            builder: (context, state) => RmStaffTrainingScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'attendance',
            builder: (context, state) => RmStaffAttendanceScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'salary',
            builder: (context, state) => RmStaffSalaryScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Verification
      GoRoute(
        path: RmRoutes.verificationPending,
        builder: (_, __) => const RmVerificationPendingScreen(),
      ),
      GoRoute(
        path: '/rm/verification/:id',
        builder: (context, state) => RmVerificationDetailScreen(
          docId: state.pathParameters['id']!,
        ),
      ),

      // Training
      GoRoute(
        path: RmRoutes.trainingAssign,
        builder: (_, __) => const RmAssignTrainingScreen(),
      ),
      GoRoute(
        path: RmRoutes.trainingProgress,
        builder: (_, __) => const RmTrainingProgressScreen(),
      ),
      GoRoute(
        path: RmRoutes.trainingCertificates,
        builder: (_, __) => const RmCertificatesScreen(),
      ),

      // Video review
      GoRoute(
        path: RmRoutes.videosPending,
        builder: (_, __) => const RmPendingVideosScreen(),
      ),
      GoRoute(
        path: '/rm/videos/:id/watch',
        builder: (context, state) => RmWatchVideoScreen(
          videoId: state.pathParameters['id']!,
        ),
      ),

      // Client detail routes
      GoRoute(
        path: '/rm/clients/:id',
        builder: (context, state) => RmClientDetailScreen(
          clientId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'requirements',
            builder: (context, state) => RmClientRequirementsScreen(
              clientId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'assign-staff',
            builder: (context, state) => RmClientAssignStaffScreen(
              clientId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'replacement',
            builder: (context, state) => RmClientReplacementScreen(
              clientId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Deployment
      GoRoute(
        path: RmRoutes.deployment,
        builder: (_, __) => const RmDeploymentHubScreen(),
      ),
      GoRoute(
        path: RmRoutes.deploymentAssignStaff,
        builder: (_, __) => const RmDeploymentAssignStaffScreen(),
      ),
      GoRoute(
        path: RmRoutes.deploymentAssignClient,
        builder: (_, __) => const RmDeploymentAssignClientScreen(),
      ),
      GoRoute(
        path: RmRoutes.deploymentTrial,
        builder: (_, __) => const RmTrialMonitoringScreen(),
      ),
      GoRoute(
        path: RmRoutes.deploymentPermanent,
        builder: (_, __) => const RmPermanentPlacementScreen(),
      ),

      // Reports
      GoRoute(
        path: RmRoutes.reportDaily,
        builder: (_, __) => const RmReportDetailScreen(
          title: 'Daily Report',
          kind: RmReportKind.daily,
        ),
      ),
      GoRoute(
        path: RmRoutes.reportWeekly,
        builder: (_, __) => const RmReportDetailScreen(
          title: 'Weekly Report',
          kind: RmReportKind.weekly,
        ),
      ),
      GoRoute(
        path: RmRoutes.reportMonthly,
        builder: (_, __) => const RmReportDetailScreen(
          title: 'Monthly Report',
          kind: RmReportKind.monthly,
        ),
      ),
      GoRoute(
        path: RmRoutes.reportAttendance,
        builder: (_, __) => const RmReportDetailScreen(
          title: 'Attendance Report',
          kind: RmReportKind.attendance,
        ),
      ),
      GoRoute(
        path: RmRoutes.reportPipeline,
        builder: (_, __) => const RmReportDetailScreen(
          title: 'Pipeline Report',
          kind: RmReportKind.pipeline,
        ),
      ),
      GoRoute(
        path: RmRoutes.reportDeployment,
        builder: (_, __) => const RmReportDetailScreen(
          title: 'Deployment Report',
          kind: RmReportKind.deployment,
        ),
      ),

      // Notifications & settings
      GoRoute(
        path: RmRoutes.notifications,
        builder: (_, __) => const RmNotificationsScreen(),
      ),
      GoRoute(
        path: RmRoutes.settings,
        pageBuilder: (_, s) => dsSlidePage(child: const RmSettingsScreen()),
        routes: [
          GoRoute(
            path: 'language',
            pageBuilder: (_, __) => dsSlidePage(
              child: const AppLanguageSettingsScreen(),
            ),
          ),
          GoRoute(
            path: 'theme',
            pageBuilder: (_, __) => dsSlidePage(
              child: const AppThemeSettingsScreen(),
            ),
          ),
        ],
      ),
    ];
