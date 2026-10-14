import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Employment agreement details screen.
class AgreementScreen extends ConsumerWidget {
  const AgreementScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreement = ref.watch(staffAgreementProvider);
    final pending = agreement.valueOrNull?.status == AgreementStatus.pending;

    return DsPage(
      title: 'Agreement',
      subtitle: 'Review employment terms',
      // `canPop()` is false when this is the only stack entry (refresh /
      // direct URL load) — fall back to home so back always works.
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffAgreementProvider),
      actions: [
        DsPageAction(
          icon: Icons.track_changes_rounded,
          tooltip: 'Status',
          onPressed: () => context.push(StaffRoutes.agreementStatus),
        ),
      ],
      bottom: agreement.hasValue
          ? (pending
              ? DsGradientButton(
                  label: 'Sign agreement',
                  icon: Icons.draw_rounded,
                  onPressed: () => context.push(StaffRoutes.agreementSignature),
                )
              : DsOutlineButton(
                  label: 'View status',
                  icon: Icons.track_changes_rounded,
                  onPressed: () => context.push(StaffRoutes.agreementStatus),
                ))
          : null,
      body: dsAsyncBody(
        agreement,
        onRetry: () => ref.invalidate(staffAgreementProvider),
        builder: (data) {
          final (color, icon, label, gradient) = switch (data.status) {
            AgreementStatus.pending => (AppColors.warning, Icons.pending_actions_rounded, 'Pending signature', DsGradientCard.orange),
            AgreementStatus.signed => (AppColors.success, Icons.verified_rounded, 'Signed', DsGradientCard.green),
            AgreementStatus.expired => (AppColors.error, Icons.event_busy_rounded, 'Expired', DsGradientCard.red),
          };
          return [
            DsGradientCard(
              colors: gradient,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsGlassPill(label.toUpperCase(), icon: icon),
                        const SizedBox(height: 12),
                        Text(
                          'Employment agreement',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          data.status == AgreementStatus.pending
                              ? 'Read carefully, then sign below.'
                              : 'A copy is kept on your profile.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  const DsFloatingIconTile(icon: Icons.description_rounded),
                ],
              ),
            ),
            DsSection('Terms', trailing: DsPill(label, color: color)),
            Container(
              padding: const EdgeInsets.all(18),
              decoration: dsCardDecoration(),
              child: _buildRichText(data.content),
            ),
          ];
        },
      ),
    );
  }

  Widget _buildRichText(String text) {
    const companyName = 'HomeGenny Pvt. Ltd.';
    final base = GoogleFonts.plusJakartaSans(fontSize: 14, color: const Color(0xFF374151), height: 1.75);
    final parts = text.split(companyName);
    if (parts.length == 1) return Text(text, style: base);

    final spans = <InlineSpan>[];
    for (var i = 0; i < parts.length; i++) {
      spans.add(TextSpan(text: parts[i]));
      if (i != parts.length - 1) {
        spans.add(
          TextSpan(
            text: companyName,
            style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w800, color: AppColors.primary),
          ),
        );
      }
    }
    return Text.rich(TextSpan(style: base, children: spans));
  }
}
