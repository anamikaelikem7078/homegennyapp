import 'package:flutter/material.dart';

import '../../../design_system/design_system.dart';

/// Consistent error view for failed requests and unexpected states.
class AppErrorView extends StatelessWidget {
  const AppErrorView({
    super.key,
    required this.title,
    this.message,
    this.onRetry,
    this.retryLabel = 'Try again',
  });

  final String title;
  final String? message;
  final VoidCallback? onRetry;
  final String retryLabel;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: DsErrorState(
        title: title,
        message: message,
        onRetry: onRetry,
        retryLabel: retryLabel,
      ),
    );
  }
}
