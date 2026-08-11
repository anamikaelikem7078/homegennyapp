import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmStage4A3Screen extends StatelessWidget {
  final String staffId;

  const RmStage4A3Screen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
        child: Column(
          children: [
            _buildHeader(),
            const SizedBox(height: 48),
            _buildAcknowledgementList(),
            const SizedBox(height: 48),
            _buildActions(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(context),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        Text(
          'CLIENT INDEMNITY',
          style: GoogleFonts.inter(
            color: const Color(0xFF4B5563),
            fontSize: 11,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'BY SIGNING, YOU\nACKNOWLEDGE:',
          textAlign: TextAlign.center,
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF111827),
            fontSize: 32,
            fontWeight: FontWeight.w500,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 24),
        Container(
          width: 48,
          height: 1,
          color: const Color(0xFFD1D5DB),
        ),
      ],
    );
  }

  Widget _buildAcknowledgementList() {
    return Column(
      children: [
        _buildAckItem(
          'Inherent Risks Assumed',
          'I understand and agree that the services provided involve inherent risks, including but not limited to, physical injury or property damage. I voluntarily assume all such risks associated with participation.',
        ),
        const SizedBox(height: 32),
        _buildAckItem(
          'Release of Liability',
          'I hereby release, waive, discharge, and covenant not to sue the provider, their officers, agents, or employees from liability for any and all claims resulting in personal injury, accidents, or illnesses.',
        ),
        const SizedBox(height: 32),
        _buildAckItem(
          'Indemnification',
          'I agree to indemnify and hold harmless the provider from any loss, liability, damage, or costs, including court costs and attorneys\' fees, that they may incur due to my participation.',
        ),
        const SizedBox(height: 32),
        _buildAckItem(
          'Medical Authorization',
          'In the event of an emergency, I authorize the provider to secure medical treatment on my behalf, and I assume full responsibility for all related expenses.',
        ),
      ],
    );
  }

  Widget _buildAckItem(String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: const Color(0xFF22C55E).withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: const Icon(Icons.check_circle_outline, color: Color(0xFF15803D), size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: const Color(0xFF111827),
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: const Color(0xFF4B5563),
                  fontSize: 13,
                  height: 1.6,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildActions(BuildContext context) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          child: ElevatedButton.icon(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Indemnity Agreement Signed')),
              );
              context.go(RmRoutes.stage4Complete(staffId));
            },
            icon: const Icon(Icons.draw_outlined, size: 20),
            label: Text(
              'I Acknowledge & Sign',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF15803D), // Forest green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
              elevation: 4,
              shadowColor: const Color(0xFF15803D).withOpacity(0.4),
            ),
          ),
        ),
        const SizedBox(height: 24),
        TextButton(
          onPressed: () => context.pop(),
          child: Text(
            'I Do Not Agree',
            style: GoogleFonts.inter(
              color: const Color(0xFFB91C1C), // Red
              fontWeight: FontWeight.w600,
              fontSize: 13,
              letterSpacing: 0.5,
            ),
          ),
        ),
      ],
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
