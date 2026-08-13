import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rm_providers.dart';

class RmStage4A2Screen extends ConsumerWidget {
  final String staffId;

  const RmStage4A2Screen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffDetailProvider(staffId));
    final staffName = staff?.name ?? 'Unknown Staff';

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: RmTheme.electricBlue),
          onPressed: () => context.pop(),
        ),
        title: Text(
          'Training — $staffName',
          style: GoogleFonts.libreCaslonText(
            color: RmTheme.electricBlue,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: RmTheme.electricBlue.withOpacity(0.15),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                'TRIPARTITE DOCUMENT',
                style: GoogleFonts.inter(
                  color: RmTheme.electricBlue,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'A2 - Scope of Work',
              style: GoogleFonts.libreCaslonText(
                color: RmTheme.textPrimary,
                fontSize: 32,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Defines the specific duties, exclusions, and operational hours for the assigned role. High-precision documentation for clarity and compliance.',
              style: GoogleFonts.inter(
                color: RmTheme.textSecondary,
                fontSize: 15,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 32),
            _buildAssignedDutiesCard(),
            const SizedBox(height: 24),
            _buildOperationalHoursCard(),
            const SizedBox(height: 24),
            _buildExclusionsCard(),
            const SizedBox(height: 48),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(RmRoutes.stage4A2Client(staffId)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: RmTheme.electricBlue,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                ),
                child: Text(
                  'View Client Preview',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 48),
          ],
        ),
      ),
    );
  }

  Widget _buildAssignedDutiesCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle, width: 1),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Assigned Duties - DR',
            style: GoogleFonts.libreCaslonText(
              color: RmTheme.textPrimary,
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 24),
          _buildDutyItem(
            Icons.directions_car_outlined,
            'MORNING PICKUP',
            'Execute punctual morning transit protocol from primary residence to designated drop-off coordinates. Ensure vehicle readiness prior to departure.',
          ),
          const SizedBox(height: 20),
          _buildDutyItem(
            Icons.school_outlined,
            'SCHOOL RUN',
            'Manage daily scholastic transportation loop. Adhere strictly to authorized routing and security protocols during transit.',
          ),
          const SizedBox(height: 20),
          _buildDutyItem(
            Icons.shopping_bag_outlined,
            'LOGISTICAL SUPPORT',
            'Assist with scheduled errands and secure transport of identified physical assets as directed by the principal.',
          ),
        ],
      ),
    );
  }

  Widget _buildDutyItem(IconData icon, String title, String description) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: RmTheme.surfaceSecondary,
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: RmTheme.textSecondary, size: 20),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  color: RmTheme.textPrimary,
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                description,
                style: GoogleFonts.inter(
                  color: RmTheme.textSecondary,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildOperationalHoursCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle, width: 1),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.access_time, color: RmTheme.textPrimary, size: 20),
              const SizedBox(width: 12),
              Text(
                'Operational Hours',
                style: GoogleFonts.libreCaslonText(
                  color: RmTheme.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: RmTheme.surfaceSecondary.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              children: [
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.libreCaslonText(
                      color: RmTheme.textPrimary,
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(text: '7:30', style: TextStyle(color: RmTheme.electricBlue, fontWeight: FontWeight.w600)),
                      TextSpan(text: ' AM'),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48, vertical: 8),
                  child: Divider(color: RmTheme.borderSubtle),
                ),
                RichText(
                  text: TextSpan(
                    style: GoogleFonts.libreCaslonText(
                      color: RmTheme.textPrimary,
                      fontSize: 16,
                    ),
                    children: const [
                      TextSpan(text: '8:00', style: TextStyle(color: RmTheme.electricBlue, fontWeight: FontWeight.w600)),
                      TextSpan(text: ' PM'),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                Text(
                  'STANDARD MON-FRI WINDOW',
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1.0,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExclusionsCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFEF2F2), // Soft red background
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFFCA5A5), width: 1), // Soft red outline
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.block, color: Color(0xFFDC2626), size: 20),
              const SizedBox(width: 12),
              Text(
                'Exclusions',
                style: GoogleFonts.libreCaslonText(
                  color: const Color(0xFF991B1B),
                  fontSize: 18,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 24),
          _buildExclusionItem('No overnight trips authorized under this SOW.'),
          const SizedBox(height: 16),
          _buildExclusionItem('Interstate transit requires separate addendum.'),
          const SizedBox(height: 16),
          _buildExclusionItem('Unauthorized passenger transport strictly prohibited.'),
        ],
      ),
    );
  }

  Widget _buildExclusionItem(String text) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 2),
          child: Icon(Icons.close, color: Color(0xFFDC2626), size: 14),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.inter(
              color: const Color(0xFF450A0A),
              fontSize: 13,
              height: 1.5,
            ),
          ),
        ),
      ],
    );
  }
}
