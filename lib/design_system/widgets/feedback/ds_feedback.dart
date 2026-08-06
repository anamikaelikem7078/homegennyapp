import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

enum DsSnackBarType { info, success, warning, error }

/// Branded snackbar for the design system.
abstract final class DsSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    DsSnackBarType type = DsSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final colors = _colorsFor(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(colors.$1, color: context.theme.cardColor, size: 20),
              SizedBox(width: AppSpacing.sm),
              Expanded(child: Text(message)),
            ],
          ),
          backgroundColor: colors.$2,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppRadius.mdAll),
          duration: duration,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: Colors.white,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static (IconData, Color) _colorsFor(DsSnackBarType type) {
    return switch (type) {
      DsSnackBarType.info => (Icons.info_outline_rounded, AppColors.secondary),
      DsSnackBarType.success => (Icons.check_circle_outline, AppColors.success),
      DsSnackBarType.warning => (Icons.warning_amber_rounded, AppColors.warning),
      DsSnackBarType.error => (Icons.error_outline_rounded, AppColors.error),
    };
  }
}

enum DsToastType { info, success, warning, error }

/// Overlay toast notification.
abstract final class DsToast {
  static OverlayEntry? _currentEntry;

  static void show(
    BuildContext context, {
    required String message,
    DsToastType type = DsToastType.info,
    Duration duration = const Duration(seconds: 3),
  }) {
    _currentEntry?.remove();
    _currentEntry = null;

    final overlay = Overlay.of(context);
    final color = _colorFor(type);
    final icon = _iconFor(type);

    late OverlayEntry entry;
    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        child: Material(
          color: Colors.transparent,
          child: AnimatedSlide(
            duration: const Duration(milliseconds: 300),
            offset: Offset.zero,
            child: Container(
              padding: EdgeInsets.symmetric(
                horizontal: AppSpacing.lg,
                vertical: AppSpacing.md,
              ),
              decoration: BoxDecoration(
                color: color,
                borderRadius: AppRadius.mdAll,
                boxShadow: [
                  BoxShadow(
                    color: color.withValues(alpha: 0.35),
                    blurRadius: 16,
                    offset: const Offset(0, 6),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(icon, color: context.theme.cardColor, size: 20),
                  SizedBox(width: AppSpacing.sm),
                  Expanded(
                    child: Text(
                      message,
                      style: TextStyle(color: context.theme.cardColor,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                  GestureDetector(
                    onTap: () {
                      entry.remove();
                      if (_currentEntry == entry) _currentEntry = null;
                    },
                    child: Icon(Icons.check, color: context.theme.cardColor,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(duration, () {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    });
  }

  static Color _colorFor(DsToastType type) {
    return switch (type) {
      DsToastType.info => AppColors.secondary,
      DsToastType.success => AppColors.success,
      DsToastType.warning => AppColors.warning,
      DsToastType.error => AppColors.error,
    };
  }

  static IconData _iconFor(DsToastType type) {
    return switch (type) {
      DsToastType.info => Icons.info_outline_rounded,
      DsToastType.success => Icons.check_circle_outline,
      DsToastType.warning => Icons.warning_amber_rounded,
      DsToastType.error => Icons.error_outline_rounded,
    };
  }
}
