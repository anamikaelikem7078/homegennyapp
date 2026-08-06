import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../design_system/design_system.dart';
import '../../extensions/context_extensions.dart';
import '../../router/app_routes.dart';

/// Generic error / not-found screen for router and unhandled failures.
class ErrorNotFoundScreen extends StatelessWidget {
  const ErrorNotFoundScreen({
    super.key,
    this.message,
    this.showHome = true,
  });

  final String? message;
  final bool showHome;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: DsErrorState(
          title: context.l10n.errorGeneric,
          message: message,
          onRetry: showHome ? () => context.go(AppRoutes.splash) : null,
          retryLabel: showHome ? 'Go home' : context.l10n.retry,
        ),
      ),
    );
  }
}
