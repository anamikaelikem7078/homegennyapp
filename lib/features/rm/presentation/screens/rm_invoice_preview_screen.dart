import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

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
  ConsumerState<RmInvoicePreviewScreen> createState() => _RmInvoicePreviewScreenState();
}

class _RmInvoicePreviewScreenState extends ConsumerState<RmInvoicePreviewScreen> {
  late DateTime _month = DateTime(DateTime.now().year, DateTime.now().month);
  bool _generating = false;

  @override
  Widget build(BuildContext context) {
    final params = StaffPeriodParams(staffId: widget.staffId, month: _month.month, year: _month.year);
    final previewAsync = ref.watch(rmInvoicePreviewProvider(params));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      appBar: AppBar(
        backgroundColor: RmTheme.offWhite,
        elevation: 0,
        title: const Text('Invoice Preview'),
        actions: [
          IconButton(icon: const Icon(Icons.chevron_left), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month - 1))),
          Center(child: Text('${_month.month}/${_month.year}')),
          IconButton(icon: const Icon(Icons.chevron_right), onPressed: () => setState(() => _month = DateTime(_month.year, _month.month + 1))),
        ],
      ),
      body: AsyncValueWidget<InvoicePreview>(
        value: previewAsync,
        onRetry: () => ref.invalidate(rmInvoicePreviewProvider(params)),
        errorTitle: 'Could not load preview',
        builder: (preview) => SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(preview.staffName ?? preview.staffId, style: RmTheme.headline(context).copyWith(fontSize: 20)),
              if (preview.staffCode != null) Text(preview.staffCode!, style: RmTheme.body(context)),
              const SizedBox(height: 20),
              _row('Monthly salary', '₹${preview.monthlySalary}'),
              _row('Monthly management fee', '₹${preview.monthlyManagementFee}'),
              _row('Present days', '${preview.presentDays}'),
              _row('Absent days', '${preview.absentDays}'),
              _row('Leave days', '${preview.leaveDays}'),
              _row('Overtime days', '${preview.overtimeDays}'),
              _row('Billable days', '${preview.billableDays} / ${preview.daysInMonth}'),
              _row('Prorated gross', '₹${preview.proratedGross}'),
              _row('Prorated management fee', '₹${preview.proratedManagementFee}'),
              const Divider(height: 32),
              Text('Payroll calculation', style: RmTheme.title(context)),
              const SizedBox(height: 8),
              _row('Gross salary', '₹${preview.calculation.grossSalary}'),
              _row('ESIC (employee)', '₹${preview.calculation.esicEmployee}'),
              _row('ESIC (employer)', '₹${preview.calculation.esicEmployer}'),
              _row('PF (employee)', '₹${preview.calculation.pfEmployee}'),
              _row('PF (employer)', '₹${preview.calculation.pfEmployer}'),
              _row('Net salary', '₹${preview.calculation.netSalary}'),
              _row('GST on fee', '₹${preview.calculation.gstOnFee}'),
              _row('Client total charge', '₹${preview.calculation.clientTotalCharge}', bold: true),
              const SizedBox(height: 24),
              if (preview.alreadyGenerated)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: RmTheme.emeraldGreen.withOpacity(0.1), borderRadius: BorderRadius.circular(8)),
                  child: Text('Invoice already generated: ${preview.invoiceId}'),
                )
              else
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: FilledButton(
                    onPressed: _generating ? null : () => _generate(preview),
                    style: FilledButton.styleFrom(backgroundColor: RmTheme.electricBlue),
                    child: _generating
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Generate Invoice'),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate(InvoicePreview preview) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Generate Invoice?'),
        content: Text('This will run payroll for ${_month.month}/${_month.year} and cannot be undone if it succeeds.'),
        actions: [
          TextButton(onPressed: () => Navigator.of(dialogContext).pop(false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.of(dialogContext).pop(true), child: const Text('Generate')),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _generating = true);
    final result = await ref.read(rmRepositoryProvider).generateInvoice(widget.staffId, month: _month.month, year: _month.year);
    if (!mounted) return;
    setState(() => _generating = false);
    result.fold(
      onSuccess: (invoice) {
        ref.invalidate(rmInvoicePreviewProvider(StaffPeriodParams(staffId: widget.staffId, month: _month.month, year: _month.year)));
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Invoice ${invoice.invoiceNumber} generated'), backgroundColor: RmTheme.emeraldGreen));
      },
      onError: (f) {
        // Handle duplicate-generation and other backend errors gracefully — surface the real message.
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(f.message), backgroundColor: RmTheme.crimsonDanger));
      },
    );
  }

  Widget _row(String label, String value, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: RmTheme.textSecondary)),
          Text(value, style: TextStyle(fontWeight: bold ? FontWeight.w800 : FontWeight.w600)),
        ],
      ),
    );
  }
}
