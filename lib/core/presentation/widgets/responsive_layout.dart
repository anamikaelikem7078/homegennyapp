import 'package:flutter/material.dart';

/// Responsive container that keeps content centered and readable on phones, tablets, and desktops.
class ResponsiveLayout extends StatelessWidget {
  const ResponsiveLayout({
    super.key,
    required this.child,
    this.maxWidth = 920,
    this.padding = const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
  });

  final Widget child;
  final double maxWidth;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    final effectiveMaxWidth = width >= 1200
        ? maxWidth.toDouble()
        : width >= 768
        ? 860.0
        : 720.0;

    return Center(
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: effectiveMaxWidth),
        child: Padding(padding: padding, child: child),
      ),
    );
  }
}
