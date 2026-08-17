import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/verification_track_placeholder.dart';

/// eChallan track — deferred, see `rm_track1_aadhaar_screen.dart`.
class RmTrack3EChallanScreen extends StatelessWidget {
  const RmTrack3EChallanScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return VerificationTrackPlaceholder(title: 'eChallan Check', staffId: staffId, onBack: () => context.pop());
  }
}
