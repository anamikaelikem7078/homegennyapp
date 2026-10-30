import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Saves a downloaded payslip PDF to a temp file and opens the share sheet.
Future<void> _saveAndSharePayslipPdf(List<int> bytes, String label) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/payslip-$label.pdf');
  await file.writeAsBytes(bytes);
  await Share.shareXFiles([XFile(file.path)], text: 'Payslip — $label');
}

Future<void> _downloadPayslip(BuildContext context, WidgetRef ref, String payslipRef, String label) async {
  final result = await ref.read(staffRepositoryProvider).downloadPayslipPdf(payslipRef);
  if (!context.mounted) return;
  switch (result) {
    case Success(data: final bytes):
      await _saveAndSharePayslipPdf(bytes, label);
      if (!context.mounted) return;
      context.showDsSnackBar('Payslip downloaded', type: DsSnackBarType.success);
    case Error(failure: final f):
      context.showDsSnackBar(f.message, type: DsSnackBarType.error);
  }
}

String _titleCase(String key) {
  final spaced = key.replaceAllMapped(RegExp('([A-Z])'), (m) => ' ${m.group(1)}');
  return spaced[0].toUpperCase() + spaced.substring(1);
}

/// Parses "₹12,345.50" style strings for proportional bars.
double _amount(String s) => double.tryParse(s.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0;

void _back(BuildContext context, [String fallback = StaffRoutes.home]) =>
    context.canPop() ? context.pop() : context.go(fallback);

String _currentFy() {
  final n = DateTime.now();
  final start = n.month >= 4 ? n.year : n.year - 1;
  return 'FY ${start % 100}-${(start + 1) % 100}';
}

/// "1 client pending" — clients of the month Finance hasn't approved yet.
String _pendingLabel(int n) => '$n ${n == 1 ? 'client' : 'clients'} pending';

/// A month Finance is still checking — not a payslip yet, so not tappable.
class _AwaitingTile extends StatelessWidget {
  const _AwaitingTile({required this.period});
  final SalaryPeriod period;

  @override
  Widget build(BuildContext context) {
    return DsListCard(
      icon: Icons.hourglass_top_rounded,
      iconColor: AppColors.warning,
      title: '${period.monthName} salary — being checked by Finance',
      subtitle: '${period.label} · the slip appears once it is approved',
    );
  }
}

/// The "Arrears" line, with the server's reason under it. Arrears are
/// already inside the net amount.
class _ArrearsCard extends StatelessWidget {
  const _ArrearsCard({required this.amount, this.note});
  final double amount;
  final String? note;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const DsIconTile(Icons.add_circle_rounded, size: 40),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Arrears',
                  style: GoogleFonts.plusJakartaSans(fontSize: 14, fontWeight: FontWeight.w700, color: AppColors.lightTextPrimary),
                ),
                if (note != null && note!.isNotEmpty)
                  Text(
                    note!,
                    style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 12),
          Text(
            '+ ${CurrencyFormatter.inr(amount)}',
            style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.success),
          ),
        ],
      ),
    );
  }
}

/// Big net-pay hero shared by salary + payslip screens.
class _NetHero extends StatelessWidget {
  const _NetHero({
    required this.month,
    required this.net,
    required this.status,
    this.pendingHouses = 0,
    this.footer,
  });
  final String month;
  final String net;
  final String status;
  final int pendingHouses;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return DsGradientCard(
      colors: DsGradientCard.green,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsGlassPill(month.toUpperCase(), icon: Icons.calendar_month_rounded),
                    const SizedBox(height: 12),
                    Text(
                      'Net pay',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.85),
                      ),
                    ),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerLeft,
                      child: Text(
                        net.replaceAll('₹', '₹ '),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 36,
                          height: 1.15,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -1,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (pendingHouses > 0)
                      Text(
                        _pendingLabel(pendingHouses),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: AppColors.sunYellow,
                        ),
                      ),
                    const SizedBox(height: 6),
                    DsGlassPill(status.toUpperCase(), icon: Icons.check_circle_rounded),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              const DsFloatingIconTile(icon: Icons.payments_rounded),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}

