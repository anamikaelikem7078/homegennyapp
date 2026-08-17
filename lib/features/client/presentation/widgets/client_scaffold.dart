import 'package:flutter/material.dart';
import '../../../../core/extensions/context_extensions.dart';
import 'package:google_fonts/google_fonts.dart';

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

/// Premium client navigation tile.
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
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.black12),
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: context.colors.surfaceVariant,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(icon, color: accentColor ?? Colors.black87, size: 24),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w400,
                      color: context.colors.onSurface,
                    ),
                  ),
                  if (subtitle != null) ...[
                    SizedBox(height: 2),
                    Text(
                      subtitle!,
                      style: TextStyle(color: context.colors.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            if (badge != null) badge!,
            trailing ?? Icon(Icons.info, color: context.colors.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

class ClientSectionHeader extends StatelessWidget {
  const ClientSectionHeader({super.key, required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppSpacing.md, top: AppSpacing.sm),
      child: Text(
        title.toUpperCase(),
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: context.colors.onSurfaceVariant,
          letterSpacing: 1.2,
        ),
      ),
    );
  }
}

/// Premium KPI card for client dashboard.
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
    return Semantics(
      button: onTap != null,
      label: '$label: $value',
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: EdgeInsets.all(AppSpacing.md),
          decoration: BoxDecoration(
            color: context.theme.cardColor,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.black12),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.03),
                blurRadius: 8,
                spreadRadius: 1,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color?.withValues(alpha: 0.2) ?? Colors.orange.shade100.withValues(alpha: 0.5),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Icon(icon, color: context.colors.onSurface, size: 20),
              ),
              SizedBox(height: AppSpacing.md),
              Text(
                value,
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.w600,
                  color: context.colors.onSurface,
                ),
              ),
              SizedBox(height: 4),
              Text(
                label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: context.colors.onSurfaceVariant,
                  letterSpacing: 0.5,
                ),
              ),
              if (subtitle != null) ...[
                SizedBox(height: 6),
                Text(
                  subtitle!,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: color ?? Colors.brown.shade700,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Assigned staff hero card for premium home UI.
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
          color: context.theme.cardColor,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.orange.shade200, width: 1.5),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 15,
              spreadRadius: 2,
              offset: const Offset(0, 5),
            ),
          ],
        ),
        child: Column(
          children: [
            Row(
              children: [
                Stack(
                  children: [
                    DsHeroAvatar(tag: heroTag, name: name, radius: 26),
                    if (isOnDuty)
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          width: 14,
                          height: 14,
                          decoration: BoxDecoration(
                            color: Colors.green.shade600,
                            shape: BoxShape.circle,
                            border: Border.all(color: context.theme.cardColor, width: 2),
                          ),
                        ),
                      ),
                  ],
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              name,
                              style: GoogleFonts.playfairDisplay(
                                color: context.colors.onSurface,
                                fontSize: 18,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                            decoration: BoxDecoration(
                              color: context.colors.surfaceVariant,
                              borderRadius: BorderRadius.circular(4),
                            ),
                            child: Text(
                              isOnDuty ? 'ON DUTY' : 'OFF DUTY',
                              style: TextStyle(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: context.colors.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ],
                      ),
                      Text(
                        series,
                        style: TextStyle(color: context.colors.onSurfaceVariant, fontSize: 13),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            Row(
              children: [
                Icon(Icons.badge_outlined, color: context.colors.onSurface, size: 18),
                SizedBox(width: 4),
                Text(staffCode, style: TextStyle(color: context.colors.onSurface, fontSize: 13)),
                const Spacer(),
                Icon(Icons.info, color: context.colors.onSurfaceVariant),
              ],
            ),
          ],
        ),
      ),
    );
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
