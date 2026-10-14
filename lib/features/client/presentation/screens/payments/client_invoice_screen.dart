import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/utils/currency_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../../domain/models/client_models.dart';
import '../../navigation/client_routes.dart';
import '../../providers/client_providers.dart';

class ClientInvoiceScreen extends ConsumerWidget {
  const ClientInvoiceScreen({super.key});

  void _back(BuildContext context) {
    if (context.canPop()) context.pop();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final invoices = ref.watch(clientInvoicesProvider);
    final invoice = invoices.valueOrNull?.firstOrNull;
    final paid = invoice != null && _isPaid(invoice.status);

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: RefreshIndicator(
        color: AppColors.primary,
        onRefresh: () async => ref.invalidate(clientInvoicesProvider),
        child: CustomScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: DsHeroHeader(
                title: invoice == null ? 'Invoice' : 'Invoice · ${invoice.billingMonth}',
                eyebrow: invoice?.invoiceNumber.isNotEmpty == true ? invoice!.invoiceNumber : 'Billing',
                eyebrowIcon: Icons.receipt_long_rounded,
                showBack: true,
                onBack: () => _back(context),
                bottom: invoice == null ? null : _TotalCard(invoice: invoice, paid: paid),
              ),
            ),
            ...invoices.when(
              loading: () => const [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(child: DsLoadingWidget()),
                ),
              ],
              error: (_, _) => [
                SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: DsErrorState(
                      title: 'Couldn\'t load invoice',
                      onRetry: () => ref.invalidate(clientInvoicesProvider),
                    ),
                  ),
                ),
              ],
              data: (list) {
                if (list.isEmpty) {
                  return const [
                    SliverFillRemaining(
                      hasScrollBody: false,
                      child: Center(
                        child: DsEmptyState(
                          title: 'No invoices yet',
                          message: 'Invoices appear after your Relationship Manager approves '
                              'shifts and Finance runs payroll.',
                          icon: Icons.receipt_long_rounded,
                        ),
                      ),
                    ),
                  ];
                }
                final inv = list.first;
                return [
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                    sliver: SliverList.list(
                      children: [
                        _sectionTitle('Line items'),
                        _ItemsCard(invoice: inv),
                        const SizedBox(height: 14),
                        _sectionTitle('Breakdown'),
                        _BreakdownCard(invoice: inv),
                        const SizedBox(height: 14),
                        const _GstNote(),
                      ]
                          .animate(interval: 60.ms)
                          .fadeIn(duration: 380.ms)
                          .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
                    ),
                  ),
                ];
              },
            ),
          ],
        ),
      ),
      bottomNavigationBar: invoice == null || paid
          ? null
          : Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(26)),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.navy.withValues(alpha: 0.08),
                    blurRadius: 24,
                    offset: const Offset(0, -6),
                  ),
                ],
              ),
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 12),
              child: SafeArea(
                top: false,
                child: Row(
                  children: [
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Total due',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextSecondary,
                          ),
                        ),
                        Text(
                          CurrencyFormatter.inr(invoice.totalAmount),
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 19,
                            fontWeight: FontWeight.w800,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: DsGradientButton(
                        label: 'Pay now',
                        icon: Icons.arrow_forward_rounded,
                        onPressed: () => context.push(
                          Uri(
                            path: ClientRoutes.paymentGateway,
                            queryParameters: {
                              'invoiceId': invoice.invoiceId,
                              'amount': invoice.totalAmount.toString(),
                            },
                          ).toString(),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ).animate().slideY(begin: 1, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
    );
  }

  static Widget _sectionTitle(String text) => Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 15,
                fontWeight: FontWeight.w800,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ],
        ),
      );
}

bool _isPaid(String status) => status.toUpperCase() == 'PAID';

BoxDecoration _card() => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(22),
      border: Border.all(color: AppColors.lightBorder),
      boxShadow: [
        BoxShadow(
          color: AppColors.navy.withValues(alpha: 0.05),
          blurRadius: 18,
          offset: const Offset(0, 8),
        ),
      ],
    );

class _TotalCard extends StatelessWidget {
  const _TotalCard({required this.invoice, required this.paid});
  final ClientInvoice invoice;
  final bool paid;

