import 'package:flutter/material.dart';

/// A helper wrapper that makes route transitions more consistent and accessible.
class HeroPage extends StatelessWidget {
  const HeroPage({super.key, required this.child, this.tag});

  final Widget child;
  final String? tag;

  @override
  Widget build(BuildContext context) {
    if (tag == null) {
      return child;
    }

    return Hero(tag: tag!, child: child);
  }
}
