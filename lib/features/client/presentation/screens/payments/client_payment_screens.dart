import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../core/extensions/context_extensions.dart';
import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

/// Saves a downloaded invoice HTML document to a temp file and opens the
/// share sheet — the invoice number names the file, the invoice's DB id is
/// what the download call itself used.
Future<void> _saveAndShareInvoiceHtml(String html, String invoiceNumber) async {
  final dir = await getTemporaryDirectory();
  final file = File('${dir.path}/invoice-$invoiceNumber.html');
  await file.writeAsString(html);
  await Share.shareXFiles([XFile(file.path)], text: 'Invoice $invoiceNumber');
}

/// Downloads [inv] and opens the share sheet, with snackbar feedback.
Future<void> _downloadInvoice(BuildContext context, WidgetRef ref, ClientInvoice inv) async {
  final result = await ref.read(clientRepositoryProvider).downloadInvoice(inv.invoiceId);
  if (!context.mounted) return;
  switch (result) {
    case Success(data: final html):
      await _saveAndShareInvoiceHtml(html, inv.invoiceNumber);
      if (!context.mounted) return;
      context.showDsSnackBar(context.l10n.statementDownloaded, type: DsSnackBarType.success);
    case Error(failure: final f):
      context.showDsSnackBar(f.message, type: DsSnackBarType.error);
  }
}

String _gatewayUri(ClientInvoice inv) => Uri(
      path: ClientRoutes.paymentGateway,
      queryParameters: {'invoiceId': inv.invoiceId, 'amount': inv.totalAmount.toString()},
    ).toString();

const _noInvoices = DsEmptyBlock(
  icon: Icons.receipt_long_rounded,
  title: 'No invoices yet',
  message: 'Invoices appear after your Relationship Manager approves shifts and Finance runs payroll.',
);

Color _paymentColor(ClientPaymentStatus s) => switch (s) {
      ClientPaymentStatus.paid => AppColors.success,
      ClientPaymentStatus.pending => AppColors.warning,
      ClientPaymentStatus.overdue => AppColors.error,
      ClientPaymentStatus.processing => AppColors.primary,
    };

/// Big amount hero shared by the payment screens.
class _AmountHero extends StatelessWidget {
  const _AmountHero({
    required this.label,
    required this.amount,
    this.pill,
    this.caption,
    this.icon = Icons.account_balance_wallet_rounded,
    this.footer,
  });

  final String label;
  final double amount;
  final String? pill;
  final String? caption;
  final IconData icon;
  final Widget? footer;

  @override
  Widget build(BuildContext context) {
    return DsGradientCard(
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
                    if (pill != null) ...[DsGlassPill(pill!), const SizedBox(height: 12)],
                    Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.8),
                      ),
                    ),
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: amount),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => FittedBox(
                        fit: BoxFit.scaleDown,
                        alignment: Alignment.centerLeft,
                        child: Text(
                          CurrencyFormatter.inr(v),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 36,
                            height: 1.15,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -1,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                    if (caption != null)
                      Text(
                        caption!,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.78),
                        ),
                      ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              DsFloatingIconTile(icon: icon),
            ],
          ),
          if (footer != null) ...[const SizedBox(height: 18), footer!],
        ],
      ),
    );
  }
}

/// Payments tab.
class ClientPaymentsTabScreen extends ConsumerStatefulWidget {
  const ClientPaymentsTabScreen({super.key});

  @override
  ConsumerState<ClientPaymentsTabScreen> createState() => _ClientPaymentsTabScreenState();
}

class _ClientPaymentsTabScreenState extends ConsumerState<ClientPaymentsTabScreen> {
  bool _autoPayEnabled = true;

