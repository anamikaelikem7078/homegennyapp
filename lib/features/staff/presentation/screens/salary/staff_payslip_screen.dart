import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/foundations/rm_theme.dart';
import '../../../../rm/presentation/widgets/rm_stage_ui.dart';

/// Demo payslip: net pay hero, earnings/deductions and disbursal info.
class StaffPayslipScreen extends StatelessWidget {
  const StaffPayslipScreen({super.key});

  static const _gross = 18000;
  static const _deductions = [
    ('ESIC (0.75%)', 135),
    ('PF (12% of ₹15k)', 1800),
  ];

  static String _inr(num v) {
    final s = v.round().toString();
    if (s.length <= 3) return '₹$s';
    return '₹${s.substring(0, s.length - 3)},${s.substring(s.length - 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final totalDeductions = _deductions.fold<int>(0, (a, d) => a + d.$2);
    final net = _gross - totalDeductions;

    return RmStageScaffold(
      title: 'Payslip',
      onBack: () {
        if (context.canPop()) context.pop();
      },
      body: [
        _NetPayHero(net: net, gross: _gross, inr: _inr),
        const RmSectionTitle(title: 'Earnings'),
        _LineCard(
          rows: [
            _Line(icon: Icons.account_balance_wallet_rounded, label: 'Gross salary', value: _inr(_gross)),
          ],
        ),
        RmSectionTitle(
          title: 'Deductions',
          trailing: RmStatusPill(label: '- ${_inr(totalDeductions)}', color: RmTheme.crimsonDanger),
        ),
        _LineCard(
          rows: [
            for (final (label, amount) in _deductions)
              _Line(
                icon: Icons.remove_circle_rounded,
                label: label,
                value: '- ${_inr(amount)}',
                negative: true,
              ),
          ],
        ),
        const SizedBox(height: 14),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          decoration: BoxDecoration(
            color: RmTheme.emeraldGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: RmTheme.emeraldGreen.withValues(alpha: 0.25)),
          ),
          child: Row(
            children: [
              Text(
                'Net pay',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.textPrimary,
                ),
              ),
              const Spacer(),
              Text(
                _inr(net),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 20,
                  fontWeight: FontWeight.w800,
                  color: RmTheme.emeraldGreen,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 14),
        const RmNote(
          tone: RmNoteTone.success,
          title: 'Disbursed',
          text: 'Paid via Razorpay on 1 Mar 2024.',
        ),
      ],
    );
  }
}

class _NetPayHero extends StatelessWidget {
  const _NetPayHero({required this.net, required this.gross, required this.inr});
  final int net;
  final int gross;
  final String Function(num) inr;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF064E3B), Color(0xFF059669), Color(0xFF34D399)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: RmTheme.emeraldGreen.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  'MARCH 2024',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10.5,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              Container(
                width: 46,
                height: 46,
                decoration: BoxDecoration(color: Colors.white, borderRadius: BorderRadius.circular(15)),
                child: const Icon(Icons.payments_rounded, color: RmTheme.iconAccent),
              )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .moveY(begin: -3, end: 3, duration: 1400.ms, curve: Curves.easeInOut),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            'Net pay',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: net.toDouble()),
            duration: 1000.ms,
            curve: Curves.easeOutCubic,
            builder: (_, v, _) => Text(
              inr(v),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 40,
                height: 1.1,
                fontWeight: FontWeight.w800,
                letterSpacing: -1.2,
                color: Colors.white,
              ),
            ),
          ),
          const SizedBox(height: 14),
          ClipRRect(
            borderRadius: BorderRadius.circular(5),
            child: LinearProgressIndicator(
              value: net / gross,
              minHeight: 8,
              backgroundColor: Colors.white.withValues(alpha: 0.2),
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${(net / gross * 100).toStringAsFixed(0)}% of gross ${inr(gross)}',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
        ],
      ),
    );
  }
}

class _Line {
  const _Line({required this.icon, required this.label, required this.value, this.negative = false});
  final IconData icon;
  final String label;
  final String value;
  final bool negative;
}

class _LineCard extends StatelessWidget {
  const _LineCard({required this.rows});
  final List<_Line> rows;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: RmTheme.borderSubtle.withValues(alpha: 0.7)),
        boxShadow: RmTheme.subtleShadow,
      ),
      child: Column(
        children: [
          for (var i = 0; i < rows.length; i++) ...[
            if (i > 0) const Divider(height: 1, indent: 68, endIndent: 16, color: RmTheme.borderSubtle),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: RmTheme.iconAccentSoft,
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Icon(rows[i].icon, color: RmTheme.iconAccent, size: 20),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      rows[i].label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: RmTheme.textPrimary,
                      ),
                    ),
                  ),
                  Text(
                    rows[i].value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: rows[i].negative ? RmTheme.crimsonDanger : RmTheme.textPrimary,
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
