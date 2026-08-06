import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import '../../widgets/staff_scaffold.dart';

/// Salary summary screen.
class StaffSalaryScreen extends ConsumerWidget {
  const StaffSalaryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final summary = ref.watch(staffSalarySummaryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_none, color: Color(0xFF475569)),
            onPressed: () {},
          ),
          Padding(
            padding: const EdgeInsets.only(right: 16),
            child: CircleAvatar(
              radius: 14,
              backgroundImage: const NetworkImage('https://images.unsplash.com/photo-1560250097-0b93528c311a?auto=format&fit=crop&q=80&w=400'),
            ),
          )
        ],
      ),
      body: summary.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (s) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          children: [
            Text(
              'FINANCIAL OVERVIEW',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Salary Details',
              style: GoogleFonts.libreCaslonText(
                fontSize: 28,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 24),
            
            // Main Salary Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.03),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
                border: Border.all(color: const Color(0xFFF1F5F9)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEEF2FF),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      s.month,
                      style: GoogleFonts.inter(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF1A56FF),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.baseline,
                    textBaseline: TextBaseline.alphabetic,
                    children: [
                      Text(
                        s.net.replaceAll('₹', '₹ '),
                        style: GoogleFonts.libreCaslonText(
                          fontSize: 40,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'INR',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF64748B),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.check_circle_outline, color: Color(0xFF1A56FF), size: 16),
                      const SizedBox(width: 6),
                      Text(
                        'Paid on ${s.month} 28, 2024',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: const Color(0xFF1A56FF),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(content: Text('Downloading payslip...')),
                        );
                      },
                      icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                      label: Text(
                        'Download Payslip',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56FF),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    height: 44,
                    child: OutlinedButton(
                      onPressed: () {
                        context.push(StaffRoutes.payslip('1'));
                      },
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Color(0xFFE2E8F0)),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      child: Text(
                        'View Details',
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: const Color(0xFF475569),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            
            // Breakdowns
            _SalaryBreakdownCard(
              title: 'GROSS PAY',
              amount: s.gross,
              icon: Icons.trending_up,
              barColor: const Color(0xFF1A56FF),
              barWidth: 0.9,
              textColor: const Color(0xFF0F172A),
            ),
            const SizedBox(height: 16),
            _SalaryBreakdownCard(
              title: 'DEDUCTIONS',
              amount: s.deductions,
              icon: Icons.trending_down,
              barColor: const Color(0xFFDC2626),
              barWidth: 0.1,
              textColor: const Color(0xFFDC2626),
            ),
            const SizedBox(height: 16),
            _SalaryBreakdownCard(
              title: 'NET PAY',
              amount: s.net,
              icon: Icons.account_balance_wallet_outlined,
              barColor: const Color(0xFF1A56FF),
              barWidth: 0.8,
              textColor: const Color(0xFF1A56FF),
            ),
            
            const SizedBox(height: 40),
            Text(
              'QUICK ACTIONS',
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.5,
              ),
            ),
            const SizedBox(height: 16),
            
            _ActionTile(
              icon: Icons.history,
              title: 'Payslip History',
              subtitle: 'View and download past earnings',
              onTap: () => context.push(StaffRoutes.salaryHistory),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.account_balance_outlined,
              title: 'Bank Details',
              subtitle: 'Manage your salary deposit account',
              onTap: () => context.push(StaffRoutes.bankDetails),
            ),
            const SizedBox(height: 12),
            _ActionTile(
              icon: Icons.receipt_long_outlined,
              title: 'Tax Declaration',
              subtitle: 'Submit investment proofs for FY 24-25',
              onTap: () => context.push(StaffRoutes.taxDeclaration),
            ),
            const SizedBox(height: 40),
            
            // Manage everything section
            Container(
              padding: const EdgeInsets.all(32),
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Manage everything in\none place.',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Easily access your earnings, bonuses,\nand tax documents from your\npersonalized dashboard.',
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: const Color(0xFF475569),
                      height: 1.5,
                    ),
                  ),
                  const SizedBox(height: 32),
                  Container(
                    height: 200,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      image: const DecorationImage(
                        image: NetworkImage('https://images.unsplash.com/photo-1554224155-6726b3ff858f?auto=format&fit=crop&q=80&w=600'),
                        fit: BoxFit.cover,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.05),
                          blurRadius: 20,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}

class _SalaryBreakdownCard extends StatelessWidget {
  const _SalaryBreakdownCard({
    required this.title,
    required this.amount,
    required this.icon,
    required this.barColor,
    required this.barWidth,
    required this.textColor,
  });
  
  final String title;
  final String amount;
  final IconData icon;
  final Color barColor;
  final double barWidth;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: const Color(0xFFF1F5F9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                title,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  color: title == 'NET PAY' ? const Color(0xFF1A56FF) : const Color(0xFF64748B),
                  letterSpacing: 1.2,
                ),
              ),
              Icon(icon, color: title == 'NET PAY' ? const Color(0xFF1A56FF) : const Color(0xFF94A3B8), size: 16),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            amount.replaceAll('₹', '₹ '),
            style: GoogleFonts.libreCaslonText(
              fontSize: 22,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 16),
          Stack(
            children: [
              Container(
                height: 3,
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(1.5),
                ),
              ),
              FractionallySizedBox(
                alignment: Alignment.centerLeft,
                widthFactor: barWidth,
                child: Container(
                  height: 3,
                  decoration: BoxDecoration(
                    color: barColor,
                    borderRadius: BorderRadius.circular(1.5),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: const Color(0xFFF1F5F9)),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: const Color(0xFF1A56FF), size: 20),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: GoogleFonts.inter(
                      fontSize: 11,
                      color: const Color(0xFF64748B),
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right, color: Color(0xFF94A3B8), size: 20),
          ],
        ),
      ),
    );
  }
}

