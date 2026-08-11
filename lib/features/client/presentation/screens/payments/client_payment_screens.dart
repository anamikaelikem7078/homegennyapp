import 'package:flutter/material.dart';
import '../../../../../core/extensions/context_extensions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';
import '../../widgets/client_scaffold.dart';

/// Payments tab.
class ClientPaymentsTabScreen extends ConsumerStatefulWidget {
  const ClientPaymentsTabScreen({super.key});

  @override
  ConsumerState<ClientPaymentsTabScreen> createState() =>
      _ClientPaymentsTabScreenState();
}

class _ClientPaymentsTabScreenState
    extends ConsumerState<ClientPaymentsTabScreen> {
  bool _autoPayEnabled = true;

  @override
  Widget build(BuildContext context) {
    final invoice = ref.watch(clientInvoiceProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        centerTitle: true,
        title: Text(
          context.l10n.financialCenter,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: invoice.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => DsErrorState(title: context.l10n.error),
        data: (inv) => ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Text(
              context.l10n.manageInvoicesDesc,
              style: GoogleFonts.inter(
                color: context.colors.onSurfaceVariant,
                fontSize: 13,
                height: 1.5,
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 32),
            // Pending Invoice Card
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF1A56FF).withOpacity(0.08),
                    blurRadius: 32,
                    spreadRadius: 0,
                    offset: const Offset(0, 16),
                  ),
                ],
                border: Border.all(
                  color: context.colors.surfaceVariant,
                  width: 1,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 6,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.orange.shade50,
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          context.l10n.pendingInvoice,
                          style: GoogleFonts.inter(
                            color: Colors.orange.shade800,
                            fontSize: 9,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 1.0,
                          ),
                        ),
                      ),
                      Text(
                        '#INV-2023-890', // Static for prototype per design, or inv.invoiceNumber
                        style: GoogleFonts.inter(
                          color: Colors.black45,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 16),
                  Text(
                    context.l10n.totalOutstanding,
                    style: GoogleFonts.inter(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 13,
                    ),
                  ),
                  SizedBox(height: 4),
                  Text(
                    '₹18,500', // inv.amount
                    style: GoogleFonts.libreCaslonText(
                      color: context.colors.onSurface,
                      fontSize: 40,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    context.l10n.dueBy(inv.dueDate),
                    style: GoogleFonts.inter(
                      color: context.colors.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () => context.push(ClientRoutes.invoice),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: Text(
                        context.l10n.payNow,
                        style: GoogleFonts.inter(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Statements & History
            Row(
              children: [
                Expanded(
                  child: _PaymentActionCard(
                    icon: Icons.history_rounded,
                    title: context.l10n.paymentHistoryTitle,
                    onTap: () => context.push(ClientRoutes.paymentHistory),
                  ),
                ),
                SizedBox(width: 16),
                Expanded(
                  child: _PaymentActionCard(
                    icon: Icons.download_rounded,
                    title: context.l10n.downloadStatements,
                    onTap: () async {
                      final result = await ref
                          .read(clientRepositoryProvider)
                          .downloadInvoice(inv.id);
                      if (!context.mounted) return;
                      result.fold(
                        onSuccess: (msg) => context.showDsSnackBar(
                          context.l10n.statementDownloaded,
                          type: DsSnackBarType.success,
                        ),
                        onError: (f) => context.showDsSnackBar(
                          f.message,
                          type: DsSnackBarType.error,
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 32),
            // Auto-pay Settings
            Text(
              context.l10n.autoPaySettings,
              style: GoogleFonts.libreCaslonText(
                color: context.colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.theme.dividerColor, width: 1),
              ),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.indigo.shade50,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.credit_card_rounded,
                      color: Colors.indigo.shade400,
                      size: 24,
                    ),
                  ),
                  SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'HDFC Bank Credit Card',
                          style: GoogleFonts.inter(
                            color: context.colors.onSurface,
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        SizedBox(height: 2),
                        Text(
                          'Ending in 4022',
                          style: GoogleFonts.inter(
                            color: context.colors.onSurfaceVariant,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    value: _autoPayEnabled,
                    activeColor: const Color(0xFF1A56FF),
                    onChanged: (val) {
                      setState(() {
                        _autoPayEnabled = val;
                      });
                    },
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            // Recent Transactions Ledger
            Text(
              context.l10n.recentTransactions,
              style: GoogleFonts.libreCaslonText(
                color: context.colors.onSurface,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
            SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.theme.dividerColor, width: 1),
              ),
              child: Column(
                children: [
                  _LedgerItem(
                    title: 'Monthly Maintenance',
                    date: 'Sep 01, 2023',
                    amount: '-₹15,000',
                    isNegative: true,
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  _LedgerItem(
                    title: 'Pool Access Fee',
                    date: 'Aug 24, 2023',
                    amount: '-₹3,500',
                    isNegative: true,
                  ),
                  const Divider(height: 1, color: Color(0xFFF3F4F6)),
                  _LedgerItem(
                    title: 'Refund: Overcharge',
                    date: 'Aug 15, 2023',
                    amount: '+₹1,200',
                    isNegative: false,
                  ),
                ],
              ),
            ),
            SizedBox(height: 100), // Padding for floating nav
          ],
        ),
      ),
    );
  }
}

class _PaymentActionCard extends StatelessWidget {
  const _PaymentActionCard({
    required this.icon,
    required this.title,
    required this.onTap,
  });

  final IconData icon;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: context.theme.dividerColor, width: 1),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.02),
              blurRadius: 10,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: const Color(0xFF1A56FF), size: 28),
            SizedBox(height: 16),
            Text(
              title,
              style: GoogleFonts.inter(
                color: context.colors.onSurface,
                fontSize: 14,
                fontWeight: FontWeight.w600,
                height: 1.3,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _LedgerItem extends StatelessWidget {
  const _LedgerItem({
    required this.title,
    required this.date,
    required this.amount,
    required this.isNegative,
  });
  final String title;
  final String date;
  final String amount;
  final bool isNegative;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: isNegative ? Colors.red.shade50 : Colors.green.shade50,
              shape: BoxShape.circle,
            ),
            child: Icon(
              isNegative
                  ? Icons.arrow_outward_rounded
                  : Icons.south_west_rounded,
              color: isNegative ? Colors.red.shade400 : Colors.green.shade500,
              size: 16,
            ),
          ),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(
                    color: context.colors.onSurface,
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  date,
                  style: GoogleFonts.inter(
                    color: context.colors.onSurfaceVariant,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          ),
          Text(
            amount,
            style: GoogleFonts.inter(
              color: isNegative
                  ? context.colors.onSurface
                  : Colors.green.shade600,
              fontSize: 15,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

/// Invoice detail.
class ClientInvoiceScreen extends ConsumerWidget {
  const ClientInvoiceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(clientInvoiceProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.colors.onSurface),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.l10n.invoiceDetails,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.download_outlined, color: Color(0xFF1A56FF)),
            onPressed: () async {
              final inv = await ref.read(clientInvoiceProvider.future);
              final result = await ref
                  .read(clientRepositoryProvider)
                  .downloadInvoice(inv.id);
              if (!context.mounted) return;
              result.fold(
                onSuccess: (msg) =>
                    context.showDsSnackBar(msg, type: DsSnackBarType.success),
                onError: (f) => context.showDsSnackBar(
                  f.message,
                  type: DsSnackBarType.error,
                ),
              );
            },
          ),
        ],
      ),
      body: invoice.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: Color(0xFF1A56FF))),
        error: (_, __) => Center(child: Text(context.l10n.errorLoadingInvoice)),
        data: (inv) => ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                color: context.theme.cardColor,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: context.theme.dividerColor),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.02),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: context.theme.dividerColor,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          context.l10n.invoiceCap,
                          style: GoogleFonts.inter(
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFFE0E7FF),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Container(
                              width: 6,
                              height: 6,
                              decoration: BoxDecoration(
                                color: Color(0xFF1A56FF),
                                shape: BoxShape.circle,
                              ),
                            ),
                            SizedBox(width: 6),
                            Text(
                              context.l10n.pending,
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: const Color(0xFF1A56FF),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 24),
                  Text(
                    'HG-INV-\n2407-001', // Ideally inv.invoiceNumber
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 32,
                      color: context.colors.onSurface,
                      fontWeight: FontWeight.w600,
                      height: 1.2,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    'Issued on July 14, 2024',
                    style: GoogleFonts.inter(
                      fontSize: 12,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 32),
                  const Divider(color: Color(0xFFF3F4F6), height: 1),
                  SizedBox(height: 32),
                  Text(
                    context.l10n.totalOutstanding,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: context.colors.onSurfaceVariant,
                    ),
                  ),
                  SizedBox(height: 8),
                  Text(
                    '₹18,500', // Ideally inv.amount
                    style: GoogleFonts.libreCaslonText(
                      fontSize: 36,
                      color: const Color(0xFF1A56FF),
                    ),
                  ),
                  SizedBox(height: 40),

                  // Fees breakdown
                  _buildFeeRow(
                    context,
                    'Service Fee',
                    'Premium Home Consultation',
                    '₹15,000',
                  ),
                  SizedBox(height: 24),
                  _buildFeeRow(
                    context,
                    'Platform Fee',
                    'Concierge Management',
                    '₹678',
                  ),
                  SizedBox(height: 24),
                  _buildFeeRow(context, 'GST', 'Tax (18%)', '₹2,822'),
                  SizedBox(height: 40),

                  // Divider with dots
                  Row(
                    children: [
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.theme.dividerColor),
                        ),
                      ),
                      Expanded(
                        child: Container(
                          height: 1,
                          color: context.theme.dividerColor,
                        ),
                      ),
                      Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: context.theme.dividerColor),
                        ),
                      ),
                    ],
                  ),
                  SizedBox(height: 40),

                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () =>
                          context.push(ClientRoutes.paymentGateway),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF1A56FF),
                        foregroundColor: Colors.white,
                        elevation: 0,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Text(
                        context.l10n.proceedToPayment,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ),
                  SizedBox(height: 32),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _buildActionBtn(
                        context,
                        Icons.share_outlined,
                        context.l10n.share,
                        onTap: () async {
                          final inv = await ref.read(
                            clientInvoiceProvider.future,
                          );
                          Share.share(
                            'Invoice: ${inv.invoiceNumber}\nAmount: ${inv.amount}\nDue Date: ${inv.dueDate}',
                          );
                        },
                      ),
                      SizedBox(width: 32),
                      _buildActionBtn(
                        context,
                        Icons.download_outlined,
                        context.l10n.download,
                        onTap: () async {
                          final inv = await ref.read(
                            clientInvoiceProvider.future,
                          );
                          final result = await ref
                              .read(clientRepositoryProvider)
                              .downloadInvoice(inv.id);
                          if (!context.mounted) return;
                          result.fold(
                            onSuccess: (msg) => context.showDsSnackBar(
                              msg,
                              type: DsSnackBarType.success,
                            ),
                            onError: (f) => context.showDsSnackBar(
                              f.message,
                              type: DsSnackBarType.error,
                            ),
                          );
                        },
                      ),
                      SizedBox(width: 32),
                      _buildActionBtn(
                        context,
                        Icons.help_outline,
                        context.l10n.help,
                        onTap: () {},
                      ),
                    ],
                  ),
                ],
              ),
            ),
            SizedBox(height: 32),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Text(
                context.l10n.securePaymentDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 11,
                  color: context.colors.onSurfaceVariant,
                  height: 1.5,
                ),
              ),
            ),
            SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeeRow(
    BuildContext context,
    String title,
    String subtitle,
    String amount,
  ) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: GoogleFonts.inter(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: context.colors.onSurface,
              ),
            ),
            SizedBox(height: 2),
            Text(
              subtitle,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: context.colors.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          amount,
          style: GoogleFonts.inter(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildActionBtn(
    BuildContext context,
    IconData icon,
    String label, {
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Row(
        children: [
          Icon(icon, size: 20, color: context.colors.onSurface),
          SizedBox(width: 8),
          Text(
            label,
            style: GoogleFonts.inter(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: context.colors.onSurface,
            ),
          ),
        ],
      ),
    );
  }
}

/// Payment history.
class ClientPaymentHistoryScreen extends ConsumerWidget {
  const ClientPaymentHistoryScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final history = ref.watch(clientPaymentHistoryProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Color(0xFF1A56FF),
          ),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.l10n.paymentHistory,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(Icons.tune_rounded, color: Color(0xFF1A56FF)),
            onPressed: () {},
          ),
        ],
      ),
      body: history.when(
        loading: () => const DsLoadingWidget(),
        error: (_, __) => const DsErrorState(title: 'Error'),
        data: (list) {
          if (list.isEmpty) {
            return Center(
              child: Text(
                context.l10n.noPaymentHistory,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                ),
              ),
            );
          }
          return ListView(
            padding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 16,
            ).copyWith(bottom: 100),
            children: [
              Text(
                context.l10n.statementOverview,
                style: GoogleFonts.inter(
                  color: context.colors.onSurfaceVariant,
                  fontSize: 10,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 1.5,
                ),
              ),
              SizedBox(height: 8),
              Text(
                context.l10n.financialArchive,
                style: GoogleFonts.libreCaslonText(
                  color: context.colors.onSurface,
                  fontSize: 32,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 16),
              Container(height: 2, width: 60, color: const Color(0xFF1A56FF)),
              SizedBox(height: 32),

              ...list.map((p) {
                IconData methodIcon;
                switch (p.method.toLowerCase()) {
                  case 'bank transfer':
                    methodIcon = Icons.account_balance;
                    break;
                  case 'credit card':
                  case 'debit card':
                    methodIcon = Icons.credit_card;
                    break;
                  case 'upi':
                  default:
                    methodIcon = Icons.qr_code_scanner;
                    break;
                }

                return Container(
                  margin: const EdgeInsets.only(bottom: 16),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: context.theme.cardColor,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: context.theme.dividerColor),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.02),
                        blurRadius: 10,
                        spreadRadius: 0,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: const Color(0xFF1A56FF).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Icon(
                          methodIcon,
                          color: const Color(0xFF1A56FF),
                          size: 24,
                        ),
                      ),
                      SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              p.amount,
                              style: GoogleFonts.libreCaslonText(
                                color: context.colors.onSurface,
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              '${p.date} · ${p.method}',
                              style: GoogleFonts.inter(
                                color: context.colors.onSurfaceVariant,
                                fontSize: 13,
                              ),
                            ),
                            SizedBox(height: 4),
                            Text(
                              p.invoiceNumber,
                              style: GoogleFonts.inter(
                                color: context.colors.onSurfaceVariant
                                    .withValues(alpha: 0.6),
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Paid Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 10,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.green.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.green.withOpacity(0.3),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline,
                              color: Colors.green,
                              size: 12,
                            ),
                            SizedBox(width: 4),
                            Text(
                              context.l10n.paid,
                              style: GoogleFonts.inter(
                                color: Colors.green.shade700,
                                fontSize: 10,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),

              SizedBox(height: 16),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: () {},
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.colors.onSurface,
                    side: BorderSide(
                      color: context.theme.dividerColor,
                      width: 1,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        context.l10n.loadMoreRecords,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          letterSpacing: 0.5,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.keyboard_arrow_down_rounded, size: 18),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

/// Download invoice screen.
class ClientDownloadInvoiceScreen extends ConsumerStatefulWidget {
  const ClientDownloadInvoiceScreen({super.key, required this.invoiceId});
  final String invoiceId;

  @override
  ConsumerState<ClientDownloadInvoiceScreen> createState() =>
      _ClientDownloadInvoiceScreenState();
}

class _ClientDownloadInvoiceScreenState
    extends ConsumerState<ClientDownloadInvoiceScreen> {
  bool _loading = false;

  Future<void> _download() async {
    setState(() => _loading = true);
    final result = await ref
        .read(clientRepositoryProvider)
        .downloadInvoice(widget.invoiceId);
    if (!mounted) return;
    setState(() => _loading = false);
    result.fold(
      onSuccess: (msg) {
        context.showDsSnackBar(msg, type: DsSnackBarType.success);
        context.pop();
      },
      onError: (f) =>
          context.showDsSnackBar(f.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ClientPageScaffold(
      title: 'Download Invoice',
      body: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.picture_as_pdf_rounded,
            size: 80,
            color: AppColors.primary.withValues(alpha: 0.5),
          ),
          SizedBox(height: AppSpacing.xl),
          Text(
            context.l10n.downloadPdfInvoice,
            style: Theme.of(context).textTheme.titleMedium,
          ),
          SizedBox(height: AppSpacing.xl),
          DsGradientButton(
            label: context.l10n.download,
            isLoading: _loading,
            onPressed: _download,
          ),
        ],
      ),
    );
  }
}

/// Payment status.
class ClientPaymentStatusScreen extends ConsumerWidget {
  const ClientPaymentStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoice = ref.watch(clientInvoiceProvider);

    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_forward_ios, color: context.colors.onSurface),
          onPressed: () {
            if (context.canPop()) context.pop();
          },
        ),
        title: Text(
          context.l10n.paymentStatus,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.arrow_forward_ios,
              color: context.colors.onSurface,
            ),
            onPressed: () {},
          ),
        ],
      ),
      body: invoice.when(
        loading: () =>
            Center(child: CircularProgressIndicator(color: Color(0xFF1A56FF))),
        error: (_, __) => Center(child: Text(context.l10n.error)),
        data: (inv) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Main Card
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: context.theme.cardColor,
                  borderRadius: BorderRadius.circular(8),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.03),
                      blurRadius: 20,
                      offset: const Offset(0, 10),
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
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 10,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: context.theme.dividerColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                context.l10n.pendingCap,
                                style: GoogleFonts.inter(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w600,
                                  color: context.colors.onSurfaceVariant,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ),
                            SizedBox(height: 8),
                            Text(
                              context.l10n.referenceInvoice(inv.invoiceNumber),
                              style: GoogleFonts.inter(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: context.colors.onSurface,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: context.colors.surfaceVariant,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Icon(
                            Icons.money_outlined,
                            size: 20,
                            color: Color(0xFF1A56FF),
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 24),
                    Text(
                      inv.amount,
                      style: GoogleFonts.libreCaslonText(
                        fontSize: 42,
                        fontWeight: FontWeight.w500,
                        color: context.colors.onSurface,
                      ),
                    ),
                    SizedBox(height: 8),
                    Text(
                      context.l10n.dueDateDesc(inv.dueDate),
                      style: GoogleFonts.inter(
                        fontSize: 13,
                        color: context.colors.onSurfaceVariant,
                      ),
                    ),
                    SizedBox(height: 24),
                    const Divider(color: Color(0xFFF3F4F6), height: 1),
                    SizedBox(height: 24),
                    _buildFeeRow(context, 'Service Fee', '₹15,000'),
                    SizedBox(height: 16),
                    _buildFeeRow(context, 'Platform Charge', '₹2,500'),
                    SizedBox(height: 16),
                    _buildFeeRow(context, 'Taxes (GST)', '₹1,000'),
                  ],
                ),
              ),
              SizedBox(height: 24),

              // Pay Now Button
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton(
                  onPressed: () => context.push(ClientRoutes.paymentGateway),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Pay Now',
                        style: GoogleFonts.inter(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      SizedBox(width: 8),
                      Icon(Icons.arrow_forward, size: 16),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 16),

              Text(
                context.l10n.secureEncryptedDesc,
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              SizedBox(height: 32),

              // Bottom Cards
              _buildInfoCard(
                context,
                Icons.support_agent_outlined,
                context.l10n.needAssistance,
                context.l10n.needAssistanceDesc,
              ),
              SizedBox(height: 16),
              _buildInfoCard(
                context,
                Icons.receipt_long_outlined,
                context.l10n.autoReceipt,
                context.l10n.autoReceiptDesc,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFeeRow(BuildContext context, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.colors.onSurfaceVariant,
          ),
        ),
        Text(
          value,
          style: GoogleFonts.inter(
            fontSize: 13,
            color: context.colors.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildInfoCard(
    BuildContext context,
    IconData icon,
    String title,
    String description,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: context.theme.cardColor,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: context.theme.dividerColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: const Color(0xFF1A56FF), size: 24),
          SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.libreCaslonText(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: context.colors.onSurface,
            ),
          ),
          SizedBox(height: 8),
          Text(
            description,
            style: GoogleFonts.inter(
              fontSize: 12,
              color: context.colors.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }
}

class ClientUpiPaymentScreen extends StatefulWidget {
  const ClientUpiPaymentScreen({super.key});

  @override
  State<ClientUpiPaymentScreen> createState() => _ClientUpiPaymentScreenState();
}

class _ClientUpiPaymentScreenState extends State<ClientUpiPaymentScreen> {
  final _pinController = TextEditingController();
  bool _isLoading = false;

  @override
  void dispose() {
    _pinController.dispose();
    super.dispose();
  }

  Future<void> _processPayment() async {
    if (_pinController.text.length < 4) {
      context.showDsSnackBar(
        context.l10n.enterValidUpiPin,
        type: DsSnackBarType.warning,
      );
      return;
    }
    setState(() => _isLoading = true);
    // Simulate network delay
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
    setState(() => _isLoading = false);

    // Show success and pop back
    context.showDsSnackBar(context.l10n.paymentSuccessful, type: DsSnackBarType.success);
    context.pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.theme.scaffoldBackgroundColor,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: context.colors.onSurface),
          onPressed: () => context.pop(),
        ),
        centerTitle: true,
        title: Text(
          context.l10n.upiPayment,
          style: GoogleFonts.libreCaslonText(
            color: context.colors.onSurface,
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Color(0xFFE0E7FF),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.account_balance_wallet_outlined,
                  size: 48,
                  color: Color(0xFF1A56FF),
                ),
              ),
              SizedBox(height: 24),
              Text(
                context.l10n.payingHomeGenny,
                style: GoogleFonts.inter(
                  fontSize: 16,
                  color: context.colors.onSurfaceVariant,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 8),
              Text(
                '₹18,500',
                style: GoogleFonts.libreCaslonText(
                  fontSize: 48,
                  color: context.colors.onSurface,
                  fontWeight: FontWeight.w600,
                ),
              ),
              SizedBox(height: 48),

              Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  context.l10n.enterUpiPin,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.0,
                    color: context.colors.onSurfaceVariant,
                  ),
                ),
              ),
              SizedBox(height: 12),
              TextField(
                controller: _pinController,
                obscureText: true,
                keyboardType: TextInputType.number,
                maxLength: 6,
                style: GoogleFonts.inter(
                  fontSize: 24,
                  letterSpacing: 8,
                  fontWeight: FontWeight.bold,
                  color: Colors.black,
                ),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  counterText: '',
                  filled: true,
                  fillColor: Colors.white,
                  contentPadding: const EdgeInsets.symmetric(vertical: 20),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                      color: Color(0xFF1A56FF),
                      width: 2,
                    ),
                  ),
                ),
              ),

              const Spacer(),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _processPayment,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF1A56FF),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: _isLoading
                      ? SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: context.theme.cardColor,
                          ),
                        )
                      : Text(
                          context.l10n.paySecurely,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                ),
              ),
              SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
