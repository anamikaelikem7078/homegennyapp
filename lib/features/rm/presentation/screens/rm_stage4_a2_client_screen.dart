import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rm_providers.dart';

class RmStage4A2ClientScreen extends ConsumerWidget {
  final String staffId;

  const RmStage4A2ClientScreen({super.key, required this.staffId});

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
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Review Statement of\nWork',
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF111827),
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Please review the details below before signing the agreement for $staffName\'s placement.',
              style: GoogleFonts.inter(
                color: const Color(0xFF6B7280),
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildNoticeCard(),
            const SizedBox(height: 24),
            _buildEngagementCard(staffName),
            const SizedBox(height: 48),
            _buildActionHub(context),
          ],
        ),
      ),
      bottomNavigationBar: _buildFloatingBottomNav(context),
    );
  }

  Widget _buildNoticeCard() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A56FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A56FF).withOpacity(0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: Color(0xFF1A56FF), size: 22),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'IMPORTANT NOTICE',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A56FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Please review carefully. This document is the binding reference for the duration of the engagement. By signing, you agree to the terms outlined within the full SOW document.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827).withOpacity(0.8),
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEngagementCard(String staffName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        boxShadow: const [
          BoxShadow(
            color: Color(0x0A000000),
            blurRadius: 24,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Text(
                  'Engagement\nDetails',
                  style: GoogleFonts.libreCaslonText(
                    color: const Color(0xFF111827),
                    fontSize: 24,
                    fontWeight: FontWeight.w500,
                    height: 1.2,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Text(
                  'DRAFT',
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
          const SizedBox(height: 24),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 24),
          _buildDetailItem('STAFF NAME', staffName),
          const SizedBox(height: 20),
          _buildDetailItem('ROLE', 'Senior DevOps Engineer'),
          const SizedBox(height: 20),
          _buildDetailItem('PLACEMENT DATE', 'October 15, 2024'),
          const SizedBox(height: 20),
          _buildDetailItem('SCHEDULE', 'Full-Time (40 hrs/week)'),
          const SizedBox(height: 32),
          TextButton.icon(
            onPressed: () {},
            icon: const Icon(Icons.description_outlined, color: Color(0xFF1A56FF), size: 18),
            label: Text(
              'View Full SOW Document (PDF)',
              style: GoogleFonts.inter(
                color: const Color(0xFF1A56FF),
                fontSize: 13,
                fontWeight: FontWeight.w600,
              ),
            ),
            style: TextButton.styleFrom(
              padding: EdgeInsets.zero,
              minimumSize: Size.zero,
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 10,
            fontWeight: FontWeight.w600,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: GoogleFonts.inter(
            color: const Color(0xFF111827),
            fontSize: 15,
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildActionHub(BuildContext context) {
    return Column(
      children: [
        Center(
          child: TextButton(
            onPressed: () {},
            child: Text(
              'Reject Agreement',
              style: GoogleFonts.inter(
                color: const Color(0xFFDC2626), // Deep red
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => context.push(RmRoutes.stage4SowAmendment(staffId)),
            style: OutlinedButton.styleFrom(
              foregroundColor: const Color(0xFF111827),
              side: const BorderSide(color: Color(0xFFE5E7EB), width: 1.5),
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: Text(
              'Request Amendment',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ),
        ),
        const SizedBox(height: 16),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('SOW Signed!')),
              );
              context.push(RmRoutes.stage4A3(staffId));
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFF22C55E), // Emerald Green
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              elevation: 4,
              shadowColor: const Color(0xFF22C55E).withOpacity(0.4),
            ),
            child: Text(
              'I Agree - Sign SOW',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
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
