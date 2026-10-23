import 'package:flutter/material.dart';

import '../onboarding/profile_gate.dart';
import 'connectivity_listener.dart';

/// Root wrapper — offline banner overlay and the app-wide reaction to
/// 403 `PROFILE_INCOMPLETE`.
class AppWrapper extends StatelessWidget {
  const AppWrapper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ProfileGateListener(
      child: Semantics(
        container: true,
        child: Stack(
          fit: StackFit.expand,
          children: [
            child,
            const Positioned(top: 0, left: 0, right: 0, child: OfflineBanner()),
          ],
        ),
      ),
    );
  }
}
