import 'package:go_router/go_router.dart';

import '../../../../core/router/page_transitions.dart';
import '../../../../core/router/route_helpers.dart';
import '../../../../core/presentation/screens/app_settings_screens.dart';

import '../../domain/models/attendance_approval_models.dart';
import '../screens/attendance/client_attendance_screens.dart';
import '../screens/attendance/client_confirm_days_screen.dart';
import '../screens/attendance/client_muster_roll_screen.dart';
import '../screens/attendance/client_staff_live_map_screen.dart';
import '../screens/care/client_care_screens.dart';
import '../screens/care/client_cook_screens.dart';
import '../screens/care/client_instruction_screens.dart';
import '../screens/complaint/client_complaint_screens.dart';
import '../screens/home/client_home_screens.dart';
import '../screens/notifications/client_notifications_screens.dart';
import '../screens/payments/client_payment_screens.dart';
import '../screens/profile/client_profile_screens.dart';
import '../screens/replacement/client_replacement_screens.dart';
import '../screens/staff/client_staff_screens.dart';
import '../screens/staff_request/client_staff_request_screens.dart';
import '../../../../core/onboarding/profile_gate.dart';
import '../../../../core/router/app_routes.dart';
import '../screens/profile/client_profile_wizard_screen.dart';
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
          GoRoute(
            path: 'location',
            builder: (context, state) => ClientStaffLiveMapScreen(
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
      GoRoute(
        path: ClientRoutes.confirmDays,
        builder: (_, state) => ClientConfirmDaysScreen(
          initialStatus: state.uri.queryParameters['status'] ?? ClientDayStatus.pending,
        ),
      ),
      GoRoute(
        path: ClientRoutes.musterRoll,
        builder: (_, __) => const ClientMusterRollScreen(),
      ),

      // Payments
      GoRoute(
        path: ClientRoutes.invoice,
        // ?id= opens one invoice (a month can hold several); else the latest.
        builder: (_, state) => ClientInvoiceScreen(invoiceId: state.uri.queryParameters['id']),
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
        path: ClientRoutes.complaintHistory,
        builder: (_, __) => const ClientComplaintHistoryScreen(),
      ),

      // Replacement
      GoRoute(
        path: ClientRoutes.replacementRequest,
        builder: (_, state) => ClientReplacementRequestScreen(placementId: state.uri.queryParameters['placement']),
      ),
      GoRoute(
        path: ClientRoutes.replacementStatus,
        builder: (_, __) => const ClientReplacementStatusScreen(),
      ),

      // Staff requests ('new' must come before ':id')
      GoRoute(
        path: ClientRoutes.staffRequests,
        builder: (_, __) => const ClientStaffRequestsScreen(),
      ),
      // Enabled only once the profile is complete (the server refuses
      // earlier with 403 PROFILE_INCOMPLETE).
      GoRoute(
        path: ClientRoutes.staffRequestNew,
        builder: (_, __) => const ProfileGate(
          title: 'Request staff',
          child: ClientStaffRequestFormScreen(),
        ),
      ),

      // "Complete your profile" wizard; `?step=` opens the first missing step.
      slideRoute(
        path: AppRoutes.clientCompleteProfile,
        builder: (_, state) => ClientProfileWizardScreen(
          initialStep: int.tryParse(state.uri.queryParameters['step'] ?? '') ?? 0,
        ),
      ),
      GoRoute(
        path: '${ClientRoutes.staffRequests}/:id',
        builder: (_, state) => ClientStaffRequestDetailScreen(requestId: state.pathParameters['id']!),
      ),

      // Daily care (staff name passed as extra for the header)
      GoRoute(
        path: '/client/care/:pid',
        builder: (_, state) => ClientCareScreen(
          placementId: state.pathParameters['pid']!,
          staffName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/client/care/:pid/plan',
        builder: (_, state) => ClientCarePlanScreen(placementId: state.pathParameters['pid']!),
      ),
      GoRoute(
        path: '/client/care/:pid/history',
        builder: (_, state) => ClientCareHistoryScreen(placementId: state.pathParameters['pid']!),
      ),
      GoRoute(
        path: '/client/care/:pid/menu',
        builder: (_, state) => ClientMenuScreen(
          placementId: state.pathParameters['pid']!,
          staffName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/client/care/:pid/meals',
        builder: (_, state) => ClientMealsScreen(placementId: state.pathParameters['pid']!),
      ),
      GoRoute(
        path: '/client/care/:pid/instructions',
        builder: (_, state) => ClientInstructionsScreen(
          placementId: state.pathParameters['pid']!,
          staffName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: '/client/care/:pid/instructions/new',
        builder: (_, state) => ClientNewInstructionScreen(
          placementId: state.pathParameters['pid']!,
          staffName: state.extra as String?,
        ),
      ),
      GoRoute(
        path: ClientRoutes.foodProfile,
        builder: (_, __) => const ClientFoodProfileScreen(),
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
