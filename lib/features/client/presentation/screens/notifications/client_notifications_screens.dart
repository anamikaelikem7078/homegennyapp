import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

/// Notifications screen.
class ClientNotificationsTabScreen extends ConsumerStatefulWidget {
  const ClientNotificationsTabScreen({super.key});

  @override
  ConsumerState<ClientNotificationsTabScreen> createState() => _ClientNotificationsTabScreenState();
}

const _filters = [
  ('All', null),
  ('Payments', 'payment'),
  ('Attendance', 'attendance'),
  ('Service', 'service'),
];

(IconData, Color) _typeStyle(String type) => switch (type) {
      'payment' => (Icons.payments_rounded, AppColors.error),
      'attendance' => (Icons.door_front_door_rounded, AppColors.primary),
      'service' => (Icons.event_rounded, AppColors.secondary),
      _ => (Icons.notifications_rounded, AppColors.iconAccent),
    };

class _ClientNotificationsTabScreenState extends ConsumerState<ClientNotificationsTabScreen> {
  String? _filter;

  @override
  Widget build(BuildContext context) {
    final notifications = ref.watch(clientNotificationsProvider);

    return DsPage(
      title: 'Notifications',
      subtitle: 'Keep track of your home\'s heartbeat',
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(clientNotificationsProvider),
      body: dsAsyncBody(
        notifications,
        onRetry: () => ref.invalidate(clientNotificationsProvider),
        builder: (list) {
          final payments = list.where((n) => n.type == 'payment').length;
          final shown = _filter == null ? list : list.where((n) => n.type == _filter).toList();
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DsGlassPill('LIVE UPDATES', icon: Icons.bolt_rounded),
                        const SizedBox(height: 12),
                        Text(
                          '${list.length} ${list.length == 1 ? 'update' : 'updates'}',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.6,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          payments > 0
                              ? '$payments payment ${payments == 1 ? 'needs' : 'need'} your attention'
                              : 'You\'re all caught up',
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
            const SizedBox(height: 18),
            SizedBox(
              height: 42,
              child: ListView.separated(
                scrollDirection: Axis.horizontal,
                clipBehavior: Clip.none,
                itemCount: _filters.length,
                separatorBuilder: (_, _) => const SizedBox(width: 8),
                itemBuilder: (context, i) => DsChoiceChip(
                  label: _filters[i].$1,
                  selected: _filter == _filters[i].$2,
                  onTap: () => setState(() => _filter = _filters[i].$2),
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (shown.isEmpty)
              const DsEmptyBlock(
                icon: Icons.notifications_off_rounded,
                title: 'Nothing here',
                message: 'No notifications in this category yet.',
              )
            else
              for (var i = 0; i < shown.length; i++)
                _NotificationCard(
                  key: ValueKey('${shown[i].title}-$i'),
                  title: shown[i].title,
                  message: shown[i].message,
                  time: shown[i].time,
                  type: shown[i].type,
                  onTap: () {
                    final requestId = shown[i].payload['request_id'];
                    // "Booking confirmed" (STAFF_REQUEST_CONFIRMED) and the
                    // other staff-request updates open the request.
                    if ((shown[i].template ?? '').startsWith('STAFF_REQUEST') && requestId is String) {
                      context.push(ClientRoutes.staffRequestDetail(requestId));
                    } else if (shown[i].type == 'payment') {
                      context.push(ClientRoutes.pendingPayment);
                    } else if (shown[i].type == 'attendance') {
                      context.push(ClientRoutes.attendanceToday);
                    }
                  },
                ).animate(delay: (50 * i.clamp(0, 8)).ms).fadeIn(duration: 300.ms).slideX(begin: 0.05, end: 0),
          ];
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  const _NotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.onTap,
  });

  final String title;
  final String message;
  final String time;
  final String type;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final (icon, color) = _typeStyle(type);
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap,
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsIconTile(icon, color: color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                child: Text(
                                  title,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14.5,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.lightTextPrimary,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                time,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.lightTextSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(
                            message,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 13,
                              height: 1.45,
                              color: const Color(0xFF374151),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                if (type == 'payment') ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        _SmallButton(
                          label: 'Pay now',
                          filled: true,
                          onTap: () => context.push(ClientRoutes.paymentGateway),
                        ),
                        _SmallButton(
                          label: 'View invoice',
                          onTap: () => context.push(ClientRoutes.invoice),
                        ),
                      ],
                    ),
                  ),
                ],
                if (type == 'service') ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding: const EdgeInsets.only(left: 56),
                    child: _SmallButton(
                      label: 'Add to calendar',
                      icon: Icons.event_available_rounded,
                      onTap: () => context.showDsSnackBar('Added to calendar', type: DsSnackBarType.success),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _SmallButton extends StatelessWidget {
  const _SmallButton({required this.label, required this.onTap, this.filled = false, this.icon});
  final String label;
  final VoidCallback onTap;
  final bool filled;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: filled ? AppColors.primary : AppColors.primary.withValues(alpha: 0.08),
      shape: const StadiumBorder(),
      child: InkWell(
        customBorder: const StadiumBorder(),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 9),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 15, color: filled ? Colors.white : AppColors.iconAccent),
                const SizedBox(width: 6),
              ],
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12.5,
                  fontWeight: FontWeight.w800,
                  color: filled ? Colors.white : AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