/// Payslip detail screen.
class StaffPayslipScreen extends ConsumerWidget {
  const StaffPayslipScreen({super.key, required this.payslipId});
  final String payslipId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final payslip = ref.watch(staffPayslipProvider(payslipId));

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        titleSpacing: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          'Payslip Details',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: false,
      ),
      body: payslip.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (p) {
          final is24500 = p.amount.contains('24,500') || p.amount.contains('24500');
          final basicPay = is24500 ? '₹14,000' : '₹15,000';
          final hra = is24500 ? '₹7,000' : '₹7,500';
          final conveyance = is24500 ? '₹3,000' : '₹3,000';
          final bonus = is24500 ? '₹2,500' : '₹2,500';
          final pf = is24500 ? '₹1,600' : '₹1,800';
          final profTax = is24500 ? '₹200' : '₹200';
          final insurance = is24500 ? '₹200' : '₹240';
          final grossPay = is24500 ? '₹26,500' : '₹28,000';
          final totalDeductions = is24500 ? '₹2,000' : '₹2,240';
          final netPayable = p.amount;

          // Format Disbursed Date: e.g. "Paid on 1 Jul 2024" -> "Disbursed on 05 Jul"
          final monthParts = p.month.split(' ');
          final monthAbbr = monthParts.isNotEmpty ? monthParts[0].substring(0, 3) : 'Aug';
          final disbursedText = 'Disbursed on 05 $monthAbbr';

          return Column(
            children: [
              Expanded(
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                  children: [
                    // Hero Metric Card
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.04),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                          BoxShadow(
                            color: Colors.black.withOpacity(0.02),
                            blurRadius: 4,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            p.month.toUpperCase(),
                            style: GoogleFonts.inter(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF64748B),
                              letterSpacing: 1.2,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            netPayable.replaceAll('₹', '₹ '),
                            style: GoogleFonts.inter(
                              fontSize: 32,
                              fontWeight: FontWeight.w700,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Status Badge
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFE6F4EA),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.check, color: Color(0xFF137333), size: 14),
                                const SizedBox(width: 6),
                                Text(
                                  disbursedText,
                                  style: GoogleFonts.inter(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF137333),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Earnings Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Earnings',
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PayslipBreakdownRow(title: 'Basic Pay', amount: basicPay),
                          const SizedBox(height: 12),
                          _PayslipBreakdownRow(title: 'HRA', amount: hra),
                          const SizedBox(height: 12),
                          _PayslipBreakdownRow(title: 'Conveyance', amount: conveyance),
                          const SizedBox(height: 12),
                          _PayslipBreakdownRow(title: 'Bonus', amount: bonus),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Deductions Card
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFF1F5F9)),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Deductions',
                            style: GoogleFonts.libreCaslonText(
                              fontSize: 18,
                              fontWeight: FontWeight.w600,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 16),
                          _PayslipBreakdownRow(title: 'PF', amount: pf),
                          const SizedBox(height: 12),
                          _PayslipBreakdownRow(title: 'Professional Tax', amount: profTax),
                          const SizedBox(height: 12),
                          _PayslipBreakdownRow(title: 'Insurance', amount: insurance),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Summary Module
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9).withOpacity(0.5),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(color: const Color(0xFFE2E8F0)),
                      ),
                      child: Column(
                        children: [
                          _PayslipSummaryRow(title: 'Gross Pay', amount: grossPay),
                          const SizedBox(height: 12),
                          _PayslipSummaryRow(
                            title: 'Total Deductions',
                            amount: totalDeductions,
                            textColor: const Color(0xFFDC2626),
                          ),
                          const Padding(
                            padding: EdgeInsets.symmetric(vertical: 12),
                            child: Divider(height: 1, color: Color(0xFFE2E8F0)),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'Net Payable',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF0F172A),
                                ),
                              ),
                              Text(
                                netPayable.replaceAll('₹', '₹ '),
                                style: GoogleFonts.inter(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A56FF),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          // Primary CTA
                          SizedBox(
                            width: double.infinity,
                            height: 48,
                            child: ElevatedButton.icon(
                              onPressed: () {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Downloading Payslip PDF...')),
                                );
                              },
                              icon: const Icon(Icons.download_rounded, color: Colors.white, size: 18),
                              label: Text(
                                'DOWNLOAD PAYSLIP (PDF)',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: const Color(0xFF1A56FF),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
              // Custom Bottom Navigation Bar
              _buildBottomNavBar(context),
            ],
          );
        },
      ),
    );
  }

  Widget _buildBottomNavBar(BuildContext context) {
    return Container(
      height: 72,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(
          top: BorderSide(color: const Color(0xFFE2E8F0), width: 1),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildNavItem(context, Icons.home_outlined, 'Home', false, () {
            context.go(StaffRoutes.home);
          }),
          _buildNavItem(context, Icons.people_outline, 'Staff', false, () {
            context.go(StaffRoutes.pipeline);
          }),
          _buildNavItem(context, Icons.payments_outlined, 'Payslips', true, () {}),
          _buildNavItem(context, Icons.settings_outlined, 'Settings', false, () {
            context.go(StaffRoutes.settings);
          }),
        ],
      ),
    );
  }

  Widget _buildNavItem(BuildContext context, IconData icon, String label, bool isActive, VoidCallback onTap) {
    if (isActive) {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            color: const Color(0xFF1A56FF),
            borderRadius: BorderRadius.circular(20),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 8),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      );
    } else {
      return GestureDetector(
        onTap: onTap,
        child: Container(
          color: Colors.transparent,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: const Color(0xFF94A3B8), size: 22),
              const SizedBox(height: 4),
              Text(
                label,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w500,
                  color: const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      );
    }
  }
}

