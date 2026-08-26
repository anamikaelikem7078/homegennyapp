import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/extensions/context_extensions.dart';
import '../../../core/router/app_routes.dart';
import '../providers/auth_provider.dart';
import '../widgets/app_widgets.dart';

/// Session expired screen. Logs the user out and returns them to the login
/// screen automatically rather than waiting for a manual tap, since a dead
/// session isn't something the user can act on from here.
class SessionExpiredScreen extends ConsumerStatefulWidget {
  const SessionExpiredScreen({super.key});

  @override
  ConsumerState<SessionExpiredScreen> createState() =>
      _SessionExpiredScreenState();
}

class _SessionExpiredScreenState extends ConsumerState<SessionExpiredScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _autoLogout());
  }

  Future<void> _autoLogout() async {
    // Goes through the notifier (not the repository directly) so
    // `authProvider`'s status flips to `unauthenticated`. Leaving it at
    // `sessionExpired` would make the router's redirect rule bounce
    // `context.go(AppRoutes.login)` straight back to this screen.
    await ref.read(authProvider.notifier).logout();
    if (mounted) {
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 24),
              const CircularProgressIndicator(),
              const Spacer(),
            ],
          ),
        ),
      ),
    );
  }
}
