import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

import '../../../../../core/router/app_routes.dart';
import '../../../../../core/utils/communication_helper.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../widgets/staff_scaffold.dart';

/// Help and support screen.
class StaffHelpScreen extends StatelessWidget {
  const StaffHelpScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.go(StaffRoutes.home);
            }
          },
        ),
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF475569)),
            onPressed: () {},
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
        children: [
          Center(
            child: Text(
              'CONCIERGE SUPPORT',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF1A56FF),
                letterSpacing: 1.5,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'How can we assist\nyour stay?',
            textAlign: TextAlign.center,
            style: GoogleFonts.libreCaslonText(
              fontSize: 28,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Experience seamless resolution through our\ncurated support channels. Our team is\navailable 24/7 to ensure your home\nexperience is nothing short of extraordinary.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 40),
          _SupportCard(
            icon: Icons.chat_bubble_outline,
            title: 'Chat with Support',
            subtitle: 'Typical response time: Under 2\nminutes.',
            actionLabel: 'Start Dialogue',
            onTap: () => context.push(AppRoutes.chat),
          ),
          const SizedBox(height: 16),
          _SupportCard(
            icon: Icons.phone_outlined,
            title: 'Call Helpline',
            subtitle: 'Direct access to our dedicated\nlocal concierge.',
            actionLabel: 'Call +1 (800) GENNY',
            onTap: () => CommunicationHelper.makePhoneCall(
              context,
              '+18005550199',
              recipientName: 'HomeGenny Helpline',
            ),
          ),
          const SizedBox(height: 16),
          _SupportCard(
            icon: Icons.email_outlined,
            title: 'Email Support',
            subtitle: 'For detailed inquiries or\ndocumentation.',
            actionLabel: 'Send Message',
            onTap: () {},
          ),
          const SizedBox(height: 48),
          Text(
            'Frequently Asked\nQuestions',
            style: GoogleFonts.libreCaslonText(
              fontSize: 24,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
              height: 1.2,
            ),
          ),
          const SizedBox(height: 24),
          _FaqTile(
            question: 'How do I check in?',
            answer:
                'Access codes are sent 24 hours prior to\nyour arrival via the app and email. Simply\nuse the smart lock keypad located at the\nmain entrance.',
          ),
          _FaqTile(
            question: 'Can I request a late checkout?',
            answer: 'Yes, subject to availability. Extra charges may apply.',
          ),
          _FaqTile(
            question: 'How does the smart home system\nwork?',
            answer: 'Use the tablet provided in the living room.',
          ),
          _FaqTile(
            question: 'What is the policy for guest\nvisitors?',
            answer: 'Visitors are allowed until 10 PM.',
          ),
          const SizedBox(height: 40),
          // Still have questions footer
          Container(
            padding: const EdgeInsets.all(32),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(24),
            ),
            child: Column(
              children: [
                Text(
                  'Still have questions?',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.libreCaslonText(
                    fontSize: 20,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Browse our full knowledge base or\nreach out to a community manager.',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: const Color(0xFF475569),
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: ElevatedButton(
                    onPressed: () {},
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF1A56FF),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Visit Help Center',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton(
                    onPressed: () {},
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Color(0xFFCBD5E1)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: Text(
                      'Documentation',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: const Color(0xFF475569),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 80),
        ],
      ),
    );
  }
}

class _SupportCard extends StatelessWidget {
  const _SupportCard({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.actionLabel,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final String actionLabel;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xFFEEF2FF),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: const Color(0xFF1A56FF), size: 20),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: GoogleFonts.libreCaslonText(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            subtitle,
            style: GoogleFonts.inter(
              fontSize: 13,
              color: const Color(0xFF64748B),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: OutlinedButton(
              onPressed: onTap,
              style: OutlinedButton.styleFrom(
                side: const BorderSide(color: Color(0xFFC7D2FE)),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                actionLabel,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: const Color(0xFF1A56FF),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _FaqTile extends StatelessWidget {
  const _FaqTile({required this.question, required this.answer});
  final String question;
  final String answer;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: const Color(0xFFF1F5F9)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ExpansionTile(
        shape: const RoundedRectangleBorder(side: BorderSide.none),
        collapsedShape: const RoundedRectangleBorder(side: BorderSide.none),
        iconColor: const Color(0xFF64748B),
        collapsedIconColor: const Color(0xFF64748B),
        title: Text(
          question,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                answer,
                style: GoogleFonts.inter(
                  fontSize: 13,
                  color: const Color(0xFF64748B),
                  height: 1.5,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
