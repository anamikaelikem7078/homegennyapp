import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../../design_system/design_system.dart';
import '../../../domain/models/staff_models.dart';
import '../../navigation/staff_routes.dart';
import '../../providers/staff_providers.dart';

/// Check-out screen with today's attendance summary and Google Maps.
class StaffCheckOutScreen extends ConsumerStatefulWidget {
  const StaffCheckOutScreen({super.key});

  @override
  ConsumerState<StaffCheckOutScreen> createState() =>
      _StaffCheckOutScreenState();
}

class _StaffCheckOutScreenState extends ConsumerState<StaffCheckOutScreen> {
  GoogleMapController? _mapController;
  bool _verifyingGps = false;
  bool _gpsVerified = false;
  bool _isSubmitting = false;
  String _selectedAddress = 'Green Park, Delhi';
  LatLng _markerPosition = const LatLng(28.6139, 77.2090);

  @override
  void initState() {
    super.initState();
    _simulateGpsVerification();
  }

  Future<void> _simulateGpsVerification() async {
    setState(() => _verifyingGps = true);
    await Future<void>.delayed(const Duration(seconds: 1));
    if (!mounted) return;
    setState(() {
      _verifyingGps = false;
      _gpsVerified = true;
    });
  }

  void _onMapTap(LatLng latLng) {
    setState(() {
      _markerPosition = latLng;
    });
    _mapController?.animateCamera(CameraUpdate.newLatLng(latLng));
    _updateAddressFromLatLng(latLng);
  }

  void _updateAddressFromLatLng(LatLng latLng) {
    // Determine quadrant relative to Delhi center (28.6139, 77.2090)
    String selectedAddress = 'Green Park, Delhi';
    if (latLng.latitude > 28.6139 && latLng.longitude < 77.2090) {
      selectedAddress = 'Safdarjung Enclave, Delhi';
    } else if (latLng.latitude <= 28.6139 && latLng.longitude >= 77.2090) {
      selectedAddress = 'Hauz Khas, Delhi';
    } else if (latLng.latitude > 28.6139 && latLng.longitude >= 77.2090) {
      selectedAddress = 'AIIMS Campus, Delhi';
    } else if (latLng.latitude <= 28.6139 && latLng.longitude < 77.2090) {
      selectedAddress = 'Deer Park, Delhi';
    }
    setState(() {
      _selectedAddress = selectedAddress;
    });
  }

