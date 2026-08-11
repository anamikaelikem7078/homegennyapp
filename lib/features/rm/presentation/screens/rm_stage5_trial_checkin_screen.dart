import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../navigation/rm_routes.dart';

class RmStage5TrialCheckinScreen extends StatefulWidget {
  const RmStage5TrialCheckinScreen({super.key});

  @override
  State<RmStage5TrialCheckinScreen> createState() => _RmStage5TrialCheckinScreenState();
}

class _RmStage5TrialCheckinScreenState extends State<RmStage5TrialCheckinScreen> {
  int _selectedDecisionIndex = 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Color(0xFF111827)),
          onPressed: () {},
        ),
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 24,
            fontWeight: FontWeight.w600,
            fontStyle: FontStyle.italic,
            letterSpacing: -0.5,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.account_circle_outlined, color: Color(0xFF111827)),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 16, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                IconButton(
                  icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                  onPressed: () {},
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Text(
                    'Trial Check-In —\nDay 7',
                    style: GoogleFonts.libreCaslonText(
                      color: const Color(0xFF111827),
                      fontSize: 32,
                      fontWeight: FontWeight.w500,
                      height: 1.2,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 32),
            _buildImportantNotice(),
            const SizedBox(height: 24),
            _buildRatingCard(),
            const SizedBox(height: 24),
            _buildDecisionHub(),
            const SizedBox(height: 32),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () => context.push(RmRoutes.clientInvoice('demo')),
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF1A56FF),
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  elevation: 4,
                  shadowColor: const Color(0xFF1A56FF).withOpacity(0.4),
                ),
                child: Text(
                  'CONFIRM & SUBMIT',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: 14,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  Widget _buildImportantNotice() {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: const Color(0xFF1A56FF).withOpacity(0.08),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: const Color(0xFF1A56FF).withOpacity(0.15)),
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
                  'IMPORTANT',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF1A56FF),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Trial ends today. Collect confirmation from both parties.',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF111827),
                    fontSize: 14,
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

  Widget _buildRatingCard() {
    return Container(
      width: double.infinity,
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
          Text(
            'CLIENT RATING',
            style: GoogleFonts.inter(
              color: const Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: List.generate(5, (index) {
              return Padding(
                padding: const EdgeInsets.only(right: 12.0),
                child: Icon(
                  index < 4 ? Icons.star : Icons.star_border,
                  color: const Color(0xFF1A56FF),
                  size: 28,
                ),
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildDecisionHub() {
    return Container(
      width: double.infinity,
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
          Text(
            'CLIENT DECISION',
            style: GoogleFonts.inter(
              color: const Color(0xFF4B5563),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          _buildCheckOption(0, 'Confirm Placement'),
          const SizedBox(height: 16),
          _buildCheckOption(1, 'Extend Trial (1x)'),
          const SizedBox(height: 16),
          _buildCheckOption(2, 'Reject Staff'),
          const SizedBox(height: 16),
          _buildCheckOption(3, 'Mutual Exit'),
        ],
      ),
    );
  }

  Widget _buildCheckOption(int index, String label) {
    bool isSelected = _selectedDecisionIndex == index;
    return GestureDetector(
      onTap: () {
        setState(() {
          _selectedDecisionIndex = index;
        });
      },
      child: Row(
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: BoxDecoration(
              color: isSelected ? const Color(0xFF1A56FF) : Colors.white,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(
                color: isSelected ? const Color(0xFF1A56FF) : const Color(0xFFD1D5DB),
                width: 1.5,
              ),
            ),
            child: isSelected
                ? const Icon(Icons.check, color: Colors.white, size: 18)
                : null,
          ),
          const SizedBox(width: 16),
          Text(
            label,
            style: GoogleFonts.inter(
              color: const Color(0xFF111827),
              fontSize: 15,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBottomNav() {
    return SafeArea(
      child: Container(
        margin: const EdgeInsets.only(left: 24, right: 24, bottom: 24),
        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
        decoration: BoxDecoration(
          color: const Color(0xFFF3F4F6),
          borderRadius: BorderRadius.circular(16),
          boxShadow: const [
            BoxShadow(
              color: Color(0x0A000000),
              blurRadius: 24,
              offset: Offset(0, 8),
            ),
          ],
          border: Border.all(color: const Color(0xFFE5E7EB), width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            _buildNavItem(Icons.home_outlined, false),
            _buildNavItem(Icons.badge_outlined, true), // Active item based on screen context
            _buildNavItem(Icons.payments_outlined, false),
            _buildNavItem(Icons.person_outline, false),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, bool isActive) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isActive ? const Color(0xFF1A56FF).withOpacity(0.1) : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Icon(
        icon,
        color: isActive ? const Color(0xFF1A56FF) : const Color(0xFF374151),
        size: 24,
      ),
    );
  }
}