  @override
  Widget build(BuildContext context) {
    final invoices = ref.watch(clientInvoicesProvider);
    final profile = ref.watch(clientProfileProvider).valueOrNull;

    return DsPage(
      title: context.l10n.financialCenter,
      subtitle: context.l10n.manageInvoicesDesc,
      showBack: false,
      extraBottomPadding: 90,
      onRefresh: () async {
        ref.invalidate(clientInvoicesProvider);
        ref.invalidate(clientProfileProvider);
      },
      actions: [
        DsPageAction(
          icon: Icons.history_rounded,
          tooltip: context.l10n.paymentHistoryTitle,
          onPressed: () => context.push(ClientRoutes.paymentHistory),
        ),
      ],
      body: dsAsyncBody(
        invoices,
        onRetry: () => ref.invalidate(clientInvoicesProvider),
        builder: (list) {
          final inv = list.isEmpty ? null : list.first;
          return [
            if (inv == null)
              _noInvoices
            else
              _AmountHero(
                pill: context.l10n.pendingInvoice.toUpperCase(),
                label: context.l10n.totalOutstanding,
                amount: inv.totalAmount,
                caption: context.l10n.dueBy(inv.dueDate),
                footer: Row(
                  children: [
                    Expanded(
                      child: DsHeroPillButton(
                        label: context.l10n.payNow,
                        icon: Icons.bolt_rounded,
                        onPressed: () => context.push(ClientRoutes.invoice),
                      ),
                    ),
                  ],
                ),
              ),
            const DsSection('Quick actions'),
            Row(
              children: [
                Expanded(
                  child: _ActionTile(
                    icon: Icons.history_rounded,
                    title: context.l10n.paymentHistoryTitle,
                    onTap: () => context.push(ClientRoutes.paymentHistory),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.download_rounded,
                    title: context.l10n.downloadStatements,
                    onTap: inv == null ? null : () => _downloadInvoice(context, ref, inv),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _ActionTile(
                    icon: Icons.receipt_long_rounded,
                    title: context.l10n.invoiceDetails,
                    onTap: inv == null ? null : () => context.push(ClientRoutes.invoice),
                  ),
                ),
              ],
            ),
            DsSection(context.l10n.autoPaySettings),
            Container(
              padding: const EdgeInsets.all(14),
              decoration: dsCardDecoration(),
              child: Row(
                children: [
                  const DsIconTile(Icons.credit_card_rounded),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          profile?.paymentMethod ?? 'No payment method on file',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                        Text(
                          profile?.accountLast4 != null
                              ? 'Ending in ${profile!.accountLast4}'
                              : (_autoPayEnabled ? 'Auto-pay is on' : 'Auto-pay is off'),
                          style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoPayEnabled,
                    activeTrackColor: AppColors.primary,
                    activeThumbColor: Colors.white,
                    onChanged: (v) {
                      HapticFeedback.selectionClick();
                      setState(() => _autoPayEnabled = v);
                    },
                  ),
                ],
              ),
            ),
            const SizedBox(height: 14),
            DsNote(
              tone: DsNoteTone.success,
              text: context.l10n.securePaymentDesc,
            ),
          ];
        },
      ),
    );
  }
}

class _ActionTile extends StatelessWidget {
  const _ActionTile({required this.icon, required this.title, required this.onTap});
  final IconData icon;
  final String title;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: onTap == null ? 0.5 : 1,
      child: Material(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        child: InkWell(
          borderRadius: BorderRadius.circular(22),
          onTap: onTap == null
              ? null
              : () {
                  HapticFeedback.selectionClick();
                  onTap!();
                },
          child: Ink(
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 14),
            decoration: dsCardDecoration(),
            child: Column(
              children: [
                DsIconTile(icon, size: 46),
                const SizedBox(height: 10),
                Text(
                  title,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: AppColors.lightTextPrimary,
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

/// Invoice detail.
class ClientInvoiceScreen extends ConsumerWidget {
  const ClientInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(clientInvoicesProvider);
    final inv = invoices.valueOrNull?.firstOrNull;

    return DsPage(
      title: context.l10n.invoiceDetails,
      subtitle: inv == null ? null : 'For ${inv.billingMonth}',
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(clientInvoicesProvider),
      actions: [
        if (inv != null) ...[
          DsPageAction(
            icon: Icons.share_rounded,
            tooltip: context.l10n.share,
            onPressed: () => Share.share(
              'Invoice: ${inv.invoiceNumber}\nAmount: ${CurrencyFormatter.inr(inv.totalAmount)}\nDue Date: ${inv.dueDate}',
            ),
          ),
          const SizedBox(width: 8),
          DsPageAction(
            icon: Icons.download_rounded,
            tooltip: context.l10n.download,
            onPressed: () => _downloadInvoice(context, ref, inv),
          ),
        ],
      ],
      bottom: inv == null
          ? null
          : DsGradientButton(
              label: context.l10n.proceedToPayment,
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(_gatewayUri(inv)),
            ),
      body: dsAsyncBody(
        invoices,
        onRetry: () => ref.invalidate(clientInvoicesProvider),
        builder: (list) {
          if (list.isEmpty) return const [_noInvoices];
          final inv = list.first;
          final detail = ref.watch(clientInvoiceDetailProvider(inv.invoiceId)).valueOrNull;
          return [
            _AmountHero(
              pill: inv.invoiceNumber.toUpperCase(),
              label: context.l10n.totalOutstanding,
              amount: inv.totalAmount,
              caption: context.l10n.dueBy(inv.dueDate),
              icon: Icons.receipt_long_rounded,
            ),
            DsSection(
              detail == null ? 'Charges' : (detail.documentType == 'TAX_INVOICE' ? 'Tax invoice' : 'Bill of supply'),
              trailing: DsPill(context.l10n.pending, color: AppColors.warning),
            ),
            // Service lines + GST breakdown from GET /client/invoices/:id,
            // falling back to the list endpoint's components while loading.
            if (detail != null) _DetailBreakdown(detail: detail) else _ItemsBreakdown(invoice: inv),
            const SizedBox(height: 14),
            DsNote(tone: DsNoteTone.success, text: context.l10n.securePaymentDesc),
          ];
        },
      ),
    );
  }
}

class _Row {
  const _Row(this.label, this.amount, {this.bold = false, this.muted = false});
  final String label;
  final double amount;
  final bool bold;
  final bool muted;
}

class _AmountRows extends StatelessWidget {
  const _AmountRows({required this.rows});
  final List<_Row> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: dsCardDecoration(),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0 && rows[i].bold) const Divider(height: 8, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: rows[i].bold ? 15 : 13.5,
                        fontWeight: rows[i].bold ? FontWeight.w800 : FontWeight.w600,
                        color: rows[i].muted ? AppColors.lightTextSecondary : AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    CurrencyFormatter.inr(rows[i].amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: rows[i].bold ? 17 : 14,
                      fontWeight: FontWeight.w800,
                      color: rows[i].bold ? AppColors.primary : AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// CGST/SGST and IGST are mutually exclusive — a same-state client gets
/// CGST+SGST, an out-of-state one gets IGST — so each row only shows when
/// non-zero; for a Bill of Supply the whole GST block disappears.
class _DetailBreakdown extends StatelessWidget {
  const _DetailBreakdown({required this.detail});
  final ClientInvoiceDetail detail;

  @override
  Widget build(BuildContext context) {
    final d = detail;
    return _AmountRows(
      rows: [
        for (final line in d.serviceLines) _Row(line.description, line.amount),
        _Row('Amount', d.taxableValue, muted: true),
        if (d.cgst > 0) _Row('9% CGST', d.cgst, muted: true),
        if (d.sgst > 0) _Row('9% SGST', d.sgst, muted: true),
        if (d.igst > 0) _Row('18% IGST', d.igst, muted: true),
        _Row('Total', d.totalAmount, bold: true),
      ],
    );
  }
}

class _ItemsBreakdown extends StatelessWidget {
  const _ItemsBreakdown({required this.invoice});
  final ClientInvoice invoice;

  @override
  Widget build(BuildContext context) {
    return _AmountRows(
      rows: [
        for (final item in invoice.items) _Row(item.description, item.amount),
        _Row('Total', invoice.totalAmount, bold: true),
      ],
    );
  }
}

/// Payment history.
class ClientPaymentHistoryScreen extends ConsumerWidget {
  const ClientPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientPaymentHistoryProvider);

    return DsPage(
      title: context.l10n.paymentHistory,
      subtitle: context.l10n.financialArchive,
      onBack: () => context.pop(),
      onRefresh: () async => ref.invalidate(clientPaymentHistoryProvider),
      body: dsAsyncBody(
        history,
        onRetry: () => ref.invalidate(clientPaymentHistoryProvider),
        builder: (list) {
          if (list.isEmpty) {
            return [
              DsEmptyBlock(
                icon: Icons.receipt_long_rounded,
                title: 'No payments yet',
                message: context.l10n.noPaymentHistory,
              ),
            ];
          }
          final paid = list.where((p) => p.status == ClientPaymentStatus.paid).length;
          return [
            DsGradientCard(
              child: Row(
                children: [
                  Expanded(child: DsGlassStat(value: '${list.length}', label: 'Payments', icon: Icons.payments_rounded)),
                  const SizedBox(width: 10),
                  Expanded(child: DsGlassStat(value: '$paid', label: 'Completed', icon: Icons.verified_rounded)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: DsGlassStat(
                      value: '${list.length - paid}',
                      label: 'In progress',
                      icon: Icons.hourglass_top_rounded,
                    ),
                  ),
                ],
              ),
            ),
            DsSection(context.l10n.statementOverview),
            for (var i = 0; i < list.length; i++)
              _PaymentCard(payment: list[i])
                  .animate(delay: (45 * i.clamp(0, 10)).ms)
                  .fadeIn(duration: 300.ms)
                  .slideX(begin: 0.05, end: 0),
          ];
        },
      ),
    );
  }
}

class _PaymentCard extends StatelessWidget {
  const _PaymentCard({required this.payment});
  final ClientPaymentHistory payment;

  @override
  Widget build(BuildContext context) {
    final p = payment;
    final methodIcon = switch (p.method.toLowerCase()) {
      'bank transfer' => Icons.account_balance_rounded,
      'credit card' || 'debit card' => Icons.credit_card_rounded,
      _ => Icons.qr_code_scanner_rounded,
    };
    final color = _paymentColor(p.status);
    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(radius: 20),
      child: Row(
        children: [
          DsIconTile(methodIcon, size: 46),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  p.amount,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
                Text(
                  '${p.date} · ${p.method}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                ),
                if (p.invoiceNumber.isNotEmpty)
                  Text(
                    p.invoiceNumber,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextHint,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          DsPill(
            clientPaymentStatusLabel(p.status),
            color: color,
            icon: p.status == ClientPaymentStatus.paid ? Icons.check_circle_rounded : null,
          ),
        ],
      ),
    );
  }
}

/// Download invoice screen.
class ClientDownloadInvoiceScreen extends ConsumerStatefulWidget {
  const ClientDownloadInvoiceScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<ClientDownloadInvoiceScreen> createState() => _ClientDownloadInvoiceScreenState();
}

class _ClientDownloadInvoiceScreenState extends ConsumerState<ClientDownloadInvoiceScreen> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    final result = await ref.read(clientRepositoryProvider).downloadInvoice(widget.invoiceId);
    if (!mounted) return;
    setState(() => _loading = false);
    switch (result) {
      case Success(data: final html):
        await _saveAndShareInvoiceHtml(html, widget.invoiceId);
        if (!mounted) return;
        context.showDsSnackBar(context.l10n.statementDownloaded, type: DsSnackBarType.success);
        context.pop();
      case Error(failure: final f):
        context.showDsSnackBar(f.message, type: DsSnackBarType.error);
    }
  }

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: 'Download invoice',
      onBack: () => context.pop(),
      bottom: DsGradientButton(
        label: context.l10n.download,
        icon: Icons.download_rounded,
        isLoading: _loading,
        onPressed: _loading ? null : _download,
      ),
      body: [
        const SizedBox(height: 20),
        Center(
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.06),
                  shape: BoxShape.circle,
                ),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scaleXY(begin: 0.92, end: 1.06, duration: 1400.ms, curve: Curves.easeInOut),
              const DsFloatingIconTile(icon: Icons.picture_as_pdf_rounded, size: 84),
            ],
          ),
        ),
        const SizedBox(height: 24),
        Text(
          context.l10n.downloadPdfInvoice,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w800,
            color: AppColors.lightTextPrimary,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'The invoice opens in your share sheet so you can save or send it.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, height: 1.45, color: AppColors.lightTextSecondary),
        ),
      ],
    );
  }
}

