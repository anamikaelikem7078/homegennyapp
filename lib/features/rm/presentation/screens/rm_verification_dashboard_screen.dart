import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rm_providers.dart';

class RmVerificationDashboardScreen extends ConsumerWidget {
  final String staffId;

  const RmVerificationDashboardScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffDetailProvider(staffId));
    final staffName = staff?.name ?? 'Unknown Staff';
    final initials = staffName.isNotEmpty ? staffName.substring(0, 2).toUpperCase() : '??';
    final staffCode = staff?.staffCode ?? 'N/A';

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
            _buildProfileCard(context, staffName, initials, staffCode),
            const SizedBox(height: 32),
            _buildTrackCard(context, 'Track 1', 'Aadhaar eKYC', Icons.fingerprint, 'VERIFIED', RmTheme.emeraldGreen, () => context.push(RmRoutes.track1(staffId))),
            const SizedBox(height: 16),
            _buildTrackCard(context, 'Track 2', 'DL Verification', Icons.badge_outlined, 'VERIFIED', RmTheme.emeraldGreen, () => context.push(RmRoutes.track2(staffId))),
            const SizedBox(height: 16),
            _buildTrackCard(context, 'Track 3', 'eChallan Check', Icons.receipt_long_outlined, 'PENDING ACTION', RmTheme.amberWarning, () => context.push(RmRoutes.track3(staffId))),
            const SizedBox(height: 16),
            _buildTrackCard(context, 'Track 4', 'Police Verification', Icons.local_police_outlined, 'WAITING', RmTheme.textSecondary, () => context.push(RmRoutes.track4(staffId))),
            const SizedBox(height: 16),
            _buildTrackCard(context, 'Track 5', 'Medical / Sobriety', Icons.medical_services_outlined, 'CLEARED', RmTheme.emeraldGreen, () => context.push(RmRoutes.track5(staffId))),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              height: 56,
              child: ElevatedButton(
                onPressed: () => context.push(RmRoutes.stage3Training(staffId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RmTheme.electricBlue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  'PROCEED TO STAGE 3',
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 0.5,
                    color: Colors.white,
                  ),
                ),
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
      title: Text(
        'Verification Stage',
        style: RmTheme.headline(context).copyWith(fontSize: 20),
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
            fontSize: 15,
            fontWeight: FontWeight.w400,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildProfileCard(BuildContext context, String staffName, String initials, String staffCode) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RmTheme.sophisticatedShadow,
        border: Border.all(color: RmTheme.borderSubtle.withOpacity(0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  color: RmTheme.electricBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                alignment: Alignment.center,
                child: Text(
                  initials,
                  style: GoogleFonts.libreCaslonText(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      staffName,
                      style: GoogleFonts.libreCaslonText(
                        color: RmTheme.textPrimary,
                        fontSize: 22,
                        fontWeight: FontWeight.w600,
                        height: 1.1,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'ID: $staffCode',
                      style: GoogleFonts.inter(
                        color: RmTheme.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  decoration: BoxDecoration(
                    color: RmTheme.offWhite,
                    borderRadius: BorderRadius.circular(4),
                    border: Border.all(color: RmTheme.borderSubtle),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.sensors, size: 16, color: RmTheme.electricBlue),
                      const SizedBox(width: 8),
                      Text(
                        'Status: Live',
                        style: GoogleFonts.inter(
                          color: RmTheme.textPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: ElevatedButton(
                  onPressed: () {},
                  style: ElevatedButton.styleFrom(
                    backgroundColor: RmTheme.electricBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(4),
                    ),
                  ),
                  child: Text(
                    'Review Case',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildTrackCard(BuildContext context, String eyebrow, String title, IconData icon, String status, Color statusColor, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: RmTheme.borderSubtle),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: RmTheme.offWhite,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: RmTheme.textSecondary),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.libreCaslonText(
                      color: RmTheme.textPrimary,
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: statusColor.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Row(
                          children: [
                            if (status == 'VERIFIED' || status == 'CLEARED')
                              Icon(Icons.check_circle_outline, size: 12, color: statusColor)
                            else if (status == 'WAITING')
                              Icon(Icons.access_time, size: 12, color: statusColor)
                            else
                              Icon(Icons.warning_amber_rounded, size: 12, color: statusColor),
                            const SizedBox(width: 4),
                            Text(
                              status,
                              style: GoogleFonts.inter(
                                color: statusColor,
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: RmTheme.borderSubtle),
          ],
        ),
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
