import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmTrack5MedicalScreen extends StatelessWidget {
  final String staffId;

  const RmTrack5MedicalScreen({super.key, required this.staffId});

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
            _buildTrack5FocusCard(context),
            const SizedBox(height: 16),
            _buildPlaceholderCard(
              title: 'Verification Dashboard',
              subtitle: 'Dashboard Overview Placeholder',
            ),
            const SizedBox(height: 16),
            _buildPlaceholderCard(
              title: 'Track 1 — Aadhaar eKYC',
              subtitle: 'Aadhaar Status Placeholder',
            ),
            const SizedBox(height: 16),
            _buildPlaceholderCard(
              title: 'Track 2 — DL Verification',
              subtitle: 'DL Status Placeholder',
            ),
            const SizedBox(height: 16),
            _buildPlaceholderCard(
              title: 'Track 3 — eChallan',
              subtitle: 'eChallan Status Placeholder',
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
        icon: const Icon(Icons.arrow_back, color: RmTheme.electricBlue),
        onPressed: () => context.pop(),
      ),
      title: Text(
        'Verification Stage',
        style: GoogleFonts.libreCaslonText(
          color: RmTheme.textPrimary,
          fontSize: 20,
          fontWeight: FontWeight.w700,
        ),
      ),
      centerTitle: true,
      actions: [
        IconButton(
          icon: const Icon(Icons.more_vert, color: RmTheme.electricBlue),
          onPressed: () {},
        ),
      ],
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'STAGE 2',
          style: GoogleFonts.inter(
            color: RmTheme.electricBlue,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 8),
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

  Widget _buildTrack5FocusCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5)),
        boxShadow: RmTheme.glassmorphismShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Card Header
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: RmTheme.offWhite.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
              border: Border(bottom: BorderSide(color: RmTheme.borderSubtle.withOpacity(0.5))),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Track 5 — Medical / Sobriety',
                  style: GoogleFonts.inter(
                    color: RmTheme.textPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Icon(Icons.info_outline, size: 16, color: RmTheme.electricBlue),
              ],
            ),
          ),
          
          Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Badge
                Text(
                  'CHECK TYPE',
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: RmTheme.borderSubtle,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'DR SERIES',
                    style: GoogleFonts.inter(
                      color: RmTheme.textPrimary,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                
                // Results Checklist
                _buildChecklistItem(
                  title: 'Blood Alcohol Test',
                  value: '0.00 mg/100ml',
                ),
                const SizedBox(height: 16),
                _buildChecklistItem(
                  title: 'Vision Check',
                  value: '6/6 Both eyes',
                ),
                const SizedBox(height: 16),
                _buildChecklistItem(
                  title: 'Drug Screening',
                  value: 'NEGATIVE',
                ),
              ],
            ),
          ),
          
          // Success Banner
          Container(
            padding: const EdgeInsets.symmetric(vertical: 16),
            decoration: BoxDecoration(
              color: RmTheme.emeraldGreen.withOpacity(0.1),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(12)),
            ),
            alignment: Alignment.center,
            child: Text(
              'TRACK 5 CLEARED',
              style: GoogleFonts.inter(
                color: RmTheme.emeraldGreen,
                fontSize: 12,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildChecklistItem({required String title, required String value}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 4),
          width: 10,
          height: 10,
          decoration: const BoxDecoration(
            color: RmTheme.emeraldGreen,
            shape: BoxShape.circle,
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: RmTheme.textPrimary,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 2),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.inter(
                      color: RmTheme.emeraldGreen,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.check, size: 12, color: RmTheme.emeraldGreen),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildPlaceholderCard({required String title, required String subtitle}) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5)),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: RmTheme.offWhite.withOpacity(0.5),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
              border: Border(bottom: BorderSide(color: RmTheme.borderSubtle.withOpacity(0.5))),
            ),
            child: Text(
              title,
              style: GoogleFonts.inter(
                color: RmTheme.textSecondary,
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
            child: Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                color: RmTheme.textSecondary.withOpacity(0.7),
                fontSize: 14,
                fontWeight: FontWeight.w400,
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
