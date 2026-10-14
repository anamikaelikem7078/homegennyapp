import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../core/di/injection.dart';
import '../../../../../core/maps/location_service.dart';
import '../../../../../core/utils/date_formatter.dart';
import '../../../../../design_system/design_system.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Check-out screen: live map (top) + today's summary and CTA (bottom panel).
class StaffCheckOutScreen extends ConsumerStatefulWidget {
  const StaffCheckOutScreen({super.key});

  @override
  ConsumerState<StaffCheckOutScreen> createState() => _StaffCheckOutScreenState();
}

class _StaffCheckOutScreenState extends ConsumerState<StaffCheckOutScreen> {
  static const _fallbackPosition = LatLng(28.6139, 77.2090);

  GoogleMapController? _mapController;
  bool _verifyingGps = false;
  bool _gpsVerified = false;
  bool _isSubmitting = false;
  String _selectedAddress = 'Locating…';
  LatLng _markerPosition = _fallbackPosition;

  @override
  void initState() {
    super.initState();
    _verifyLocation();
  }

  Future<void> _verifyLocation() async {
    setState(() => _verifyingGps = true);
    try {
      final position = await ref.read(locationServiceProvider).getCurrentPosition();
      if (!mounted) return;
      final latLng = LatLng(position.latitude, position.longitude);
      setState(() {
        _markerPosition = latLng;
        _verifyingGps = false;
        _gpsVerified = true;
      });
      _mapController?.animateCamera(CameraUpdate.newLatLngZoom(latLng, 16));
      await _updateAddressFromLatLng(latLng);
    } on LocationServiceException catch (e) {
      if (!mounted) return;
      setState(() {
        _verifyingGps = false;
        _gpsVerified = false;
        _selectedAddress = e.message;
      });
    }
  }

  // The check-out location is always the device's real GPS fix — the map is
  // for looking only, so a tap can't move where attendance is recorded.
  Future<void> _updateAddressFromLatLng(LatLng latLng) async {
    setState(() => _selectedAddress = 'Finding the address…');
    final label = await ref.read(locationServiceProvider).reverseGeocodeAddress(
          latitude: latLng.latitude,
          longitude: latLng.longitude,
        );
    if (!mounted) return;
    setState(() {
      _selectedAddress = label ?? '${latLng.latitude.toStringAsFixed(5)}, ${latLng.longitude.toStringAsFixed(5)}';
    });
  }

  Future<void> _checkOut() async {
    if (!_gpsVerified) return;
    HapticFeedback.mediumImpact();
    setState(() => _isSubmitting = true);
    final result = await ref.read(staffRepositoryProvider).checkOut(
          latitude: _markerPosition.latitude,
          longitude: _markerPosition.longitude,
        );
    if (!mounted) return;
    setState(() => _isSubmitting = false);
    result.fold(
      onSuccess: (data) {
        ref.invalidate(staffTodayAttendanceProvider);
        ref.invalidate(staffAttendanceHistoryProvider);
        ref.invalidate(staffDashboardProvider);
        context.showDsSnackBar('Checked out successfully', type: DsSnackBarType.success);
        context.go(StaffRoutes.attendance);
      },
      onError: (failure) => context.showDsSnackBar(failure.message, type: DsSnackBarType.error),
    );
  }

  void _back() => context.canPop() ? context.pop() : context.go(StaffRoutes.attendance);

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(staffTodayAttendanceProvider);

    // Loading / error / nothing-to-check-out states use the standard page.
    final record = today.valueOrNull;
    if (!today.hasValue || record == null || record.checkOut != null) {
      return DsPage(
        title: 'Check out',
        subtitle: 'End your work day',
        onBack: _back,
        body: dsAsyncBody(
          today,
          onRetry: () => ref.invalidate(staffTodayAttendanceProvider),
          builder: (r) => [
            if (r == null)
              const DsEmptyBlock(
                icon: Icons.schedule_rounded,
                title: 'No check-in found',
                message: 'You need to check in before checking out.',
              )
            else
              DsEmptyBlock(
                icon: Icons.check_circle_rounded,
                color: AppColors.success,
                title: 'Already checked out',
                message: 'You checked out at ${DateFormatter.timestamp(r.checkOut)}',
                action: DsGradientButton(
                  label: 'Back to attendance',
                  isExpanded: false,
                  onPressed: () => context.go(StaffRoutes.attendance),
                ),
              ),
          ],
        ),
      );
    }

    final checkInTime = record.checkIn != null ? DateFormatter.timestamp(record.checkIn) : '—';
    final topInset = MediaQuery.paddingOf(context).top;

