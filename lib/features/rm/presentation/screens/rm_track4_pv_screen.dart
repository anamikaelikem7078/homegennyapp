import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmTrack4PvScreen extends StatelessWidget {
  final String staffId;

  const RmTrack4PvScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(context),
            const SizedBox(height: 32),
            _buildPvCard(context),
            const SizedBox(height: 24),
            Center(
              child: Column(
                children: [
                  Text(
                    'POLICE VERIFICATION',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 10,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'DR/SC/UC wait for CLEAR. M3X can proceed pending.',
                    style: GoogleFonts.inter(
                      color: RmTheme.textPrimary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(context),
    );
  }

  AppBar _buildAppBar(BuildContext context) {
    return AppBar(
      backgroundColor: RmTheme.offWhite,
      elevation: 0,
      leading: IconButton(
        icon: const Icon(Icons.arrow_back, color: RmTheme.textPrimary),
        onPressed: () => context.pop(),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: RmTheme.electricBlue,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(
              'S2_VERIFY',
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            'Verification Stage',
            style: RmTheme.headline(context).copyWith(fontSize: 20),
          ),
        ],
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: RmTheme.textPrimary),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: RmTheme.borderSubtle,
            borderRadius: BorderRadius.circular(4),
          ),
          child: Text(
            'STAGE 2',
            style: GoogleFonts.inter(
              color: RmTheme.textPrimary,
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Verification — 5\nParallel Tracks',
          style: GoogleFonts.libreCaslonText(
            color: RmTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'All tracks run simultaneously. Pipeline cannot advance until all mandatory tracks are complete. DR series runs all 5 tracks. SC/UC/M3X run tracks 1, 4, and 5 (partial).',
          style: GoogleFonts.inter(
            color: RmTheme.textSecondary,
            fontSize: 14,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildPvCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: RmTheme.glassmorphismShadow,
      ),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(20.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: const BoxDecoration(
                        color: Color(0xFFF3F4F6),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(Icons.arrow_back, size: 16, color: RmTheme.textPrimary),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Track 4 — Police\nVerification',
                      style: GoogleFonts.inter(
                        color: RmTheme.textPrimary,
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        height: 1.2,
                      ),
                    ),
                  ],
                ),
                Row(
                  children: [
                    const Icon(Icons.more_horiz, color: RmTheme.textPrimary),
                    const SizedBox(width: 8),
                    Text(
                      '100%',
                      style: GoogleFonts.inter(
                        color: RmTheme.textPrimary,
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: RmTheme.borderSubtle),
          Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              children: [
                _buildStepperItem(
                  'PV Application Submitted',
                  '12 Mar 2024',
                  RmTheme.emeraldGreen,
                  true,
                  true,
                ),
                _buildStepperItem(
                  'Awaiting Police Clearance',
                  'Pending — Day 8 of ~21',
                  const Color(0xFFEA580C), // Orange
                  true,
                  true,
                  isPendingText: true,
                ),
                _buildStepperItem(
                  'PV Result',
                  'Not yet received',
                  RmTheme.borderSubtle,
                  false,
                  false,
                ),
                const SizedBox(height: 24),
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: RmTheme.electricBlue.withOpacity(0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: RmTheme.electricBlue.withOpacity(0.3)),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.info_outline, color: RmTheme.electricBlue, size: 20),
                      const SizedBox(width: 12),
                      Expanded(
                        child: RichText(
                          text: TextSpan(
                            style: GoogleFonts.inter(
                              color: RmTheme.electricBlue,
                              fontSize: 12,
                              height: 1.5,
                            ),
                            children: const [
                              TextSpan(text: 'DR/SC/UC must wait for PV '),
                              TextSpan(text: 'CLEAR', style: TextStyle(fontWeight: FontWeight.bold)),
                              TextSpan(text: ' before advancing. Maid (M3X) may proceed with '),
                              TextSpan(text: 'PENDING PV.', style: TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperItem(String title, String subtitle, Color color, bool isActive, bool hasLine, {bool isPendingText = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 24,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(color: color, width: 2),
                  ),
                  child: Center(
                    child: Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: isActive ? color : Colors.transparent,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
                if (hasLine)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: const Color(0xFFE5E7EB),
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: RmTheme.textPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  if (isPendingText)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        subtitle,
                        style: GoogleFonts.inter(
                          color: color,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    )
                  else
                    Text(
                      subtitle,
                      style: GoogleFonts.inter(
                        color: RmTheme.textSecondary,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        border: const Border(top: BorderSide(color: RmTheme.borderSubtle)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.dashboard_outlined, 'Dashboard', false, onTap: () => context.pushReplacement(RmRoutes.dashboard)),
              _buildNavItem(Icons.view_kanban_outlined, 'Tracks', true),
              _buildNavItem(Icons.chat_bubble_outline, 'Messages', false),
              _buildNavItem(Icons.admin_panel_settings_outlined, 'Admin', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: isActive
            ? BoxDecoration(
                color: RmTheme.electricBlue,
                borderRadius: BorderRadius.circular(12),
              )
            : null,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: isActive ? Colors.white : RmTheme.textSecondary),
            const SizedBox(height: 4),
            Text(
              label,
              style: GoogleFonts.inter(
                color: isActive ? Colors.white : RmTheme.textSecondary,
                fontSize: 10,
                fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