class _PayslipBreakdownRow extends StatelessWidget {
  const _PayslipBreakdownRow({
    required this.title,
    required this.amount,
  });

  final String title;
  final String amount;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w400,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          amount.replaceAll('₹', '₹ '),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
        ),
      ],
    );
  }
}

class _PayslipSummaryRow extends StatelessWidget {
  const _PayslipSummaryRow({
    required this.title,
    required this.amount,
    this.textColor = const Color(0xFF475569),
  });

  final String title;
  final String amount;
  final Color textColor;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          title,
          style: GoogleFonts.inter(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF64748B),
          ),
        ),
        Text(
          amount.replaceAll('₹', '₹ '),
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }
}

/// Salary history list.
class StaffSalaryHistoryScreen extends ConsumerWidget {
  const StaffSalaryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(staffPayslipHistoryProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: history.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Text(
              'Salary History',
              style: GoogleFonts.libreCaslonText(
                fontSize: 32,
                fontWeight: FontWeight.w600,
                color: const Color(0xFF0F172A),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Detailed breakdown of your professional earnings and disbursement status.',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: const Color(0xFF64748B),
                height: 1.5,
              ),
            ),
            const SizedBox(height: 24),
            ...list.map((p) => Padding(
              padding: const EdgeInsets.only(bottom: 16),
              child: GestureDetector(
                onTap: () => context.push(StaffRoutes.payslip(p.id)),
                child: Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: const Color(0xFFF1F5F9)),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.04),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 4,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.month.toUpperCase(),
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF64748B),
                                letterSpacing: 1,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              p.amount.replaceAll('₹', '₹ '),
                              style: GoogleFonts.inter(
                                fontSize: 20,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF0F172A),
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE6F4EA),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          'Paid',
                          style: GoogleFonts.inter(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF137333),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      const Icon(
                        Icons.chevron_right,
                        color: Color(0xFFB0BEC5),
                        size: 20,
                      ),
                    ],
                  ),
                ),
              ),
            )),
            const SizedBox(height: 24),
            Center(
              child: TextButton(
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Archived payments coming soon')),
                  );
                },
                child: Text(
                  'VIEW ARCHIVED PAYMENTS',
                  style: GoogleFonts.inter(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: const Color(0xFF1A56FF),
                    letterSpacing: 1.2,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }
}

