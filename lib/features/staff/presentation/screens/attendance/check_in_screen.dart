import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/maps/location_service.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Check-in screen with selfie capture and GPS verification.
class StaffCheckInScreen extends ConsumerStatefulWidget {
  const StaffCheckInScreen({super.key});

  @override
  ConsumerState<StaffCheckInScreen> createState() => _StaffCheckInScreenState();
}

class _StaffCheckInScreenState extends ConsumerState<StaffCheckInScreen> {
  File? _selfie;
  bool _verifyingGps = false;
  bool _gpsVerified = false;
  bool _isSubmitting = false;
  Position? _position;
  String? _locationLabel;
  bool _resolvingAddress = false;
  String? _locationError;

  @override
  void initState() {
    super.initState();
    _verifyLocation();
  }

  Future<void> _verifyLocation() async {
    setState(() {
      _verifyingGps = true;
      _gpsVerified = false;
      _locationError = null;
      _locationLabel = null;
    });
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      if (!mounted) return;
      setState(() {
        _position = position;
        _verifyingGps = false;
        _gpsVerified = true;
        _resolvingAddress = true;
      });
      // Best-effort; the card shows coordinates if no address comes back.
      final label = await ref.read(locationServiceProvider).reverseGeocodeAddress(
            latitude: position.latitude,
            longitude: position.longitude,
          );
      if (!mounted) return;
      setState(() {
        _locationLabel = label;
        _resolvingAddress = false;
      });
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyingGps = false;
        _gpsVerified = false;
        _locationError = e.message;
      });
    }
  }

  Future<void> _checkIn() async {
    final placementConfirmed = ref.read(staffDeploymentProvider).valueOrNull?.hasActivePlacement ?? false;
    if (!placementConfirmed) {
      context.showDsSnackBar('Attendance unlocks once your placement is confirmed', type: DsSnackBarType.warning);
      return;
    }
    if (_selfie == null) {
      context.showDsSnackBar('Please capture a selfie before checking in', type: DsSnackBarType.warning);
      return;
    }
    if (!_gpsVerified) {
      context.showDsSnackBar('Waiting for GPS verification', type: DsSnackBarType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    // Note: the backend's check-in endpoint only accepts optional
    // latitude/longitude — there is no selfie field. The selfie capture
    // above is a local-only verification step.
    final result = await ref.read(staffRepositoryProvider).checkIn(
          latitude: _position?.latitude,
          longitude: _position?.longitude,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (data) {
        ref.invalidate(staffTodayAttendanceProvider);
        ref.invalidate(staffAttendanceHistoryProvider);
        ref.invalidate(staffDashboardProvider);
        context.showDsSnackBar('Checked in successfully', type: DsSnackBarType.success);
        context.go(StaffRoutes.attendance);
      },
      onError: (failure) => context.showDsSnackBar(failure.message, type: DsSnackBarType.error),
    );
  }

  @override
  Widget build(BuildContext context) {
    final deployment = ref.watch(staffDeploymentProvider);
    final placementConfirmed = deployment.valueOrNull?.hasActivePlacement ?? false;
    void back() => context.canPop() ? context.pop() : context.go(StaffRoutes.attendance);

    // Defends the route itself, not just the hub screen's toggle — a staff
    // member without a confirmed placement has no work site to check in
    // against, so block entry here too regardless of how it was reached.
    if (!deployment.isLoading && !placementConfirmed) {
      return DsPage(
        title: 'Check in',
        subtitle: 'Verify your location and identity',
        onBack: back,
        body: [
          DsEmptyBlock(
            icon: Icons.lock_rounded,
            title: 'Placement not confirmed yet',
            message: 'Attendance can only be marked once you have been deployed to a client.',
            action: DsGradientButton(
              label: 'View deployment status',
              icon: Icons.badge_rounded,
              isExpanded: false,
              onPressed: () => context.go(StaffRoutes.deployment),
            ),
          ),
        ],
      );
    }

    final steps = [_gpsVerified, _selfie != null];
    final done = steps.where((s) => s).length;

    return DsPage(
      title: 'Check in',
      subtitle: 'Verify your location and identity',
      onBack: back,
      bottom: DsGradientButton(
        label: done == 2 ? 'Check in now' : 'Complete $done of 2 steps',
        icon: Icons.fingerprint_rounded,
        isLoading: _isSubmitting,
        onPressed: _selfie != null && _gpsVerified && !_isSubmitting ? _checkIn : null,
      ),
      body: [
        DsGradientCard(
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    DsGlassPill('STEP $done OF 2', icon: Icons.checklist_rounded),
                    const SizedBox(height: 12),
                    Text(
                      done == 2 ? 'All set — check in!' : 'Ready to start your shift?',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 10),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: TweenAnimationBuilder<double>(
                        tween: Tween(end: done / 2),
                        duration: 400.ms,
                        builder: (_, v, _) => LinearProgressIndicator(
                          value: v,
                          minHeight: 7,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                          color: AppColors.sunYellow,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 14),
              const DsFloatingIconTile(icon: Icons.login_rounded),
            ],
          ),
        ),
        const DsSection('1. Location'),
        _GpsStatusCard(
          verifying: _verifyingGps,
          verified: _gpsVerified,
          address: _locationLabel,
          resolvingAddress: _resolvingAddress,
          position: _position,
          error: _locationError,
          workSite: deployment.valueOrNull?.deploymentAddress,
          onRetry: _verifyingGps ? null : _verifyLocation,
        ),
        const DsSection('2. Selfie'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: dsCardDecoration(),
          child: DsImagePicker(
            label: 'Selfie for attendance',
            height: 200,
            initialImage: _selfie,
            onImagePicked: (file) => setState(() => _selfie = file),
          ),
        ),
        const SizedBox(height: 12),
        const DsNote(text: 'Take a clear selfie at your work location. This helps verify your attendance.'),
      ],
    );
  }
}

