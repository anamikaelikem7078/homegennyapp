import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/ds_buttons.dart';

/// Empty state illustration with optional action.
class DsEmptyState extends StatelessWidget {
  const DsEmptyState({
    super.key,
    required this.title,
    this.message,
    this.icon = Icons.inbox_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String? message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _DsStateLayout(
      icon: icon,
      iconColor: AppColors.primary,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

/// Error state with retry action.
class DsErrorState extends StatelessWidget {
  const DsErrorState({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return _DsStateLayout(
      icon: Icons.error_outline_rounded,
      iconColor: AppColors.error,
      title: title,
      message: message ?? 'Something went wrong. Please try again.',
      actionLabel: onRetry != null ? retryLabel : null,
      onAction: onRetry,
    );
  }
}

/// No data state for empty lists.
class DsNoDataWidget extends StatelessWidget {
  const DsNoDataWidget({
    super.key,
    this.title = 'No data found',
    this.message = 'There is nothing to show here yet.',
    this.icon = Icons.folder_open_outlined,
    this.actionLabel,
    this.onAction,
  });

  final String title;
  final String message;
  final IconData icon;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return _DsStateLayout(
      icon: icon,
      iconColor: AppColors.secondary,
      title: title,
      message: message,
      actionLabel: actionLabel,
      onAction: onAction,
    );
  }
}

class _DsStateLayout extends StatelessWidget {
  const _DsStateLayout({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
  });

  final IconData icon;
  final Color iconColor;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: EdgeInsets.all(AppSpacing.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                color: iconColor.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(icon, size: 48, color: iconColor),
            )
                .animate()
                .fadeIn(duration: 400.ms)
                .scale(
                  begin: const Offset(0.8, 0.8),
                  end: const Offset(1, 1),
                  curve: Curves.easeOutBack,
                ),
            SizedBox(height: AppSpacing.xl),
            Text(
              title,
              style: Theme.of(context).textTheme.titleLarge,
              textAlign: TextAlign.center,
            ).animate().fadeIn(delay: 100.ms),
            if (message != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                message!,
                style: Theme.of(context).textTheme.bodyMedium,
                textAlign: TextAlign.center,
              ).animate().fadeIn(delay: 200.ms),
            ],
            if (actionLabel != null && onAction != null) ...[
              SizedBox(height: AppSpacing.xl),
              DsPrimaryButton(
                label: actionLabel!,
                onPressed: onAction,
                isExpanded: false,
              ).animate().fadeIn(delay: 300.ms),
            ],
          ],
        ),
      ),
    );
  }
}