/// Payment status.
class ClientPaymentStatusScreen extends ConsumerWidget {
  const ClientPaymentStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(clientInvoicesProvider);
    final inv = invoices.valueOrNull?.firstOrNull;

    return DsPage(
      title: context.l10n.paymentStatus,
      onBack: () {
        if (context.canPop()) context.pop();
      },
      onRefresh: () async => ref.invalidate(clientInvoicesProvider),
      bottom: inv == null
          ? null
          : DsGradientButton(
              label: 'Pay now',
              icon: Icons.arrow_forward_rounded,
              onPressed: () => context.push(_gatewayUri(inv)),
            ),
      body: dsAsyncBody(
        invoices,
        onRetry: () => ref.invalidate(clientInvoicesProvider),
        builder: (list) {
          if (list.isEmpty) return const [_noInvoices];
          final inv = list.first;
          return [
            _AmountHero(
              pill: context.l10n.pendingCap,
              label: context.l10n.referenceInvoice(inv.id),
              amount: inv.totalAmount,
              caption: context.l10n.dueDateDesc(inv.dueDate),
              icon: Icons.hourglass_top_rounded,
            ),
            const DsSection('Charges'),
            _ItemsBreakdown(invoice: inv),
            const SizedBox(height: 14),
            DsNote(tone: DsNoteTone.success, text: context.l10n.secureEncryptedDesc),
            const SizedBox(height: 14),
            DsAdaptiveGrid(
              children: [
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.support_agent_rounded,
                  title: context.l10n.needAssistance,
                  subtitle: context.l10n.needAssistanceDesc,
                ),
                DsListCard(
                  margin: EdgeInsets.zero,
                  icon: Icons.receipt_long_rounded,
                  title: context.l10n.autoReceipt,
                  subtitle: context.l10n.autoReceiptDesc,
                ),
              ],
            ),
          ];
        },
      ),
    );
  }
}

