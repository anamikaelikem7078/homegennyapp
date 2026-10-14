import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';

enum DsSnackBarType { info, success, warning, error }

/// Navy floating snackbar with a colored status chip.
abstract final class DsSnackBar {
  static void show(
    BuildContext context, {
    required String message,
    DsSnackBarType type = DsSnackBarType.info,
    Duration duration = const Duration(seconds: 3),
    String? actionLabel,
    VoidCallback? onAction,
  }) {
    final (icon, color) = _colorsFor(type);

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: color,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: Colors.white, size: 18),
              )
                  .animate()
                  .scaleXY(
                    begin: 0.3,
                    end: 1,
                    duration: 450.ms,
                    curve: Curves.elasticOut,
                  ),
              SizedBox(width: AppSpacing.md),
              Expanded(
                child: Text(
                  message,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w600,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
          backgroundColor: AppColors.navy,
          behavior: SnackBarBehavior.floating,
          padding: const EdgeInsets.fromLTRB(12, 12, 16, 12),
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
          duration: duration,
          action: actionLabel != null
              ? SnackBarAction(
                  label: actionLabel,
                  textColor: AppColors.sunYellow,
                  onPressed: onAction ?? () {},
                )
              : null,
        ),
      );
  }

  static (IconData, Color) _colorsFor(DsSnackBarType type) {
    return switch (type) {
      DsSnackBarType.info => (Icons.info_rounded, AppColors.primary),
      DsSnackBarType.success => (Icons.check_rounded, AppColors.success),
      DsSnackBarType.warning => (Icons.priority_high_rounded, AppColors.warning),
      DsSnackBarType.error => (Icons.close_rounded, AppColors.error),
    };
  }
}

enum DsToastType { info, success, warning, error }

/// Overlay toast notification — white card dropping in from the top.
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
    void dismiss() {
      if (_currentEntry == entry) {
        entry.remove();
        _currentEntry = null;
      }
    }

    entry = OverlayEntry(
      builder: (context) => Positioned(
        top: MediaQuery.paddingOf(context).top + AppSpacing.md,
        left: AppSpacing.md,
        right: AppSpacing.md,
        child: Material(
          color: Colors.transparent,
          child: Container(
            padding: const EdgeInsets.fromLTRB(12, 12, 8, 12),
            decoration: BoxDecoration(
              color: Theme.of(context).cardColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: color.withValues(alpha: 0.25)),
              boxShadow: [
                BoxShadow(
                  color: AppColors.navy.withValues(alpha: 0.15),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(icon, color: color, size: 20),
                ),
                SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    message,
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                ),
                IconButton(
                  onPressed: dismiss,
                  icon: const Icon(Icons.close_rounded, size: 18),
                  visualDensity: VisualDensity.compact,
                ),
              ],
            ),
          )
              .animate()
              .slideY(
                begin: -1.2,
                end: 0,
                duration: 420.ms,
                curve: Curves.easeOutBack,
              )
              .fadeIn(duration: 200.ms),
        ),
      ),
    );

    _currentEntry = entry;
    overlay.insert(entry);

    Future<void>.delayed(duration, dismiss);
  }

  static Color _colorFor(DsToastType type) {
    return switch (type) {
      DsToastType.info => AppColors.primary,
      DsToastType.success => AppColors.success,
      DsToastType.warning => AppColors.warning,
      DsToastType.error => AppColors.error,
    };
  }

  static IconData _iconFor(DsToastType type) {
    return switch (type) {
      DsToastType.info => Icons.info_rounded,
      DsToastType.success => Icons.check_circle_rounded,
      DsToastType.warning => Icons.warning_rounded,
      DsToastType.error => Icons.error_rounded,
    };
  }
}
