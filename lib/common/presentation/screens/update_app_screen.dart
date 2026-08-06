import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../widgets/app_button.dart';
import '../widgets/app_widgets.dart';

/// Force update screen.
class UpdateAppScreen extends StatelessWidget {
  const UpdateAppScreen({super.key, this.updateUrl});

  final String? updateUrl;

  Future<void> _openStore() async {
    // In production, use url_launcher to open store URL
    if (updateUrl != null) {
      // await launchUrl(Uri.parse(updateUrl!));
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;

    return PopScope(
      canPop: false,
      child: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              children: [
                const Spacer(),
                StatusIllustration(
                  icon: Icons.system_update_alt_rounded,
                  title: l10n.updateAppTitle,
                  message: l10n.updateAppMessage,
                  iconColor: context.colors.secondary,
                ),
                const Spacer(),
                AppButton(
                  label: l10n.updateNow,
                  onPressed: _openStore,
                  icon: Icons.download_rounded,
                ),
                SizedBox(height: 16),
                TextButton(
                  onPressed: () {
                    // Only for dev — skip update
                    context.go(AppRoutes.splash);
                  },
                  child: Text('Skip (Dev only)'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