/// Salary summary screen — the latest month, or [period] when opened for a
/// specific one (e.g. from a "Salary slip ready" notification).
class StaffSalaryScreen extends ConsumerWidget {
  const StaffSalaryScreen({super.key, this.period});
  final SalaryPeriod? period;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final provider = staffSalarySummaryProvider(period);
    final summary = ref.watch(provider);

    final actions = [
      DsListCard(
        margin: EdgeInsets.zero,
        icon: Icons.history_rounded,
        title: 'Payslip history',
        subtitle: 'View and download past earnings',
        onTap: () => context.push(StaffRoutes.salaryHistory),
      ),
      DsListCard(
        margin: EdgeInsets.zero,
        icon: Icons.account_balance_rounded,
        title: 'Bank details',
        subtitle: 'Your salary deposit account',
        onTap: () => context.push(StaffRoutes.bankDetails),
      ),
      DsListCard(
        margin: EdgeInsets.zero,
        icon: Icons.receipt_long_rounded,
        title: 'Tax declaration',
        subtitle: 'Submit investment proofs for ${_currentFy()}',
        onTap: () => context.push(StaffRoutes.taxDeclaration),
      ),
    ];

    return DsPage(
      title: 'Salary',
      subtitle: 'Your earnings overview',
      onBack: () => _back(context),
      onRefresh: () async => ref.invalidate(provider),
      body: dsAsyncBody(
        summary,
        onRetry: () => ref.invalidate(provider),
        builder: (s) {
          final awaiting = [
            if (s.awaitingApproval.isNotEmpty) ...[
              const DsSection('Being checked'),
              for (final p in s.awaitingApproval) _AwaitingTile(period: p),
            ],
          ];
          if (!s.hasPayslips) {
            return [
              // The server's message is shown as is (e.g. "Your salary for
              // 11/2026 is being checked by Finance…").
              DsEmptyBlock(
                icon: Icons.payments_rounded,
                title: period?.label ?? 'No payslip yet',
                message: s.emptyMessage ?? 'Your salary details will appear here once payroll runs for the first time.',
              ),
              ...awaiting,
              const DsSection('Quick actions'),
              DsAdaptiveGrid(children: actions),
            ];
          }
          final gross = _amount(s.gross);
          final ded = _amount(s.deductions);
          final net = _amount(s.net);
          return [
            _NetHero(
              month: s.month,
              net: s.net,
              status: s.status,
              pendingHouses: s.pendingHouses,
              footer: s.ref == null
                  ? null
                  : Row(
                      children: [
                        Expanded(
                          child: DsHeroPillButton(
                            label: 'Download',
                            icon: Icons.download_rounded,
                            onPressed: () => _downloadPayslip(context, ref, s.ref!, s.month),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: DsHeroPillButton(
                            label: 'Details',
                            icon: Icons.receipt_long_rounded,
                            onPressed: () => context.push(StaffRoutes.payslip(s.ref!)),
                          ),
                        ),
                      ],
                    ),
            ),
            const DsSection('Breakdown'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(),
              child: Column(
                children: [
                  _BarRow(label: 'Gross pay', value: s.gross, fraction: 1, color: AppColors.primary, icon: Icons.trending_up_rounded),
                  const SizedBox(height: 14),
                  _BarRow(
                    label: 'Deductions',
                    value: s.deductions,
                    fraction: gross == 0 ? 0 : ded / gross,
                    color: AppColors.error,
                    icon: Icons.trending_down_rounded,
                  ),
                  if (s.arrears > 0) ...[
                    const SizedBox(height: 14),
                    _BarRow(
                      label: 'Arrears',
                      value: CurrencyFormatter.inr(s.arrears),
                      fraction: gross == 0 ? 0 : s.arrears / gross,
                      color: AppColors.primary,
                      icon: Icons.add_circle_rounded,
                    ),
                  ],
                  const SizedBox(height: 14),
                  // net = gross − deductions + arrears
                  _BarRow(
                    label: 'Net pay',
                    value: s.net,
                    fraction: gross == 0 ? 0 : net / gross,
                    color: AppColors.success,
                    icon: Icons.account_balance_wallet_rounded,
                  ),
                ],
              ),
            ),
            if (s.arrears > 0) ...[
              const SizedBox(height: 12),
              _ArrearsCard(amount: s.arrears, note: s.arrearsNote),
            ],
            if (s.houses.isNotEmpty) ...[
              DsSection('Earned from', trailing: DsPill('${s.houses.length}')),
              for (final h in s.houses) _HouseTile(house: h),
            ],
            ...awaiting,
            const DsSection('Quick actions'),
            DsAdaptiveGrid(children: actions),
          ];
        },
      ),
    );
  }
}

