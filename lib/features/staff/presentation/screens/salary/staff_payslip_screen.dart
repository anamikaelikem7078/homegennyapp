import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';

class StaffPayslipScreen extends StatelessWidget {
  const StaffPayslipScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      extendBody: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Color(0xFF111827)),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(
          'Payslip — March 2024',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF111827),
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 24, bottom: 120),
        child: Column(
          children: [
            _buildVisualCenter(),
            const SizedBox(height: 48),
            _buildFinancialCard(),
            const SizedBox(height: 48),
            _buildFooter(),
          ],
        ),
      ),
      bottomNavigationBar: _buildStaffBottomNav(2), // Money tab active
    );
  }

  Widget _buildVisualCenter() {
    return Column(
      children: [
        Text(
          'NET PAY',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.5,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '₹16,065',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF22C55E),
            fontSize: 48,
            fontWeight: FontWeight.w600,
            letterSpacing: -1.0,
          ),
        ),
      ],
    );
  }

  Widget _buildFinancialCard() {
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
        children: [
          _buildRow('Gross Salary', '₹18,000', isBold: false, isRed: false),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFF3F4F6), height: 1),
          const SizedBox(height: 16),
          _buildRow('ESIC (0.75%)', '- ₹135', isBold: false, isRed: true),
          const SizedBox(height: 16),
          _buildRow('PF (12% of ₹15k)', '- ₹1,800', isBold: false, isRed: true),
          const SizedBox(height: 16),
          const Divider(color: Color(0xFFE5E7EB), height: 1),
          const SizedBox(height: 16),
          _buildRow('Net Pay', '₹16,065', isBold: true, isRed: false, valueColor: const Color(0xFF22C55E)),
        ],
      ),
    );
  }

  Widget _buildRow(String label, String value, {required bool isBold, required bool isRed, Color? valueColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: isBold ? const Color(0xFF111827) : const Color(0xFF4B5563),
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w400,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            color: valueColor ?? (isRed ? const Color(0xFFDC2626) : const Color(0xFF111827)),
            fontSize: 15,
            fontWeight: isBold ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ],
    );
  }

  Widget _buildFooter() {
    return Text(
      'Disbursed via Razorpay · 1 Mar 2024',
      style: GoogleFonts.inter(
        color: const Color(0xFF6B7280),
        fontSize: 12,
        fontWeight: FontWeight.w400,
      ),
    );
  }

  Widget _buildStaffBottomNav(int currentIndex) {
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
            _buildNavItem(Icons.home_outlined, currentIndex == 0),
            _buildNavItem(Icons.badge_outlined, currentIndex == 1),
            _buildNavItem(Icons.payments_outlined, currentIndex == 2),
            _buildNavItem(Icons.person_outline, currentIndex == 3),
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
