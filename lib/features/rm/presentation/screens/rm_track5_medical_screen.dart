import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/verification_track_placeholder.dart';

/// Medical screening track — deferred, see `rm_track1_aadhaar_screen.dart`.
class RmTrack5MedicalScreen extends StatelessWidget {
  const RmTrack5MedicalScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return VerificationTrackPlaceholder(title: 'Medical Screening', staffId: staffId, onBack: () => context.pop());
  }
}
