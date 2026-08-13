import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../common/presentation/providers/auth_provider.dart';
import '../providers/rm_providers.dart';

class RmTrack1AadhaarScreen extends ConsumerWidget {
  final String staffId;

  const RmTrack1AadhaarScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final staff = ref.watch(rmStaffDetailProvider(staffId));
    
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
            _buildStatusHeader(context),
            const SizedBox(height: 24),
            _buildActionButtons(context, ref, staff?.id ?? staffId),
            const SizedBox(height: 24),
            _buildSubjectInfo(context, staff?.name ?? 'Unknown'),
            const SizedBox(height: 24),
            _buildStatusBreakdown(context),
            const SizedBox(height: 24),
            _buildComplianceNotice(context),
            const SizedBox(height: 32),
          ],
        ),
      ),
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
          'Track 1 — Aadhaar\neKYC',
          style: GoogleFonts.libreCaslonText(
            color: RmTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w600,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'UIDAI API · OTP-based · Last 4 only stored. All tracks run simultaneously. Pipeline cannot advance until all mandatory tracks are complete.',
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

  Widget _buildStatusHeader(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle),
      ),
      child: Column(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: RmTheme.emeraldGreen.withOpacity(0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: const Icon(
              Icons.check_circle_outline,
              color: RmTheme.emeraldGreen,
              size: 48,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'VERIFIED',
            style: GoogleFonts.libreCaslonText(
              color: RmTheme.emeraldGreen,
              fontSize: 28,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Identity confirmed via UIDAI database\nmatching.',
            textAlign: TextAlign.center,
            style: GoogleFonts.inter(
              color: RmTheme.textSecondary,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButtons(BuildContext context, WidgetRef ref, String sId) {
    return Row(
      children: [
        Expanded(
          child: ElevatedButton(
            onPressed: () async {
              final rmId = ref.read(authProvider).user?.id ?? 'rm-demo-1';
              // Assume document ID is somehow tied to staff ID, e.g. "doc-aadhaar-<staffId>"
              await ref.read(rmRepositoryProvider).approveDocument('doc-aadhaar-$sId', rmId);
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aadhaar Approved!')));
              context.pop();
            },
            style: ElevatedButton.styleFrom(backgroundColor: RmTheme.emeraldGreen),
            child: const Text('Approve', style: TextStyle(color: Colors.white)),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: () async {
              final rmId = ref.read(authProvider).user?.id ?? 'rm-demo-1';
              await ref.read(rmRepositoryProvider).rejectDocument('doc-aadhaar-$sId', rmId, 'Mismatched details');
              ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Aadhaar Rejected!')));
              context.pop();
            },
            style: OutlinedButton.styleFrom(foregroundColor: RmTheme.crimsonDanger),
            child: const Text('Reject'),
          ),
        ),
      ],
    );
  }

  Widget _buildSubjectInfo(BuildContext context, String staffName) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F4F6),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Subject Info',
            style: GoogleFonts.libreCaslonText(
              color: RmTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  'https://images.unsplash.com/photo-1506794778202-cad84cf45f1d?w=150',
                  width: 56,
                  height: 56,
                  fit: BoxFit.cover,
                ),
              ),
              const SizedBox(width: 16),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    staffName,
                    style: GoogleFonts.inter(
                      color: RmTheme.textPrimary,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Applicant ID: #$staffId',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: RmTheme.electricBlue,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'View Full Report',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Icon(Icons.arrow_forward, size: 16),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBreakdown(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'EKYC STATUS BREAKDOWN',
          style: GoogleFonts.inter(
            color: RmTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        _buildBreakdownItem('NAME (UIDAI)', 'Ramesh Kumar Singh', Icons.check_circle_outline, RmTheme.emeraldGreen),
        const SizedBox(height: 12),
        _buildBreakdownItem('DOB MATCH', '15-Mar-1992', Icons.check_circle_outline, RmTheme.emeraldGreen),
        const SizedBox(height: 12),
        _buildBreakdownItem('AADHAAR [STORED]', '.... .... 4821', Icons.lock_outline, RmTheme.emeraldGreen),
      ],
    );
  }

  Widget _buildBreakdownItem(String label, String value, IconData icon, Color iconColor) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: RmTheme.borderSubtle),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: RmTheme.textSecondary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                value,
                style: GoogleFonts.inter(
                  color: RmTheme.textPrimary,
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          Icon(icon, color: iconColor, size: 20),
        ],
      ),
    );
  }

  Widget _buildComplianceNotice(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.electricBlue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(8),
        border: const Border(
          left: BorderSide(color: RmTheme.electricBlue, width: 4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline, color: RmTheme.electricBlue, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Compliance Notice',
                  style: GoogleFonts.inter(
                    color: RmTheme.textPrimary,
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Full Aadhaar number NOT stored. Only last 4 digits retained per DPDP Act 2023 guidelines. Data encrypted at rest.',
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 12,
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
}
