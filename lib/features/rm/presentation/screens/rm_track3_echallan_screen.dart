import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../design_system/foundations/rm_theme.dart';
import '../navigation/rm_routes.dart';

class RmTrack3EChallanScreen extends StatelessWidget {
  final String staffId;

  const RmTrack3EChallanScreen({super.key, required this.staffId});

  @override
  Widget build(BuildContext context) {
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
            _buildChallanListCard(context),
            const SizedBox(height: 16),
            _buildScenarioCard(context),
            const SizedBox(height: 32),
            _buildPipelineSummary(context),
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
      leading: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.menu, color: RmTheme.textPrimary),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.arrow_back, color: RmTheme.textPrimary),
            onPressed: () => context.pop(),
          ),
        ],
      ),
      leadingWidth: 96,
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
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: RmTheme.borderSubtle,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 6,
                height: 6,
                decoration: const BoxDecoration(
                  color: RmTheme.amberWarning,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'TRACK 3 IN PROGRESS',
                style: GoogleFonts.inter(
                  color: RmTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'eChallan Check',
          style: GoogleFonts.libreCaslonText(
            color: RmTheme.textPrimary,
            fontSize: 32,
            fontWeight: FontWeight.w400,
            height: 1.1,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          'Reviewing traffic violation records for the applicant. Multiple citations require conditional registration review under DR-08 protocol.',
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

  Widget _buildChallanListCard(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: RmTheme.sophisticatedShadow,
      ),
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 4,
              decoration: const BoxDecoration(
                color: RmTheme.amberWarning,
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(12),
                  bottomLeft: Radius.circular(12),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: RmTheme.amberWarning, size: 24),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '2 CHALLANS\nFOUND',
                                style: GoogleFonts.libreCaslonText(
                                  color: RmTheme.textPrimary,
                                  fontSize: 20,
                                  fontWeight: FontWeight.w400,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'Awaiting resolution or conditional approval.',
                                style: GoogleFonts.inter(
                                  color: RmTheme.textPrimary,
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: const Color(0xFFE5E7EB),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'DL-1420110012345',
                        style: GoogleFonts.inter(
                          color: RmTheme.textPrimary,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildChallanItem('CHALLAN 1', '₹500', 'Signal violation', '10 Jan 2024'),
                    const SizedBox(height: 12),
                    _buildChallanItem('CHALLAN 2', '₹1000', 'Speeding', '22 Nov 2023'),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildChallanItem(String label, String amount, String reason, String date) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                label,
                style: GoogleFonts.inter(
                  color: RmTheme.textPrimary,
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  letterSpacing: 0.5,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: const Color(0xFFE5E7EB),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  amount,
                  style: GoogleFonts.inter(
                    color: RmTheme.textPrimary,
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            reason,
            style: GoogleFonts.inter(
              color: RmTheme.textPrimary,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 4),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: RmTheme.textSecondary),
              const SizedBox(width: 4),
              Text(
                date,
                style: GoogleFonts.inter(
                  color: RmTheme.textSecondary,
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildScenarioCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB), // Pale amber
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.gavel, color: Color(0xFFB45309), size: 20),
              const SizedBox(width: 8),
              Text(
                'DR-08 Scenario',
                style: GoogleFonts.libreCaslonText(
                  color: const Color(0xFFB45309),
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          RichText(
            text: TextSpan(
              style: GoogleFonts.inter(
                color: RmTheme.textPrimary,
                fontSize: 13,
                height: 1.5,
              ),
              children: [
                TextSpan(
                  text: '1-2 challans. ',
                  style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                ),
                const TextSpan(text: 'Conditional registration applies.'),
              ],
            ),
          ),
          const SizedBox(height: 16),
          Text(
            'Must disclose to client during placement process as per compliance guidelines.',
            style: GoogleFonts.inter(
              color: RmTheme.textPrimary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 24),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFD97706),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Apply DR-08 & Continue',
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

  Widget _buildPipelineSummary(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'VERIFICATION PIPELINE',
          style: GoogleFonts.inter(
            color: RmTheme.textSecondary,
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 1.0,
          ),
        ),
        const SizedBox(height: 16),
        _buildTimelineItem('T1: Aadhaar', 'Verified', RmTheme.electricBlue, true, true),
        _buildTimelineItem('T2: DL Check', 'Verified', RmTheme.electricBlue, true, true),
        _buildTimelineItem('T3: eChallan', 'Pending Action', RmTheme.amberWarning, false, true, isCurrent: true),
        _buildTimelineItem('T4: Police Ver.', 'Waiting', RmTheme.borderSubtle, false, false, isLast: true),
      ],
    );
  }

  Widget _buildTimelineItem(String title, String status, Color color, bool isDone, bool hasLine, {bool isCurrent = false, bool isLast = false}) {
    return IntrinsicHeight(
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          SizedBox(
            width: 32,
            child: Column(
              children: [
                Container(
                  width: 20,
                  height: 20,
                  decoration: BoxDecoration(
                    color: isDone ? color : Colors.transparent,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCurrent ? color : (isDone ? color : color),
                      width: isCurrent ? 4 : 1,
                    ),
                  ),
                  child: isDone
                      ? const Icon(Icons.check, size: 12, color: Colors.white)
                      : (isCurrent
                          ? Center(
                              child: Container(
                                width: 6,
                                height: 6,
                                decoration: const BoxDecoration(
                                  color: Colors.white,
                                  shape: BoxShape.circle,
                                ),
                              ),
                            )
                          : null),
                ),
                if (!isLast)
                  Expanded(
                    child: Container(
                      width: 1,
                      color: hasLine ? const Color(0xFFE5E7EB) : Colors.transparent,
                    ),
                  ),
              ],
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(bottom: 16.0),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: BoxDecoration(
                  color: isDone || isCurrent ? RmTheme.cardSurface : Colors.transparent,
                  border: Border.all(color: isCurrent ? color : (isDone ? RmTheme.borderSubtle : Colors.transparent)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      title,
                      style: GoogleFonts.inter(
                        color: isCurrent ? color : (isDone ? RmTheme.electricBlue : RmTheme.textSecondary),
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      status,
                      style: GoogleFonts.inter(
                        color: isCurrent ? color : RmTheme.textSecondary,
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
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
              _buildNavItem(Icons.chat_bubble_outline, 'Messages', false, showDot: true),
              _buildNavItem(Icons.admin_panel_settings_outlined, 'Admin', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, bool isActive, {VoidCallback? onTap, bool showDot = false}) {
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
            Stack(
              clipBehavior: Clip.none,
              children: [
                Icon(icon, color: isActive ? Colors.white : RmTheme.textSecondary),
                if (showDot)
                  Positioned(
                    top: 0,
                    right: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
              ],
            ),
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
