import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../design_system/tokens/app_durations.dart';

/// No transition — used for bottom-nav tab switches.
Page<T> dsNoTransitionPage<T>({required Widget child, LocalKey? key}) {
  return NoTransitionPage(key: key, child: child);
}

/// Shared-axis slide for detail / push routes.
Page<T> dsSlidePage<T>({
  required Widget child,
  LocalKey? key,
  bool fromRight = true,
}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: AppDurations.pageTransition,
    reverseTransitionDuration: AppDurations.pageTransition,
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final begin = Offset(fromRight ? 0.06 : -0.06, 0.0);
      final slide = Tween<Offset>(begin: begin, end: Offset.zero).animate(
        CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
      );
      final fade = CurvedAnimation(parent: animation, curve: Curves.easeOut);
      return FadeTransition(
        opacity: fade,
        child: SlideTransition(position: slide, child: child),
      );
    },
  );
}

/// Fade transition for auth / modal flows.
Page<T> dsFadePage<T>({required Widget child, LocalKey? key}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: AppDurations.pageTransition,
    transitionsBuilder: (context, animation, _, child) =>
        FadeTransition(opacity: animation, child: child),
  );
}

/// Scale + fade for dialogs / sheets.
Page<T> dsScalePage<T>({required Widget child, LocalKey? key}) {
  return CustomTransitionPage(
    key: key,
    child: child,
    transitionDuration: AppDurations.pageTransition,
    transitionsBuilder: (context, animation, _, child) {
      return ScaleTransition(
        scale: Tween<double>(begin: 0.96, end: 1).animate(
          CurvedAnimation(parent: animation, curve: Curves.easeOutCubic),
        ),
        child: FadeTransition(opacity: animation, child: child),
      );
    },
  );
}
