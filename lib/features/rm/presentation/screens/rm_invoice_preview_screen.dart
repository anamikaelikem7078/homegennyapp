import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../core/utils/result.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Invoice preview + generation. Every number here comes straight from the
/// backend (`GET /rm/attendance/:staffId/invoice-preview`) — the app never
/// recomputes the calculation client-side.
class RmInvoicePreviewScreen extends ConsumerStatefulWidget {
  const RmInvoicePreviewScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmInvoicePreviewScreen> createState() =>
      _RmInvoicePreviewScreenState();
}

class _RmInvoicePreviewScreenState extends ConsumerState<RmInvoicePreviewScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _generating = false;

  final List<String> _monthNames = [
    'January', 'February', 'March', 'April', 'May', 'June',
    'July', 'August', 'September', 'October', 'November', 'December'
  ];

  @override
  Widget build(BuildContext context) {
    final params = StaffPeriodParams(
      staffId: widget.staffId,
      month: _month.month,
      year: _month.year,
    );
    final previewAsync = ref.watch(rmInvoicePreviewProvider(params));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: RmTheme.textPrimary),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Invoice Preview',
          style: RmTheme.headline(context).copyWith(fontSize: 20),
        ),
      ),
      body: Column(
        children: [
          // ── Premium Month Selector Banner ──
          _buildMonthSelector(),

          Expanded(
            child: AsyncValueWidget<InvoicePreview>(
              value: previewAsync,
              onRetry: () => ref.invalidate(rmInvoicePreviewProvider(params)),
              errorTitle: 'Could not load preview',
              builder: (preview) => SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Staff Profile Header ──
                    _buildStaffHeader(preview),

                    const SizedBox(height: 16),

                    // ── Attendance Metrics Grid ──
                    _buildAttendanceGrid(preview),

                    const SizedBox(height: 16),

                    // ── Base Contracts & Proration Card ──
                    _buildBaseContractsCard(preview),

                    const SizedBox(height: 16),

                    // ── Payroll & Taxes Card ──
                    _buildPayrollCard(preview),

                    const SizedBox(height: 20),

                    // ── Client Total Charge Hero Banner ──
                    _buildTotalHeroCard(preview),

                    const SizedBox(height: 24),

                    // ── Invoice Generation Footer ──
                    _buildActionFooter(preview),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Component Builders ───────────────────────────────────────────────────

  Widget _buildMonthSelector() {
    final monthName = _monthNames[_month.month - 1];
    return Container(
      margin: const EdgeInsets.fromLTRB(20, 4, 20, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.2,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x03000000),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_left_rounded, size: 24),
            color: RmTheme.textPrimary,
            onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month - 1),
            ),
            splashRadius: 20,
          ),
          Text(
            '$monthName ${_month.year}',
            style: GoogleFonts.inter(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: RmTheme.electricBlue,
            ),
          ),
          IconButton(
            icon: const Icon(Icons.keyboard_arrow_right_rounded, size: 24),
            color: RmTheme.textPrimary,
            onPressed: () => setState(
              () => _month = DateTime(_month.year, _month.month + 1),
            ),
            splashRadius: 20,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms)
        .slideY(begin: -0.05, end: 0, duration: 300.ms);
  }

  Widget _buildStaffHeader(InvoicePreview preview) {
    final staffName = preview.staffName ?? preview.staffId;
    final firstLetter = staffName.isNotEmpty ? staffName[0].toUpperCase() : '?';

    return Row(
      children: [
        CircleAvatar(
          radius: 24,
          backgroundColor: RmTheme.electricBlue.withValues(alpha: 0.1),
          child: Text(
            firstLetter,
            style: GoogleFonts.inter(
              color: RmTheme.electricBlue,
              fontWeight: FontWeight.bold,
              fontSize: 18,
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                staffName,
                style: RmTheme.title(context).copyWith(
                  fontSize: 18,
                  color: RmTheme.textPrimary,
                ),
              ),
              if (preview.staffCode != null)
                Text(
                  preview.staffCode!,
                  style: RmTheme.body(context).copyWith(fontSize: 13),
                ),
            ],
          ),
        ),
      ],
    )
        .animate()
        .fadeIn(delay: 50.ms, duration: 400.ms)
        .slideX(begin: -0.02, end: 0, delay: 50.ms, duration: 400.ms);
  }

  Widget _buildAttendanceGrid(InvoicePreview preview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Attendance Breakdown',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: RmTheme.textPrimary,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: RmTheme.electricBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${preview.billableDays} / ${preview.daysInMonth} Billable',
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: RmTheme.electricBlue,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _buildAttendanceCell(
                  label: 'Present',
                  value: '${preview.presentDays}',
                  color: RmTheme.emeraldGreen,
                ),
              ),
              Expanded(
                child: _buildAttendanceCell(
                  label: 'Absent',
                  value: '${preview.absentDays}',
                  color: RmTheme.crimsonDanger,
                ),
              ),
              Expanded(
                child: _buildAttendanceCell(
                  label: 'Leave',
                  value: '${preview.leaveDays}',
                  color: RmTheme.textSecondary,
                ),
              ),
              Expanded(
                child: _buildAttendanceCell(
                  label: 'Overtime',
                  value: '${preview.overtimeDays}',
                  color: RmTheme.amberWarning,
                ),
              ),
            ],
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 100.ms, duration: 400.ms)
        .slideY(begin: 0.04, end: 0, delay: 100.ms, duration: 400.ms);
  }

  Widget _buildAttendanceCell({
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 22,
            fontWeight: FontWeight.w800,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: RmTheme.textSecondary,
          ),
        ),
      ],
    );
  }

  Widget _buildBaseContractsCard(InvoicePreview preview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Base & Proration Details',
            style: GoogleFonts.libreCaslonText(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('Monthly Salary', '₹${preview.monthlySalary}'),
          const Divider(height: 20, thickness: 0.6),
          _buildRow('Monthly Management Fee', '₹${preview.monthlyManagementFee}'),
          const Divider(height: 20, thickness: 0.6),
          _buildRow(
            'Prorated Gross Salary',
            '₹${preview.proratedGross}',
            highlightColor: RmTheme.electricBlue,
          ),
          const Divider(height: 20, thickness: 0.6),
          _buildRow(
            'Prorated Management Fee',
            '₹${preview.proratedManagementFee}',
            highlightColor: RmTheme.electricBlue,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 150.ms, duration: 400.ms)
        .slideY(begin: 0.04, end: 0, delay: 150.ms, duration: 400.ms);
  }

  Widget _buildPayrollCard(InvoicePreview preview) {
    final calc = preview.calculation;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: RmTheme.cardSurface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: RmTheme.borderSubtle.withValues(alpha: 0.5),
          width: 1.5,
        ),
        boxShadow: const [
          BoxShadow(
            color: Color(0x04000000),
            blurRadius: 10,
            offset: Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Payroll Calculation',
            style: GoogleFonts.libreCaslonText(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: RmTheme.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          _buildRow('Gross Salary', '₹${calc.grossSalary}'),
          const Divider(height: 16, thickness: 0.6),
          _buildRow('ESIC (Employee contribution)', '₹${calc.esicEmployee}'),
          const Divider(height: 16, thickness: 0.6),
          _buildRow('ESIC (Employer contribution)', '₹${calc.esicEmployer}'),
          const Divider(height: 16, thickness: 0.6),
          _buildRow('PF (Employee contribution)', '₹${calc.pfEmployee}'),
          const Divider(height: 16, thickness: 0.6),
          _buildRow('PF (Employer contribution)', '₹${calc.pfEmployer}'),
          const Divider(height: 16, thickness: 0.6),
          _buildRow('GST on Fee', '₹${calc.gstOnFee}'),
          const Divider(height: 20, thickness: 0.8),
          _buildRow(
            'Net Salary Transferred',
            '₹${calc.netSalary}',
            highlightColor: RmTheme.emeraldGreen,
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 200.ms, duration: 400.ms)
        .slideY(begin: 0.04, end: 0, delay: 200.ms, duration: 400.ms);
  }

  Widget _buildTotalHeroCard(InvoicePreview preview) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            RmTheme.electricBlue,
            RmTheme.electricBlue.withValues(alpha: 0.85),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withValues(alpha: 0.25),
            blurRadius: 15,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'CLIENT TOTAL CHARGE',
                style: GoogleFonts.inter(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: Colors.white.withValues(alpha: 0.8),
                  letterSpacing: 1.0,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Inclusive of all proration & GST',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
          Text(
            '₹${preview.calculation.clientTotalCharge}',
            style: GoogleFonts.inter(
              fontSize: 26,
              fontWeight: FontWeight.w900,
              color: Colors.white,
            ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(delay: 250.ms, duration: 450.ms)
        .scale(begin: const Offset(0.96, 0.96), end: const Offset(1.0, 1.0), delay: 250.ms, duration: 450.ms);
  }

  Widget _buildActionFooter(InvoicePreview preview) {
    if (preview.alreadyGenerated) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: RmTheme.emeraldGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: RmTheme.emeraldGreen.withValues(alpha: 0.2),
            width: 1.2,
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: RmTheme.emeraldGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Invoice generated: ${preview.invoiceId}',
                style: GoogleFonts.inter(
                  color: const Color(0xFF047857), // Dark emerald green
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
    }

    return SizedBox(
      width: double.infinity,
      height: 54,
      child: FilledButton(
        onPressed: _generating ? null : () => _generate(preview),
        style: FilledButton.styleFrom(
          backgroundColor: RmTheme.electricBlue,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          elevation: 2,
        ),
        child: _generating
            ? const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  color: Colors.white,
                ),
              )
            : Text(
                'Generate Invoice',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
      ),
    ).animate().fadeIn(delay: 300.ms, duration: 300.ms);
  }

  Widget _buildRow(String label, String value, {Color? highlightColor}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: RmTheme.textSecondary,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: highlightColor != null ? 15.5 : 14.5,
            fontWeight: highlightColor != null ? FontWeight.w800 : FontWeight.w600,
            color: highlightColor ?? RmTheme.textPrimary,
          ),
        ),
      ],
    );
  }

  // ─── Logical Methods ───────────────────────────────────────────────────────

  Future<void> _generate(InvoicePreview preview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          'Generate Invoice?',
          style: RmTheme.title(context),
        ),
        content: Text(
          'This will run payroll for ${_month.month}/${_month.year} and cannot be undone if it succeeds.',
          style: GoogleFonts.inter(height: 1.4),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
            child: const Text('Generate'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _generating = true);
    final result = await ref
        .read(rmRepositoryProvider)
        .generateInvoice(widget.staffId, month: _month.month, year: _month.year);
    if (!mounted) return;
    setState(() => _generating = false);
    result.fold(
      onSuccess: (invoice) {
        ref.invalidate(
          rmInvoicePreviewProvider(
            StaffPeriodParams(
              staffId: widget.staffId,
              month: _month.month,
              year: _month.year,
            ),
          ),
        );
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Invoice ${invoice.invoiceNumber} generated'),
            backgroundColor: RmTheme.emeraldGreen,
          ),
        );
      },
      onError: (f) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(f.message),
            backgroundColor: RmTheme.crimsonDanger,
          ),
        );
      },
    );
  }
}
