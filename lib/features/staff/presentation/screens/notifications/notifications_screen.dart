import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Staff notifications.
class StaffNotificationsScreen extends ConsumerWidget {
  const StaffNotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(staffNotificationsProvider);

    return DsPage(
      title: 'Notifications',
      subtitle: 'Stay updated',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffNotificationsProvider),
      body: dsAsyncBody(
        notifications,
        onRetry: () => ref.invalidate(staffNotificationsProvider),
        builder: (list) {
          final unread = list.where((n) => !n.isRead).length;
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DsGlassPill('INBOX', icon: Icons.inbox_rounded),
                        const SizedBox(height: 12),
                        Text(
                          unread == 0 ? 'All caught up' : '$unread unread',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 24,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        Text(
                          '${list.length} ${list.length == 1 ? 'notification' : 'notifications'} in total',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.8),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const DsFloatingIconTile(icon: Icons.notifications_active_rounded),
                ],
              ),
            ),
            const SizedBox(height: 16),
            if (list.isEmpty)
              const DsEmptyBlock(
                icon: Icons.notifications_off_rounded,
                color: AppColors.success,
                title: 'No notifications',
                message: 'You are all caught up!',
              )
            else
              for (var i = 0; i < list.length; i++)
                _NotificationTile(
                  title: list[i].title,
                  message: list[i].message,
                  time: list[i].time,
                  isRead: list[i].isRead,
                  icon: _iconFor(list[i].type),
                  onTap: () {
                    ref.read(staffRepositoryProvider).markNotificationRead(list[i].id);
                    ref.invalidate(staffNotificationsProvider);
                    _navigateForType(context, list[i].type, list[i].data);
                  },
                ).animate(delay: (45 * i.clamp(0, 10)).ms).fadeIn(duration: 280.ms).slideX(begin: 0.05, end: 0),
          ];
        },
      ),
    );
  }

  IconData _iconFor(String type) => switch (type) {
        'document' => Icons.folder_rounded,
        'training' => Icons.school_rounded,
        'salary' => Icons.payments_rounded,
        'agreement' => Icons.description_rounded,
        'QUIZ_RESCHEDULED' => Icons.event_repeat_rounded,
        'QUIZ_PASSED' => Icons.emoji_events_rounded,
        'QUIZ_FAILED' => Icons.quiz_rounded,
        _ => Icons.notifications_rounded,
      };

  void _navigateForType(BuildContext context, String type, Map<String, dynamic>? data) {
    switch (type) {
      case 'document':
        context.push(StaffRoutes.documents);
      case 'training':
      case 'QUIZ_RESCHEDULED':
        context.push(StaffRoutes.training);
      case 'salary':
        context.push(StaffRoutes.salary);
      case 'agreement':
        context.push(StaffRoutes.agreement);
      case 'QUIZ_PASSED':
      case 'QUIZ_FAILED':
        final attemptId = data?['attemptId'] as String?;
        if (attemptId != null) {
          context.push(StaffRoutes.trainingResult(attemptId));
        } else {
          context.push(StaffRoutes.training);
        }
    }
  }
}

class _NotificationTile extends StatelessWidget {
  const _NotificationTile({
    required this.title,
    required this.message,
    required this.time,
    required this.isRead,
    required this.icon,
    required this.onTap,
  });

  final String title;
  final String message;
  final String time;
  final bool isRead;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isRead ? Colors.white : AppColors.primaryContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(
              radius: 20,
              color: isRead ? Colors.white : AppColors.primaryContainer.withValues(alpha: 0.5),
              border: isRead ? null : AppColors.primary.withValues(alpha: 0.25),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                DsIconTile(icon, size: 42),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              title,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14.5,
                                fontWeight: isRead ? FontWeight.w700 : FontWeight.w800,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          if (!isRead)
                            Container(
                              width: 8,
                              height: 8,
                              decoration: const BoxDecoration(color: AppColors.secondary, shape: BoxShape.circle),
                            )
                                .animate(onPlay: (c) => c.repeat(reverse: true))
                                .scaleXY(begin: 0.8, end: 1.3, duration: 800.ms),
                        ],
                      ),
                      const SizedBox(height: 3),
                      Text(
                        message,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, height: 1.45, color: const Color(0xFF374151)),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        time,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: AppColors.lightTextSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
