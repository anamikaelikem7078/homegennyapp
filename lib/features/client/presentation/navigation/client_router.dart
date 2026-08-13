import 'package:go_router/go_router.dart';

import '../../../../core/router/page_transitions.dart';
import '../../../../core/router/route_helpers.dart';
import '../../../../core/presentation/screens/app_settings_screens.dart';

import '../screens/attendance/client_attendance_screens.dart';
import '../screens/complaint/client_complaint_screens.dart';
import '../screens/home/client_home_screens.dart';
import '../screens/notifications/client_notifications_screens.dart';
import '../screens/payments/client_payment_screens.dart';
import '../screens/profile/client_profile_screens.dart';
import '../screens/replacement/client_replacement_screens.dart';
import '../screens/staff/client_staff_screens.dart';
import 'client_routes.dart';
import 'client_shell_screen.dart';

/// Client module GoRouter route definitions.
List<RouteBase> get clientRoutes => [
      GoRoute(
        path: ClientRoutes.root,
        redirect: (_, __) => ClientRoutes.dashboard,
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) =>
            ClientShellScreen(navigationShell: navigationShell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ClientRoutes.dashboard,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const ClientHomeScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ClientRoutes.staff,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const ClientStaffTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ClientRoutes.payments,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const ClientPaymentsTabScreen(),
                ),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ClientRoutes.settings,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const ClientSettingsScreen(),
                ),
                routes: [
                  GoRoute(
                    path: 'language',
                    pageBuilder: (_, __) => dsSlidePage(
                      child: const AppLanguageSettingsScreen(useGradient: true),
                    ),
                  ),
                  GoRoute(
                    path: 'theme',
                    pageBuilder: (_, __) => dsSlidePage(
                      child: const AppThemeSettingsScreen(useGradient: true),
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: ClientRoutes.profile,
                pageBuilder: (context, state) => dsNoTransitionPage(
                  child: const ClientProfileTabScreen(),
                ),
              ),
            ],
          ),
        ],
      ),

      // Dashboard sub-routes
      GoRoute(
        path: ClientRoutes.notifications,
        builder: (_, __) => const ClientNotificationsTabScreen(),
      ),
      GoRoute(
        path: ClientRoutes.assignedStaff,
        builder: (_, __) => const ClientAssignedStaffScreen(),
      ),
      GoRoute(
        path: ClientRoutes.attendanceSummary,
        builder: (_, __) => const ClientAttendanceSummaryScreen(),
      ),
      GoRoute(
        path: ClientRoutes.pendingPayment,
        builder: (_, __) => const ClientPendingPaymentScreen(),
      ),

      // Staff detail routes
      GoRoute(
        path: '/client/staff/:id',
        builder: (context, state) => ClientStaffProfileScreen(
          staffId: state.pathParameters['id']!,
        ),
        routes: [
          GoRoute(
            path: 'experience',
            builder: (context, state) => ClientStaffExperienceScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'skills',
            builder: (context, state) => ClientStaffSkillsScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'attendance',
            builder: (context, state) => ClientStaffAttendanceScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
          GoRoute(
            path: 'performance',
            builder: (context, state) => ClientStaffPerformanceScreen(
              staffId: state.pathParameters['id']!,
            ),
          ),
        ],
      ),

      // Attendance
      GoRoute(
        path: ClientRoutes.attendanceToday,
        builder: (_, __) => const ClientTodayAttendanceScreen(),
      ),
      GoRoute(
        path: ClientRoutes.attendanceHistory,
        builder: (_, __) => const ClientAttendanceHistoryScreen(),
      ),
      GoRoute(
        path: ClientRoutes.attendanceRaiseIssue,
        builder: (_, __) => const ClientRaiseAttendanceIssueScreen(),
      ),

      // Payments
      GoRoute(
        path: ClientRoutes.invoice,
        builder: (_, __) => const ClientInvoiceScreen(),
      ),
      GoRoute(
        path: ClientRoutes.paymentHistory,
        builder: (_, __) => const ClientPaymentHistoryScreen(),
      ),
      GoRoute(
        path: ClientRoutes.paymentGateway,
        builder: (context, state) {
          final invoiceId = state.uri.queryParameters['invoiceId'] ?? '';
          final amountStr = state.uri.queryParameters['amount'] ?? '0';
          return ClientUpiPaymentScreen(
            invoiceId: invoiceId, 
            amount: double.tryParse(amountStr) ?? 0,
          );
        },
      ),
      GoRoute(
        path: '/client/payments/invoice/:id/download',
        builder: (context, state) => ClientDownloadInvoiceScreen(
          invoiceId: state.pathParameters['id']!,
        ),
      ),
      GoRoute(
        path: ClientRoutes.paymentStatus,
        builder: (_, __) => const ClientPaymentStatusScreen(),
      ),

      // Complaint
      GoRoute(
        path: ClientRoutes.complaintRaise,
        builder: (_, __) => const ClientRaiseComplaintScreen(),
      ),
      GoRoute(
        path: ClientRoutes.complaintUpload,
        builder: (_, __) => const ClientComplaintUploadScreen(),
      ),
      GoRoute(
        path: ClientRoutes.complaintHistory,
        builder: (_, __) => const ClientComplaintHistoryScreen(),
      ),

      // Replacement
      GoRoute(
        path: ClientRoutes.replacementRequest,
        builder: (_, __) => const ClientReplacementRequestScreen(),
      ),
      GoRoute(
        path: ClientRoutes.replacementStatus,
        builder: (_, __) => const ClientReplacementStatusScreen(),
      ),

      // Profile sub-routes
      GoRoute(
        path: ClientRoutes.personalDetails,
        builder: (_, __) => const ClientPersonalDetailsScreen(),
      ),
      GoRoute(
        path: ClientRoutes.address,
        builder: (_, __) => const ClientAddressScreen(),
      ),
      GoRoute(
        path: ClientRoutes.paymentDetails,
        builder: (_, __) => const ClientPaymentDetailsScreen(),
      ),
    ];
