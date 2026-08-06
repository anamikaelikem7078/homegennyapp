import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../../tokens/app_durations.dart';

/// Subtle fade + slide-in for list items and cards — no UI redesign.
class DsFadeIn extends StatelessWidget {
  const DsFadeIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.index = 0,
  });

  final Widget child;
  final Duration delay;
  final int index;

  @override
  Widget build(BuildContext context) {
    final stagger = Duration(milliseconds: 40 * index);
    return child
        .animate()
        .fadeIn(
          duration: AppDurations.normal,
          delay: delay + stagger,
          curve: Curves.easeOutCubic,
        )
        .slideY(
          begin: 0.04,
          end: 0,
          duration: AppDurations.normal,
          delay: delay + stagger,
          curve: Curves.easeOutCubic,
        );
  }
}
