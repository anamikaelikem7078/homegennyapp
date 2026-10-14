import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../core/extensions/context_extensions.dart';
import '../../../../design_system/design_system.dart';
import '../../../../design_system/widgets/layout/ds_role_layout.dart';
import '../../domain/models/client_models.dart';

export '../../../../design_system/widgets/layout/ds_role_layout.dart'
    show DsMenuTileStyle, DsKpiCard, DsHeroAvatar;

/// Client detail page scaffold with gradient app bar.
class ClientPageScaffold extends DsPageScaffold {
  const ClientPageScaffold({
    super.key,
    required super.title,
    required super.body,
    super.subtitle,
    super.actions,
    super.floatingActionButton,
    super.showBack = true,
  }) : super(useGradient: true);
}

/// Client navigation tile — white rounded card, orange icon tile.
class ClientMenuTile extends StatelessWidget {
  const ClientMenuTile({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    required this.onTap,
    this.trailing,
    this.badge,
    this.accentColor,
  });

  final IconData icon;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final Widget? trailing;
  final Widget? badge;
  final Color? accentColor;

  @override
  Widget build(BuildContext context) {
    final accent = accentColor ?? AppColors.iconAccent;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: Ink(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
            decoration: AppDecorations.softCard(context),
            child: Row(
              children: [
                Container(
                  width: 44,
                  height: 44,
                  decoration: AppDecorations.iconTile(color: accent, radius: 14),
                  child: Icon(icon, color: accent, size: 22),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: context.colors.onSurface,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w500,
                            color: context.colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (badge != null) badge!,
                trailing ??
                    Container(
                      width: 30,
                      height: 30,
                      decoration: const BoxDecoration(
                        color: AppColors.primaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.chevron_right_rounded,
                        color: AppColors.secondary,
                        size: 20,
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

/// Section header — bold title with a short orange accent bar.
class ClientSectionHeader extends StatelessWidget {
  const ClientSectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 18,
            decoration: BoxDecoration(
              color: AppColors.iconAccent,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              title,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.3,
                color: context.colors.onSurface,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// KPI card for the client dashboard.
class ClientKpiCard extends StatelessWidget {
  const ClientKpiCard({
    super.key,
    required this.label,
    required this.value,
    required this.icon,
    this.color,
    this.subtitle,
    this.onTap,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color? color;
  final String? subtitle;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.iconAccent;
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.lg),
          decoration: AppDecorations.softCard(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: AppDecorations.iconTile(color: accent),
                child: Icon(icon, color: accent, size: 21),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: context.colors.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurfaceVariant,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: AppColors.primaryContainer,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    subtitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primary,
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms).slideY(begin: 0.15, end: 0);
  }
}

/// Assigned staff hero card — blue gradient card with on-duty pulse.
class ClientStaffHeroCard extends StatelessWidget {
  const ClientStaffHeroCard({
    super.key,
    required this.name,
    required this.series,
    required this.staffCode,
    required this.isOnDuty,
    required this.onTap,
    this.heroTag = 'client-staff-hero',
  });

  final String name;
  final String series;
  final String staffCode;
  final bool isOnDuty;
  final VoidCallback onTap;
  final String heroTag;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: BoxDecoration(
          gradient: AppColors.brandGradient,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: AppColors.primary.withValues(alpha: 0.3),
              blurRadius: 24,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(2),
                      decoration: const BoxDecoration(
                        color: AppColors.sunYellow,
                        shape: BoxShape.circle,
                      ),
                      child: DsHeroAvatar(tag: heroTag, name: name, radius: 26),
                    ),
                    if (isOnDuty)
                      Positioned(
                        bottom: 1,
                        right: 1,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: const Color(0xFF22C55E),
                            shape: BoxShape.circle,
                            border: Border.all(color: Colors.white, width: 2),
                          ),
                        )
                            .animate(onPlay: (c) => c.repeat(reverse: true))
                            .scaleXY(begin: 1, end: 1.2, duration: 900.ms),
                      ),
                  ],
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        series,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: isOnDuty
                        ? const Color(0xFF22C55E).withValues(alpha: 0.2)
                        : Colors.white.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: isOnDuty
                          ? const Color(0xFF4ADE80)
                          : Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Text(
                    isOnDuty ? 'On duty' : 'Off duty',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w800,
                      color: isOnDuty ? const Color(0xFFBBF7D0) : Colors.white,
                    ),
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Row(
                children: [
                  const Icon(
                    Icons.badge_rounded,
                    color: AppColors.sunYellow,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    staffCode,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    'View profile',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.arrow_forward_rounded,
                    color: Colors.white,
                    size: 16,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.1, end: 0);
  }
}

String clientPaymentStatusLabel(ClientPaymentStatus status) => switch (status) {
      ClientPaymentStatus.pending => 'Pending',
      ClientPaymentStatus.paid => 'Paid',
      ClientPaymentStatus.overdue => 'Overdue',
      ClientPaymentStatus.processing => 'Processing',
    };

DsStatusType clientPaymentStatusType(ClientPaymentStatus status) => switch (status) {
      ClientPaymentStatus.paid => DsStatusType.success,
      ClientPaymentStatus.pending => DsStatusType.warning,
      ClientPaymentStatus.overdue => DsStatusType.error,
      ClientPaymentStatus.processing => DsStatusType.primary,
    };

String clientComplaintStatusLabel(ClientComplaintStatus status) => switch (status) {
      ClientComplaintStatus.open => 'Open',
      ClientComplaintStatus.inProgress => 'In Progress',
      ClientComplaintStatus.resolved => 'Resolved',
      ClientComplaintStatus.closed => 'Closed',
    };

DsStatusType clientComplaintStatusType(ClientComplaintStatus status) => switch (status) {
      ClientComplaintStatus.resolved => DsStatusType.success,
      ClientComplaintStatus.closed => DsStatusType.primary,
      ClientComplaintStatus.inProgress => DsStatusType.warning,
      ClientComplaintStatus.open => DsStatusType.error,
    };

String clientReplacementStatusLabel(ClientReplacementStatus status) => switch (status) {
      ClientReplacementStatus.pending => 'Pending',
      ClientReplacementStatus.inReview => 'In Review',
      ClientReplacementStatus.approved => 'Approved',
      ClientReplacementStatus.rejected => 'Rejected',
      ClientReplacementStatus.completed => 'Completed',
    };

DsStatusType clientReplacementStatusType(ClientReplacementStatus status) => switch (status) {
      ClientReplacementStatus.completed => DsStatusType.success,
      ClientReplacementStatus.approved => DsStatusType.success,
      ClientReplacementStatus.inReview => DsStatusType.warning,
      ClientReplacementStatus.pending => DsStatusType.primary,
      ClientReplacementStatus.rejected => DsStatusType.error,
    };
