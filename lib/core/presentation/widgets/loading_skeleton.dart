import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Reusable skeleton placeholder used while content is loading.
class LoadingSkeleton extends StatelessWidget {
  const LoadingSkeleton({super.key, this.itemCount = 4, this.height = 96});

  final int itemCount;
  final double height;

  @override
  Widget build(BuildContext context) {
    return ListView.separated(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: itemCount,
      separatorBuilder: (_, __) => SizedBox(height: AppSpacing.md),
      itemBuilder: (_, __) => Container(
        height: height,
        decoration: BoxDecoration(
          color: Theme.of(
            context,
          ).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
          borderRadius: AppRadius.mdAll,
        ),
        child: const DsShimmerLoader(
          width: double.infinity,
          height: double.infinity,
        ),
      ),
    );
  }
}