  Future<void> _checkOut() async {
    if (!_gpsVerified) return;

    setState(() => _isSubmitting = true);
    final result = await ref.read(staffRepositoryProvider).checkOut();
    if (!mounted) return;
    setState(() => _isSubmitting = false);

    result.fold(
      onSuccess: (data) {
        ref.invalidate(staffTodayAttendanceProvider);
        ref.invalidate(staffAttendanceHistoryProvider);
        ref.invalidate(staffDashboardProvider);
        context.showDsSnackBar(data.message, type: DsSnackBarType.success);
        context.go(StaffRoutes.attendance);
      },
      onError: (failure) {
        context.showDsSnackBar(failure.message, type: DsSnackBarType.error);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = ref.watch(staffTodayAttendanceProvider);
    final primaryColor = const Color(0xFF1A56FF);
    final textDark = const Color(0xFF0F172A);
    final textGrey = const Color(0xFF64748B);

    final floatCardShadows = [
      BoxShadow(
        color: Colors.black.withOpacity(0.06),
        blurRadius: 20,
        offset: const Offset(0, 10),
      ),
      BoxShadow(
        color: Colors.black.withOpacity(0.02),
        blurRadius: 4,
        offset: const Offset(0, 2),
      ),
    ];

    return Scaffold(
      backgroundColor: const Color(0xFFFBF9F8),
      body: today.when(
        loading: () => const Center(child: DsLoadingWidget(message: 'Loading...')),
        error: (e, _) => DsErrorState(
          title: 'Failed to load',
          message: e.toString(),
          onRetry: () => ref.invalidate(staffTodayAttendanceProvider),
        ),
        data: (record) {
          if (record == null) {
            return const DsEmptyState(
              title: 'No check-in found',
              message: 'You need to check in before checking out.',
              icon: Icons.schedule_rounded,
            );
          }
          if (record.checkOut != null) {
            return DsEmptyState(
              title: 'Already checked out',
              message: 'You checked out at ${record.checkOut}',
              icon: Icons.check_circle_outline_rounded,
              actionLabel: 'Back to attendance',
              onAction: () => context.go(StaffRoutes.attendance),
            );
          }

          final checkInTime = record.checkIn ?? '09:02 AM';

          return Stack(
            children: [
              // 1. Live Immersive Google Map background
              Positioned.fill(
                child: GoogleMap(
                  initialCameraPosition: const CameraPosition(
                    target: LatLng(28.6139, 77.2090),
                    zoom: 14.5,
                  ),
                  onMapCreated: (controller) {
                    _mapController = controller;
                  },
                  onTap: _onMapTap,
                  zoomControlsEnabled: false,
                  myLocationButtonEnabled: false,
                  myLocationEnabled: false,
                ),
              ),

              // 2. Translucent overlay or visual depth elements
              Positioned.fill(
                child: Container(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.white.withOpacity(0.4),
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withOpacity(0.1),
                      ],
                      stops: const [0.0, 0.25, 0.75, 1.0],
                    ),
                  ),
                ),
              ),

              // 3. Fixed center marker tag bubble & location pin pointer
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height * 0.46 - 62,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: floatCardShadows,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.location_on_outlined, color: primaryColor, size: 16),
                        const SizedBox(width: 6),
                        Text(
                          _selectedAddress,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                            color: textDark,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Center Marker Pin Pointer
              Positioned(
                left: 0,
                right: 0,
                top: MediaQuery.of(context).size.height * 0.46 - 18,
                child: Center(
                  child: Icon(
                    Icons.location_pin,
                    color: primaryColor,
                    size: 38,
                  ),
                ),
              ),

              // 4. Transparent Header App Bar
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: Container(
                  padding: EdgeInsets.only(top: MediaQuery.of(context).padding.top + 8, bottom: 8),
                  color: Colors.transparent,
                  child: Row(
                    children: [
                      const SizedBox(width: 8),
                      IconButton(
                        icon: Icon(Icons.arrow_back_ios_new_rounded, color: primaryColor, size: 20),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              'Check Out',
                              style: GoogleFonts.libreCaslonText(
                                color: primaryColor,
                                fontSize: 24,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'End your work day',
                              style: GoogleFonts.inter(
                                color: textGrey,
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 48), // Balancing back button
                    ],
                  ),
                ),
              ),

              // 5. Floating high-depth "3D" status cards
              Positioned(
                top: MediaQuery.of(context).padding.top + 72,
                left: 20,
                right: 20,
                child: Column(
                  children: [
                    // Card 1: Today Status Info
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: floatCardShadows,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryColor,
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: const Center(
                              child: Icon(
                                Icons.check_circle_outline,
                                color: Colors.white,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Today',
                                  style: GoogleFonts.inter(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                    color: textDark,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'In: $checkInTime',
                                  style: GoogleFonts.inter(
                                    fontSize: 13,
                                    color: textGrey,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'PRESENT',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Card 2: Location verified status
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: floatCardShadows,
                        border: Border.all(color: Colors.white.withOpacity(0.8), width: 1),
                      ),
                      child: Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: primaryColor.withOpacity(0.12),
                              borderRadius: BorderRadius.circular(14),
                            ),
                            child: Center(
                              child: Icon(
                                Icons.verified_user_outlined,
                                color: primaryColor,
                                size: 22,
                              ),
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Text(
                              _verifyingGps
                                  ? 'Verifying your location...'
                                  : 'Location verified for check-out',
                              style: GoogleFonts.inter(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                                color: textDark,
                              ),
                            ),
                          ),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              'READY',
                              style: GoogleFonts.inter(
                                fontSize: 10,
                                fontWeight: FontWeight.w700,
                                color: textDark,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Subtitle: Address info floating above map
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      decoration: BoxDecoration(
                        color: Colors.white.withOpacity(0.9),
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: floatCardShadows,
                      ),
                      child: Text(
                        'Work location: $_selectedAddress',
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: textDark,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // 6. Floating Google Map navigation controls (Bottom right)
              Positioned(
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 96,
                child: Column(
                  children: [
                    // Locate GPS Button
                    GestureDetector(
                      onTap: () {
                        _mapController?.animateCamera(
                          CameraUpdate.newLatLngZoom(const LatLng(28.6139, 77.2090), 15),
                        );
                        setState(() {
                          _markerPosition = const LatLng(28.6139, 77.2090);
                          _selectedAddress = 'Green Park, Delhi';
                        });
                      },
                      child: Container(
                        width: 46,
                        height: 46,
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: floatCardShadows,
                        ),
                        child: Icon(Icons.my_location, color: primaryColor, size: 22),
                      ),
                    ),
                    
                    const SizedBox(height: 12),

                    // Zoom Panel
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(16),
                        boxShadow: floatCardShadows,
                      ),
                      child: Column(
                        children: [
                          IconButton(
                            icon: Icon(Icons.add, color: textDark, size: 20),
                            onPressed: () {
                              _mapController?.animateCamera(CameraUpdate.zoomIn());
                            },
                          ),
                          Container(width: 24, height: 1, color: const Color(0xFFF1F5F9)),
                          IconButton(
                            icon: Icon(Icons.remove, color: textDark, size: 20),
                            onPressed: () {
                              _mapController?.animateCamera(CameraUpdate.zoomOut());
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // 7. Dynamic Brand Electric Blue Check Out Button
              Positioned(
                left: 20,
                right: 20,
                bottom: MediaQuery.of(context).padding.bottom + 16,
                child: ElevatedButton(
                  onPressed: _gpsVerified && !_isSubmitting ? _checkOut : null,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: primaryColor, // Signature Electric Blue
                    foregroundColor: Colors.white,
                    elevation: 10,
                    shadowColor: primaryColor.withOpacity(0.3),
                    padding: const EdgeInsets.symmetric(vertical: 18),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                    disabledBackgroundColor: primaryColor.withOpacity(0.5),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                            strokeWidth: 2.5,
                            color: Colors.white,
                          ),
                        )
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.logout_rounded, size: 22, color: Colors.white),
                            const SizedBox(width: 10),
                            Text(
                              'Check Out Now',
                              style: GoogleFonts.inter(
                                fontSize: 16,
                                fontWeight: FontWeight.w700,
                                letterSpacing: 0.5,
                              ),
                            ),
                          ],
                        ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
