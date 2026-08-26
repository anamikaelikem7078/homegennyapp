import 'package:flutter/material.dart';
import '../../../core/extensions/context_extensions.dart';
import 'package:shimmer/shimmer.dart';

import '../../../core/theme/app_colors.dart';
import '../../foundations/app_decorations.dart';
import '../../tokens/app_radius.dart';
import '../../tokens/app_spacing.dart';

/// Shimmer loading placeholder.
class DsShimmerLoader extends StatelessWidget {
  const DsShimmerLoader({
    super.key,
    this.width,
    this.height = 16,
    this.borderRadius,
  });

  final double? width;
  final double height;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Shimmer.fromColors(
      baseColor: isDark ? AppColors.darkSurfaceVariant : AppColors.lightBorder,
      highlightColor:
          isDark ? AppColors.darkBorder : AppColors.lightSurfaceVariant,
      child: Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          color: context.theme.cardColor,
          borderRadius: borderRadius ?? AppRadius.smAll,
        ),
      ),
    );
  }
}

/// Skeleton loader mimicking a list card layout.
class DsSkeletonLoader extends StatelessWidget {
  const DsSkeletonLoader({
    super.key,
    this.itemCount = 3,
    this.showAvatar = true,
  });

  final int itemCount;
  final bool showAvatar;

  @override
  Widget build(BuildContext context) {
    // A plain Column, not a ListView: this loader only ever renders a fixed,
    // small itemCount and is frequently nested inside another scrollable
    // (e.g. AsyncValueWidget used inside a SingleChildScrollView/Column) —
    // a ListView there gets unbounded height and throws
    // "Vertical viewport was given unbounded height".
    return Padding(
      padding: EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          for (var index = 0; index < itemCount; index++) ...[
            if (index > 0) SizedBox(height: AppSpacing.md),
            Container(
              padding: EdgeInsets.all(AppSpacing.lg),
              decoration: AppDecorations.softCard(context),
              child: Row(
                children: [
                  if (showAvatar)
                    const DsShimmerLoader(width: 48, height: 48, borderRadius: BorderRadius.all(Radius.circular(24))),
                  if (showAvatar) SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        DsShimmerLoader(width: double.infinity, height: 14),
                        SizedBox(height: AppSpacing.xs),
                        DsShimmerLoader(width: 120, height: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Centered loading widget with optional message.
class DsLoadingWidget extends StatelessWidget {
  const DsLoadingWidget({
    super.key,
    this.message,
    this.size = 36,
  });

  final String? message;
  final double size;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: const CircularProgressIndicator(
              strokeWidth: 3,
              color: Color(0xFF1A56FF),
            ),
          ),
          if (message != null) ...[
            SizedBox(height: AppSpacing.lg),
            Text(message!, style: Theme.of(context).textTheme.bodyMedium),
          ],
        ],
      ),
    );
  }
}

/// Pagination loader for infinite scroll lists.
class DsPaginationLoader extends StatelessWidget {
  const DsPaginationLoader({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: AppSpacing.xl),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          SizedBox(
            width: 20,
            height: 20,
            child: CircularProgressIndicator(strokeWidth: 2.5),
          ),
          if (message != null) ...[
            SizedBox(width: AppSpacing.sm),
            Text(message!, style: Theme.of(context).textTheme.bodySmall),
          ],
        ],
      ),
    );
  }
}

/// Branded pull-to-refresh wrapper.
class DsRefreshIndicator extends StatelessWidget {
  const DsRefreshIndicator({
    super.key,
    required this.onRefresh,
    required this.child,
    this.color,
  });

  final Future<void> Function() onRefresh;
  final Widget child;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: color ?? AppColors.primary,
      backgroundColor: Theme.of(context).cardColor,
      strokeWidth: 2.5,
      child: child,
    );
  }
}
