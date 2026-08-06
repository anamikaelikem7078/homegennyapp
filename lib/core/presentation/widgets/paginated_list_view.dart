import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Lazy-loading list with pagination footer.
class PaginatedListView<T> extends StatelessWidget {
  const PaginatedListView({
    super.key,
    required this.items,
    required this.itemBuilder,
    required this.onLoadMore,
    this.hasMore = false,
    this.isLoadingMore = false,
    this.padding,
    this.separatorBuilder,
    this.emptyTitle = 'No items',
    this.emptyMessage = 'Nothing to show yet.',
  });

  final List<T> items;
  final Widget Function(BuildContext context, T item, int index) itemBuilder;
  final VoidCallback onLoadMore;
  final bool hasMore;
  final bool isLoadingMore;
  final EdgeInsetsGeometry? padding;
  final Widget Function(BuildContext context, int index)? separatorBuilder;
  final String emptyTitle;
  final String emptyMessage;

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty && !isLoadingMore) {
      return DsEmptyState(title: emptyTitle, message: emptyMessage);
    }

    final count = items.length + (hasMore || isLoadingMore ? 1 : 0);

    return ListView.separated(
      padding: padding ?? AppBreakpoints.pagePadding(context),
      itemCount: count,
      separatorBuilder: separatorBuilder ?? (_, __) => SizedBox(height: AppSpacing.sm),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          if (hasMore && !isLoadingMore) {
            WidgetsBinding.instance.addPostFrameCallback((_) => onLoadMore());
          }
          return Padding(
            padding: EdgeInsets.all(AppSpacing.lg),
            child: Center(child: DsPaginationLoader()),
          );
        }
        return DsFadeIn(
          index: index,
          child: itemBuilder(context, items[index], index),
        );
      },
    );
  }
}
