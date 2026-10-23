import 'package:flutter/material.dart';

/// For full-screen layouts built as a [Column] with [Spacer]s (content
/// centered, button pinned to the bottom).
///
/// On tall screens it looks exactly like the plain Column; on short ones
/// (landscape phones, split screen, large text) it scrolls instead of
/// overflowing. A plain SingleChildScrollView would break the Spacers.
class ScrollableFill extends StatelessWidget {
  const ScrollableFill({super.key, required this.child, this.padding});

  /// Usually a Column with Spacers / Expanded.
  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: padding,
        child: ConstrainedBox(
          constraints: BoxConstraints(
            minHeight: constraints.maxHeight - (padding?.vertical ?? 0),
          ),
          child: IntrinsicHeight(child: child),
        ),
      ),
    );
  }
}
