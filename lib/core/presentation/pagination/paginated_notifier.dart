import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/api_response.dart';

/// State for paginated lists with lazy loading.
class PaginatedState<T> {
  const PaginatedState({
    this.items = const [],
    this.page = 1,
    this.hasMore = true,
    this.isLoadingMore = false,
    this.isRefreshing = false,
  });

  final List<T> items;
  final int page;
  final bool hasMore;
  final bool isLoadingMore;
  final bool isRefreshing;

  PaginatedState<T> copyWith({
    List<T>? items,
    int? page,
    bool? hasMore,
    bool? isLoadingMore,
    bool? isRefreshing,
  }) {
    return PaginatedState(
      items: items ?? this.items,
      page: page ?? this.page,
      hasMore: hasMore ?? this.hasMore,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      isRefreshing: isRefreshing ?? this.isRefreshing,
    );
  }
}

/// Base notifier for cursor/page pagination — extend per feature.
abstract class PaginatedNotifier<T> extends StateNotifier<PaginatedState<T>> {
  PaginatedNotifier() : super(const PaginatedState());

  static const defaultPerPage = 20;

  Future<PaginatedResponse<T>> fetchPage(PaginationParams params);

  Future<void> loadInitial() async {
    state = state.copyWith(isRefreshing: true);
    final response = await fetchPage(const PaginationParams(page: 1));
    state = PaginatedState(
      items: response.items,
      page: 1,
      hasMore: response.hasNextPage,
    );
  }

  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore) return;
    state = state.copyWith(isLoadingMore: true);
    final nextPage = state.page + 1;
    final response = await fetchPage(PaginationParams(page: nextPage));
    state = PaginatedState(
      items: [...state.items, ...response.items],
      page: nextPage,
      hasMore: response.hasNextPage,
    );
  }

  Future<void> refresh() => loadInitial();
}

/// Scroll listener helper for infinite scroll.
void onPaginatedScroll({
  required ScrollController controller,
  required VoidCallback loadMore,
  double threshold = 200,
}) {
  if (!controller.hasClients) return;
  final max = controller.position.maxScrollExtent;
  final current = controller.position.pixels;
  if (max - current <= threshold) loadMore();
}
