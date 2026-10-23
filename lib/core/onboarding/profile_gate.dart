import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../common/presentation/providers/auth_provider.dart';
import '../../design_system/design_system.dart';
import '../router/app_router.dart';
import '../router/app_routes.dart';
import 'onboarding_providers.dart';
import 'profile_gate_bus.dart';

/// Opens the profile wizard at the first missing step.
void openProfileWizard(BuildContext context, WidgetRef ref) {
  final missing = ref.read(onboardingProvider).valueOrNull?.missing ?? const [];
  final route = profileWizardRoute(ref.read(authProvider).user?.role, missing);
  if (route != null) context.push(route);
}

/// Wraps an action screen (check-in, upload, request staff…). Until the
/// profile is complete it shows "Complete your profile first" instead; the
/// server refuses those actions anyway with 403 `PROFILE_INCOMPLETE`.
class ProfileGate extends ConsumerWidget {
  const ProfileGate({super.key, required this.child, this.title});

  final Widget child;

  /// App bar title of the locked view; defaults to "Complete your profile".
  final String? title;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!ref.watch(profileLockedProvider)) return child;
    return DsPage(
      title: title ?? 'Complete your profile',
      onBack: () => context.canPop() ? context.pop() : context.go('/'),
      body: [
        const SizedBox(height: 24),
        const ProfileIncompleteCard(),
      ],
    );
  }
}

/// "Complete your profile first" card with a button into the wizard.
class ProfileIncompleteCard extends ConsumerWidget {
  const ProfileIncompleteCard({super.key, this.compact = false});

  /// Smaller variant for the top of a home screen.
  final bool compact;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Container(
      padding: EdgeInsets.all(compact ? 16 : 20),
      decoration: BoxDecoration(
        color: AppColors.warning.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              const Icon(Icons.lock_rounded, color: AppColors.warning, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Complete your profile first',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: compact ? 15 : 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.lightTextPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'You can look around, but actions stay locked until your profile is done. It takes about two minutes.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w500,
              color: AppColors.lightTextSecondary,
            ),
          ),
          const SizedBox(height: 14),
          DsGradientButton(
            label: 'Complete profile',
            icon: Icons.arrow_forward_rounded,
            onPressed: () => openProfileWizard(context, ref),
          ),
        ],
      ),
    );
  }
}

/// App-wide reaction to 403 `PROFILE_INCOMPLETE`: refresh the onboarding
/// status and open the wizard at the first missing step. Sits above the
/// Navigator (in `AppWrapper`), so it navigates through the router itself.
class ProfileGateListener extends ConsumerStatefulWidget {
  const ProfileGateListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<ProfileGateListener> createState() => _ProfileGateListenerState();
}

class _ProfileGateListenerState extends ConsumerState<ProfileGateListener> {
  StreamSubscription<List<String>>? _sub;
  DateTime? _lastOpened;

  @override
  void initState() {
    super.initState();
    _sub = ProfileGateBus.instance.onProfileIncomplete.listen(_onIncomplete);
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }

  void _onIncomplete(List<String> missing) {
    ref.invalidate(onboardingProvider);
    final router = ref.read(routerProvider);
    final path = router.routerDelegate.currentConfiguration.uri.path;
    if (path == AppRoutes.staffCompleteProfile || path == AppRoutes.clientCompleteProfile) return;
    // Several refused calls can land together — open the wizard once.
    final now = DateTime.now();
    if (_lastOpened != null && now.difference(_lastOpened!) < const Duration(seconds: 3)) return;
    final route = profileWizardRoute(ref.read(authProvider).user?.role, missing);
    if (route == null) return;
    _lastOpened = now;
    router.push(route);
  }

  @override
  Widget build(BuildContext context) => widget.child;
}