class _GpsStatusCard extends StatelessWidget {
  const _GpsStatusCard({
    required this.verifying,
    required this.verified,
    required this.resolvingAddress,
    this.address,
    this.position,
    this.error,
    this.workSite,
    this.onRetry,
  });

  final bool verifying;
  final bool verified;
  final bool resolvingAddress;

  /// Full address from the backend (Google); null → show coordinates.
  final String? address;
  final Position? position;
  final String? error;

  /// The client's address from the deployment, to compare against.
  final String? workSite;
  final VoidCallback? onRetry;

  /// Beyond this the fix is too vague to say which house the staff is at.
  static const _impreciseMeters = 100;

  @override
  Widget build(BuildContext context) {
    final (color, icon, title) = verifying
        ? (AppColors.primary, Icons.gps_fixed_rounded, 'Verifying location…')
        : verified
            ? (AppColors.success, Icons.location_on_rounded, 'Location captured')
            : (AppColors.error, Icons.gps_off_rounded, 'Location not verified');
    final p = position;
    final coords = p == null ? null : '${p.latitude.toStringAsFixed(5)}, ${p.longitude.toStringAsFixed(5)}';
    final accuracy = p == null || p.accuracy <= 0 ? null : p.accuracy.round();
    final imprecise = verified && accuracy != null && accuracy > _impreciseMeters;

    final String body;
    if (verifying) {
      body = 'Fetching your current GPS position';
    } else if (!verified) {
      body = error ?? 'Unable to confirm your work location';
    } else if (address != null) {
      body = address!;
    } else if (resolvingAddress) {
      body = 'Finding the address…';
    } else {
      body = coords ?? 'Your GPS location has been recorded';
    }

    final small = GoogleFonts.plusJakartaSans(fontSize: 12, color: AppColors.lightTextSecondary);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: dsCardDecoration(border: color.withValues(alpha: 0.3)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Stack(
                alignment: Alignment.center,
                children: [
                  if (verifying)
                    Container(
                      width: 52,
                      height: 52,
                      decoration: BoxDecoration(color: color.withValues(alpha: 0.12), shape: BoxShape.circle),
                    )
                        .animate(onPlay: (c) => c.repeat())
                        .scaleXY(begin: 0.7, end: 1.3, duration: 1200.ms)
                        .fadeOut(duration: 1200.ms),
                  DsIconTile(icon, color: color, size: 46),
                ],
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14.5,
                              fontWeight: FontWeight.w800,
                              color: AppColors.lightTextPrimary,
                            ),
                          ),
                        ),
                        DsPill(verifying ? 'Checking' : (verified ? 'Verified' : 'Failed'), color: color),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      body,
                      maxLines: 4,
                      overflow: TextOverflow.ellipsis,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        height: 1.35,
                        fontWeight: address != null ? FontWeight.w600 : FontWeight.w400,
                        color: address != null ? AppColors.lightTextPrimary : AppColors.lightTextSecondary,
                      ),
                    ),
                    if (verified && address != null && coords != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(coords, style: small),
                      ),
                    if (accuracy != null && verified)
                      Padding(
                        padding: const EdgeInsets.only(top: 2),
                        child: Text(
                          'Accurate to about $accuracy m',
                          style: small.copyWith(color: imprecise ? AppColors.warning : AppColors.lightTextSecondary),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          if (imprecise) ...[
            const SizedBox(height: 10),
            const DsNote(
              tone: DsNoteTone.warning,
              text: 'Your location is not precise. Step near a window or outside, then tap Refresh.',
            ),
          ],
          if (workSite != null && workSite!.trim().isNotEmpty) ...[
            const SizedBox(height: 10),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.home_work_rounded, size: 16, color: AppColors.lightTextSecondary),
                const SizedBox(width: 6),
                Expanded(child: Text('Work site: ${workSite!.trim()}', style: small)),
              ],
            ),
          ],
          if (!verifying && onRetry != null)
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: Text(verified ? 'Refresh' : 'Retry'),
              ),
            ),
        ],
      ),
    );
  }
}
