import 'package:flutter/material.dart';
import 'package:homegennyapp/design_system/widgets/navigation/ds_navigation.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:flutter/services.dart';
import '../../../../core/exceptions/failures.dart';
import '../../../../design_system/widgets/buttons/ds_buttons.dart';
import '../../../../design_system/widgets/dialogs/ds_dialogs.dart';
import '../../../../design_system/widgets/feedback/ds_feedback.dart';
import '../widgets/rm_stage_ui.dart';
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

class _RmInvoicePreviewScreenState
    extends ConsumerState<RmInvoicePreviewScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _generating = false;

  static const _monthNames = [
    'January',
    'February',
    'March',
    'April',
    'May',
    'June',
    'July',
    'August',
    'September',
    'October',
    'November',
    'December',
  ];

  /// Horizontal page padding: tighter on small phones, roomier on large ones.
  double _hPad(BuildContext context) {
    final w = MediaQuery.sizeOf(context).width;
    if (w < 340) return 12;
    if (w < 400) return 16;
    return 20;
  }

  @override
  Widget build(BuildContext context) {
    final params = StaffPeriodParams(
      staffId: widget.staffId,
      month: _month.month,
      year: _month.year,
    );
    final previewAsync = ref.watch(rmInvoicePreviewProvider(params));
    final preview = previewAsync.valueOrNull;

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: Padding(
          padding: const EdgeInsets.only(left: 20),
          child: DsBackButton(onPressed: () => Navigator.of(context).pop()),
        ),
        titleSpacing: 0,
        leadingWidth: 64,
        toolbarHeight: 68,
        title: Text(
          'Invoice preview',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            letterSpacing: -0.4,
            color: RmTheme.textPrimary,
          ),
        ),
        actions: [SizedBox(width: _hPad(context))],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: EdgeInsets.fromLTRB(
                _hPad(context),
                16,
                _hPad(context),
                20,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 560),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildMonthSelector(preview),
                      const SizedBox(height: 16),
                      previewAsync.when(
                        loading: () => const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(child: CircularProgressIndicator()),
                        ),
                        error: (e, _) => _buildError(e, params),
                        data: (preview) => Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            _buildStaffCard(preview),
                            const SizedBox(height: 14),
                            _buildAttendanceCard(preview),
                            const SizedBox(height: 14),
                            _buildBaseCard(preview),
                            const SizedBox(height: 14),
                            _buildPayrollCard(preview),
                            const SizedBox(height: 14),
                            _buildTotalHeroCard(preview),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          if (preview != null) _buildBottomBar(preview),
        ],
      ),
    );
  }

  // ─── Shared pieces ────────────────────────────────────────────────────────

  BoxDecoration _cardDecoration() => BoxDecoration(
    color: RmTheme.cardSurface,
    borderRadius: BorderRadius.circular(22),
    border: Border.all(
      color: RmTheme.borderSubtle.withValues(alpha: 0.7),
      width: 1,
    ),
    boxShadow: RmTheme.subtleShadow,
  );

  Widget _cardTitle(String text, {IconData icon = Icons.receipt_long_rounded}) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: RmTheme.iconAccentSoft,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, size: 19, color: RmTheme.iconAccent),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              letterSpacing: -0.2,
              color: RmTheme.textPrimary,
            ),
          ),
        ),
      ],
    );
  }

  Widget _statusChip(bool generated) {
    final color = generated ? const Color(0xFF4ADE80) : const Color(0xFFFFD84D);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            generated ? 'Generated' : 'Draft',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Component builders ───────────────────────────────────────────────────

  void _shiftMonth(int delta) {
    HapticFeedback.selectionClick();
    setState(() => _month = DateTime(_month.year, _month.month + delta));
  }

  /// Gradient month picker card with glass arrows and a sliding month label.
  Widget _buildMonthSelector(InvoicePreview? preview) {
    final monthName = _monthNames[_month.month - 1];

    Widget arrow(IconData icon, String tip, VoidCallback onTap) => Material(
          color: Colors.white.withValues(alpha: 0.14),
          shape: CircleBorder(
            side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          ),
          child: InkWell(
            customBorder: const CircleBorder(),
            onTap: onTap,
            child: Tooltip(
              message: tip,
              child: SizedBox(
                width: 40,
                height: 40,
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
          ),
        );

    return Container(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withValues(alpha: 0.28),
            blurRadius: 22,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Row(
        children: [
          arrow(Icons.chevron_left_rounded, 'Previous month', () => _shiftMonth(-1)),
          Expanded(
            child: AnimatedSwitcher(
              duration: 300.ms,
              transitionBuilder: (child, anim) => FadeTransition(
                opacity: anim,
                child: SlideTransition(
                  position: Tween(
                    begin: const Offset(0, 0.3),
                    end: Offset.zero,
                  ).animate(anim),
                  child: child,
                ),
              ),
              child: Column(
                key: ValueKey(_month),
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(
                        Icons.calendar_month_rounded,
                        size: 18,
                        color: Color(0xFFFFD84D),
                      ),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          '$monthName ${_month.year}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  if (preview != null)
                    _statusChip(preview.alreadyGenerated)
                  else
                    Text(
                      'Billing period',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.75),
                      ),
                    ),
                ],
              ),
            ),
          ),
          arrow(Icons.chevron_right_rounded, 'Next month', () => _shiftMonth(1)),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.1, end: 0);
  }

  /// Friendly error: a missing confirmed placement is an expected state,
  /// not a crash, so it gets its own explanation.
  Widget _buildError(Object e, StaffPeriodParams params) {
    final message = e is Failure ? e.message : e.toString();
    final noPlacement = message.toLowerCase().contains('placement');

    return RmEmptyBlock(
      icon: noPlacement ? Icons.handshake_rounded : Icons.cloud_off_rounded,
      color: noPlacement ? RmTheme.iconAccent : RmTheme.crimsonDanger,
      title: noPlacement ? 'No confirmed placement' : 'Could not load preview',
      message: noPlacement
          ? 'An invoice can only be previewed once this staff member has a '
              'confirmed placement for the selected month.'
          : message,
      action: Row(
        children: [
          Expanded(
            child: DsOutlineButton(
              label: 'Prev month',
              icon: Icons.chevron_left_rounded,
              onPressed: () => _shiftMonth(-1),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: DsGradientButton(
              label: 'Retry',
              icon: Icons.refresh_rounded,
              onPressed: () => ref.invalidate(rmInvoicePreviewProvider(params)),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 350.ms).scaleXY(begin: 0.96, end: 1);
  }

  Widget _buildStaffCard(InvoicePreview preview) {
    final staffName = preview.staffName ?? preview.staffId;
    final firstLetter = staffName.isNotEmpty ? staffName[0].toUpperCase() : '?';

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: _cardDecoration(),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: RmTheme.electricBlue.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: RmTheme.electricBlue.withValues(alpha: 0.15),
              ),
            ),
            child: Text(
              firstLetter,
              style: GoogleFonts.plusJakartaSans(
                color: RmTheme.electricBlue,
                fontWeight: FontWeight.w800,
                fontSize: 22,
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: RmTheme.title(
                    context,
                  ).copyWith(fontSize: 20, color: RmTheme.textPrimary),
                ),
                if (preview.staffCode != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    preview.staffCode!,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      color: RmTheme.textSecondary,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 50.ms, duration: 300.ms);
  }

  Widget _buildAttendanceCard(InvoicePreview preview) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 8,
            children: [
              _cardTitle('Attendance', icon: Icons.event_available_rounded),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: RmTheme.electricBlue.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: RmTheme.electricBlue.withValues(alpha: 0.2),
                  ),
                ),
                child: Text(
                  '${preview.billableDays} / ${preview.daysInMonth} Billable',
                  style: GoogleFonts.plusJakartaSans(
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
              _statTile('Present', preview.presentDays, RmTheme.emeraldGreen),
              const SizedBox(width: 8),
              _statTile('Absent', preview.absentDays, RmTheme.crimsonDanger),
              const SizedBox(width: 8),
              _statTile('Leave', preview.leaveDays, RmTheme.textSecondary),
              const SizedBox(width: 8),
              _statTile('Overtime', preview.overtimeDays, RmTheme.amberWarning),
            ],
          ),
        ],
      ),
    ).animate().fadeIn(delay: 100.ms, duration: 300.ms);
  }

  Widget _statTile(String label, int value, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: color.withValues(alpha: 0.18),
          ),
        ),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            children: [
              Text(
                '$value',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                label,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w500,
                  color: RmTheme.textSecondary,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBaseCard(InvoicePreview preview) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Base & proration', icon: Icons.account_balance_wallet_rounded),
          const SizedBox(height: 8),
          _buildRow('Monthly Salary', '₹${preview.monthlySalary}'),
          _buildRow(
            'Monthly Management Fee',
            '₹${preview.monthlyManagementFee}',
          ),
          _buildRow(
            'Prorated Gross Salary',
            '₹${preview.proratedGross}',
            highlightColor: RmTheme.electricBlue,
          ),
          _buildRow(
            'Prorated Management Fee',
            '₹${preview.proratedManagementFee}',
            highlightColor: RmTheme.electricBlue,
            last: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 150.ms, duration: 300.ms);
  }

  Widget _buildPayrollCard(InvoicePreview preview) {
    final calc = preview.calculation;
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      decoration: _cardDecoration(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _cardTitle('Payroll calculation', icon: Icons.calculate_rounded),
          const SizedBox(height: 8),
          _buildRow('Gross Salary', '₹${calc.grossSalary}'),
          _buildRow('ESIC (Employee contribution)', '₹${calc.esicEmployee}'),
          _buildRow('ESIC (Employer contribution)', '₹${calc.esicEmployer}'),
          _buildRow('PF (Employee contribution)', '₹${calc.pfEmployee}'),
          _buildRow('PF (Employer contribution)', '₹${calc.pfEmployer}'),
          _buildRow('GST on Fee', '₹${calc.gstOnFee}'),
          _buildRow(
            'Net Salary Transferred',
            '₹${calc.netSalary}',
            highlightColor: RmTheme.emeraldGreen,
            emphasize: true,
            last: true,
          ),
        ],
      ),
    ).animate().fadeIn(delay: 200.ms, duration: 300.ms);
  }

  Widget _buildTotalHeroCard(InvoicePreview preview) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [RmTheme.navy, Color(0xFF1238B8), RmTheme.electricBlue],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: RmTheme.electricBlue.withValues(alpha: 0.28),
            blurRadius: 18,
            offset: const Offset(0, 8),
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
                  'CLIENT TOTAL CHARGE',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                    letterSpacing: 1.0,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Inclusive of all proration & GST',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                '₹${preview.calculation.clientTotalCharge}',
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.8,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    ).animate().fadeIn(delay: 250.ms, duration: 350.ms);
  }

  /// Sticky bottom action area (CTA or "already generated" notice).
  Widget _buildBottomBar(InvoicePreview preview) {
    final Widget content;
    if (preview.alreadyGenerated) {
      content = Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: RmTheme.emeraldGreen.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: RmTheme.emeraldGreen.withValues(alpha: 0.25),
          ),
        ),
        child: Row(
          children: [
            const Icon(Icons.check_circle_rounded, color: RmTheme.emeraldGreen),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Invoice generated: ${preview.invoiceId}',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF047857),
                  fontWeight: FontWeight.w700,
                  fontSize: 13.5,
                ),
              ),
            ),
          ],
        ),
      );
    } else {
      content = DsGradientButton(
        label: 'Generate invoice',
        icon: Icons.receipt_long_rounded,
        isLoading: _generating,
        onPressed: _generating ? null : () => _generate(preview),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
        boxShadow: [
          BoxShadow(
            color: RmTheme.navy.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, -6),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(_hPad(context), 12, _hPad(context), 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 560),
              child: SizedBox(width: double.infinity, child: content),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildRow(
    String label,
    String value, {
    Color? highlightColor,
    bool emphasize = false,
    bool last = false,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 13),
      decoration: BoxDecoration(
        border: last
            ? null
            : Border(
                bottom: BorderSide(
                  color: RmTheme.borderSubtle.withValues(alpha: 0.7),
                ),
              ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: emphasize ? FontWeight.w700 : FontWeight.w400,
                color: emphasize ? RmTheme.textPrimary : RmTheme.textSecondary,
              ),
            ),
          ),
          const SizedBox(width: 12),
          Flexible(
            child: FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerRight,
              child: Text(
                value,
                maxLines: 1,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: highlightColor != null || emphasize
                      ? FontWeight.w700
                      : FontWeight.w600,
                  color: highlightColor ?? RmTheme.textPrimary,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ─── Logical Methods ───────────────────────────────────────────────────────

  Future<void> _generate(InvoicePreview preview) async {
    final confirmed = await DsConfirmationDialog.show(
      context: context,
      title: 'Generate invoice?',
      message: 'This will run payroll for ${_monthNames[_month.month - 1]} ${_month.year} and cannot be undone if it succeeds.',
      confirmLabel: 'Generate',
      icon: Icons.receipt_long_rounded,
    );
    if (confirmed != true) return;

    setState(() => _generating = true);
    final result = await ref
        .read(rmRepositoryProvider)
        .generateInvoice(
          widget.staffId,
          month: _month.month,
          year: _month.year,
        );
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
        DsSnackBar.show(
          context,
          message: 'Invoice ${invoice.invoiceNumber} generated',
          type: DsSnackBarType.success,
        );
      },
      onError: (f) {
        DsSnackBar.show(
          context,
          message: f.message,
          type: DsSnackBarType.error,
        );
      },
    );
  }
}
