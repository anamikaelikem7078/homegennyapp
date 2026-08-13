import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmStage4CompleteScreen extends StatelessWidget {
  final String staffId;

  const RmStage4CompleteScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF1A56FF)),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 48),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 32),
              _buildVisualCenter(),
              const SizedBox(height: 32),
              _buildSuccessHeader(),
              const SizedBox(height: 48),
              _buildAuditTrailCard(),
              const SizedBox(height: 64),
              _buildFinalCTA(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildVisualCenter() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        color: const Color(0xFF1A56FF).withOpacity(0.1),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: const Color(0xFF1A56FF).withOpacity(0.3), width: 2, style: BorderStyle.solid), // In Flutter dashed requires custom painter, using solid for now or could use package, but sticking to standard.
      ),
      alignment: Alignment.center,
      child: const Text(
        '🎉',
        style: TextStyle(fontSize: 64),
      ),
    );
  }

  Widget _buildSuccessHeader() {
    return Column(
      children: [
        Text(
          'All Agreements Executed!',
          textAlign: TextAlign.center,
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 24,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          'The legal foundation for your\ndeployment is complete.',
          textAlign: TextAlign.center,
          style: GoogleFonts.inter(
            color: const Color(0xFF4B5563),
            fontSize: 15,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildAuditTrailCard() {
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
        children: [
          _buildAuditStep(
            'A1 EOR Signed',
            'Employer of Record\nagreement established.',
            isLast: false,
          ),
          _buildAuditStep(
            'A2 SOW Signed',
            'Statement of Work\nterms finalized.',
            isLast: false,
          ),
          _buildAuditStep(
            'A3 Indemnity Signed',
            'Mutual indemnification\nclauses active.',
            isLast: true,
          ),
        ],
      ),
    );
  }

  Widget _buildAuditStep(String title, String description, {required bool isLast}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Column(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  shape: BoxShape.circle,
                  border: Border.all(color: const Color(0xFF22C55E), width: 2),
                ),
                child: const Icon(Icons.check, color: Color(0xFF22C55E), size: 16),
              ),
              if (!isLast)
                Expanded(
                  child: Container(
                    width: 2,
                    margin: const EdgeInsets.symmetric(vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withOpacity(0.5),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 24),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF111827),
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    description,
                    style: GoogleFonts.inter(
                      color: const Color(0xFF4B5563),
                      fontSize: 13,
                      height: 1.5,
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

  Widget _buildFinalCTA(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => context.push(RmRoutes.staffActivePlacement(staffId)),
        style: ElevatedButton.styleFrom(
          backgroundColor: const Color(0xFFE25611), // Vibrant Orange
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          elevation: 8,
          shadowColor: const Color(0xFFE25611).withOpacity(0.4),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Advance to S5 Deployment',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                fontSize: 15,
              ),
            ),
            const SizedBox(width: 8),
            const Icon(Icons.arrow_forward, size: 20),
          ],
        ),
      ),
    );
  }
}
