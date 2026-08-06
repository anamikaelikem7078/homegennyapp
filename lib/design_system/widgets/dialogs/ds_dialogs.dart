import 'package:flutter/material.dart';

import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';
import '../buttons/ds_buttons.dart';

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
    return Padding(
      padding: EdgeInsets.fromLTRB(
        AppSpacing.xl,
        AppSpacing.md,
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
                  style: Theme.of(context).textTheme.titleLarge,
                ),
              ),
              if (showClose)
                IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: Icon(Icons.close_rounded),
                ),
            ],
          ),
          SizedBox(height: AppSpacing.md),
          child,
        ],
      ),
    );
  }
}

/// Confirmation dialog with primary and outline actions.
abstract final class DsConfirmationDialog {
  static Future<bool?> show({
    required BuildContext context,
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        title: Text(title),
        content: Text(message),
        actions: [
          DsOutlineButton(
            label: cancelLabel,
            isExpanded: false,
            onPressed: () => Navigator.of(context).pop(false),
          ),
          SizedBox(height: AppSpacing.sm),
          DsPrimaryButton(
            label: confirmLabel,
            isExpanded: false,
            onPressed: () => Navigator.of(context).pop(true),
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
    return showDialog<void>(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.check_circle_rounded,
                color: Colors.green,
                size: 48,
              ),
            ),
            SizedBox(height: AppSpacing.lg),
            Text(title, style: Theme.of(context).textTheme.titleLarge),
            if (message != null) ...[
              SizedBox(height: AppSpacing.sm),
              Text(
                message,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
            ],
            SizedBox(height: AppSpacing.xl),
            DsPrimaryButton(
              label: buttonLabel,
              onPressed: () {
                Navigator.of(context).pop();
                onDone?.call();
              },
            ),
          ],
        ),
      ),
    );
  }
}

/// Loading dialog overlay.
abstract final class DsLoadingDialog {
  static void show(BuildContext context, {String? message}) {
    showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (context) => PopScope(
        canPop: false,
        child: AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: AppRadius.xlAll),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const CircularProgressIndicator(),
              if (message != null) ...[
                SizedBox(height: AppSpacing.lg),
                Text(message, textAlign: TextAlign.center),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static void hide(BuildContext context) {
    Navigator.of(context, rootNavigator: true).pop();
  }
}
