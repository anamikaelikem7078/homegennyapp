import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../widgets/verification_track_placeholder.dart';

/// Aadhaar eKYC track — deferred for this integration pass (RM asked to
/// skip wiring the 3rd-party-backed verification flows for now). The real
/// endpoint (`POST /verification/aadhaar`, mock mode server-side) and exact
/// request body are documented in `RmRemoteDataSource.verifyAadhaar`,
/// ready to wire up when this track is picked back up.
class RmTrack1AadhaarScreen extends StatelessWidget {
  const RmTrack1AadhaarScreen({super.key, required this.staffId});
  final String staffId;

  @override
  Widget build(BuildContext context) {
    return VerificationTrackPlaceholder(
      title: 'Aadhaar eKYC',
      staffId: staffId,
      onBack: () => context.pop(),
    );
  }
}
