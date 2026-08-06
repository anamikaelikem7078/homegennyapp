import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_spacing.dart';
import '../chips/ds_status_chip.dart';

/// Progress overview card with percentage bar.
class DsProgressCard extends StatelessWidget {
  const DsProgressCard({
    super.key,
    required this.title,
    required this.progress,
    this.subtitle,
    this.icon,
    this.color,
    this.onTap,
  });

  final String title;
  final double progress;
  final String? subtitle;
  final IconData? icon;
  final Color? color;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final accent = color ?? AppColors.primary;
    final clamped = progress.clamp(0.0, 1.0);

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (icon != null)
                  Container(
                    padding: EdgeInsets.all(AppSpacing.sm),
                    decoration: BoxDecoration(
                      color: accent.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: accent, size: 22),
                  ),
                if (icon != null) SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(title, style: Theme.of(context).textTheme.titleMedium),
                      if (subtitle != null)
                        Text(subtitle!, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                ),
                Text(
                  '${(clamped * 100).round()}%',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: accent,
                        fontWeight: FontWeight.w700,
                      ),
                ),
              ],
            ),
            SizedBox(height: AppSpacing.md),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: clamped,
                minHeight: 8,
                backgroundColor: accent.withValues(alpha: 0.15),
                color: accent,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.05, end: 0);
  }
}

/// Document file card.
class DsDocumentCard extends StatelessWidget {
  const DsDocumentCard({
    super.key,
    required this.title,
    required this.subtitle,
    this.fileType = 'PDF',
    this.onTap,
    this.onDownload,
  });

  final String title;
  final String subtitle;
  final String fileType;
  final VoidCallback? onTap;
  final VoidCallback? onDownload;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context),
        child: Row(
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.md),
              decoration: BoxDecoration(
                color: AppColors.secondaryContainer,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Text(
                fileType,
                style: const TextStyle(
                  color: AppColors.secondary,
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                ],
              ),
            ),
            if (onDownload != null)
              IconButton(
                onPressed: onDownload,
                icon: Icon(Icons.download_rounded),
              ),
          ],
        ),
      ),
    );
  }
}

/// Attendance summary card.
class DsAttendanceCard extends StatelessWidget {
  const DsAttendanceCard({
    super.key,
    required this.date,
    required this.checkIn,
    this.checkOut,
    required this.status,
    this.onTap,
  });

  final String date;
  final String checkIn;
  final String? checkOut;
  final DsStatusType status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                gradient: AppColors.brandGradient,
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(Icons.check, color: context.theme.cardColor),
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(date, style: Theme.of(context).textTheme.titleSmall),
                  SizedBox(height: 4),
                  Text(
                    'In: $checkIn${checkOut != null ? ' · Out: $checkOut' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
            DsStatusChip(
              label: _statusLabel(status),
              type: status,
            ),
          ],
        ),
      ),
    );
  }

  String _statusLabel(DsStatusType type) => switch (type) {
        DsStatusType.success => 'Present',
        DsStatusType.warning => 'Late',
        DsStatusType.error => 'Absent',
        _ => 'Pending',
      };
}

/// Salary summary card.
class DsSalaryCard extends StatelessWidget {
  const DsSalaryCard({
    super.key,
    required this.month,
    required this.amount,
    required this.status,
    this.onTap,
  });

  final String month;
  final String amount;
  final DsStatusType status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context).copyWith(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppColors.primary.withValues(alpha: 0.08),
              AppColors.secondary.withValues(alpha: 0.08),
            ],
          ),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(month, style: Theme.of(context).textTheme.bodyMedium),
                  SizedBox(height: 4),
                  Text(
                    amount,
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                ],
              ),
            ),
            DsStatusChip(label: _statusLabel(status), type: status),
          ],
        ),
      ),
    );
  }

  String _statusLabel(DsStatusType type) => switch (type) {
        DsStatusType.success => 'Paid',
        DsStatusType.warning => 'Processing',
        DsStatusType.error => 'Failed',
        _ => 'Pending',
      };
}

/// Staff member card.
class DsStaffCard extends StatelessWidget {
  const DsStaffCard({
    super.key,
    required this.name,
    required this.role,
    this.avatarUrl,
    this.department,
    this.onTap,
  });

  final String name;
  final String role;
  final String? avatarUrl;
  final String? department;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _DsPersonCard(
      name: name,
      subtitle: role,
      department: department,
      avatarUrl: avatarUrl,
      accent: AppColors.primary,
      onTap: onTap,
    );
  }
}

/// Client card.
class DsClientCard extends StatelessWidget {
  const DsClientCard({
    super.key,
    required this.name,
    required this.property,
    this.avatarUrl,
    this.status,
    this.onTap,
  });

  final String name;
  final String property;
  final String? avatarUrl;
  final DsStatusType? status;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return _DsPersonCard(
      name: name,
      subtitle: property,
      avatarUrl: avatarUrl,
      accent: AppColors.secondary,
      trailing: status != null
          ? DsStatusChip(label: 'Active', type: status!)
          : null,
      onTap: onTap,
    );
  }
}

/// Notification card.
class DsNotificationCard extends StatelessWidget {
  const DsNotificationCard({
    super.key,
    required this.title,
    required this.message,
    required this.time,
    this.isRead = false,
    this.icon,
    this.onTap,
  });

  final String title;
  final String message;
  final String time;
  final bool isRead;
  final IconData? icon;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context).copyWith(
          color: isRead
              ? null
              : (isDark
                  ? AppColors.primary.withValues(alpha: 0.08)
                  : AppColors.primaryContainer.withValues(alpha: 0.5)),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: EdgeInsets.all(AppSpacing.sm),
              decoration: BoxDecoration(
                color: AppColors.secondary.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon ?? Icons.notifications_outlined,
                color: AppColors.secondary,
                size: 20,
              ),
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
                          title,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.w700),
                        ),
                      ),
                      Text(time, style: Theme.of(context).textTheme.bodySmall),
                    ],
                  ),
                  SizedBox(height: 4),
                  Text(
                    message,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DsPersonCard extends StatelessWidget {
  const _DsPersonCard({
    required this.name,
    required this.subtitle,
    required this.accent,
    this.avatarUrl,
    this.department,
    this.trailing,
    this.onTap,
  });

  final String name;
  final String subtitle;
  final Color accent;
  final String? avatarUrl;
  final String? department;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: EdgeInsets.all(AppSpacing.lg),
        decoration: AppDecorations.softCard(context),
        child: Row(
          children: [
            CircleAvatar(
              radius: 26,
              backgroundColor: accent.withValues(alpha: 0.15),
              backgroundImage:
                  avatarUrl != null ? NetworkImage(avatarUrl!) : null,
              child: avatarUrl == null
                  ? Text(
                      name.isNotEmpty ? name[0].toUpperCase() : '?',
                      style: TextStyle(
                        color: accent,
                        fontWeight: FontWeight.w700,
                        fontSize: 18,
                      ),
                    )
                  : null,
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, style: Theme.of(context).textTheme.titleSmall),
                  Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
                  if (department != null)
                    Text(
                      department!,
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                ],
              ),
            ),
            trailing ?? Icon(Icons.chevron_right_rounded),
          ],
        ),
      ),
    );
  }
}
