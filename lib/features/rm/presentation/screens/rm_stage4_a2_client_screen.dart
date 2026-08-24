import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/presentation/async_value_widget.dart';
import '../../../../design_system/foundations/rm_theme.dart';
import '../../../../design_system/tokens/app_spacing.dart';
import '../../domain/models/rm_models.dart';
import '../providers/rm_providers.dart';

/// Client picker for the S4 Agreements stage — `GET /finance/customers`.
/// Agreements (A1/A2/A3) all require a `client_id`, so this is selected
/// once per staff and carried into each instrument screen. Returns the
/// selected [FinanceCustomer] via `Navigator.pop`.
class RmStage4A2ClientScreen extends ConsumerStatefulWidget {
  const RmStage4A2ClientScreen({super.key, required this.staffId});
  final String staffId;

  @override
  ConsumerState<RmStage4A2ClientScreen> createState() =>
      _RmStage4A2ClientScreenState();
}

class _RmStage4A2ClientScreenState
    extends ConsumerState<RmStage4A2ClientScreen> {
  String _search = '';
  FinanceCustomer? _selected;

  @override
  Widget build(BuildContext context) {
    final customersAsync = ref
        .watch(financeCustomersProvider(_search.isEmpty ? null : _search));

    return Scaffold(
      backgroundColor: RmTheme.offWhite,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // ── Header ──
            _Header(onBack: () => context.pop()),

            SizedBox(height: AppSpacing.xs),

            // ── Search Bar ──
            _SearchField(
              onChanged: (v) => setState(() => _search = v),
            ),

            SizedBox(height: AppSpacing.xs),

            // ── Client List ──
            Expanded(
              child: AsyncValueWidget<List<FinanceCustomer>>(
                value: customersAsync,
                onRetry: () => ref.invalidate(
                  financeCustomersProvider(
                      _search.isEmpty ? null : _search),
                ),
                builder: (customers) {
                  if (customers.isEmpty) {
                    return _EmptyState(searchQuery: _search);
                  }
                  return ListView.separated(
                    padding: EdgeInsets.symmetric(
                      horizontal: AppSpacing.md,
                      vertical: AppSpacing.xs,
                    ),
                    itemCount: customers.length,
                    separatorBuilder: (_, _) => Divider(
                      height: 1,
                      thickness: 0.5,
                      color: RmTheme.borderSubtle.withValues(alpha: 0.5),
                      indent: AppSpacing.md,
                      endIndent: AppSpacing.md,
                    ),
                    itemBuilder: (context, index) {
                      final c = customers[index];
                      final isSelected = _selected?.id == c.id;

                      return _ClientRow(
                        customer: c,
                        isSelected: isSelected,
                        index: index,
                        onTap: () async {
                          setState(() => _selected = c);
                          // Brief delay so the user sees the selection
                          await Future.delayed(
                            const Duration(milliseconds: 200),
                          );
                          if (!context.mounted) return;
                          context.pop(c);
                        },
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Header ──────────────────────────────────────────────────────────────────

class _Header extends StatelessWidget {
  const _Header({required this.onBack});
  final VoidCallback onBack;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xs,
        AppSpacing.md,
        AppSpacing.md,
        AppSpacing.xs,
      ),
      child: Row(
        children: [
          IconButton(
            onPressed: onBack,
            icon: const Icon(
              Icons.arrow_back_rounded,
              color: RmTheme.textPrimary,
              size: 22,
            ),
            splashRadius: 20,
            tooltip: 'Back',
          ),
          SizedBox(width: AppSpacing.xs),
          Text(
            'Select Client',
            style: RmTheme.headline(context).copyWith(fontSize: 22),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(duration: 300.ms)
        .slideX(begin: -0.03, end: 0, duration: 300.ms);
  }
}

// ─── Search Field ────────────────────────────────────────────────────────────

class _SearchField extends StatefulWidget {
  const _SearchField({required this.onChanged});
  final ValueChanged<String> onChanged;

  @override
  State<_SearchField> createState() => _SearchFieldState();
}

class _SearchFieldState extends State<_SearchField> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: AppSpacing.md),
      child: Container(
        decoration: BoxDecoration(
          color: RmTheme.cardSurface,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: RmTheme.borderSubtle.withValues(alpha: 0.15),
            width: 1.5,
          ),
          boxShadow: const [
            BoxShadow(
              color: Color(0x06000000),
              blurRadius: 8,
              offset: Offset(0, 2),
            ),
          ],
        ),
        child: TextField(
          controller: _controller,
          onChanged: (v) {
            widget.onChanged(v);
            setState(() {});
          },
          style: GoogleFonts.inter(
            fontSize: 15,
            fontWeight: FontWeight.w400,
            color: RmTheme.textPrimary,
          ),
          decoration: InputDecoration(
            hintText: 'Search clients',
            hintStyle: GoogleFonts.inter(
              fontSize: 15,
              fontWeight: FontWeight.w400,
              color: const Color(0xFF94A3B8), // textHint
            ),
            prefixIcon: const Padding(
              padding: EdgeInsets.only(left: 16, right: 10),
              child: Icon(
                Icons.search_rounded,
                color: Color(0xFF94A3B8),
                size: 22,
              ),
            ),
            prefixIconConstraints: const BoxConstraints(
              minWidth: 48,
              minHeight: 44,
            ),
            suffixIcon: _controller.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(
                      Icons.close_rounded,
                      size: 18,
                      color: RmTheme.textSecondary,
                    ),
                    onPressed: () {
                      _controller.clear();
                      widget.onChanged('');
                      setState(() {});
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 0,
              vertical: 14,
            ),
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(duration: 350.ms, delay: 80.ms)
        .slideY(begin: -0.04, end: 0, duration: 300.ms, delay: 80.ms);
  }
}

// ─── Client Row ──────────────────────────────────────────────────────────────

class _ClientRow extends StatelessWidget {
  const _ClientRow({
    required this.customer,
    required this.isSelected,
    required this.index,
    required this.onTap,
  });

  final FinanceCustomer customer;
  final bool isSelected;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final metadata = [customer.city, customer.unitCode]
        .where((e) => e != null && e.isNotEmpty)
        .join(' · ');

    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        curve: Curves.easeOutCubic,
        margin: EdgeInsets.symmetric(vertical: AppSpacing.xxs / 2),
        decoration: BoxDecoration(
          color: isSelected
              ? const Color(0xFF1A56FF).withValues(alpha: 0.10)
              : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border(
                  left: BorderSide(
                    color: const Color(0xFF1A56FF),
                    width: 3.5,
                  ),
                )
              : null,
        ),
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: AppSpacing.md,
            vertical: AppSpacing.sm + 2,
          ),
          child: Row(
            children: [
              // ── Content ──
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      customer.customerName,
                      style: GoogleFonts.inter(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                    if (metadata.isNotEmpty) ...[
                      const SizedBox(height: 3),
                      Text(
                        metadata,
                        style: GoogleFonts.inter(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w500,
                          color: RmTheme.textSecondary,
                        ),
                      ),
                    ],
                  ],
                ),
              ),

              // ── Check icon ──
              if (isSelected)
                Container(
                  width: 24,
                  height: 24,
                  decoration: const BoxDecoration(
                    color: Color(0xFF1A56FF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.check_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                )
                    .animate()
                    .fadeIn(duration: 200.ms)
                    .scale(begin: const Offset(0.5, 0.5), end: const Offset(1, 1), duration: 200.ms),
            ],
          ),
        ),
      ),
    )
        .animate()
        .fadeIn(
          duration: 300.ms,
          delay: Duration(milliseconds: 40 * index.clamp(0, 12)),
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.03,
          end: 0,
          duration: 300.ms,
          delay: Duration(milliseconds: 40 * index.clamp(0, 12)),
          curve: Curves.easeOutCubic,
        );
  }
}

// ─── Empty State ─────────────────────────────────────────────────────────────

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.searchQuery});
  final String searchQuery;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: RmTheme.borderSubtle.withValues(alpha: 0.25),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.person_search_outlined,
                color: RmTheme.textSecondary,
                size: 28,
              ),
            ),
            SizedBox(height: AppSpacing.md),
            Text(
              searchQuery.isNotEmpty
                  ? 'No clients match "$searchQuery"'
                  : 'No clients found',
              textAlign: TextAlign.center,
              style: GoogleFonts.inter(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: RmTheme.textSecondary,
              ),
            ),
            SizedBox(height: AppSpacing.xxs),
            Text(
              'Try a different search term',
              style: GoogleFonts.inter(
                fontSize: 13,
                color: RmTheme.textSecondary.withValues(alpha: 0.7),
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
