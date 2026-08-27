import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../design_system/design_system.dart';
import '../auth/session_event_bus.dart';
import '../exceptions/failures.dart';
import '../extensions/context_extensions.dart';

/// DRY wrapper for Riverpod [AsyncValue] with skeleton, error retry, and a11y.
class AsyncValueWidget<T> extends StatelessWidget {
  const AsyncValueWidget({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.loadingMessage,
    this.useSkeleton = true,
    this.skeletonCount = 4,
    this.errorTitle,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? loadingMessage;
  final bool useSkeleton;
  final int skeletonCount;
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => useSkeleton
          ? DsSkeletonLoader(itemCount: skeletonCount)
          : DsLoadingWidget(message: loadingMessage ?? context.l10n.loading),
      error: (error, _) {
        if (error is AuthFailure) {
          SessionEventBus.instance.notifySessionExpired();
        }
        return DsErrorState(
          title: errorTitle ?? context.l10n.errorGeneric,
          message: error.toString(),
          onRetry: onRetry,
        );
      },
      data: builder,
    );
  }
}

/// Sliver variant for nested scroll views.
class AsyncValueSliverWidget<T> extends StatelessWidget {
  const AsyncValueSliverWidget({
    super.key,
    required this.value,
    required this.builder,
    this.onRetry,
    this.errorTitle,
  });

  final AsyncValue<T> value;
  final Widget Function(T data) builder;
  final VoidCallback? onRetry;
  final String? errorTitle;

  @override
  Widget build(BuildContext context) {
    return value.when(
      loading: () => const SliverFillRemaining(
        child: DsLoadingWidget(),
      ),
      error: (error, _) {
        if (error is AuthFailure) {
          SessionEventBus.instance.notifySessionExpired();
        }
        return SliverFillRemaining(
          child: DsErrorState(
            title: errorTitle ?? context.l10n.errorGeneric,
            onRetry: onRetry,
          ),
        );
      },
      data: (data) => builder(data),
    );
  }
}
