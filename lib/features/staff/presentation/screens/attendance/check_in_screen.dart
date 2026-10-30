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
import '../../../data/services/location_sharing_service.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';
import 'location_consent.dart';

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

  /// The house picked by the staff member (only asked with several houses).
  String? _placementId;
  bool _placementTouched = false;

  @override
  void initState() {
    super.initState();
    // The on-duty sharing notice comes before the location permission ask.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      await ensureLocationSharingConsent(context, ref);
      if (mounted) await _verifyLocation();
    });
  }

  /// Pre-selects the house nearest to the GPS fix; the staff member can
  /// still change it.
  void _preselectNearest(List<StaffPlacementOption> placements) {
    final p = _position;
    if (_placementTouched || p == null || placements.length < 2) return;
    final location = ref.read(locationServiceProvider);
    StaffPlacementOption? nearest;
    var best = double.infinity;
    for (final option in placements) {
      if (!option.hasHome) continue;
      final d = location.distanceInMeters(
        startLatitude: p.latitude,
        startLongitude: p.longitude,
        endLatitude: option.homeLat!,
        endLongitude: option.homeLng!,
      );
      if (d < best) {
        best = d;
        nearest = option;
      }
    }
    if (nearest != null && nearest.placementId != _placementId) {
      setState(() => _placementId = nearest!.placementId);
    }
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
      final placements = ref.read(staffPlacementsTodayProvider).valueOrNull?.placements;
      if (placements != null) _preselectNearest(placements);
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

  Future<void> _checkIn(List<StaffPlacementOption> placements) async {
    if (_selfie == null) {
      context.showDsSnackBar('Please capture a selfie before checking in', type: DsSnackBarType.warning);
      return;
    }
    if (placements.length > 1 && _placementId == null) {
      context.showDsSnackBar('Choose the house you are checking in at', type: DsSnackBarType.warning);
      return;
    }

    setState(() => _isSubmitting = true);
    // Note: the backend's check-in endpoint takes latitude/longitude and an
    // optional placement_id — there is no selfie field. The selfie capture
    // above is a local-only verification step. Without GPS the check-in
    // still goes through; the family just can't see the location.
    final result = await ref.read(staffRepositoryProvider).checkIn(
          latitude: _position?.latitude,
          longitude: _position?.longitude,
          placementId: placements.length > 1 ? _placementId : null,
        );
    if (!mounted) return;

    await result.fold(
      onSuccess: (data) async {
        final sharing = hasLocationSharingConsent(ref) &&
            await ref.read(locationSharingServiceProvider).start(intervalSec: data.locationIntervalSec);
        if (!mounted) return;
        setState(() => _isSubmitting = false);
        ref.invalidate(staffPlacementsTodayProvider);
        ref.invalidate(staffTodayAttendanceProvider);
        ref.invalidate(staffAttendanceHistoryProvider);
        ref.invalidate(staffDashboardProvider);

        final where = data.clientName == null ? '' : ' at ${data.clientName}';
        final distance = data.distanceM;
        if (data.atHome == false && distance != null) {
          context.showDsSnackBar(
            'Checked in$where. You are ${formatDistance(distance)} from the client\'s home.',
            type: DsSnackBarType.warning,
          );
        } else if (!sharing) {
          context.showDsSnackBar(
            'Checked in$where. Location is off — the family can\'t see where you are.',
            type: DsSnackBarType.warning,
          );
        } else {
          context.showDsSnackBar('Checked in$where', type: DsSnackBarType.success);
        }
        context.go(StaffRoutes.attendance);
      },
      onError: (failure) async {
        setState(() => _isSubmitting = false);
        // "You work at more than one house — choose …": the list may be
        // stale, so reload it and let the staff member pick.
        if (failure.message.contains('more than one house')) ref.invalidate(staffPlacementsTodayProvider);
        context.showDsSnackBar(failure.message, type: DsSnackBarType.error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final placementsAsync = ref.watch(staffPlacementsTodayProvider);
    final placements = placementsAsync.valueOrNull?.placements ?? const <StaffPlacementOption>[];
    void back() => context.canPop() ? context.pop() : context.go(StaffRoutes.attendance);

    ref.listen(staffPlacementsTodayProvider, (_, next) {
      final list = next.valueOrNull?.placements;
      if (list != null) _preselectNearest(list);
    });

    // Defends the route itself, not just the hub screen's toggle — trial,
    // confirmed and today's one-time visits are listed; nothing listed
    // means there is no house to check in at.
    if (placementsAsync.hasValue && placements.isEmpty) {
      return DsPage(
        title: 'Check in',
        subtitle: 'Verify your location and identity',
        onBack: back,
        body: [
          DsEmptyBlock(
            icon: Icons.lock_rounded,
            title: 'No active placement',
            message: 'You can check in once your RM has placed you.',
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

    StaffPlacementOption? selected;
    for (final p in placements) {
      if (p.placementId == _placementId) selected = p;
    }
    if (placements.length == 1) selected = placements.first;

    // GPS is no longer required: without it the check-in still goes through.
    final gpsDone = _gpsVerified || (!_verifyingGps && _locationError != null);
    final steps = [gpsDone, _selfie != null];
    final done = steps.where((s) => s).length;
    final canSubmit = _selfie != null && !_verifyingGps && !_isSubmitting && placementsAsync.hasValue;

    return DsPage(
      title: 'Check in',
      subtitle: 'Verify your location and identity',
      onBack: back,
      bottom: DsGradientButton(
        label: done == 2 ? 'Check in now' : 'Complete $done of 2 steps',
        icon: Icons.fingerprint_rounded,
        isLoading: _isSubmitting,
        onPressed: canSubmit ? () => _checkIn(placements) : null,
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
          workSite: selected == null ? null : '${selected.clientName}, ${selected.address ?? ''}',
          onRetry: _verifyingGps ? null : _verifyLocation,
        ),
        if (!_verifyingGps && !_gpsVerified) ...[
          const SizedBox(height: 10),
          const DsNote(
            tone: DsNoteTone.warning,
            text: 'You can still check in, but location is off — the family can\'t see where you are.',
          ),
        ],
        if (placements.length > 1) ...[
          const DsSection('Where are you checking in?'),
          for (final option in placements)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _PlacementTile(
                option: option,
                selected: option.placementId == _placementId,
                onTap: () => setState(() {
                  _placementTouched = true;
                  _placementId = option.placementId;
                }),
              ),
            ),
        ],
        const DsSection('2. Selfie'),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: dsCardDecoration(),
          child: DsImagePicker(
            label: 'Selfie for attendance',
            height: 200,
            preferFrontCamera: true,
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

class _PlacementTile extends StatelessWidget {
  const _PlacementTile({required this.option, required this.selected, required this.onTap});

  final StaffPlacementOption option;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final color = selected ? AppColors.primary : AppColors.lightTextSecondary;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: dsCardDecoration(border: selected ? AppColors.primary.withValues(alpha: 0.5) : null),
        child: Row(
          children: [
            Icon(selected ? Icons.radio_button_checked_rounded : Icons.radio_button_off_rounded, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    option.clientName,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14.5,
                      fontWeight: FontWeight.w800,
                      color: AppColors.lightTextPrimary,
                    ),
                  ),
                  if (option.address != null && option.address!.trim().isNotEmpty)
                    Text(
                      option.address!.trim(),
                      style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                    ),
                ],
              ),
            ),
            if (option.today == 'CHECKED_OUT') const DsPill('Done', color: AppColors.success),
          ],
        ),
      ),
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
