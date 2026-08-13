import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/rm_providers.dart';

class RmStage4A1Screen extends ConsumerWidget {
  final String staffId;

  const RmStage4A1Screen({super.key, required this.staffId});

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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 32.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Text(
                    'A1 - EOR Contract',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.libreCaslonText(
                      color: RmTheme.textPrimary,
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Please review the terms of your employment carefully before proceeding with the digital signature.',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 16,
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Text(
                    'SCROLL TO READ ALL 12 CLAUSES',
                    style: GoogleFonts.inter(
                      color: RmTheme.textSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      letterSpacing: 1.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Icon(Icons.keyboard_arrow_down, color: RmTheme.textSecondary),
                  const SizedBox(height: 24),
                  _buildContractCard(),
                ],
              ),
            ),
          ),
          _buildFooter(context),
        ],
      ),
    );
  }

  Widget _buildContractCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: RmTheme.borderSubtle, width: 1),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Clause 1 - Employment',
            style: GoogleFonts.libreCaslonText(
              color: RmTheme.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The Employer agrees to employ the Employee, and the Employee agrees to enter into employment with the Employer, serving as a Senior Analyst, based in the primary operational office.',
            style: GoogleFonts.inter(
              color: RmTheme.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'The Employee shall devote their full business time, attention, and energies to the business of the Employer and shall not during the term of this Agreement engage in any other business activity whether or not such business activity is pursued for gain, profit or other pecuniary advantage.',
            style: GoogleFonts.inter(
              color: RmTheme.textSecondary,
              fontSize: 16,
              height: 1.6,
            ),
          ),
          // Adding some extra space to simulate a long document
          const SizedBox(height: 48),
        ],
      ),
    );
  }

  Widget _buildFooter(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: RmTheme.borderSubtle, width: 1)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.verified_user_outlined, color: RmTheme.electricBlue, size: 18),
                const SizedBox(width: 8),
                Text(
                  'Powered by Secure eSign',
                  style: GoogleFonts.inter(
                    color: RmTheme.textSecondary,
                    fontSize: 14,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            TextButton(
              onPressed: () {},
              child: Text(
                'Reject / Object to Clause',
                style: GoogleFonts.inter(
                  color: const Color(0xFFDC2626), // Deep red
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  context.push(RmRoutes.stage4A1OTP(staffId));
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: RmTheme.emeraldGreen,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  'Sign Agreement (eSign OTP)',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w600,
                    fontSize: 15,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
