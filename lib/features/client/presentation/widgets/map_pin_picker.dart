import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_maps_flutter/google_maps_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/presentation/widgets/location_address_widget.dart';
import '../../../../design_system/design_system.dart';

/// Opens a full-screen map with a fixed centre pin; returns the pinned
/// point, or null if the user backs out.
Future<LatLng?> pickMapPin(BuildContext context, {LatLng? initial}) =>
    Navigator.of(context).push<LatLng>(
      MaterialPageRoute(fullscreenDialog: true, builder: (_) => _MapPinPage(initial: initial)),
    );

class _MapPinPage extends ConsumerStatefulWidget {
  const _MapPinPage({this.initial});
  final LatLng? initial;

  @override
  ConsumerState<_MapPinPage> createState() => _MapPinPageState();
}

class _MapPinPageState extends ConsumerState<_MapPinPage> {
  /// Used when there is no earlier pin and no GPS fix (New Delhi).
  static const _fallback = LatLng(28.6139, 77.2090);

  late LatLng _center = widget.initial ?? _fallback;
  LatLng? _settled;
  GoogleMapController? _map;

  @override
  void initState() {
    super.initState();
    _settled = widget.initial;
    if (widget.initial == null) _goToMyLocation(quiet: true);
  }

  Future<void> _goToMyLocation({bool quiet = false}) async {
    try {
      final p = await ref.read(locationServiceProvider).getCurrentPosition();
      if (!mounted) return;
      final here = LatLng(p.latitude, p.longitude);
      setState(() => _center = _settled = here);
      await _map?.animateCamera(CameraUpdate.newLatLngZoom(here, 17));
    } catch (e) {
      if (!quiet && mounted) context.showDsSnackBar('$e', type: DsSnackBarType.warning);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = _settled;
    return Scaffold(
      appBar: AppBar(title: const Text('Pin your home')),
      body: Column(
        children: [
          Expanded(
            child: Stack(
              children: [
                Positioned.fill(
                  child: GoogleMap(
                    initialCameraPosition: CameraPosition(target: _center, zoom: widget.initial == null ? 12 : 17),
                    onMapCreated: (c) => _map = c,
                    onCameraMove: (pos) => _center = pos.target,
                    onCameraIdle: () => setState(() => _settled = _center),
                    zoomControlsEnabled: false,
                    myLocationButtonEnabled: false,
                    myLocationEnabled: true,
                  ),
                ),
                const IgnorePointer(
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.only(bottom: 40),
                      child: Icon(Icons.location_on_rounded, size: 48, color: AppColors.primary),
                    ),
                  ),
                ),
                Positioned(
                  right: 16,
                  bottom: 16,
                  child: FloatingActionButton.small(
                    heroTag: 'pin-my-location',
                    tooltip: 'My location',
                    onPressed: _goToMyLocation,
                    child: const Icon(Icons.my_location_rounded),
                  ),
                ),
              ],
            ),
          ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  if (pin != null) LocationAddressWidget(latitude: pin.latitude, longitude: pin.longitude),
                  const SizedBox(height: 12),
                  DsGradientButton(
                    label: 'Use this location',
                    icon: Icons.check_rounded,
                    onPressed: pin == null ? null : () => Navigator.of(context).pop(pin),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
