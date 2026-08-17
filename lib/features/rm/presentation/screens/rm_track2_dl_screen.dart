import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/verification_track_placeholder.dart';

/// Driving license track — deferred, see `rm_track1_aadhaar_screen.dart`.
class RmTrack2DlScreen extends StatelessWidget {
  const RmTrack2DlScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return VerificationTrackPlaceholder(title: 'Driving License', staffId: staffId, onBack: () => context.pop());
  }
}