  @override
  Widget build(BuildContext context) {
    final statusColor = paid ? const Color(0xFF6EE7B7) : AppColors.sunYellow;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  paid ? 'Amount paid' : 'Total due',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.78),
                  ),
                ),
                const SizedBox(height: 2),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    CurrencyFormatter.inr(invoice.totalAmount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -1,
                      color: Colors.white,
                    ),
                  ),
                ),
                if (invoice.dueDate.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Due ${invoice.dueDate}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w600,
                      color: Colors.white.withValues(alpha: 0.78),
                    ),
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(
                    color: paid ? AppColors.success : AppColors.secondary,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 6),
                Text(
                  paid ? 'Paid' : _titleCase(invoice.status.isEmpty ? 'Pending' : invoice.status),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ).animate(onPlay: (c) => c.repeat(reverse: true)).custom(
                duration: 1200.ms,
                builder: (_, v, child) => DecoratedBox(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(20),
                    boxShadow: [
                      BoxShadow(
                        color: statusColor.withValues(alpha: 0.35 * v),
                        blurRadius: 14 * v,
                      ),
                    ],
                  ),
                  child: child,
                ),
              ),
        ],
      ),
    );
  }

  static String _titleCase(String s) => s
      .toLowerCase()
      .split('_')
      .map((w) => w.isEmpty ? w : '${w[0].toUpperCase()}${w.substring(1)}')
      .join(' ');
}

class _ItemsCard extends StatelessWidget {
  const _ItemsCard({required this.invoice});
  final ClientInvoice invoice;

  @override
  Widget build(BuildContext context) {
    if (invoice.items.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(18),
        decoration: _card(),
        child: Text(
          'No line items on this invoice.',
          style: GoogleFonts.plusJakartaSans(fontSize: 13.5, color: AppColors.lightTextSecondary),
        ),
      );
    }
    return Container(
      decoration: _card(),
      child: Column(
        children: [
          for (var i = 0; i < invoice.items.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 70, endIndent: 16, color: AppColors.lightBorder),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColors.iconAccentSoft,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.receipt_rounded, color: AppColors.iconAccent, size: 21),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      invoice.items[i].description,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextPrimary,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    CurrencyFormatter.inr(invoice.items[i].amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
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

class _BreakdownCard extends StatelessWidget {
  const _BreakdownCard({required this.invoice});
  final ClientInvoice invoice;

  @override
  Widget build(BuildContext context) {
    final total = invoice.totalAmount <= 0 ? 1.0 : invoice.totalAmount;
    final parts = [
      ('Staff salary', invoice.salaryComponent, AppColors.primary),
      ('Management fee', invoice.managementFee, AppColors.secondary),
      ('GST', invoice.gstAmount, AppColors.accent),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: _card(),
      child: Column(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(6),
            child: SizedBox(
              height: 12,
              child: Row(
                children: [
                  for (final (_, amount, color) in parts)
                    if (amount > 0)
                      Expanded(
                        flex: ((amount / total) * 1000).round().clamp(1, 1000),
                        child: Container(color: color),
                      ),
                ],
              ),
            ),
          ).animate().scaleX(begin: 0, end: 1, alignment: Alignment.centerLeft, duration: 800.ms, curve: Curves.easeOutCubic),
          const SizedBox(height: 14),
          for (final (label, amount, color) in parts)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  Container(
                    width: 10,
                    height: 10,
                    decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: AppColors.lightTextSecondary,
                      ),
                    ),
                  ),
                  Text(
                    CurrencyFormatter.inr(amount),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                ],
              ),
            ),
          const Divider(height: 20, color: AppColors.lightBorder),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Total',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 15,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
              Text(
                CurrencyFormatter.inr(invoice.totalAmount),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _GstNote extends StatelessWidget {
  const _GstNote();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.primaryContainer,
        borderRadius: BorderRadius.circular(18),
      ),
      child: Row(
        children: [
          const Icon(Icons.info_rounded, color: AppColors.iconAccent, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'GST applies only on the management fee.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.lightTextPrimary,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
