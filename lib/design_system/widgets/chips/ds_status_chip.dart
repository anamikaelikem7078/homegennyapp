import 'package:flutter/material.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Status chip for labels like Active, Pending, Approved.
class DsStatusChip extends StatelessWidget {
  const DsStatusChip({
    super.key,
    required this.label,
    this.type = DsStatusType.neutral,
    this.icon,
  });

  final String label;
  final DsStatusType type;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final colors = _colors(type);

    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xxs,
      ),
      decoration: BoxDecoration(
        color: colors.$1,
        borderRadius: AppRadius.fullAll,
        border: Border.all(color: colors.$2.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 14, color: colors.$2),
            SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
              color: colors.$2,
              fontSize: 12,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  (Color, Color) _colors(DsStatusType type) {
    return switch (type) {
      DsStatusType.success => (
          AppColors.success.withValues(alpha: 0.12),
          AppColors.success,
        ),
      DsStatusType.warning => (
          AppColors.warning.withValues(alpha: 0.12),
          AppColors.warning,
        ),
      DsStatusType.error => (
          AppColors.error.withValues(alpha: 0.12),
          AppColors.error,
        ),
      DsStatusType.info => (
          AppColors.secondaryContainer,
          AppColors.secondary,
        ),
      DsStatusType.primary => (
          AppColors.primaryContainer,
          AppColors.primary,
        ),
      DsStatusType.neutral => (
          AppColors.lightSurfaceVariant,
          AppColors.lightTextSecondary,
        ),
    };
  }
}

enum DsStatusType {
  success,
  warning,
  error,
  info,
  primary,
  neutral,
}
