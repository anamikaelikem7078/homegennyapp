import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/di/injection.dart';
import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../widgets/app_button.dart';
import '../widgets/app_widgets.dart';

/// Session expired screen.
class SessionExpiredScreen extends ConsumerWidget {
  const SessionExpiredScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Spacer(),
              StatusIllustration(
                icon: Icons.timer_off_outlined,
                title: l10n.sessionExpiredTitle,
                message: l10n.sessionExpiredMessage,
                iconColor: context.colors.error,
              ),
              const Spacer(),
              AppButton(
                label: l10n.signInAgain,
                onPressed: () async {
                  await ref.read(authRepositoryProvider).logout();
                  if (context.mounted) {
                    context.go(AppRoutes.login);
                  }
                },
                icon: Icons.login_rounded,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