class _BarRow extends StatelessWidget {
  const _BarRow({required this.label, required this.value, required this.fraction, required this.color, required this.icon});
  final String label;
  final String value;
  final double fraction;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Row(
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                label,
                style: GoogleFonts.plusJakartaSans(fontSize: 13.5, fontWeight: FontWeight.w600, color: AppColors.lightTextSecondary),
              ),
            ),
            Text(
              value.replaceAll('₹', '₹ '),
              style: GoogleFonts.plusJakartaSans(fontSize: 15, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: fraction.clamp(0, 1).toDouble()),
            duration: 900.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => LinearProgressIndicator(
              value: v,
              minHeight: 7,
              backgroundColor: AppColors.lightSurfaceVariant,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

class _HouseTile extends StatelessWidget {
  const _HouseTile({required this.house});
  final SalaryHouse house;

  @override
  Widget build(BuildContext context) {
    return DsListCard(
      icon: Icons.home_work_rounded,
      title: house.clientName,
      subtitle: '${house.placementType} · ${house.worked}',
      trailing: Text(
        CurrencyFormatter.inr(house.grossSalary),
        style: GoogleFonts.plusJakartaSans(fontSize: 14.5, fontWeight: FontWeight.w800, color: AppColors.lightTextPrimary),
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
    final p = payslip.valueOrNull;

    return DsPage(
      title: 'Payslip',
      subtitle: p?.month,
      onBack: () => _back(context, StaffRoutes.salary),
      onRefresh: () async => ref.invalidate(staffPayslipProvider(payslipId)),
      bottom: p == null
          ? null
          : DsGradientButton(
              label: 'Download PDF',
              icon: Icons.download_rounded,
              onPressed: () => _downloadPayslip(context, ref, p.ref, p.month),
            ),
      body: dsAsyncBody(
        payslip,
        onRetry: () => ref.invalidate(staffPayslipProvider(payslipId)),
        builder: (p) {
          final deductionRows = p.deductionBreakdown.entries.where((e) => e.value > 0).toList();
          return [
            _NetHero(month: p.month, net: p.amount, status: p.status, pendingHouses: p.pendingHouses),
            const DsSection('Earnings'),
            DsInfoCard(
              lines: [
                DsInfoLine(
                  Icons.account_balance_wallet_rounded,
                  p.presentDays != null ? '${p.presentDays} days paid' : 'Gross salary',
                  p.grossAmount.replaceAll('₹', '₹ '),
                ),
              ],
            ),
            if (p.arrears > 0) ...[
              const SizedBox(height: 12),
              _ArrearsCard(amount: p.arrears, note: p.arrearsNote),
            ],
            if (deductionRows.isNotEmpty) ...[
              DsSection('Deductions', trailing: DsPill(p.deductionsAmount, color: AppColors.error)),
              DsInfoCard(
                lines: [
                  for (final e in deductionRows)
                    DsInfoLine(
                      Icons.remove_circle_rounded,
                      _titleCase(e.key),
                      '- ${CurrencyFormatter.inr(e.value)}',
                      valueColor: AppColors.error,
                    ),
                ],
              ),
            ],
            if (p.houses.isNotEmpty) ...[
              const DsSection('Earned from'),
              for (final h in p.houses) _HouseTile(house: h),
            ],
            const DsSection('Summary'),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: dsCardDecoration(color: const Color(0xFFF0FDF4), border: AppColors.success.withValues(alpha: 0.25)),
              child: Column(
                children: [
                  _summaryRow('Gross pay', p.grossAmount),
                  const SizedBox(height: 8),
                  _summaryRow('Total deductions', '- ${p.deductionsAmount}', color: AppColors.error),
                  if (p.arrears > 0) ...[
                    const SizedBox(height: 8),
                    _summaryRow('Arrears', '+ ${CurrencyFormatter.inr(p.arrears)}', color: AppColors.success),
                  ],
                  const Divider(height: 22, color: AppColors.lightBorder),
                  _summaryRow('Net payable', p.amount, bold: true, color: AppColors.success),
                ],
              ),
            ),
          ];
        },
      ),
    );
  }

  static Widget _summaryRow(String label, String value, {bool bold = false, Color? color}) => Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: bold ? 15 : 13.5,
                fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                color: bold ? AppColors.lightTextPrimary : AppColors.lightTextSecondary,
              ),
            ),
          ),
          Text(
            value.replaceAll('₹', '₹ '),
            style: GoogleFonts.plusJakartaSans(
              fontSize: bold ? 18 : 14,
              fontWeight: FontWeight.w800,
              color: color ?? AppColors.lightTextPrimary,
            ),
          ),
        ],
      );
}

