import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rm_providers.dart';

class RmStage4HubScreen extends ConsumerWidget {
  final String staffId;

  const RmStage4HubScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffDetailProvider(staffId));
    final staffName = staff?.name ?? 'Unknown Staff';

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      extendBody: true, // For floating bottom nav
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A56FF)),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Training — $staffName',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Stack(
        children: [
          // Background glows
          Positioned(
            top: -100,
            right: -100,
            child: Container(
              width: 300,
              height: 300,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A56FF).withOpacity(0.05),
              ),
            ),
          ),
          Positioned(
            bottom: -50,
            left: -100,
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A56FF).withOpacity(0.03),
              ),
            ),
          ),
          // Main content
          SingleChildScrollView(
            padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeaderCard(),
                const SizedBox(height: 24),
                _buildInstrumentStack(context, staffName),
                const SizedBox(height: 32),
                _buildPrimaryCTA(context),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: _buildFloatingBottomNav(context),
    );
  }

  Widget _buildCard({required Widget child, Color? leftBorderColor, Color color = Colors.white}) {
    return Container(
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000), // ~0.04 alpha
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (leftBorderColor != null)
              Container(width: 4, color: leftBorderColor),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20),
                child: child,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard() {
    return _buildCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F4F6),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'CURRENT STAGE',
              style: GoogleFonts.inter(
                color: const Color(0xFF374151),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'S4 - AGREEMENTS STAGE',
            style: GoogleFonts.libreCaslonText(
              color: const Color(0xFF111827),
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Client requires 3 finalized documents to proceed to boarding.',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 14,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 18, color: Color(0xFF111827)),
              const SizedBox(width: 8),
              Text(
                'Due: Oct 24, 2023',
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildInstrumentStack(BuildContext context, String staffName) {
    return Column(
      children: [
        _buildA1SignedCard(context, staffName),
        const SizedBox(height: 16),
        _buildA2PendingCard(context),
        const SizedBox(height: 16),
        _buildA3LockedCard(context),
      ],
    );
  }

  Widget _buildA1SignedCard(BuildContext context, String staffName) {
    return GestureDetector(
      onTap: () => context.push(RmRoutes.stage4A1(staffId)),
      child: _buildCard(
        leftBorderColor: const Color(0xFF22C55E),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.check_circle_outline, color: Color(0xFF22C55E), size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A1 - EOR\nEmployment',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Signed on Oct 20\nby $staffName',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: const Color(0xFF22C55E).withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'SIGNED',
                style: GoogleFonts.inter(
                  color: const Color(0xFF22C55E),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(width: 12),
            const Icon(Icons.visibility_outlined, color: Color(0xFF111827), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildA2PendingCard(BuildContext context) {
    return GestureDetector(
      onTap: () => context.push(RmRoutes.stage4A2(staffId)),
      child: _buildCard(
        leftBorderColor: const Color(0xFF1A56FF),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56FF),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.assignment_outlined, color: Colors.white, size: 24),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'A2 - Scope of\nWork',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Sent Oct 21.\nAwaiting client\nsignature.',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 12,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: const Color(0xFF1A56FF).withOpacity(0.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'PENDING\nCLIENT',
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  color: const Color(0xFF1A56FF),
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                  height: 1.2,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.more_vert, color: Color(0xFF6B7280), size: 22),
          ],
        ),
      ),
    );
  }

  Widget _buildA3LockedCard(BuildContext context) {
    return _buildCard(
      color: const Color(0xFFF9FAFB),
      leftBorderColor: const Color(0xFFE5E7EB),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(Icons.lock_outline, color: Color(0xFF6B7280), size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A3 - Client Indemnity',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Unlocks after A2\ncompletion.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF6B7280),
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: const Color(0xFFE5E7EB).withOpacity(0.5),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'LOCKED',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 10,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrimaryCTA(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: () {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Reminder sent to client.')),
          );
        },
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFF1A56FF),
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 4,
          shadowColor: const Color(0xFF1A56FF).withOpacity(0.4),
        ),
        icon: const Icon(Icons.notifications_active_outlined, size: 20),
        label: Text(
          'Send Reminder to Client',
          style: GoogleFonts.inter(
            fontWeight: FontWeight.w600,
            fontSize: 14,
          ),
        ),
      ),
    );
  }

  Widget _buildFloatingBottomNav(BuildContext context) {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.grid_view, false, context, () => context.go(RmRoutes.dashboard)),
            _buildNavItem(Icons.insert_chart_outlined, true, context, () {}),
            _buildNavItem(Icons.chat_bubble_outline, false, context, () {}),
            _buildNavItem(Icons.admin_panel_settings_outlined, false, context, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isActive ? const Color(0xFF1A56FF) : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: isActive ? Colors.white : const Color(0xFF6B7280),
          size: 24,
        ),
      ),
    );
  }
}
