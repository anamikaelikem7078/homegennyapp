import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Client deployment details screen.
class DeploymentScreen extends ConsumerWidget {
  const DeploymentScreen({super.key});

  Future<void> _directions(BuildContext context, String address) async {
    final uri = Uri.parse('https://www.google.com/maps/search/?api=1&query=${Uri.encodeComponent(address)}');
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      await Clipboard.setData(ClipboardData(text: address));
      if (context.mounted) context.showDsSnackBar('Address copied — paste it into your maps app');
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final deployment = ref.watch(staffDeploymentProvider);
    final address = deployment.valueOrNull?.deploymentAddress;

    return DsPage(
      title: 'Deployment',
      subtitle: 'Your current placement',
      onBack: () => context.canPop() ? context.pop() : context.go(StaffRoutes.home),
      onRefresh: () async => ref.invalidate(staffDeploymentProvider),
      bottom: address == null || address.isEmpty
          ? null
          : DsGradientButton(
              label: 'Get directions',
              icon: Icons.directions_rounded,
              onPressed: () => _directions(context, address),
            ),
      body: dsAsyncBody(
        deployment,
        onRetry: () => ref.invalidate(staffDeploymentProvider),
        builder: (info) {
          if (!info.hasActivePlacement && info.clientName == null) {
            return const [
              DsEmptyBlock(
                icon: Icons.work_off_rounded,
                title: 'No active placement',
                message: 'Your Relationship Manager will assign you to a home soon.',
              ),
            ];
          }
          return [
            DsGradientCard(
              colors: DsGradientCard.green,
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const DsGlassPill('ACTIVE CLIENT', icon: Icons.verified_rounded),
                        const SizedBox(height: 12),
                        Text(
                          info.clientName ?? 'No active client',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            letterSpacing: -0.4,
                            color: Colors.white,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          info.deploymentDate != null ? 'Since ${info.deploymentDate}' : 'Start date pending',
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
                  const DsFloatingIconTile(icon: Icons.home_work_rounded),
                ],
              ),
            ),
            const DsSection('Joining details'),
            DsInfoCard(
              lines: [
                DsInfoLine(Icons.event_rounded, 'Start date', info.deploymentDate ?? '—'),
                DsInfoLine(
                  Icons.badge_rounded,
                  'Placement',
                  info.hasActivePlacement ? 'Active' : 'Pending',
                  valueColor: info.hasActivePlacement ? AppColors.success : AppColors.warning,
                ),
              ],
            ),
            const DsSection('Work location'),
            DsListCard(
              icon: Icons.location_on_rounded,
              title: address ?? 'Address not available',
              subtitle: address == null ? null : 'Tap to copy the address',
              onTap: address == null
                  ? null
                  : () {
                      Clipboard.setData(ClipboardData(text: address));
                      context.showDsSnackBar('Address copied', type: DsSnackBarType.success);
                    },
              trailing: const Icon(Icons.copy_rounded, color: AppColors.primary, size: 20),
            ),
            const DsSection('Documents'),
            DsListCard(
              icon: Icons.description_rounded,
              title: 'View agreement',
              subtitle: 'Your employment agreement for this placement',
              onTap: () => context.push(StaffRoutes.agreement),
            ),
          ];
        },
      ),
    );
  }
}
