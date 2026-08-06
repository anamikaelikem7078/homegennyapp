import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

/// Notifications tab.
class ClientNotificationsTabScreen extends ConsumerWidget {
  const ClientNotificationsTabScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notifications = ref.watch(clientNotificationsProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        
        toolbarHeight: 0,

        // We will build a custom header in the body
      ),
      body: notifications.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: Color(0xFF1A56FF))),
        error: (_, __) => Center(child: Text('Error loading notifications')),
        data: (list) {
          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              // Header
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  IconButton(
                    icon: Icon(Icons.arrow_back_ios_new_rounded, color: context.colors.onSurface),
                    onPressed: () => context.pop(),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    splashRadius: 24,
                  ),
                  const SizedBox(width: 16),
                  Text(
                    'Notifications',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              SizedBox(height: 8),
              Text(
                "Keep track of your home's heartbeat.",
                style: GoogleFonts.inter(
                  fontSize: 14,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              SizedBox(height: 24),

              // Weekly Summary Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(16),
                  gradient: const LinearGradient(
                    colors: [Color(0xFFBCC6CC), Color(0xFF98A4AB)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.1),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'LIVE UPDATES',
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 1.5,
                        color: context.theme.cardColor.withOpacity(0.8),
                      ),
                    ),
                    SizedBox(height: 4),
                    Text(
                      'Your Weekly Summary',
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 24,
                        color: context.theme.cardColor,
                      ),
                    ),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Notification List
              ...list.map((n) {
                return _NotificationCard(
                  title: n.title,
                  message: n.message,
                  time: n.time,
                  type: n.type,
                  onTap: () {
                    if (n.type == 'payment') {
                      context.push(ClientRoutes.pendingPayment);
                    } else if (n.type == 'attendance') {
                      context.push(ClientRoutes.attendanceToday);
                    }
                  },
                );
              }),

              // Bottom spacing for nav bar
              SizedBox(height: 100),
            ],
          );
        },
      ),
    );
  }
}

class _NotificationCard extends StatelessWidget {
  final String title;
  final String message;
  final String time;
  final String type;
  final VoidCallback onTap;

  const _NotificationCard({
    required this.title,
    required this.message,
    required this.time,
    required this.type,
    required this.onTap,
  });

  IconData _getIcon() {
    switch (type) {
      case 'payment':
        return Icons.payments_outlined;
      case 'attendance':
        return Icons.door_front_door_outlined;
      case 'service':
        return Icons.calendar_today_outlined;
      default:
        return Icons.notifications_none_outlined;
    }
  }

  Color _getIconBgColor() {
    switch (type) {
      case 'payment':
        return const Color(0xFFFFF0F0); // Light red
      case 'attendance':
        return const Color(0xFFF0F4FF); // Light blue
      case 'service':
        return const Color(0xFFF5F5F0); // Light warm gray
      default:
        return const Color(0xFFF5F5F5);
    }
  }

  Color _getIconColor() {
    switch (type) {
      case 'payment':
        return const Color(0xFFE53935);
      case 'attendance':
        return const Color(0xFF1A56FF);
      case 'service':
        return const Color(0xFF424242);
      default:
        return Colors.black54;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.theme.dividerColor),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.02),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: _getIconBgColor(),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(_getIcon(), color: _getIconColor(), size: 20),
              ),
              SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          title,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurface,
                          ),
                        ),
                        Text(
                          time,
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            color: context.colors.onSurfaceVariant,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 4),
                    Text(
                      message,
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.colors.onSurface,
                        height: 1.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (type == 'payment') ...[
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 56), // align with text
              child: Wrap(
                spacing: 12,
                runSpacing: 8,
                children: [
                  ElevatedButton(
                    onPressed: () => context.push(ClientRoutes.paymentGateway),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      'Pay Now',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  OutlinedButton(
                    onPressed: () => context.push(ClientRoutes.invoice),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: const BorderSide(color: Color(0xFFE5E7EB)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                      ),
                      padding: const EdgeInsets.symmetric(
                        horizontal: 24,
                        vertical: 0,
                      ),
                      minimumSize: const Size(0, 36),
                    ),
                    child: Text(
                      'View Invoice',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
          if (type == 'service') ...[
            SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.only(left: 56), // align with text
              child: GestureDetector(
                onTap: () => context.showDsSnackBar(
                  'Added to Calendar',
                  type: DsSnackBarType.success,
                ),
                child: Text(
                  'Add to Calendar',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A56FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