/// Salary history list.
class StaffSalaryHistoryScreen extends ConsumerWidget {
  const StaffSalaryHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(staffPayslipHistoryProvider);

    return DsPage(
      title: 'Salary history',
      subtitle: 'All your payslips',
      onBack: () => _back(context, StaffRoutes.salary),
      onRefresh: () async => ref.invalidate(staffPayslipHistoryProvider),
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(staffPayslipHistoryProvider),
        builder: (h) {
          final list = h.payslips;
          final awaiting = [
            if (h.awaitingApproval.isNotEmpty) ...[
              const DsSection('Being checked'),
              for (final p in h.awaitingApproval) _AwaitingTile(period: p),
            ],
          ];
          if (list.isEmpty) {
            return [
              const DsEmptyBlock(
                icon: Icons.receipt_long_rounded,
                title: 'No payslips yet',
                message: 'Payslips appear here once Finance approves each month.',
              ),
              ...awaiting,
            ];
          }
          final total = list.fold<double>(0, (a, p) => a + _amount(p.amount));
          final max = list.map((p) => _amount(p.amount)).fold<double>(0, (a, b) => b > a ? b : a);
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(child: DsGlassStat(value: '${list.length}', label: 'Payslips', icon: Icons.receipt_long_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                    flex: 2,
                    child: DsGlassStat(value: CurrencyFormatter.inr(total), label: 'Total earned', icon: Icons.savings_rounded),
                  ),
                ],
              ),
            ),
            ...awaiting,
            const DsSection('Payslips'),
            for (var i = 0; i < list.length; i++)
              _PayslipTile(payslip: list[i], fraction: max == 0 ? 0 : _amount(list[i].amount) / max)
                  .animate(delay: (45 * i.clamp(0, 10)).ms)
                  .fadeIn(duration: 280.ms)
                  .slideX(begin: 0.05, end: 0),
          ];
        },
      ),
    );
  }
}

class _PayslipTile extends StatelessWidget {
  const _PayslipTile({required this.payslip, required this.fraction});
  final Payslip payslip;
  final double fraction;

