import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../widgets/rm_bottom_navigation.dart';

class RmAlertsScreen extends ConsumerWidget {
  const RmAlertsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Mock notifications list
    final alerts = [
      {
        'type': 'warning',
        'title': 'Trial Ending Tomorrow',
        'message': 'Preeti K. (Maid) completes 7-day trial tomorrow at the Patel household. Action required.',
        'time': '2 hours ago',
      },
      {
        'type': 'danger',
        'title': 'Document Rejected',
        'message': 'Aadhaar verification failed for new candidate Suresh M. Please follow up.',
        'time': '4 hours ago',
      },
      {
        'type': 'info',
        'title': 'Stage 3 Training Complete',
        'message': 'Rahul S. has completed all Stage 3 training modules.',
        'time': '5 hours ago',
      },
      {
        'type': 'success',
        'title': 'First Payment Received',
        'message': 'Client Sharma Household processed their first deployment payment.',
        'time': '1 day ago',
      },
      {
        'type': 'warning',
        'title': 'Overdue EOR Signature',
        'message': 'The A1 Employer of Record agreement for Amit R. is 2 days overdue.',
        'time': '1 day ago',
      },
    ];

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        title: Text('Alerts & Notifications', style: RmTheme.headline(context).copyWith(fontSize: 20)),
        backgroundColor: RmTheme.cardSurface,
        elevation: 0,
        actions: [
          TextButton(
            onPressed: () {},
            child: Text(
              'Mark All Read',
              style: GoogleFonts.inter(
                color: RmTheme.electricBlue,
                fontWeight: FontWeight.w600,
                fontSize: 13,
              ),
            ),
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: alerts.length,
        itemBuilder: (context, index) {
          return _buildAlertCard(alerts[index]);
        },
      ),
      bottomNavigationBar: const RmBottomNavigation(currentIndex: 3),
    );
  }

  Widget _buildAlertCard(Map<String, String> alert) {
    Color iconColor;
    Color bgColor;
    IconData icon;

    switch (alert['type']) {
      case 'danger':
        iconColor = RmTheme.crimsonDanger;
        bgColor = RmTheme.crimsonDanger.withOpacity(0.1);
        icon = Icons.error_outline;
        break;
      case 'success':
        iconColor = RmTheme.emeraldGreen;
        bgColor = RmTheme.emeraldGreen.withOpacity(0.1);
        icon = Icons.check_circle_outline;
        break;
      case 'info':
        iconColor = RmTheme.electricBlue;
        bgColor = RmTheme.electricBlue.withOpacity(0.1);
        icon = Icons.info_outline;
        break;
      case 'warning':
      default:
        iconColor = RmTheme.amberWarning;
        bgColor = RmTheme.amberWarning.withOpacity(0.1);
        icon = Icons.warning_amber_rounded;
        break;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: RmTheme.borderSubtle),
        boxShadow: const [
          BoxShadow(
            color: Color(0x05000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: bgColor,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: iconColor, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(
                        alert['title']!,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          fontSize: 15,
                          color: RmTheme.textPrimary,
                        ),
                      ),
                    ),
                    Text(
                      alert['time']!,
                      style: GoogleFonts.inter(
                        fontSize: 11,
                        color: RmTheme.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  alert['message']!,
                  style: GoogleFonts.inter(
                    fontSize: 13,
                    color: RmTheme.textSecondary,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
