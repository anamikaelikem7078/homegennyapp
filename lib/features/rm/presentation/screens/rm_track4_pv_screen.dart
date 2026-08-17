import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/verification_track_placeholder.dart';

/// Police verification track — deferred, see `rm_track1_aadhaar_screen.dart`.
/// Note: unlike Aadhaar/DL/eChallan, `POST /verification/pv/submit/:staffId`
/// is real (not mocked) and the staff row's `pv_status` field already
/// reflects it — see the Verification hub for that read-only status.
class RmTrack4PvScreen extends StatelessWidget {
  const RmTrack4PvScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return VerificationTrackPlaceholder(title: 'Police Verification', staffId: staffId, onBack: () => context.pop());
  }
}
