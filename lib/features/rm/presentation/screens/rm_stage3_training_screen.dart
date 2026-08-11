import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmStage3TrainingScreen extends StatelessWidget {
  final String staffId;

  const RmStage3TrainingScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: _buildAppBar(context),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildHeader(),
            const SizedBox(height: 32),
            _buildProgressCard(),
            const SizedBox(height: 24),
            _buildModuleStack(context),
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
      title: Text(
        'Training — Ramesh K.',
        style: GoogleFonts.libreCaslonText(
          color: RmTheme.electricBlue,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
      ),
      centerTitle: true,
    );
  }

  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: RmTheme.borderSubtle,
              borderRadius: BorderRadius.circular(16),
            ),
            child: Text(
              'STAGE 3',
              style: GoogleFonts.inter(
                color: RmTheme.textPrimary,
                fontSize: 10,
                fontWeight: FontWeight.w700,
                letterSpacing: 1.0,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Training & Video Self-Certification',
          textAlign: TextAlign.center,
          style: GoogleFonts.libreCaslonText(
            color: RmTheme.textPrimary,
            fontSize: 28,
            fontWeight: FontWeight.w600,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Series-specific curriculum delivered in-branch. Culminates in the Video Self-Certification — the most legally significant document in the pipeline. SHA-256 verified on every playback. 7-year permanent retention.',
          textAlign: TextAlign.center,
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

  Widget _buildProgressCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'TRAINING CHECKLIST',
                    style: GoogleFonts.inter(
                      color: RmTheme.textPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '3 of 5 modules complete',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 14,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
              Text(
                '60%',
                style: GoogleFonts.libreCaslonText(
                  color: RmTheme.electricBlue,
                  fontSize: 28,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: const LinearProgressIndicator(
              value: 0.6,
              backgroundColor: RmTheme.borderSubtle,
              valueColor: AlwaysStoppedAnimation<Color>(RmTheme.electricBlue),
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildModuleStack(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        _buildCompletedModule('Module 1 — Road Safety', 'Completed · 4h'),
        const SizedBox(height: 12),
        _buildCompletedModule('Module 2 — Client Protocols', 'Completed · 2h'),
        const SizedBox(height: 12),
        _buildCompletedModule('Module 3 — Emergency Procedures', 'Completed · 1.5h'),
        const SizedBox(height: 12),
        _buildActiveModule(context, 'Module 4 — Conduct\n& NDA', 'In progress'),
        const SizedBox(height: 12),
        _buildLockedModule('Module 5 — Video Self-Cert', 'Locked until M4 done'),
      ],
    );
  }

  Widget _buildCompletedModule(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: const Border(left: BorderSide(color: RmTheme.emeraldGreen, width: 4)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.03),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.check_circle_outline, color: RmTheme.emeraldGreen, size: 24),
          const SizedBox(width: 16),
          Expanded(
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
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActiveModule(BuildContext context, String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.electricBlue, width: 1.5),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withOpacity(0.1),
            blurRadius: 16,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(2),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(color: RmTheme.electricBlue, width: 2),
            ),
            child: const Icon(Icons.circle, color: RmTheme.electricBlue, size: 12),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: RmTheme.electricBlue,
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: RmTheme.electricBlue,
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          ElevatedButton(
            onPressed: () {
              // Simulating progression to Video Upload / Review for demonstration
              context.push(RmRoutes.stage3VideoUpload(staffId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: RmTheme.electricBlue,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            ),
            child: Text(
              'Resume',
              style: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLockedModule(String title, String subtitle) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.offWhite,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle),
      ),
      child: Row(
        children: [
          const Icon(Icons.lock_outline, color: RmTheme.textSecondary, size: 24),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 12,
                    fontWeight: FontWeight.w400,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        border: Border(top: BorderSide(color: RmTheme.borderSubtle)),
      ),
      child: SafeArea(
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(Icons.grid_view, 'Dashboard', false, context, () => context.go(RmRoutes.dashboard)),
            _buildNavItem(Icons.view_kanban, 'Tracks', true, context, () {}), // Currently active
            _buildNavItem(Icons.chat_bubble_outline, 'Messages', false, context, () {}),
            _buildNavItem(Icons.admin_panel_settings_outlined, 'Admin', false, context, () {}),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, BuildContext context, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isActive ? RmTheme.electricBlue : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              icon,
              color: isActive ? Colors.white : RmTheme.textSecondary,
              size: 24,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.inter(
              color: isActive ? RmTheme.textPrimary : RmTheme.textSecondary,
              fontSize: 10,
              fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}
