import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Agreement status — onboarding document progress.
class AgreementStatusScreen extends ConsumerWidget {
  const AgreementStatusScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final agreement = ref.watch(staffAgreementProvider);
    final status = agreement.valueOrNull?.status;

    return DsPage(
      title: 'Agreement status',
      subtitle: 'Track your onboarding paperwork',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffAgreementProvider),
      bottom: switch (status) {
        AgreementStatus.pending => DsGradientButton(
            label: 'Sign now',
            icon: Icons.draw_rounded,
            onPressed: () => context.push(StaffRoutes.agreementSignature),
          ),
        AgreementStatus.signed => DsOutlineButton(
            label: 'View agreement',
            icon: Icons.description_rounded,
            onPressed: () => context.push(StaffRoutes.agreement),
          ),
        _ => null,
      },
      body: dsAsyncBody(
        agreement,
        onRetry: () => ref.invalidate(staffAgreementProvider),
        builder: (data) {
          final signed = data.status == AgreementStatus.signed;
          final expired = data.status == AgreementStatus.expired;
          final (pill, color) = switch (data.status) {
            AgreementStatus.pending => ('Signature required', AppColors.warning),
            AgreementStatus.signed => ('Signed', AppColors.success),
            AgreementStatus.expired => ('Expired', AppColors.error),
          };
          final done = signed ? 4 : 2;

          return [
            DsGradientCard(
              colors: signed ? DsGradientCard.green : (expired ? DsGradientCard.red : DsGradientCard.blue),
              child: Row(
                children: [
                  SizedBox(
                    width: 74,
                    height: 74,
                    child: TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0, end: done / 4),
                      duration: 900.ms,
                      curve: Curves.easeOutCubic,
                      builder: (_, v, _) => Stack(
                        alignment: Alignment.center,
                        children: [
                          SizedBox.expand(
                            child: CircularProgressIndicator(
                              value: v,
                              strokeWidth: 7,
                              strokeCap: StrokeCap.round,
                              backgroundColor: Colors.white.withValues(alpha: 0.2),
                              color: AppColors.sunYellow,
                            ),
                          ),
                          Text(
                            '$done/4',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Employment agreement',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'The terms between you and the household.',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.4,
                            fontWeight: FontWeight.w500,
                            color: Colors.white.withValues(alpha: 0.85),
                          ),
                        ),
                        const SizedBox(height: 8),
                        DsGlassPill(pill.toUpperCase()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            DsSection('Progress', trailing: DsPill(pill, color: color)),
            DsStepList(
              steps: [
                const DsStep(
                  title: 'Agreement generated',
                  subtitle: 'Prepared by HomeGenny',
                  state: DsStepState.done,
                ),
                const DsStep(
                  title: 'Review completed',
                  subtitle: 'Terms checked by your Relationship Manager',
                  state: DsStepState.done,
                ),
                DsStep(
                  title: 'Digital signature',
                  subtitle: signed
                      ? 'Signed electronically'
                      : expired
                          ? 'The signing window has expired — contact your RM'
                          : 'Waiting for your electronic signature',
                  state: signed ? DsStepState.done : (expired ? DsStepState.failed : DsStepState.active),
                  icon: Icons.draw_rounded,
                  onTap: data.status == AgreementStatus.pending
                      ? () => context.push(StaffRoutes.agreementSignature)
                      : null,
                ),
                DsStep(
                  title: 'Activation',
                  subtitle: 'Full access once the agreement is signed',
                  state: signed ? DsStepState.done : DsStepState.locked,
                ),
              ],
            ),
            if (expired) ...[
              const SizedBox(height: 14),
              const DsNote(
                tone: DsNoteTone.danger,
                title: 'Agreement expired',
                text: 'Ask your Relationship Manager to issue a fresh agreement.',
              ),
            ],
          ];
        },
      ),
    );
  }
}
