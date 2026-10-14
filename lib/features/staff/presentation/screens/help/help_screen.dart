import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';

/// Help and support screen.
class StaffHelpScreen extends StatelessWidget {
  const StaffHelpScreen({super.key});

  static const _faqs = [
    (Icons.login_rounded, 'How do I check in?',
        'Open the Attendance tab and tap Check in when you reach the client\'s home. Your GPS location is verified automatically.'),
    (Icons.schedule_rounded, 'What if I\'m running late?',
        'Let your Relationship Manager know through chat or the helpline as early as possible.'),
    (Icons.payments_rounded, 'When is my salary paid?',
        'Salary is paid monthly after attendance is approved. You can see each payslip under Salary.'),
    (Icons.folder_rounded, 'A document was rejected — what now?',
        'Open Documents, tap the rejected document and re-upload a clear photo or PDF.'),
  ];

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: 'Help & support',
      subtitle: 'We\'re here 24/7',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const DsGlassPill('SUPPORT', icon: Icons.support_agent_rounded),
                    const SizedBox(height: 12),
                    Text(
                      'How can we help you today?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 21,
                        height: 1.2,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Chat, call or email — our team usually replies in minutes.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.45,
                        fontWeight: FontWeight.w500,
                        color: Colors.white.withValues(alpha: 0.82),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const DsFloatingIconTile(icon: Icons.headset_mic_rounded),
            ],
          ),
        ),
        const DsSection('Contact us'),
        DsAdaptiveGrid(
          children: [
            DsListCard(
              margin: EdgeInsets.zero,
              icon: Icons.chat_bubble_rounded,
              title: 'Chat with support',
              subtitle: 'Typical reply in under 2 minutes',
              onTap: () => context.push(AppRoutes.chat),
            ),
            DsListCard(
              margin: EdgeInsets.zero,
              icon: Icons.phone_rounded,
              title: 'Call helpline',
              subtitle: 'Talk to our support team directly',
              onTap: () => CommunicationHelper.makePhoneCall(
                context,
                '+18005550199',
                recipientName: 'HomeGenny Helpline',
              ),
            ),
            DsListCard(
              margin: EdgeInsets.zero,
              icon: Icons.mail_rounded,
              title: 'Email support',
              subtitle: 'For detailed questions or documents',
              onTap: () => context.showDsSnackBar('Email us at support@homegenny.com'),
            ),
          ],
        ),
        DsSection('Frequently asked', trailing: DsPill('${_faqs.length} topics')),
        for (final (icon, q, a) in _faqs) DsExpandCard(icon: icon, title: q, child: Text(a)),
        const SizedBox(height: 8),
        const DsNote(
          title: 'Still have questions?',
          text: 'Your Relationship Manager can help with anything about your placement, salary or documents.',
        ),
      ],
    );
  }
}