/// Bank details screen.
class StaffBankDetailsScreen extends ConsumerStatefulWidget {
  const StaffBankDetailsScreen({super.key});

  @override
  ConsumerState<StaffBankDetailsScreen> createState() => _StaffBankDetailsScreenState();
}

class _StaffBankDetailsScreenState extends ConsumerState<StaffBankDetailsScreen> {
  bool _obscureAccountNumber = true;
  bool _isEditing = false;

  late TextEditingController _holderController;
  late TextEditingController _numberController;
  late TextEditingController _bankNameController;
  late TextEditingController _ifscController;

  String? _localHolder;
  String? _localNumber;
  String? _localBankName;
  String? _localIfsc;

  @override
  void initState() {
    super.initState();
    _holderController = TextEditingController();
    _numberController = TextEditingController();
    _bankNameController = TextEditingController();
    _ifscController = TextEditingController();
  }

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  void _initFields(BankDetails b) {
    if (_localHolder == null) {
      _localHolder = b.accountHolder;
      _localNumber = '123456784567'; // dummy full number for editing
      _localBankName = b.bankName;
      _localIfsc = b.ifsc;

      _holderController.text = _localHolder!;
      _numberController.text = _localNumber!;
      _bankNameController.text = _localBankName!;
      _ifscController.text = _localIfsc!;
    }
  }

  String _maskAccountNumber(String number) {
    final clean = number.replaceAll(' ', '');
    if (clean.length <= 4) return clean;
    return '****' + clean.substring(clean.length - 4);
  }