  @override
  Widget build(BuildContext context) {
    final p = payslip;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: () => context.push(StaffRoutes.payslip(p.ref)),
          child: Ink(
            padding: const EdgeInsets.all(14),
            decoration: dsCardDecoration(),
            child: Column(
              children: [
                Row(
                  children: [
                    const DsIconTile(Icons.receipt_rounded, size: 44),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            p.month,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.lightTextSecondary,
                            ),
                          ),
                          Text(
                            p.amount.replaceAll('₹', '₹ '),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                          if (p.pendingHouses > 0)
                            Text(
                              _pendingLabel(p.pendingHouses),
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.warning,
                              ),
                            ),
                          if (p.arrears > 0)
                            Text(
                              'Includes ${CurrencyFormatter.inr(p.arrears)} arrears',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.lightTextSecondary,
                              ),
                            ),
                        ],
                      ),
                    ),
                    DsPill(p.status, color: AppColors.success),
                    const SizedBox(width: 4),
                    const Icon(Icons.chevron_right_rounded, color: AppColors.primary),
                  ],
                ),
                const SizedBox(height: 10),
                ClipRRect(
                  borderRadius: BorderRadius.circular(3),
                  child: LinearProgressIndicator(
                    value: fraction.clamp(0, 1).toDouble(),
                    minHeight: 5,
                    backgroundColor: AppColors.lightSurfaceVariant,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
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
  bool _isEditing = false;
  bool _saving = false;

  final _holderController = TextEditingController();
  final _numberController = TextEditingController();
  final _bankNameController = TextEditingController();
  final _ifscController = TextEditingController();

  @override
  void dispose() {
    _holderController.dispose();
    _numberController.dispose();
    _bankNameController.dispose();
    _ifscController.dispose();
    super.dispose();
  }

  /// Pre-fills the editable form from the last known values. The account
  /// number always comes back masked from the server — the field starts
  /// blank so the user re-enters the full number rather than editing a
  /// masked value.
  void _startEditing(BankDetails b) {
    _holderController.text = b.accountHolderName;
    _numberController.text = '';
    _bankNameController.text = b.bankName;
    _ifscController.text = b.ifsc;
    setState(() => _isEditing = true);
  }

  Future<void> _save() async {
    if (_holderController.text.trim().isEmpty ||
        _numberController.text.trim().isEmpty ||
        _ifscController.text.trim().isEmpty) {
      context.showDsSnackBar('Account holder, account number and IFSC are required', type: DsSnackBarType.warning);
      return;
    }
    setState(() => _saving = true);
    final result = await ref.read(staffRepositoryProvider).updateBankDetails(
          accountHolderName: _holderController.text.trim(),
          accountNumber: _numberController.text.trim(),
          ifsc: _ifscController.text.trim().toUpperCase(),
          bankName: _bankNameController.text.trim().isEmpty ? null : _bankNameController.text.trim(),
        );
    if (!mounted) return;
    setState(() {
      _saving = false;
      _isEditing = false;
    });
    result.fold(
      onSuccess: (_) {
        ref.invalidate(staffBankDetailsProvider);
        context.showDsSnackBar('Bank details updated — verification will be re-run', type: DsSnackBarType.success);
      },
      // Surfaces the server's own message (e.g. a 400 for a bad IFSC format)
      // rather than duplicating IFSC validation on the client.
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final bank = ref.watch(staffBankDetailsProvider);
    final b = bank.valueOrNull;

    return DsPage(
      title: 'Bank details',
      subtitle: 'Where your salary is deposited',
      onBack: () => _back(context, StaffRoutes.salary),
      onRefresh: () async => ref.invalidate(staffBankDetailsProvider),
      bottom: b == null
          ? null
          : _isEditing
              ? Row(
                  children: [
                    Expanded(
                      flex: 2,
                      child: DsOutlineButton(
                        label: 'Cancel',
                        onPressed: _saving ? null : () => setState(() => _isEditing = false),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      flex: 3,
                      child: DsGradientButton(
                        label: 'Save details',
                        icon: Icons.check_rounded,
                        isLoading: _saving,
                        onPressed: _saving ? null : _save,
                      ),
                    ),
                  ],
                )
              : DsOutlineButton(
                  label: 'Edit details',
                  icon: Icons.edit_rounded,
                  onPressed: () => _startEditing(b),
                ),
      body: dsAsyncBody(
        bank,
        onRetry: () => ref.invalidate(staffBankDetailsProvider),
        builder: (b) => [
          // Bank-card style summary.
          AspectRatio(
            aspectRatio: 1.75,
            child: DsGradientCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.bankName.isEmpty ? 'Bank account' : b.bankName,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(fontSize: 16, fontWeight: FontWeight.w800, color: Colors.white),
                        ),
                      ),
                      DsGlassPill(
                        b.verified ? 'VERIFIED' : 'PENDING',
                        icon: b.verified ? Icons.verified_rounded : Icons.hourglass_top_rounded,
                      ),
                    ],
                  ),
                  const Spacer(),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      b.accountNumberMasked.isNotEmpty ? b.accountNumberMasked : '••••  ••••  ${b.last4}',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 22,
                        letterSpacing: 1.5,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          b.accountHolderName.toUpperCase(),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            letterSpacing: 1,
                            fontWeight: FontWeight.w700,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ),
                      Text(
                        b.ifsc,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13, fontWeight: FontWeight.w800, color: AppColors.sunYellow),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 14),
          if (_isEditing) ...[
            const DsSection('Update account'),
            DsLabeledField(
              label: 'Account holder',
              controller: _holderController,
              icon: Icons.person_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            DsLabeledField(
              label: 'Account number',
              controller: _numberController,
              icon: Icons.credit_card_rounded,
              hint: 'Enter full account number',
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
            ),
            const SizedBox(height: 14),
            DsLabeledField(
              label: 'Bank name',
              optional: true,
              controller: _bankNameController,
              icon: Icons.account_balance_rounded,
              textCapitalization: TextCapitalization.words,
            ),
            const SizedBox(height: 14),
            DsLabeledField(
              label: 'IFSC code',
              controller: _ifscController,
              icon: Icons.qr_code_rounded,
              hint: 'e.g. HDFC0000133',
              textCapitalization: TextCapitalization.characters,
              inputFormatters: [LengthLimitingTextInputFormatter(11)],
            ),
            const SizedBox(height: 8),
            Text(
              '11 characters: 4 letters, then 0, then 6 letters or numbers.',
              style: GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary),
            ),
          ] else ...[
            const DsSection('Account'),
            DsInfoCard(
              lines: [
                DsInfoLine(Icons.person_rounded, 'Account holder', b.accountHolderName),
                DsInfoLine(Icons.credit_card_rounded, 'Account number',
                    b.accountNumberMasked.isNotEmpty ? b.accountNumberMasked : '••••${b.last4}'),
                DsInfoLine(Icons.account_balance_rounded, 'Bank', b.bankName),
                DsInfoLine(Icons.qr_code_rounded, 'IFSC', b.ifsc, valueColor: AppColors.primary),
              ],
            ),
            const SizedBox(height: 14),
            DsNote(
              tone: b.verified ? DsNoteTone.success : DsNoteTone.warning,
              title: b.verified ? 'Verified account' : 'Pending verification',
              text: b.verified
                  ? 'Salary will be deposited here${b.verifiedAt != null ? ' · verified ${b.verifiedAt}' : ''}.'
                  : 'We\'re verifying this account. This usually takes a day.',
            ),
          ],
          const SizedBox(height: 14),
          const DsNote(
            title: 'Encrypted storage',
            text: 'Your bank details are encrypted and only used for salary payments.',
          ),
        ],
      ),
    );
  }
}