class ClientUpiPaymentScreen extends ConsumerStatefulWidget {
  const ClientUpiPaymentScreen({super.key, required this.invoiceId, required this.amount});
  final String invoiceId;
  final double amount;

  @override
  ConsumerState<ClientUpiPaymentScreen> createState() => _ClientUpiPaymentScreenState();
}

class _ClientUpiPaymentScreenState extends ConsumerState<ClientUpiPaymentScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_pinController.text.length < 4) {
      context.showDsSnackBar(context.l10n.enterValidUpiPin, type: DsSnackBarType.warning);
      return;
    }
    setState(() => _isLoading = true);

    final repo = ref.read(clientRepositoryProvider);
    final result = await repo.makeDemoPayment(widget.invoiceId, widget.amount, 'UPI');

    if (!mounted) return;
    setState(() => _isLoading = false);

    result.fold(
      onSuccess: (_) {
        context.showDsSnackBar(context.l10n.paymentSuccessful, type: DsSnackBarType.success);
        ref.invalidate(clientInvoicesProvider);
        ref.invalidate(clientPaymentHistoryProvider);
        ref.invalidate(clientDashboardProvider);
        context.pop();
      },
      onError: (f) => context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return DsPage(
      title: context.l10n.upiPayment,
      onBack: () => context.pop(),
      bottom: DsGradientButton(
        label: context.l10n.paySecurely,
        icon: Icons.lock_rounded,
        isLoading: _isLoading,
        onPressed: _isLoading ? null : _processPayment,
      ),
      body: [
        _AmountHero(
          pill: 'UPI',
          label: context.l10n.payingHomeGenny,
          amount: widget.amount,
          icon: Icons.account_balance_wallet_rounded,
        ),
        DsSection(context.l10n.enterUpiPin),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: dsCardDecoration(),
          child: Column(
            children: [
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 26,
                  letterSpacing: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.lightTextPrimary,
                ),
                decoration: const InputDecoration(counterText: '', hintText: '••••'),
              ),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Icon(Icons.lock_rounded, size: 14, color: AppColors.iconAccent),
                  const SizedBox(width: 6),
                  Flexible(
                    child: Text(
                      'Your PIN is never stored',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