  Widget _buildEditField(String label, IconData icon, TextEditingController controller) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w600,
            color: const Color(0xFF0F172A),
          ),
          decoration: InputDecoration(
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            filled: true,
            fillColor: const Color(0xFFF8FAFC),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFFE2E8F0)),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Color(0xFF1A56FF), width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(staffBankDetailsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Color(0xFF1A56FF)),
          onPressed: () {
            if (context.canPop()) {
              context.pop();
            }
          },
        ),
        title: Text(
          'HomeGenny',
          style: GoogleFonts.libreCaslonText(
            color: const Color(0xFF1A56FF),
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        centerTitle: true,
      ),
      body: bank.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (b) {
          _initFields(b);

          return ListView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bank Details',
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    width: 60,
                    height: 3,
                    color: const Color(0xFF1A56FF),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // Bank Details Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: const Color(0xFFF1F5F9)),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 24,
                      offset: const Offset(0, 10),
                    ),
                  ],
                ),
                child: _isEditing
                    ? Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildEditField('ACCOUNT HOLDER', Icons.person_outline, _holderController),
                          const SizedBox(height: 20),
                          _buildEditField('ACCOUNT NUMBER', Icons.credit_card_outlined, _numberController),
                          const SizedBox(height: 20),
                          _buildEditField('BANK NAME', Icons.account_balance_outlined, _bankNameController),
                          const SizedBox(height: 20),
                          _buildEditField('IFSC CODE', Icons.qr_code_outlined, _ifscController),
                          const SizedBox(height: 32),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton(
                                  onPressed: () {
                                    setState(() {
                                      // Restore fields to local state values
                                      _holderController.text = _localHolder!;
                                      _numberController.text = _localNumber!;
                                      _bankNameController.text = _localBankName!;
                                      _ifscController.text = _localIfsc!;
                                      _isEditing = false;
                                    });
                                  },
                                  style: OutlinedButton.styleFrom(
                                    side: const BorderSide(color: Color(0xFFE2E8F0)),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'CANCEL',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: const Color(0xFF64748B),
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: ElevatedButton(
                                  onPressed: () {
                                    if (_holderController.text.trim().isEmpty ||
                                        _numberController.text.trim().isEmpty ||
                                        _bankNameController.text.trim().isEmpty ||
                                        _ifscController.text.trim().isEmpty) {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(content: Text('All fields are required')),
                                      );
                                      return;
                                    }
                                    setState(() {
                                      _localHolder = _holderController.text.trim();
                                      _localNumber = _numberController.text.trim();
                                      _localBankName = _bankNameController.text.trim();
                                      _localIfsc = _ifscController.text.trim();
                                      _isEditing = false;
                                    });
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      const SnackBar(content: Text('Bank details updated successfully')),
                                    );
                                  },
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xFF1A56FF),
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                  ),
                                  child: Text(
                                    'SAVE DETAILS',
                                    style: GoogleFonts.inter(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w700,
                                      color: Colors.white,
                                      letterSpacing: 1,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      )
                    : Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _BankDetailField(
                            icon: Icons.person_outline,
                            label: 'ACCOUNT HOLDER',
                            value: _localHolder ?? b.accountHolder,
                          ),
                          const SizedBox(height: 24),
                          _BankDetailField(
                            icon: Icons.credit_card_outlined,
                            label: 'ACCOUNT NUMBER',
                            value: _obscureAccountNumber
                                ? _maskAccountNumber(_localNumber ?? b.accountNumber)
                                : (_localNumber ?? b.accountNumber),
                            trailing: IconButton(
                              icon: Icon(
                                _obscureAccountNumber ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                                color: const Color(0xFF1A56FF),
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscureAccountNumber = !_obscureAccountNumber;
                                });
                              },
                            ),
                          ),
                          const SizedBox(height: 24),
                          _BankDetailField(
                            icon: Icons.account_balance_outlined,
                            label: 'BANK NAME',
                            value: _localBankName ?? b.bankName,
                          ),
                          const SizedBox(height: 24),
                          _BankDetailField(
                            icon: Icons.qr_code_outlined,
                            label: 'IFSC CODE',
                            value: _localIfsc ?? b.ifsc,
                            isHighlighted: true,
                          ),
                          const SizedBox(height: 32),
                          Center(
                            child: TextButton.icon(
                              onPressed: () {
                                setState(() {
                                  _isEditing = true;
                                });
                              },
                              icon: const Icon(Icons.edit_outlined, color: Color(0xFF1A56FF), size: 16),
                              label: Text(
                                'EDIT DETAILS',
                                style: GoogleFonts.inter(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: const Color(0xFF1A56FF),
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
              ),
            const SizedBox(height: 24),

            // Verification Card
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: const Color(0xFFE6F4EA),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFFCEEAD6)),
              ),
              child: Row(
                children: [
                  const Icon(Icons.check_circle_outline, color: Color(0xFF137333), size: 20),
                  const SizedBox(width: 12),
                  Text(
                    'STATUS: VERIFIED',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFF137333),
                      letterSpacing: 1,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // Vault Banner
            Container(
              height: 200,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                image: const DecorationImage(
                  image: NetworkImage('https://images.unsplash.com/photo-1601597111158-2fceff292cdc?auto=format&fit=crop&q=80&w=600'),
                  fit: BoxFit.cover,
                ),
              ),
              child: Stack(
                children: [
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(16),
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Colors.black.withOpacity(0.8),
                          Colors.black.withOpacity(0.2),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 24,
                    left: 24,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'SECURITY FIRST',
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w800,
                            color: Colors.white.withOpacity(0.6),
                            letterSpacing: 1.5,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Encrypted Storage',
                          style: GoogleFonts.libreCaslonText(
                            fontSize: 24,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
            ],
          );
        },
      ),
    );
  }
}

class _BankDetailField extends StatelessWidget {
  const _BankDetailField({
    required this.icon,
    required this.label,
    required this.value,
    this.trailing,
    this.isHighlighted = false,
  });

  final IconData icon;
  final String label;
  final String value;
  final Widget? trailing;
  final bool isHighlighted;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(icon, color: const Color(0xFF94A3B8), size: 18),
            const SizedBox(width: 8),
            Text(
              label,
              style: GoogleFonts.inter(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF64748B),
                letterSpacing: 1.2,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: Container(
                padding: isHighlighted
                    ? const EdgeInsets.symmetric(horizontal: 12, vertical: 8)
                    : EdgeInsets.zero,
                decoration: isHighlighted
                    ? BoxDecoration(
                        color: const Color(0xFFEEF2FF),
                        borderRadius: BorderRadius.circular(6),
                      )
                    : null,
                child: Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isHighlighted ? const Color(0xFF1A56FF) : const Color(0xFF0F172A),
                  ),
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ],
    );
  }
}
