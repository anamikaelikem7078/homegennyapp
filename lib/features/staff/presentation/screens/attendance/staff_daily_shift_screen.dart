import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import '../../../../rm/presentation/navigation/rm_routes.dart';

class StaffDailyShiftScreen extends StatelessWidget {
  const StaffDailyShiftScreen({super.key});

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
          icon: const Icon(Icons.arrow_back, color: Color(0xFF6B7280)),
          onPressed: () {},
        ),
        title: Text(
          'BACK',
          style: GoogleFonts.inter(
            color: const Color(0xFF6B7280),
            fontSize: 12,
            fontWeight: FontWeight.w600,
            letterSpacing: 0.5,
          ),
        ),
        titleSpacing: 0,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(left: 24, right: 24, top: 8, bottom: 120),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Daily Shift Log',
              style: GoogleFonts.libreCaslonText(
                color: const Color(0xFF111827),
                fontSize: 32,
                fontWeight: FontWeight.w500,
                height: 1.2,
              ),
            ),
            const SizedBox(height: 32),
            _buildCheckInCard(),
            const SizedBox(height: 24),
            _buildCheckOutCard(context),
            const SizedBox(height: 24),
            _buildWeeklyCalendarCard(),
          ],
        ),
      ),
      bottomNavigationBar: _buildStaffBottomNav(1), // Assuming ID badge tab is active
    );
  }

  Widget _buildCheckInCard() {
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
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'CHECK-IN',
                    style: GoogleFonts.inter(
                      color: const Color(0xFF6B7280),
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 1.0,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '07:42 AM',
                    style: GoogleFonts.libreCaslonText(
                      color: const Color(0xFF111827),
                      fontSize: 40,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ],
              ),
              const Icon(
                Icons.login, // or similar arrow-entry icon
                color: Color(0xFFE5E7EB),
                size: 48,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: const Color(0xFF22C55E).withOpacity(0.15),
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: const Color(0xFF22C55E).withOpacity(0.3), width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.location_on_outlined, color: Color(0xFF15803D), size: 16),
                const SizedBox(width: 8),
                Text(
                  'GPS Verified: Bandra West, Mumbai ✓',
                  style: GoogleFonts.inter(
                    color: const Color(0xFF15803D),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckOutCard(BuildContext context) {
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
            'CHECK-OUT',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => context.push(RmRoutes.staffPayslip('demo')),
              icon: const Icon(Icons.logout, size: 20),
              label: Text(
                'Tap to Check Out',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w600,
                  fontSize: 15,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF1A56FF),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 20),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                elevation: 4,
                shadowColor: const Color(0xFF1A56FF).withOpacity(0.4),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildWeeklyCalendarCard() {
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
            'THIS WEEK',
            style: GoogleFonts.inter(
              color: const Color(0xFF6B7280),
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 1.0,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              _buildDayColumn('Mon', status: DayStatus.completed),
              _buildDayColumn('Tue', status: DayStatus.completed),
              _buildDayColumn('Wed', status: DayStatus.current),
              _buildDayColumn('Thu', status: DayStatus.future),
              _buildDayColumn('Fri', status: DayStatus.future),
              _buildDayColumn('Sat', status: DayStatus.off),
              _buildDayColumn('Sun', status: DayStatus.off),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(String label, {required DayStatus status}) {
    Color boxColor;
    Color borderColor = Colors.transparent;
    Widget? innerText;
    double width = 36;
    double height = 36;

    switch (status) {
      case DayStatus.completed:
        boxColor = const Color(0xFF10B981); // Emerald 500
        break;
      case DayStatus.current:
        boxColor = const Color(0xFFF97316); // Orange 500
        borderColor = const Color(0xFFFDBA74); // Orange 300
        height = 42; // slightly taller to highlight
        break;
      case DayStatus.future:
        boxColor = const Color(0xFFE5E7EB); // Gray 200
        break;
      case DayStatus.off:
        boxColor = const Color(0xFFF3F4F6); // Gray 100
        innerText = Center(
          child: Text(
            'OFF',
            style: GoogleFonts.inter(
              color: const Color(0xFF9CA3AF),
              fontSize: 10,
              fontWeight: FontWeight.w600,
            ),
          ),
        );
        break;
    }

    return Column(
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            color: status == DayStatus.current ? const Color(0xFF111827) : const Color(0xFF6B7280),
            fontSize: 11,
            fontWeight: status == DayStatus.current ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: boxColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(
              color: borderColor,
              width: status == DayStatus.current ? 2 : 0,
            ),
          ),
          child: innerText,
        ),
      ],
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

enum DayStatus { completed, current, future, off }
