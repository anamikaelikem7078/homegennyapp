import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../../core/theme/app_colors.dart';
import '../../tokens/app_spacing.dart';

/// Vertical timeline widget for activity feeds and history.
class DsTimeline extends StatelessWidget {
  const DsTimeline({
    super.key,
    required this.items,
    this.showConnector = true,
  });

  final List<DsTimelineItem> items;
  final bool showConnector;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: List.generate(items.length, (index) {
        final item = items[index];
        final isLast = index == items.length - 1;

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Column(
              children: [
                Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: (item.color ?? AppColors.primary)
                        .withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: item.color ?? AppColors.primary,
                      width: 2,
                    ),
                  ),
                  child: Icon(
                    item.icon ?? Icons.circle,
                    size: 14,
                    color: item.color ?? AppColors.primary,
                  ),
                ),
                if (showConnector && !isLast)
                  Container(
                    width: 2,
                    height: 48,
                    color: Theme.of(context).dividerColor,
                  ),
              ],
            ),
            SizedBox(width: AppSpacing.md),
            Expanded(
              child: Padding(
                padding: EdgeInsets.only(bottom: isLast ? 0 : AppSpacing.lg),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            item.title,
                            style: Theme.of(context)
                                .textTheme
                                .titleSmall
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                        ),
                        if (item.time != null)
                          Text(
                            item.time!,
                            style: Theme.of(context).textTheme.bodySmall,
                          ),
                      ],
                    ),
                    if (item.subtitle != null) ...[
                      SizedBox(height: 4),
                      Text(
                        item.subtitle!,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        )
            .animate(delay: (index * 80).ms)
            .fadeIn(duration: 300.ms)
            .slideX(begin: 0.05, end: 0);
      }),
    );
  }
}

class DsTimelineItem {
  const DsTimelineItem({
    required this.title,
    this.subtitle,
    this.time,
    this.icon,
    this.color,
  });

  final String title;
  final String? subtitle;
  final String? time;
  final IconData? icon;
  final Color? color;
}
