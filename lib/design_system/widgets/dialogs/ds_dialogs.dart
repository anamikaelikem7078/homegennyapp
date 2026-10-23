import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/ds_buttons.dart';

/// Shared pop-in transition for every design-system dialog.
Future<T?> _showDsDialog<T>({
  required BuildContext context,
  required WidgetBuilder builder,
  bool barrierDismissible = true,
}) {
  return showGeneralDialog<T>(
    context: context,
    barrierDismissible: barrierDismissible,
    barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
    barrierColor: AppColors.navy.withValues(alpha: 0.55),
    transitionDuration: const Duration(milliseconds: 320),
    pageBuilder: (context, _, _) => builder(context),
    transitionBuilder: (context, anim, _, child) {
      final curved = CurvedAnimation(parent: anim, curve: Curves.easeOutBack);
      return FadeTransition(
        opacity: anim,
        child: ScaleTransition(
          scale: Tween(begin: 0.85, end: 1.0).animate(curved),
          child: child,
        ),
      );
    },
  );
}

/// Rounded card used as the body of design-system dialogs.
class DsDialogCard extends StatelessWidget {
  const DsDialogCard({
    super.key,
    required this.children,
    this.padding,
  });

  final List<Widget> children;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      insetPadding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 420),
        // Dialog caps the height to the screen; scroll inside it so tall
        // content still fits in landscape or with large text.
        child: SingleChildScrollView(
          padding: padding ?? const EdgeInsets.fromLTRB(24, 28, 24, 22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: children,
          ),
        ),
      ),
    );
  }
}

/// Circular icon bubble with a soft halo, popping in.
class DsDialogIcon extends StatelessWidget {
  const DsDialogIcon({super.key, required this.icon, required this.color});

  final IconData icon;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        shape: BoxShape.circle,
      ),
      alignment: Alignment.center,
      child: Container(
        width: 54,
        height: 54,
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.18),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: color, size: 30),
      ),
    )
        .animate(delay: 120.ms)
        .scaleXY(begin: 0.4, end: 1, duration: 500.ms, curve: Curves.elasticOut)
        .fadeIn(duration: 200.ms);
  }
}

Widget _dialogTitle(BuildContext context, String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 20,
        fontWeight: FontWeight.w800,
        letterSpacing: -0.4,
        color: Theme.of(context).colorScheme.onSurface,
      ),
    );

Widget _dialogMessage(BuildContext context, String text) => Text(
      text,
      textAlign: TextAlign.center,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 14.5,
        height: 1.45,
        fontWeight: FontWeight.w500,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );

/// Design system bottom sheet helper and widget.
abstract final class DsBottomSheet {
  static Future<T?> show<T>({
    required BuildContext context,
    required String title,
    required Widget child,
    bool showClose = true,
    bool isScrollControlled = true,
  }) {
    return showModalBottomSheet<T>(
      context: context,
      isScrollControlled: isScrollControlled,
      useSafeArea: true,
      showDragHandle: false,
      builder: (context) => Padding(
        padding: EdgeInsets.only(
          bottom: MediaQuery.viewInsetsOf(context).bottom,
        ),
        child: DsBottomSheetContent(
          title: title,
          showClose: showClose,
          child: child,
        ),
      ),
    );
  }
}

class DsBottomSheetContent extends StatelessWidget {
  const DsBottomSheetContent({
    super.key,
    required this.title,
    required this.child,
    this.showClose = true,
  });

  final String title;
  final Widget child;
  final bool showClose;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        14,
        AppSpacing.xl,
        AppSpacing.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Theme.of(context).dividerColor,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          SizedBox(height: AppSpacing.lg),
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 20,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.4,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
              if (showClose)
                Material(
                  color: isDark
                      ? AppColors.darkSurfaceVariant
                      : AppColors.lightSurfaceVariant,
                  shape: const CircleBorder(),
                  child: InkWell(
                    customBorder: const CircleBorder(),
                    onTap: () => Navigator.of(context).pop(),
                    child: const Padding(
                      padding: EdgeInsets.all(8),
                      child: Icon(Icons.close_rounded, size: 20),
                    ),
                  ),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.lg),
          child
              .animate()
              .fadeIn(duration: 300.ms, delay: 80.ms)
              .slideY(begin: 0.08, end: 0, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

/// Confirmation dialog with stacked pill actions.
abstract final class DsConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    IconData? icon,
  }) {
    return _showDsDialog<bool>(
      context: context,
      builder: (context) => DsDialogCard(
        children: [
          DsDialogIcon(
            icon: icon ??
                (isDestructive
                    ? Icons.warning_amber_rounded
                    : Icons.help_outline_rounded),
            color: isDestructive ? AppColors.error : AppColors.iconAccent,
          ),
          const SizedBox(height: 18),
          _dialogTitle(context, title),
          const SizedBox(height: 8),
          _dialogMessage(context, message),
          const SizedBox(height: 24),
          if (isDestructive)
            DsButtonBase(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
              decoration: BoxDecoration(
                color: AppColors.error,
                boxShadow: [
                  BoxShadow(
                    color: AppColors.error.withValues(alpha: 0.35),
                    blurRadius: 18,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Text(
                confirmLabel,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                ),
              ),
            )
          else
            DsPrimaryButton(
              label: confirmLabel,
              onPressed: () => Navigator.of(context).pop(true),
            ),
          const SizedBox(height: 10),
          DsOutlineButton(
            label: cancelLabel,
            onPressed: () => Navigator.of(context).pop(false),
          ),
        ],
      ),
    );
  }
}

/// Success dialog with animated check icon.
abstract final class DsSuccessDialog {
  static Future<void> show({
    required BuildContext context,
    required String title,
    String? message,
    String buttonLabel = 'Done',
    VoidCallback? onDone,
  }) {
    return _showDsDialog<void>(
      context: context,
      builder: (context) => DsDialogCard(
        children: [
          const DsDialogIcon(
            icon: Icons.check_rounded,
            color: AppColors.success,
          ),
          const SizedBox(height: 18),
          _dialogTitle(context, title),
          if (message != null) ...[
            const SizedBox(height: 8),
            _dialogMessage(context, message),
          ],
          const SizedBox(height: 24),
          DsPrimaryButton(
            label: buttonLabel,
            onPressed: () {
              Navigator.of(context).pop();
              onDone?.call();
            },
          ),
        ],
      ),
    );
  }
}

/// Loading dialog overlay.
abstract final class DsLoadingDialog {
  static void show(BuildContext context, {String? message}) {
    _showDsDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: DsDialogCard(
          padding: const EdgeInsets.fromLTRB(24, 30, 24, 26),
          children: [
            const SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(strokeWidth: 3.5),
            ),
            if (message != null) ...[
              const SizedBox(height: 18),
              Text(
                message,
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 15,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
