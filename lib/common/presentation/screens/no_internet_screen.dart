import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/network/network_info.dart';
import '../../../core/presentation/widgets/responsive_layout.dart';
import '../../../core/router/app_routes.dart';
import '../widgets/app_button.dart';
import '../widgets/app_widgets.dart';

/// No internet connection screen.
class NoInternetScreen extends ConsumerWidget {
  const NoInternetScreen({super.key});

  Future<void> _retry(BuildContext context, WidgetRef ref) async {
    final isConnected = await ref.read(networkInfoProvider).isConnected;
    if (!context.mounted) return;

    if (isConnected) {
      context.go(AppRoutes.splash);
    } else {
      context.showAppSnackBar(context.l10n.noInternetMessage, isError: true);
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = context.l10n;

    return Scaffold(
      body: SafeArea(
        child: ResponsiveLayout(
          child: Column(
            children: [
              const Spacer(),
              StatusIllustration(
                icon: Icons.wifi_off_rounded,
                title: l10n.noInternetTitle,
                message: l10n.noInternetMessage,
                iconColor: context.colors.primary,
              ),
              const Spacer(),
              Semantics(
                button: true,
                child: AppButton(
                  label: l10n.retry,
                  onPressed: () => _retry(context, ref),
                  icon: Icons.refresh_rounded,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