    return Scaffold(
      backgroundColor: AppColors.lightBackground,
      body: Column(
        children: [
          // ── Map area ────────────────────────────────────────────────
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: _markerPosition, zoom: 16),
                    onMapCreated: (controller) {
                      _mapController = controller;
                      if (_gpsVerified) {
                        controller.animateCamera(CameraUpdate.newLatLngZoom(_markerPosition, 16));
                      }
                    },
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: true,
                  ),
                ),
                // Top fade for legibility of the header.
                Positioned(
                  top: 0,
                  left: 0,
                  right: 0,
                  height: topInset + 90,
                  child: IgnorePointer(
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [Colors.white.withValues(alpha: 0.85), Colors.white.withValues(alpha: 0)],
                        ),
                      ),
                    ),
                  ),
                ),
                // Center pin (always the map's center, any screen size).
                IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.only(bottom: 40),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            constraints: const BoxConstraints(maxWidth: 260),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(14),
                              boxShadow: dsCardShadow,
                            ),
                            child: Text(
                              _selectedAddress,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                          ),
                          const Icon(Icons.location_pin, color: AppColors.iconAccent, size: 40)
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .moveY(begin: -4, end: 0, duration: 700.ms, curve: Curves.easeInOut),
                        ],
                      ),
                    ),
                  ),
                ),
                // Header.
                Positioned(
                  top: topInset + 8,
                  left: dsGutter(context),
                  right: dsGutter(context),
                  child: Row(
                    children: [
                      DsBackButton(onPressed: _back),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Check out',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 20,
                                fontWeight: FontWeight.w800,
                                color: AppColors.lightTextPrimary,
                              ),
                            ),
                            Text(
                              'End your work day',
                              style: GoogleFonts.plusJakartaSans(fontSize: 12.5, color: AppColors.lightTextSecondary),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                // Map controls.
                Positioned(
                  right: dsGutter(context),
                  bottom: 16,
                  child: Column(
                    children: [
                      _MapButton(
                        icon: Icons.my_location_rounded,
                        onTap: _verifyingGps ? null : _verifyLocation,
                        loading: _verifyingGps,
                      ),
                      const SizedBox(height: 10),
                      _MapButton(icon: Icons.add_rounded, onTap: () => _mapController?.animateCamera(CameraUpdate.zoomIn())),
                      const SizedBox(height: 6),
                      _MapButton(icon: Icons.remove_rounded, onTap: () => _mapController?.animateCamera(CameraUpdate.zoomOut())),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // ── Bottom panel ───────────────────────────────────────────
          Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              boxShadow: [
                BoxShadow(color: AppColors.navy.withValues(alpha: 0.1), blurRadius: 24, offset: const Offset(0, -6)),
              ],
            ),
            padding: EdgeInsets.fromLTRB(dsGutter(context), 10, dsGutter(context), 12),
            child: SafeArea(
              top: false,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 44,
                    height: 5,
                    decoration: BoxDecoration(color: AppColors.lightBorder, borderRadius: BorderRadius.circular(3)),
                  ),
                  const SizedBox(height: 14),
                  Row(
                    children: [
                      Expanded(
                        child: _PanelStat(icon: Icons.login_rounded, label: 'Checked in', value: checkInTime),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: _PanelStat(
                          icon: _gpsVerified ? Icons.verified_rounded : Icons.gps_not_fixed_rounded,
                          label: 'Location',
                          value: _verifyingGps ? 'Checking…' : (_gpsVerified ? 'Verified' : 'Not verified'),
                          valueColor: _gpsVerified ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _gpsVerified ? Icons.location_on_rounded : Icons.gps_not_fixed_rounded,
                        size: 18,
                        color: _gpsVerified ? AppColors.success : AppColors.warning,
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          _selectedAddress,
                          maxLines: 3,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12.5,
                            height: 1.35,
                            fontWeight: FontWeight.w600,
                            color: AppColors.lightTextPrimary,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DsGradientButton(
                    label: 'Check out now',
                    icon: Icons.logout_rounded,
                    isLoading: _isSubmitting,
                    onPressed: _gpsVerified && !_isSubmitting ? _checkOut : null,
                  ),
                ],
              ),
            ),
          ).animate().slideY(begin: 1, end: 0, duration: 450.ms, curve: Curves.easeOutCubic),
        ],
      ),
    );
  }
}

class _PanelStat extends StatelessWidget {
  const _PanelStat({required this.icon, required this.label, required this.value, this.valueColor});
  final IconData icon;
  final String label;
  final String value;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppColors.lightBackground, borderRadius: BorderRadius.circular(18)),
      child: Row(
        children: [
          DsIconTile(icon, size: 38),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.lightTextSecondary,
                  ),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      fontWeight: FontWeight.w800,
                      color: valueColor ?? AppColors.lightTextPrimary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _MapButton extends StatelessWidget {
  const _MapButton({required this.icon, required this.onTap, this.loading = false});
  final IconData icon;
  final VoidCallback? onTap;
  final bool loading;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: const CircleBorder(),
      elevation: 3,
      shadowColor: Colors.black26,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 44,
          height: 44,
          child: loading
              ? const Padding(
                  padding: EdgeInsets.all(12),
                  child: CircularProgressIndicator(strokeWidth: 2.2),
                )
              : Icon(icon, color: AppColors.iconAccent, size: 22),
        ),
      ),
    );
  }
}
